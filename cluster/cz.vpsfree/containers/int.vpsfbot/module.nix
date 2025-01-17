{ config, ... }:
{
  cluster."cz.vpsfree/containers/int.vpsfbot" = {
    spin = "nixos";
    swpins.channels = [ "nixos-stable" "os-staging" ];
    container.id = 21296;
    host = { name = "vpsfbot"; location = "int"; domain = "vpsfree.cz"; };
    addresses.primary = { address = "172.16.4.8"; prefix = 32; };
    services = {
      node-exporter = {};
    };
  };
}
