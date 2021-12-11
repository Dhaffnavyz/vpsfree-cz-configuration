{ config, pkgs, lib, confLib, confData, confMachine, ... }:
with lib;
let
  proxyPrg = confLib.findConfig {
    cluster = config.cluster;
    name = "cz.vpsfree/containers/prg/proxy";
  };

  httpPort = confMachine.services.graylog-http.port;
  rsyslogTcpPort = confMachine.services.graylog-rsyslog-tcp.port;
  rsyslogUdpPort = confMachine.services.graylog-rsyslog-udp.port;
  gelfPort = confMachine.services.graylog-gelf.port;

  loggedAddresses = filter (a:
    a.config.logging.enable
  ) (confLib.getAllAddressesOf config.cluster 4);
in {
  imports = [
    ../../../../../environments/base.nix
    ../../../../../profiles/ct.nix
  ];

  nixpkgs.overlays = import ../../../../../overlays;

  networking.firewall = {
    extraCommands = ''
      ### Allow access to graylog from proxy.prg
      iptables -A nixos-fw -p tcp --dport ${toString httpPort} -s ${proxyPrg.addresses.primary.address} -j nixos-fw-accept

      ### Management networks
      ${concatMapStringsSep "\n" (net: ''
        # Allow access from ${net.location} @ ${net.address}/${toString net.prefix}
        iptables -A nixos-fw -p tcp -s ${net.address}/${toString net.prefix} --dport ${toString rsyslogTcpPort} -j nixos-fw-accept
        iptables -A nixos-fw -p udp -s ${net.address}/${toString net.prefix} --dport ${toString rsyslogUdpPort} -j nixos-fw-accept
        iptables -A nixos-fw -p udp -s ${net.address}/${toString net.prefix} --dport ${toString gelfPort} -j nixos-fw-accept
      '') confData.vpsadmin.networks.management.ipv4}

      ### Individual machines
      ${concatMapStringsSep "\n" (a: ''
        # Allow access from ${a.config.host.fqdn} @ ${a.address}
        iptables -A nixos-fw -p tcp -s ${a.address} --dport ${toString rsyslogTcpPort} -j nixos-fw-accept
        iptables -A nixos-fw -p udp -s ${a.address} --dport ${toString rsyslogUdpPort} -j nixos-fw-accept
        iptables -A nixos-fw -p udp -s ${a.address} --dport ${toString gelfPort} -j nixos-fw-accept
      '') loggedAddresses}
    '';
  };

  services.graylog = {
    enable = true;
    # pwgen -N 1 -s 96
    passwordSecret = lib.fileContents /secrets/graylog/passwordSecretSalt;
    # echo -n somepass | shasum -a 256
    rootPasswordSha2 = "86a09e9fb695d0a2d17439318566b69d4f04486cf96a422473d9b7ee782d4845";
    elasticsearchHosts = [ "http://localhost:9200" ];
    extraConfig = ''
      http_bind_address = ${confMachine.addresses.primary.address}:${toString httpPort}
      http_publish_uri  = https://log.prg.vpsfree.cz/
      http_external_uri = https://log.prg.vpsfree.cz/
      '';
    plugins = [
      pkgs.graylogPlugins.alertmanager-callback
    ];
  };

  services.elasticsearch = {
    enable = true;
    package = pkgs.elasticsearch6-oss;
  };

  services.mongodb = {
    enable = true;
  };

  services.SystemdJournal2Gelf = {
    enable = true;
    graylogServer = "127.0.0.1:${toString gelfPort}";
  };
}

