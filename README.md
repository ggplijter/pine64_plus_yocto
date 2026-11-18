# Pine64+ Yocto image

A Yocto Project 5.0 (Scarthgap) image for the Pine64+ (Allwinner A64), built with
[kas](https://kas.readthedocs.io) in a container. The image contains systemd,
NetworkManager, an SSH server and LVGL running on the DRM/KMS display backend.

> Development image: root logs in without a password (`debug-tweaks`).
> Never use this configuration in production.

## Repository layout

```
.
├── pine64-plus.yml        kas configuration: layers, machine, image settings
├── pine64-plus.lock.yml   exact commit of every external layer
├── pyproject.toml         Python project with kas as dependency
├── uv.lock                exact kas version (also selects the build container)
├── env.sh                 source this to activate the kas tooling
├── build_yocto.sh         build the image or open a bitbake shell
├── create_img.sh          unpack the SD card image for flashing
└── meta-pine64/           own layer
    ├── conf/layer.conf
    ├── recipes-bsp/u-boot/       boot.cmd with DTB fallback and cma=256M
    └── recipes-graphics/lvgl/    patch: LVGL DRM driver uses the primary plane only
```

The external layers (`poky/`, `meta-openembedded/`, `meta-arm/`, `meta-sunxi/`) and
the `build/` directory are created by kas and are not part of the repository.

## Prerequisites

- **WSL2** with a Debian or Ubuntu distribution (a native Linux machine works too).
  Keep the project on the Linux filesystem (for example `~/yocto/pine64`), never
  under `/mnt/c` or `/mnt/d`.
- **Resources:** a first build takes several hours and needs 50 to 100 GB of disk
  space. In WSL, assign enough CPU and memory in `C:\Users\<you>\.wslconfig`:

  ```ini
  [wsl2]
  processors=14
  memory=24GB
  swap=16GB
  ```

- **Podman** for rootless containers:

  ```bash
  sudo apt install -y podman uidmap dbus-user-session
  sudo loginctl enable-linger $USER
  ```

  Enable systemd in WSL (`/etc/wsl.conf`, section `[boot]`, `systemd=true`) and
  restart WSL with `wsl --shutdown`. If Podman warns that there is no systemd user
  session, start the user D-Bus socket once:

  ```bash
  systemctl --user add-wants sockets.target dbus.socket
  systemctl --user start dbus.socket
  ```

- **uv** to manage the pinned kas version:

  ```bash
  curl -LsSf https://astral.sh/uv/install.sh | sh
  ```

## Setup

```bash
git clone <repository-url> ~/yocto/pine64
cd ~/yocto/pine64
source env.sh
```

`env.sh` installs kas from `uv.lock` into `.venv`, activates it and selects the
Debian 12 build container (`KAS_CONTAINER_IMAGE_DISTRO=debian-bookworm`), which is
validated for Scarthgap. The prompt shows `(pine64)` while the environment is active;
`deactivate` leaves it.

## Building

```bash
./build_yocto.sh            # build the image
./build_yocto.sh shell      # bitbake shell inside the container
./build_yocto.sh lock       # update pine64-plus.lock.yml to newer layer commits
```

The script checks the YAML syntax first, then runs `kas-container`. It works with or
without `source env.sh`, since it calls kas through `uv run`.

Later builds reuse the shared state cache in `build/`, so small changes take minutes.
Don't delete `build/`; to clean up, use `kas-container purge` or rebuild a single
recipe with `bitbake -c cleansstate <recipe>` in the shell.

Commands like `bitbake`, `bitbake-layers` and `oe-pkgdata-util` only exist inside
the container (`./build_yocto.sh shell`).

## Flashing

```bash
./create_img.sh             # writes /mnt/d/pine64-yocto.img
./create_img.sh /mnt/e      # or another drive
```

Write the `.img` file to an SD card with balenaEtcher or Rufus.

## First boot

Connect HDMI and Ethernet and power on. The Yocto splash screen appears, followed by
a login prompt. Log in as `root` without a password, on the console or over SSH:

```bash
ssh root@<board-ip>
```

Useful checks on the board:

```bash
nmcli device                   # NetworkManager status
ls -l /dev/dri/by-path/        # which DRM card is the display
grep -i cma /proc/meminfo      # CmaTotal should be about 262144 kB
```

## LVGL demo

The demo (`/usr/bin/lvgl`) opens the display device from the environment variable
`LV_VIDEO_CARD`, and falls back to `/dev/dri/card0` when it isn't set. On this board
`card0` is often the Lima GPU, which can't display anything, so always set the
variable.

The numbers `card0` and `card1` depend on which driver registers first and can swap
between boots. The links in `/dev/dri/by-path/` are named after the hardware and stay
the same, so use the display engine's link:

```bash
ls -l /dev/dri/by-path/                       # find the display engine entry
LV_VIDEO_CARD=/dev/dri/by-path/<display-engine-entry> lvgl &
kill %1                                       # stop it again
```

A quick test with a card number works too, for example
`LV_VIDEO_CARD=/dev/dri/card1 lvgl`. The same variable selects the framebuffer device
when the demo is built for fbdev (default `/dev/fb0`).

## Customizations and why

| Change | Where | Reason |
| --- | --- | --- |
| Own `boot.cmd` | `meta-pine64/recipes-bsp/u-boot` | meta-sunxi's aarch64 script loads `allwinner/<board>.dtb`, but the DTB is in the root of the boot partition |
| `cma=256M` | `boot.cmd` | the default 16 MB CMA pool cannot hold full HD display buffers |
| `use-mailine-graphics` | `pine64-plus.yml` | enables meta-sunxi's `drm.cfg`: Allwinner display drivers, Lima, CMA (keep the typo, it matches meta-sunxi) |
| Primary plane patch | `meta-pine64/recipes-graphics/lvgl` | LVGL 9.1 picked HDMI overlay plane 50, which hangs the kernel on the A64 |
| systemd + NetworkManager | `pine64-plus.yml` | Armbian-like network management |

## Known issues

- Using the HDMI overlay plane (plane 50) for a full-screen buffer freezes the
  kernel. Reproduce with
  `modetest -M sun4i-drm -a -s 62@60:1920x1080 -P 50@60:1920x1080@XR24`.
  Not yet reported upstream.
- The LVGL demo warns that `lv_tick_inc()` is not called; time-based features may not
  work correctly.

## Line endings

`.gitattributes` forces LF line endings. Shell scripts, `boot.cmd` and patch files
break with Windows (CRLF) line endings, so commit from WSL, not from a Windows copy.
