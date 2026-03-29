{ config, lib, pkgs, ... }:

let
  cfg = config.programs.direnv-overlay;
  helperPath = "${cfg.package}/share/direnv/lib/direnv-overlay.sh";
in
{
  options.programs.direnv-overlay = with lib; {
    enable = mkEnableOption "direnv-overlay integration";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = literalExpression "pkgs.callPackage ./nix/package.nix { }";
      description = "Package providing the direnv-overlay helper library.";
    };

    installDirenvLib = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Install the helper into the XDG direnv lib directory so direnv can load
        it from `~/.config/direnv/lib/direnv-overlay.sh`.
      '';
    };

    enableInStdlib = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Append `use_direnv_overlay` to the Home Manager direnv stdlib.
      '';
    };

    overlayRoot = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = literalExpression ''"${config.home.homeDirectory}/.direnv-overlay"'';
      description = ''
        Value to export as `DIRENV_OVERLAY_ROOT` before `use_direnv_overlay`
        runs.
      '';
    };

    mapFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = literalExpression ''"${config.xdg.configHome}/direnv/overlays.map"'';
      description = ''
        Value to export as `DIRENV_OVERLAY_MAP_FILE` before
        `use_direnv_overlay` runs.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.programs.direnv.enable;
        message = "programs.direnv-overlay.enable requires programs.direnv.enable = true.";
      }
    ];

    xdg.configFile = lib.mkIf cfg.installDirenvLib {
      "direnv/lib/direnv-overlay.sh".source = helperPath;
    };

    programs.direnv.stdlib = lib.mkIf cfg.enableInStdlib (lib.mkAfter ''
      ${lib.optionalString (cfg.overlayRoot != null) ''
        export DIRENV_OVERLAY_ROOT=${lib.escapeShellArg cfg.overlayRoot}
      ''}
      ${lib.optionalString (cfg.mapFile != null) ''
        export DIRENV_OVERLAY_MAP_FILE=${lib.escapeShellArg cfg.mapFile}
      ''}
      use_direnv_overlay
    '');
  };
}
