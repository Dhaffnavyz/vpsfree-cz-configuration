{ config, ... }:
{
  cluster."cz.vpsfree/containers/int.rubygems" = {
    spin = "nixos";
    swpins.channels = [ "nixos-stable" "os-staging" ];
    container.id = 21286;
    host = { name = "rubygems"; location = "int"; domain = "vpsfree.cz"; };
    addresses.primary = { address = "172.16.4.7"; prefix = 32; };
    services = {
      geminabox = {};
      node-exporter = {};
    };
  };
}
