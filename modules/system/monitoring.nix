{ lib, config, pkgs, confMachine, confLib, ... }:
with lib;
let
  cfg = config.system.monitoring;

  allDeployments = confLib.getClusterDeployments config.cluster;

  monitorings = filter (d: d.config.monitoring.isMonitor) allDeployments;

  exporterPort = confMachine.services.node-exporter.port;
in {
  options = {
    system.monitoring = {
      enable = mkOption {
        type = types.bool;
        description = "Monitor this system";
      };
    };
  };

  config = mkMerge [
    {
      system.monitoring.enable = mkDefault confMachine.monitoring.enable;
    }
    (mkIf cfg.enable {
      networking.firewall.extraCommands = concatStringsSep "\n" (map (d: ''
        # Allow access to node-exporter from ${d.config.host.fqdn}
        iptables -A nixos-fw -p tcp -m tcp -s ${d.config.addresses.primary.address} --dport ${toString exporterPort} -j nixos-fw-accept
      '') monitorings);

      services.prometheus.exporters = {
        node = {
          enable = true;
          port = exporterPort;
          extraFlags = [ "--collector.textfile.directory=/run/metrics" ];
          enabledCollectors = [
            "vmstat"
            "interrupts"
            "textfile"
            "processes"
          ] ++ (optionals (confMachine.spin == "nixos") [ "systemd" "logind" ])
            ++ (optionals (confMachine.spin == "vpsadminos") [ "runit" "nfs" ])
            ++ (optionals (!config.boot.isContainer) [ "hwmon" "mdadm" "ksmd" ]);
        };
      };
    })
  ];
}
