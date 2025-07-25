self: {
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.tsidp;
  inherit
    (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
in {
  # tsidp config options
  options.services.tsidp = {
    enable = mkEnableOption "Enable tsidp service";

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/tsidp";
      description = "Directory where tsidp stores its data.";
    };

    hostname = mkOption {
      type = types.str;
      default = "tsidp";
      description = "The hostname for the tsidp service appears as on the tailnet.";
    };

    userspace = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to run tsidp in userspace mode.";
    };

    serviceRestartMode = mkOption {
      type = types.enum [
        "always"
        "on-failure"
      ];
      default = "always";
      description = "The systemd service restart mode for tsidp.";
    };

    serviceRestartInterval = mkOption {
      type = types.int;
      default = 5;
      description = "Systemd RestartSec for tsidp service.";
    };

    user = mkOption {
      type = types.str;
      default = "tsidp";
      description = "The user under which the tsidp service runs.";
    };

    group = mkOption {
      type = types.str;
      default = "tsidp";
      description = "The group under which the tsidp service runs.";
    };
  };

  config = mkIf cfg.enable {
    # tsidp service configuration
    users.users = mkIf (config.services.tsidp.user == "tsidp") {
      tsidp = {
        name = "tsidp";
        group = cfg.group;
        isSystemUser = true;
        description = "Tailscale Identity Provider (tsidp) User.";
      };
    };
    users.groups = mkIf (cfg.group == "tsidp") {tsidp = {};};

    systemd.services.tsidp = {
      description = "Tailscale Identity Provider (tsidp)";
      wantedBy = ["network-online.target"];
      after = ["network-online.target"];
      environment = {
        TAILSCALE_USE_WIP_CODE = "1";
      };
      serviceConfig = {
        Type = "simple";
        Restart = "${cfg.serviceRestartMode}";
        RestartSec = cfg.serviceRestartInterval;
        StateDirectory = "tsidp";
        User = "${cfg.user}";
        ExecStart = "${self.packages.${pkgs.system}.tailscale}/bin/tsidp --dir ${cfg.dataDir} --hostname ${cfg.hostname}";
      };
    };
  };
}
