# fail2ban

[![Docker Image Version (latest by date)](https://img.shields.io/docker/v/ttionya/fail2ban?label=Version&logo=docker)](https://hub.docker.com/r/ttionya/fail2ban/tags) [![Docker Pulls](https://img.shields.io/docker/pulls/ttionya/fail2ban?label=Docker%20Pulls&logo=docker)](https://hub.docker.com/r/ttionya/fail2ban) [![GitHub](https://img.shields.io/github/license/ttionya/fail2ban?label=License&logo=github)](https://github.com/ttionya/fail2ban/blob/master/LICENSE)

This project is forked from [crazy-max/docker-fail2ban](https://github.com/crazy-max/docker-fail2ban) and modified from it. **Any subsequent mention of `upstream` refers to that project.**

Starting with Fail2Ban 1.1.1, this project no longer builds from a modified copy of the upstream source code. Instead, it periodically builds from the `crazymax/fail2ban:<version>-debian` image published by the upstream project, with additional enhancements. The last version built the old way, Fail2Ban 1.1.0, is available in the [1.1.0 branch](https://github.com/ttionya/fail2ban/tree/1.1.0).

**Note: If you are NOT looking for this project with a strong purpose, please use the [crazymax/fail2ban](https://hub.docker.com/r/crazymax/fail2ban) image directly.**

## About

This project is rebuilt from the upstream `crazymax/fail2ban:<version>-debian` image with the following modifications:

1. Keep dependencies up to date.

   To ensure timely security updates, all dependencies are updated on every rebuild. As a result, the image size may vary depending on the updated dependencies.

2. Built-in `inotify-tools`, including the `inotifywait` command.

   If your log file names rotate over time, you can use `inotifywait` to monitor file creation or deletion and reload Fail2Ban.

## Usage

### fail2ban

The configuration for Fail2Ban is the same as upstream, please refer to the [crazy-max/docker-fail2ban documentation](https://github.com/crazy-max/docker-fail2ban/blob/master/README.md).

### inotifywait

You can use the built-in `inotifywait` to monitor the creation and removal of log files.

To enable it, mount a configuration file at `/etc/inotifywait.conf`. **This configuration file is specific to this image.**

The typical configuration file is as follows:

```
# fail2ban-client reload (for all)
-m -e create,moved_from --include .*\.access\..*\.log$ /var/log/nginx

# fail2ban-client reload nginx
-m -e create,moved_from --include .*\.access\..*\.log$ /var/log/nginx [nginx]

# fail2ban-client reload nginx && fail2ban-client reload httpd
-m -e create,moved_from --include .*\.access\..*\.log$ /var/log/nginx [nginx httpd]
```

1. Each line contains the arguments passed to `inotifywait`, excluding the command name itself.
2. Blank lines and lines starting with `#` are ignored.
3. The trailing `[jail]` is **OPTIONAL** and represents which jails need to be reloaded when the watch is triggered, separated by **SPACES**.

## Example

```sh
docker run -d \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  --mount type=bind,source=/path/to/fail2ban/data,target=/data \
  --mount type=bind,source=/path/to/inotifywait.conf,target=/etc/inotifywait.conf,readonly \
  --mount type=bind,source=/run/log/journal,target=/run/log/journal,readonly \
  --mount type=bind,source=/var/log/journal,target=/var/log/journal,readonly \
  --mount type=bind,source=/etc/machine-id,target=/etc/machine-id,readonly \
  --mount type=bind,source=/var/log/nginx,target=/var/log/nginx,readonly \
  ttionya/fail2ban
```

## Versioning

The version is divided into three parts, separated by hyphens (`-`).

| Part | Version | Description                                              |
|------|---------|----------------------------------------------------------|
| 1    | `1.1.0`   | `fail2ban` version number                                | 
| 2    | `r1`      | Upstream version number                                  |
| 3    | `1` or `b1` | Project version number (`b` for beta, number for stable) |

## Schedule

To ensure the use of the latest dependencies, this image is rebuilt every Monday at 06:00 UTC.

## Thanks

- [crazy-max/docker-fail2ban](https://github.com/crazy-max/docker-fail2ban)
- [Byh0ki/fail2ban](https://gitlab.com/byh0ki-org/containers/fail2ban)
- [fail2ban/fail2ban](https://github.com/fail2ban/fail2ban)

## License

MIT
