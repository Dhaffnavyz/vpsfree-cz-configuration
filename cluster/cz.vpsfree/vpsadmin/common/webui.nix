{ pkgs, lib, config, confLib, ... }:
let
  proxyPrg = confLib.findConfig {
    cluster = config.cluster;
    name = "cz.vpsfree/containers/prg/proxy";
  };
in {
  vpsadmin.webui = {
    enable = true;

    productionEnvironmentId = 1;

    domain = "vpsadmin.vpsfree.cz";

    api = {
      externalUrl = "https://api.vpsfree.cz";
      internalUrl = "http://${proxyPrg.addresses.primary.address}:5000";
    };

    extraConfig = ''
      require "/private/vpsadmin-webui.php";
    '';

    allowedIPv4Ranges = [
      "${proxyPrg.addresses.primary.address}/32"
    ];
  };
}