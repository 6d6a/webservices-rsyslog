{ ref ? "master" }:

with import <nixpkgs> {
  overlays = [
    (import (builtins.fetchGit {
      url = "git@gitlab.intr:_ci/nixpkgs.git";
      inherit ref;
    }))
  ];
};

let

  inherit (builtins) concatMap getEnv toJSON;
  inherit (dockerTools) buildLayeredImage;
  inherit (lib)
    concatMapStringsSep firstNChars flattenSet dockerRunCmd mkRootfs;
  inherit (lib.attrsets) collect isDerivation;
  inherit (stdenv) mkDerivation;


  rootfs = mkRootfs {
    name = "rsyslog-rootfs";
    src = ./rootfs;
    inherit rsyslog;
  };

  dockerArgHints = {
    init = false;
    read_only = true;
    network = "host";
    tmpfs = [ "/tmp:mode=1777" "/run/bin:exec,suid" "/run/rsyslog=1777" ];
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
    rsyslog
    tzdata
  ];
  config = {
    Entrypoint = [ "${rsyslog}/sbin/rsyslogd" "-f" "/etc/rsyslog.conf" "-d" "-n" ];
    Env = [
      "TZ=:/etc/localtime"
      "CRON_TZ=Europe/Moscow"
      "TZDIR=${tzdata}/share/zoneinfo"
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
