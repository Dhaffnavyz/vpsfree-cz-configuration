{ lib, config, pkgs, confMachine, confLib, ... }:
with lib;
let
  shared = import ./shared.nix { inherit lib config confMachine confLib; };
in {
  inherit (shared) options;

  config = mkMerge [
    shared.config

    (mkIf shared.enable {
      services.rsyslogd.forward = [
        "${shared.services.graylog-rsyslog-tcp.address}:${toString shared.services.graylog-rsyslog-tcp.port}"
      ];
    })
  ];
}
