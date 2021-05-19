{ pkgs, lib, config, ... }:
{
  imports = [
    ../../../../../environments/base.nix
    ../../../../../profiles/ct.nix
  ];

  clusterconf.monitor = {
    enable = true;
    retention.time = "30d";
    retention.size = "10GB";
    alerters = [
      "cz.vpsfree/containers/prg/int.alerts1"
      "cz.vpsfree/containers/prg/int.alerts2"
    ];
    externalUrl = "https://mon2.prg.vpsfree.cz/";
    allowedMachines = [
      "cz.vpsfree/containers/prg/proxy"
      "cz.vpsfree/containers/prg/int.grafana"
    ];
  };
}
