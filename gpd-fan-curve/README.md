# gpd-fan-curve

Quiet fan curve for GPD devices (`gpd_fan` hwmon driver). The EC keeps the fan at ~2400 rpm even idle and cold;
this drives it in manual mode from the CPU temperature (k10temp Tctl): off below 48 °C, 70→255 PWM from 55 to
85 °C, gentle wind-down. Hands control back to the EC on exit or on any error (and the unit does too).

```bash
gpd-fan-curve status          # cpu temp, rpm, mode, pwm
gpd-fan-curve run --help      # curve options
```

Install: setup.md step 36.
