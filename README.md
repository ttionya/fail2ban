# fail2ban

[![Docker Image Version (latest by date)](https://img.shields.io/docker/v/ttionya/fail2ban?label=Version&logo=docker)](https://hub.docker.com/r/ttionya/fail2ban/tags) [![Docker Pulls](https://img.shields.io/docker/pulls/ttionya/fail2ban?label=Docker%20Pulls&logo=docker)](https://hub.docker.com/r/ttionya/fail2ban) [![GitHub](https://img.shields.io/github/license/ttionya/fail2ban?label=License&logo=github)](https://github.com/ttionya/fail2ban/blob/master/LICENSE)

This project is forked from [crazy-max/docker-fail2ban](https://github.com/crazy-max/docker-fail2ban) and modified based on it. **Any subsequent mention of `upstream` refers to that project.**

**Note: If you are NOT looking for this project with a strong purpose, please use the [crazymax/fail2ban](https://hub.docker.com/r/crazymax/fail2ban) image directly.**

## About

Two modifications were made when rebuilding of this project:

1. Built based on `debian:12-slim` instead of `alpine`

   Alpine does not support the `systemd` backend. If you need to set `backend: systemd` due to the journal logging system, you can try using this image.

2. Built-in `inotify-tools`, including the `inotifywait` command.

   If your log file names rotate over time, you can use `inotifywait` to monitor file creation or deletion and reload fail2ban.

## Usage

### fail2ban

The configuration for fail2ban is the same as upstream, please refer to the [crazy-max/docker-fail2ban documentation](https://github.com/crazy-max/docker-fail2ban/blob/master/README.md).

### inotifywait

You can use the built-in `inotifywait` to monitor the creation and removal of log files.

You only need to mount the configuration file to `/etc/inotifywait.conf`. **This configuration file is specific to this image.**

The typical configuration file is as follows:

```
# fail2ban-client reload (for all)
-m -e create,moved_from --include .*\.access\..*\.log$ /var/logs/nginx

# fail2ban-client reload nginx
-m -e create,moved_from --include .*\.access\..*\.log$ /var/logs/nginx [nginx]

# fail2ban-client reload nginx && fail2ban-client reload httpd
-m -e create,moved_from --include .*\.access\..*\.log$ /var/logs/nginx [nginx httpd]
```

1. Each line is an option section for `inotifywait` (excluding the `inotifywait` command).
2. Blank lines and lines starting with `#` are ignored.
3. The trailing `[jail]` is **OPTIONAL** and represents which jails need to be reloaded when the watch is triggered, separated by **SPACES**.

## Schedule

To ensure the use of the latest dependencies, this image is rebuilt every Monday at 6:00 AM.

## Thanks

- [crazy-max/docker-fail2ban](https://github.com/crazy-max/docker-fail2ban)
- [Byh0ki/fail2ban](https://gitlab.com/byh0ki-org/containers/fail2ban)
- [fail2ban/fail2ban](https://github.com/fail2ban/fail2ban)

## License

MIT
