use std::process::Command;

fn git(args: &[&str]) -> Option<String> {
    let out = Command::new("git").args(args).output().ok()?;
    out.status.success().then(|| String::from_utf8_lossy(&out.stdout).trim().to_string())
}

fn main() {
    let sha = git(&["rev-parse", "--short", "HEAD"]).unwrap_or_else(|| "unknown".into());
    let dirty = git(&["status", "--porcelain", "."]).is_some_and(|s| !s.is_empty());
    let built = Command::new("date").arg("+%-d %b %Y %H:%M").output().ok()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_else(|| "unknown".into());
    println!(
        "cargo:rustc-env=BUILD_INFO={} ({}{}, built {})",
        env!("CARGO_PKG_VERSION"), sha, if dirty { "-dirty" } else { "" }, built
    );
    for p in ["../.git/HEAD", "../.git/index"] {
        println!("cargo:rerun-if-changed={p}");
    }
}
