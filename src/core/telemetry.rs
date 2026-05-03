//! Local telemetry identity helpers.
//!
//! Remote telemetry/network sending is intentionally disabled in the rtk-tx v1
//! fork. Local SQLite tracking for `gain` remains implemented in
//! [`crate::core::tracking`].

use super::constants::RTK_DATA_DIR;
use sha2::{Digest, Sha256};
use std::fmt::Write as FmtWrite;
use std::io::Write as IoWrite;
use std::path::PathBuf;
use std::sync::OnceLock;

static CACHED_SALT: OnceLock<String> = OnceLock::new();

/// Remote telemetry is disabled for rtk-tx v1.
///
/// This function remains as a compatibility hook for the existing startup flow,
/// but it never reads config, spawns a thread, compiles an endpoint, or performs
/// network I/O regardless of build-time environment variables.
pub fn maybe_ping() {}

pub fn generate_device_hash() -> String {
    let salt = get_or_create_salt();
    let mut hasher = Sha256::new();
    hasher.update(salt.as_bytes());
    format!("{:x}", hasher.finalize())
}

fn get_or_create_salt() -> String {
    CACHED_SALT
        .get_or_init(|| {
            let salt_path = salt_file_path();

            if let Ok(contents) = std::fs::read_to_string(&salt_path) {
                let trimmed = contents.trim().to_string();
                if trimmed.len() == 64 && trimmed.chars().all(|c| c.is_ascii_hexdigit()) {
                    return trimmed;
                }
            }

            let salt = random_salt();
            if let Some(parent) = salt_path.parent() {
                let _ = std::fs::create_dir_all(parent);
            }
            if let Ok(mut f) = std::fs::File::create(&salt_path) {
                let _ = f.write_all(salt.as_bytes());
                #[cfg(unix)]
                {
                    use std::os::unix::fs::PermissionsExt;
                    let _ = std::fs::set_permissions(
                        &salt_path,
                        std::fs::Permissions::from_mode(0o600),
                    );
                }
            }
            salt
        })
        .clone()
}

fn random_salt() -> String {
    let mut buf = [0u8; 32];
    if getrandom::fill(&mut buf).is_err() {
        let fallback = format!("{:?}:{}", std::time::SystemTime::now(), std::process::id());
        let mut hasher = Sha256::new();
        hasher.update(fallback.as_bytes());
        return format!("{:x}", hasher.finalize());
    }
    buf.iter().fold(String::new(), |mut output, b| {
        let _ = write!(output, "{b:02x}");
        output
    })
}

pub fn salt_file_path() -> PathBuf {
    dirs::data_local_dir()
        .unwrap_or_else(|| PathBuf::from("/tmp"))
        .join(RTK_DATA_DIR)
        .join(".device_salt")
}

pub fn telemetry_marker_path() -> PathBuf {
    let data_dir = dirs::data_local_dir()
        .unwrap_or_else(|| PathBuf::from("/tmp"))
        .join(RTK_DATA_DIR);
    let _ = std::fs::create_dir_all(&data_dir);
    data_dir.join(".telemetry_last_ping")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_maybe_ping_is_noop_even_with_telemetry_url_env() {
        let marker_path = dirs::data_local_dir()
            .unwrap_or_else(|| PathBuf::from("/tmp"))
            .join(crate::core::constants::RTK_DATA_DIR)
            .join(".telemetry_last_ping");
        let before = std::fs::metadata(&marker_path)
            .ok()
            .and_then(|m| m.modified().ok());

        let previous_url = std::env::var_os("RTK_TELEMETRY_URL");
        let previous_endpoint = std::env::var_os("RTK_TELEMETRY_ENDPOINT");
        let previous_token = std::env::var_os("RTK_TELEMETRY_TOKEN");
        std::env::set_var("RTK_TELEMETRY_URL", "http://127.0.0.1:9/rtk-test");
        std::env::set_var("RTK_TELEMETRY_ENDPOINT", "http://127.0.0.1:9/rtk-test");
        std::env::set_var("RTK_TELEMETRY_TOKEN", "test-token");

        maybe_ping();

        match previous_url {
            Some(value) => std::env::set_var("RTK_TELEMETRY_URL", value),
            None => std::env::remove_var("RTK_TELEMETRY_URL"),
        }
        match previous_endpoint {
            Some(value) => std::env::set_var("RTK_TELEMETRY_ENDPOINT", value),
            None => std::env::remove_var("RTK_TELEMETRY_ENDPOINT"),
        }
        match previous_token {
            Some(value) => std::env::set_var("RTK_TELEMETRY_TOKEN", value),
            None => std::env::remove_var("RTK_TELEMETRY_TOKEN"),
        }

        let after = std::fs::metadata(&marker_path)
            .ok()
            .and_then(|m| m.modified().ok());
        assert_eq!(after, before);
    }

    #[test]
    fn test_device_hash_is_stable() {
        let h1 = generate_device_hash();
        let h2 = generate_device_hash();
        assert_eq!(h1, h2);
        assert_eq!(h1.len(), 64);
    }

    #[test]
    fn test_device_hash_is_valid_hex() {
        let hash = generate_device_hash();
        assert!(hash.chars().all(|c| c.is_ascii_hexdigit()));
    }

    #[test]
    fn test_salt_is_persisted() {
        let s1 = get_or_create_salt();
        let s2 = get_or_create_salt();
        assert_eq!(s1, s2);
        assert_eq!(s1.len(), 64);
        assert!(s1.chars().all(|c| c.is_ascii_hexdigit()));
    }

    #[test]
    fn test_random_salt_uniqueness() {
        let s1 = random_salt();
        let s2 = random_salt();
        assert_ne!(s1, s2);
        assert_eq!(s1.len(), 64);
        assert_eq!(s2.len(), 64);
    }

    #[test]
    fn test_salt_file_path_is_in_rtk_tx_dir() {
        let path = salt_file_path();
        assert!(path.to_string_lossy().contains("rtk-tx"));
        assert!(path.to_string_lossy().contains(".device_salt"));
    }

    #[test]
    fn test_marker_path_is_in_rtk_tx_dir() {
        let path = telemetry_marker_path();
        assert!(path.to_string_lossy().contains("rtk-tx"));
    }
}
