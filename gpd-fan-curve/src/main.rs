//! Quiet fan curve for GPD devices: drives the `gpd_fan` hwmon in manual mode from the CPU
//! temperature (k10temp Tctl) and hands control back to the EC on exit or on any error.

use std::{
    fs,
    path::PathBuf,
    sync::{
        Arc,
        atomic::{AtomicBool, Ordering},
    },
    thread,
    time::Duration,
};

use clap::{CommandFactory, Parser, Subcommand};

#[derive(Parser)]
#[command(version = env!("BUILD_INFO"), about, after_help = "\
Examples:
  gpd-fan-curve status                 temperature, fan speed and mode
  sudo gpd-fan-curve run               apply the default curve (systemd runs this)
  sudo gpd-fan-curve run --off-below 45 --curve 55:70,70:140,80:255
  gpd-fan-curve completions fish > ~/.config/fish/completions/gpd-fan-curve.fish")]
struct Cli {
    #[command(subcommand)]
    cmd: Cmd,
}

#[derive(Subcommand)]
enum Cmd {
    /// Show CPU temperature, fan RPM, mode and PWM
    Status,
    /// Run the fan curve until stopped; restores EC control on exit
    Run {
        /// Curve points TEMP_C:PWM (0-255), ascending; linear between points, full speed above the last
        #[arg(long, default_value = "55:70,65:110,75:170,85:255", value_parser = parse_curve)]
        curve: Curve,
        /// Fan stops when the temperature falls below this (°C), and starts again at the first curve point
        #[arg(long, default_value_t = 48.0)]
        off_below: f64,
        /// Seconds between updates
        #[arg(long, default_value_t = 2)]
        interval: u64,
        /// Largest PWM drop per update, so the fan winds down gently
        #[arg(long, default_value_t = 10)]
        step_down: u8,
    },
    /// Print a shell completion script
    Completions { shell: clap_complete::Shell },
}

#[derive(Clone)]
struct Curve(Vec<(f64, u8)>);

fn parse_curve(s: &str) -> Result<Curve, String> {
    let mut pts = Vec::new();
    for p in s.split(',') {
        let (t, v) = p.split_once(':').ok_or(format!("'{p}': expected TEMP:PWM"))?;
        let t: f64 = t.trim().parse().map_err(|_| format!("'{t}': not a temperature"))?;
        let v: u8 = v.trim().parse().map_err(|_| format!("'{v}': PWM must be 0-255"))?;
        pts.push((t, v));
    }
    if pts.windows(2).any(|w| w[1].0 <= w[0].0) {
        return Err("curve temperatures must ascend".into());
    }
    Ok(Curve(pts))
}

impl Curve {
    fn pwm(&self, t: f64) -> u8 {
        let p = &self.0;
        if t <= p[0].0 {
            return p[0].1;
        }
        for w in p.windows(2) {
            let ((t0, v0), (t1, v1)) = (w[0], w[1]);
            if t <= t1 {
                return (v0 as f64 + (v1 as f64 - v0 as f64) * (t - t0) / (t1 - t0)).round() as u8;
            }
        }
        255
    }
}

fn hwmon(name: &str) -> Result<PathBuf, String> {
    for e in fs::read_dir("/sys/class/hwmon").map_err(|e| e.to_string())? {
        let p = e.map_err(|e| e.to_string())?.path();
        if fs::read_to_string(p.join("name")).is_ok_and(|n| n.trim() == name) {
            return Ok(p);
        }
    }
    Err(format!("no hwmon named '{name}' (is the {name} driver loaded?)"))
}

fn read(p: &PathBuf) -> Result<i64, String> {
    fs::read_to_string(p)
        .map_err(|e| format!("{}: {e}", p.display()))?
        .trim()
        .parse()
        .map_err(|e| format!("{}: {e}", p.display()))
}

fn write(p: &PathBuf, v: impl ToString) -> Result<(), String> {
    fs::write(p, v.to_string()).map_err(|e| format!("{}: {e} (run as root)", p.display()))
}

fn cpu_temp(k10: &PathBuf) -> Result<f64, String> {
    Ok(read(&k10.join("temp1_input"))? as f64 / 1000.0)
}

fn status() -> Result<(), String> {
    let (fan, k10) = (hwmon("gpdfan")?, hwmon("k10temp")?);
    let mode = match read(&fan.join("pwm1_enable"))? {
        0 => "full speed",
        1 => "manual",
        2 => "EC auto",
        _ => "unknown",
    };
    let pwm = read(&fan.join("pwm1")).map_or("-".into(), |v| v.to_string());
    println!("cpu {:.1}°C  fan {} rpm  mode {mode}  pwm {pwm}", cpu_temp(&k10)?, read(&fan.join("fan1_input"))?);
    Ok(())
}

fn run(curve: Curve, off_below: f64, interval: u64, step_down: u8) -> Result<(), String> {
    let (fan, k10) = (hwmon("gpdfan")?, hwmon("k10temp")?);
    let (enable, pwm_path) = (fan.join("pwm1_enable"), fan.join("pwm1"));
    let stop = Arc::new(AtomicBool::new(false));
    for sig in [libc_sig::SIGTERM, libc_sig::SIGINT] {
        libc_sig::on(sig, stop.clone());
    }
    write(&enable, 1)?;
    let mut cur: u8 = 255; // manual mode starts at full speed; ease down from there
    let res = (|| {
        while !stop.load(Ordering::Relaxed) {
            let t = cpu_temp(&k10)?;
            let target = if t < off_below || (cur == 0 && t < curve.0[0].0) { 0 } else { curve.pwm(t) };
            cur = if target >= cur { target } else { cur.saturating_sub(step_down).max(target) };
            write(&pwm_path, cur)?;
            thread::sleep(Duration::from_secs(interval));
        }
        Ok(())
    })();
    let back = write(&enable, 2);
    res.and(back)
}

/// Minimal SIGTERM/SIGINT handling without extra crates.
mod libc_sig {
    use std::sync::{Arc, OnceLock, atomic::AtomicBool, atomic::Ordering};
    pub const SIGINT: i32 = 2;
    pub const SIGTERM: i32 = 15;
    static FLAG: OnceLock<Arc<AtomicBool>> = OnceLock::new();
    unsafe extern "C" {
        fn signal(sig: i32, handler: extern "C" fn(i32)) -> usize;
    }
    extern "C" fn handle(_: i32) {
        if let Some(f) = FLAG.get() {
            f.store(true, Ordering::Relaxed);
        }
    }
    pub fn on(sig: i32, flag: Arc<AtomicBool>) {
        let _ = FLAG.set(flag);
        unsafe { signal(sig, handle) };
    }
}

fn main() {
    let res = match Cli::parse().cmd {
        Cmd::Status => status(),
        Cmd::Run { curve, off_below, interval, step_down } => run(curve, off_below, interval, step_down),
        Cmd::Completions { shell } => {
            clap_complete::generate(shell, &mut Cli::command(), "gpd-fan-curve", &mut std::io::stdout());
            Ok(())
        }
    };
    if let Err(e) = res {
        eprintln!("gpd-fan-curve: {e}");
        std::process::exit(1);
    }
}
