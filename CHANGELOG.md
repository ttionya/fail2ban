# Changelog

## 1.1.1-r0-0 (20260921)

> Important (from upstream):
> 
> Review the [Fail2ban 1.1.1 changelog](https://github.com/fail2ban/fail2ban/blob/1.1.1/ChangeLog#ver-111-20260815---triple-one-win) before upgrading.
>
> Custom actions derived from `iptables.conf` may need updates for multiple-chain support, including replacing `<chain>` with `$chain` and `<_ipt_for_proto-iter>` with `<_ipt-iter>` in overridden commands. Existing jail settings such as `chain = DOCKER-USER` remain supported.
>
> Exim `normal` mode now excludes several risky rules, which moved to `more`. Review the upstream guidance before enabling that mode.
>
> With `backend = auto`, missing log files can now trigger a fallback to systemd when a journal match exists. Set `systemd_if_nologs = false` for file-only monitoring. Journal monitoring requires the Debian image and mounted host journals.
>
> Both image variants preserve their existing iptables ban actions and `backend = auto` defaults for SSH and Postfix.

> Important:
> 
> Starting with Fail2Ban 1.1.1, this project no longer builds from a modified copy of the upstream source code. Instead, it periodically builds from the `crazymax/fail2ban:<version>-debian` image published by the upstream project.

### Feature

- Bump Fail2Ban from `1.1.0` to `1.1.1`
- Drop `linux/386` and `linux/arm/v6` support
- Add the current project version tag

<br>

## 1.1.0-r5-1 (20260527)

### Feature

- Updated `sshd` filter to support OpenSSH's new daemon name `sshd-session`

<br>

## 1.1.0-r5-0 (20260517)

### Feature

- Add `linux/riscv64` support

<br>

## 1.1.0-r4-0 (20260401)

### Feature

- Bump `debian:12-slim` to `debian:13-slim`

<br>

## 1.1.0-r3-0 (20250713)

### Feature

- Sync upstream to remove support for ssmtp

<br>

## 1.1.0-r1-1 (20250219)

### Feature

- Support reloading a specified jail

### Chore

- Compatible with docker/bake-action@v6

<br>

## 1.1.0-r1-0 (20241118)

### Feature

- Built based on `debian:12-slim` instead of `alpine`
- Built-in `inotify-tools`
