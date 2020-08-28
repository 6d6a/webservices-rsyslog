{ nixpkgs ? (import <nixpkgs> { }).fetchgit {
  url = "https://github.com/NixOS/nixpkgs.git";
  rev = "ce9f1aaa39ee2a5b76a9c9580c859a74de65ead5";
  sha256 = "1s2b9rvpyamiagvpl5cggdb2nmx4f7lpylipd397wz8f0wngygpi";
}, overlayUrl ? "git@gitlab.intr:_ci/nixpkgs.git", overlayRef ? "master" }:

with import nixpkgs {
  overlays = [
    (self: super:
      with super; rec {
        overlayed = (import nixpkgs {
          overlays = [
            (import (builtins.fetchGit {
              url = "https://gitlab.intr/_ci/nixpkgs";
              ref = "master";
            }))
          ];
        });
      })
  ];
};

let

  inherit (builtins) toJSON;
  inherit (dockerTools) buildLayeredImage;
  inherit (lib) concatMapStringsSep;
  inherit (overlayed.lib) dockerRunCmd flattenSet mkRootfs;

  rootfs = mkRootfs {
    name = "rsyslog-rootfs";
    src = ./rootfs;
    inherit rsyslog;
  };

  dockerArgHints = {
    init = false;
    read_only = true;
    network = "host";
    tmpfs = [ "/tmp:mode=1777" ];
    volumes = [
      ({
        type = "bind";
        source = "/home";
        target = "/home";
      })
      ({
        type = "bind";
        source = "/opt/run";
        target = "/opt/run";
      })

      ({
        type = "tmpfs";
        target = "/run";
      })
    ];
  };

in pkgs.dockerTools.buildLayeredImage rec {
  name = "docker-registry.intr/webservices/rsyslog";
  tag = "latest";
  contents = [
    rootfs
    syslogng
    tzdata
    locale
  ];
  config = {
    Entrypoint = [ "${syslogng}/bin/syslog-ng" "-f" "${rootfs}/etc/syslog-ng.conf" "-R" "/run/syslog-ng.persist" "-c" "/run/syslog-ng.ctl" "--pidfile=/run/syslog-ng.pid" "--foreground" ];
    Env = [
      "TZ=:/etc/localtime"
      "CRON_TZ=Europe/Moscow"
      "TZDIR=${tzdata}/share/zoneinfo"
      "LOCALE_ARCHIVE_2_27=${locale}/lib/locale/locale-archive"
      "LOCALE_ARCHIVE=${locale}/lib/locale/locale-archive"
      "LC_ALL=ru_RU.UTF-8"
    ];
    Labels = flattenSet rec {
      ru.majordomo.docker.arg-hints-json = builtins.toJSON dockerArgHints;
      ru.majordomo.docker.cmd = dockerRunCmd dockerArgHints "${name}:${tag}";
      ru.majordomo.docker.exec.reload-cmd = "/bin/true";
    };
  };
#  extraCommands = ''
#    ln -s ${tzdata}/share/zoneinfo/Europe/Moscow etc/localtime
#  '';
}
