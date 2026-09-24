## Disclaimer
Since the autodarts github repository was removed, this repository periodically fetches the latest version from the autodarts api to build and push the image to michvllni/autodarts.

For this reason, the releases in this repository ended when the repository got removed.

Check the [docker hub page](https://hub.docker.com/r/michvllni/autodarts) to find the most recent tags.

## Upgrading from v1
Starting with `2.0.0`, the image runs the new Autodarts Headless v2 client. If you want to stay on v1 for now, pin the image to `michvllni/autodarts:1`.

- Your existing `./config` volume keeps working. Your board credentials are migrated automatically on the first start and the old config is kept as `config.bak.toml`.
- Camera assignments are **not** migrated. Open the board page at `http://servername:3180` and assign your cameras again.
- `network_mode: host` is now the recommended setup, see [Networking](#networking).

## Installation
It is possible to run autodarts in a docker container.

If you do not know how to install docker, you can follow [this](https://docs.docker.com/engine/install/) guide.

Please note that this is only available for linux based systems with either arm64 or amd64 architectures so far.

Before getting started, you will have to know the names of your camera interfaces.

You can find them with a tool like `v4l2-utils`:
```sh
sudo apt install v4l2-utils
v4l2-ctl --list-devices
```
in the output, you will see your cameras. What you need is the first device path for each of them (in my case `/dev/video0`, `/dev/video2` and `/dev/video4`:
```
USB HD Camera: USB HD Camera (usb-0000:01:00.0-1.2):
        /dev/video0
        /dev/video1
        /dev/media4

USB HD Camera: USB HD Camera (usb-0000:01:00.0-1.3):
        /dev/video2
        /dev/video3
        /dev/media5

USB HD Camera: USB HD Camera (usb-0000:01:00.0-1.4):
        /dev/video4
        /dev/video5
        /dev/media6
```

Use the following docker-compose configuration and add your devices in the `devices` section accordingly:
```yml
services:
  autodarts:
    image: michvllni/autodarts:latest
    container_name: autodarts
    restart: unless-stopped
    network_mode: host
    devices:
    - /dev/video0:/dev/video0
    - /dev/video2:/dev/video2
    - /dev/video4:/dev/video4
    volumes:
    - ./config:/root/.config/autodarts
```

This configuration will automatically expose the cameras to the container and provide the board page at http://servername:3180.

You can also find this configuration at [this link](https://raw.githubusercontent.com/michvllni/autodarts-releases/main/docker-compose.yml).

Save it into the directory of your choice, then navigate into that directory and execute `sudo docker-compose up -d`

## Setup
Open the board page at `http://servername:3180`, enter your board credentials and assign your cameras. Everything is saved to `./config/config.toml` and survives container restarts.

Alternatively, you can use the terminal UI of the headless client inside the container, e.g. to log in via QR code and create or claim a board:
```sh
sudo docker exec -it autodarts ./autodarts
```

## Networking
`network_mode: host` is recommended for two reasons:
- The Autodarts Desktop app and `autodarts remote` discover boards on your network via mDNS (UDP port 5353), which does not work from inside a docker bridge network.
- Autodarts assigns a DNS A-Record to your board to make it accessible for the platform. This DNS Record is roughly `<board ip>.<board id>.autodarts.direct -> <board ip>`, e.g. `172-19-0-2.01234567-89ab-cdef-0123-456789abcdef.autodarts.direct -> 172-19-0-2`. With a bridge network this is the container ip, which is not reachable from other devices and causes long loading times on the boards/lobby pages.

If you cannot use host networking, replace `network_mode: host` with a port mapping:
```diff
-    network_mode: host
+    ports:
+    - 3180:3180
```

## Podman and SELinux
If the logs show `permission denied (add user to video group)` for your cameras on a SELinux enabled host (e.g. Fedora) with podman, add `--security-opt label=disable` to the container, or `security_opt: [label=disable]` in the compose file.

## Useful commands
| Command | Explanation |
| --------| ----------- |
| `sudo docker compose logs` | Print the logs from the container |
| `sudo docker compose logs -f` | Follow the logs. Press ctrl+c to cancel |
| `sudo docker compose restart` | Restart the container |
| `sudo docker compose down` | Remove the container |
