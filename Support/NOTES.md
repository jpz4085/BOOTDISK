## Troubleshooting

### Virtual Terminal Suddenly Closed

When creating Windows to Go media under Linux the terminal application may suddenly be closed by the userspace out of memory killer (systemd-oomd) as indicated in the system logs. This happens most frequently under the GNOME desktop environment and  requires the systemd-oomd service and the user environment service (user@service) to be configured with more lenient memory pressure settings. The steps below provide a guide that should be applicable to most or all Linux distributions.

1. Open a terminal and enter the commands below to check the memory pressure limit and duration.
    - `oomctl`
    - `systemd-analyze cat-config systemd/oomd.conf`
2. If the limit is less than 80% and the duration less than one minute these will need adjusted.
3. The vendor defaults shown by the commands above can be overridden with drop-in configuration files. The first example below will configure new OOMD defaults and the second example applies to the user service configuration. Apply both if needed.
    - `printf '[OOM]\nDefaultMemoryPressureLimit=80%%\nDefaultMemoryPressureDurationSec=60s\n' | sudo tee /etc/systemd/oomd.conf.d/override.conf`
    - `printf '[Service]\nManagedOOMMemoryPressureLimit=80%%\nManagedOOMMemoryPressure=kill\n' | sudo tee /etc/systemd/system/user@.service.d/override.conf`
4. Stop then restart the appropriate daemons as show below. The socket daemon may not be present on all distributions.
    - `sudo systemctl stop systemd-oomd.service`
    - `sudo systemctl stop systemd-oomd.socket`
    - `sudo systemctl daemon-reload`
    - `sudo systemctl start systemd-oomd.service`
    - `sudo systemctl start systemd-oomd.socket`
5. Enter both commands from the first step again to confirm the memory pressure limit and duration are using the new values.
6. If the above change is successful the Windows to Go process should complete without issues on the next attempt.
