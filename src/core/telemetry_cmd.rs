use anyhow::{Context, Result};
use clap::Subcommand;

#[derive(Debug, Subcommand)]
pub enum TelemetrySubcommand {
    Status,
    Enable,
    Disable,
    Forget,
}

pub fn run(command: &TelemetrySubcommand) -> Result<()> {
    match command {
        TelemetrySubcommand::Status => run_status(),
        TelemetrySubcommand::Enable => run_enable(),
        TelemetrySubcommand::Disable => run_disable(),
        TelemetrySubcommand::Forget => run_forget(),
    }
}

fn run_status() -> Result<()> {
    let config = crate::core::config::Config::load().unwrap_or_default();

    let consent_str = match config.telemetry.consent_given {
        Some(true) => "yes",
        Some(false) => "no",
        None => "never asked",
    };

    let enabled_str = if config.telemetry.enabled {
        "yes"
    } else {
        "no"
    };

    let env_override = std::env::var("RTK_TELEMETRY_DISABLED").unwrap_or_default() == "1";

    println!("Telemetry status:");
    println!("  consent:       {}", consent_str);
    if let Some(date) = &config.telemetry.consent_date {
        println!("  consent date:  {}", date);
    }
    println!("  enabled:       {}", enabled_str);
    if env_override {
        println!("  env override:  RTK_TELEMETRY_DISABLED=1 (blocked)");
    }
    println!("  remote send:   disabled in rtk-tx v1 (no network telemetry)");
    println!("  local gain:    enabled via local SQLite tracking");

    let salt_path = super::telemetry::salt_file_path();
    if salt_path.exists() {
        let hash = super::telemetry::generate_device_hash();
        println!("  device hash:   {}...{}", &hash[..8], &hash[56..]);
    } else {
        println!("  device hash:   (no salt file)");
    }

    println!();
    println!("Remote telemetry is absent from this rtk-tx v1 fork.");
    println!("Details: docs/TELEMETRY.md");

    Ok(())
}

fn run_enable() -> Result<()> {
    crate::hooks::init::save_telemetry_consent(false)?;
    println!("Remote telemetry is disabled/absent in rtk-tx v1.");
    println!("No network sending was enabled. Local SQLite tracking/gain remains available.");

    Ok(())
}

fn run_disable() -> Result<()> {
    crate::hooks::init::save_telemetry_consent(false)?;
    println!("Telemetry disabled.");
    Ok(())
}

fn run_forget() -> Result<()> {
    crate::hooks::init::save_telemetry_consent(false)?;

    let salt_path = super::telemetry::salt_file_path();
    let marker_path = super::telemetry::telemetry_marker_path();

    if salt_path.exists() {
        std::fs::remove_file(&salt_path)
            .with_context(|| format!("Failed to delete {}", salt_path.display()))?;
    }

    if marker_path.exists() {
        let _ = std::fs::remove_file(&marker_path);
    }

    // Purge local tracking database (GDPR Art. 17 — right to erasure applies to local data too)
    let db_path = crate::core::tracking::get_db_path()?;
    if db_path.exists() {
        match std::fs::remove_file(&db_path) {
            Ok(()) => println!("Local tracking database deleted: {}", db_path.display()),
            Err(e) => eprintln!("rtk: could not delete {}: {}", db_path.display(), e),
        }
    }

    println!("Local telemetry data deleted. Telemetry disabled.");
    println!("Remote telemetry is disabled/absent in rtk-tx v1; no server erasure request was sent or needed.");
    Ok(())
}
