{
  description = "Yunz Darwin System Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
    }:
    let
      configuration =
        { pkgs, config, ... }:
        {
          nixpkgs.config.allowUnfree = true;

          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.jetbrains.idea-ultimate
            pkgs.syncthing
            pkgs.prometheus
            pkgs.wget
            # pkgs.go
            pkgs.qbittorrent
            pkgs.mysql84
            # terminals
            pkgs.tldr
            # pkgs.docker
            pkgs.lazydocker
            pkgs.neovim
            pkgs.gnupg
            pkgs.mkalias
            pkgs.tmux
            pkgs.alacritty
            pkgs.kitty
            pkgs.obsidian
            pkgs.fastfetch
            pkgs.neofetch
            pkgs.vesktop
            pkgs.raycast
            pkgs.cowsay
            pkgs.bat
            pkgs.eza
            pkgs.starship
            pkgs.fzf
            pkgs.fd
            pkgs.thefuck
            pkgs.zoxide
            pkgs.yazi
            pkgs.delta
            pkgs.tree
            pkgs.delta
            pkgs.lazygit
            pkgs.bottom
            pkgs.ripgrep
            pkgs.direnv
            pkgs.git
            pkgs.arc-browser
            pkgs.sketchybar
            pkgs.btop
            pkgs.hugo
            pkgs.sketchybar
            pkgs.lua
            pkgs.home-manager

          ];

          homebrew = {
            enable = true;
            brews = [
              #"mas"
              # "mysql"
              "vifm"
              "cloudflared"
              "mpv"
              "uv"
            ];
            casks = [
              "vlc"
              "docker"
              "firefox"
              "nikitabobko/tap/aerospace"
              "karabiner-elements"
              "capcut"
              "scroll-reverser"
              "jitouch"
              "google-chrome"
              "mongodb-compass"
            ];
            # app store
            masApps = {
              #"Yoink" = 457622435;
            };
            onActivation.cleanup = "zap";
          };

          fonts.packages = [
            (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
          ];

          system.activationScripts.applications.text =
            let
              env = pkgs.buildEnv {
                name = "system-applications";
                paths = config.environment.systemPackages;
                pathsToLink = "/Applications";
              };
            in
            pkgs.lib.mkForce ''
              # Set up applications.
              echo "setting up /Applications..." >&2
              rm -rf /Applications/Nix\ Apps
              mkdir -p /Applications/Nix\ Apps
              find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
              while read -r src; do
                app_name=$(basename "$src")
                echo "copying $src" >&2
                ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
              done
            '';

          system.defaults = {
            dock.autohide = true;
            finder.FXPreferredViewStyle = "clmv";
            loginwindow.GuestEnabled = false;
            NSGlobalDomain.AppleInterfaceStyle = "Dark";
            NSGlobalDomain.KeyRepeat = 2;
            dock.expose-group-by-app = true;
          };

          # Auto upgrade nix package and the daemon service.
          services.nix-daemon.enable = true;
          # nix.package = pkgs.nix;

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable alternative shell support in nix-darwin.
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."pro" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              #enable = true;
              enableRosetta = true;
              # for apple silicon use rosetta
              user = "yunz";
            };
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."pro".pkgs;
    };
}
