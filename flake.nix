{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    # home-manager vscode extensions 
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

    mac-app-util.url = "github:hraban/mac-app-util";
    helix.url = "github:helix-editor/helix/master";

  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, homebrew-core
    , homebrew-cask, home-manager, nix-vscode-extensions, mac-app-util, helix
    , ... }:
    let
      configuration = { pkgs, config, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        nixpkgs.config.allowUnfree = true;
        environment.systemPackages =
          import ./system-pkgs/system_pkgs.nix { pkgs = pkgs; }
          ++ [ (pkgs.python3.withPackages (ps: with ps; [ debugpy ])) ];
        homebrew = {
          enable = true;
          casks = [
            "chatgpt"
            "wechat"
            "qqmusic"
            "qq"
            "steam"
            "iina"
            "iterm2"
            "font-lxgw-wenkai"
            "font-lxgw-bright"
            "orbstack"
            "motrix"
            "anki"
            "obsidian"
            # "yacreader"
            "zotero"
          ];
          # TODO: Need to be enable if mas list bug finished.
          # brews = [ "mas" ];
          # masApps = { "vivid" = 6443470555; };
          brews = [ "pandoc" "pdm" ];
          onActivation.cleanup = "zap";
          onActivation.autoUpdate = true;
          onActivation.upgrade = true;
        };
        fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

        system.activationScripts.applications.text = let
          env = pkgs.buildEnv {
            name = "system-applications";
            paths = config.environment.systemPackages;
            pathsToLink = "/Applications";
          };
        in pkgs.lib.mkForce ''
          # Set up applications.
          echo "setting up/Applications..." >&2
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
          dock.autohide = false;
          dock.orientation = "right";
        };

        system.keyboard = {
          enableKeyMapping = true;
          remapCapsLockToEscape = true;
        };

        security.pam.services = { sudo_local.touchIdAuth = true; };
        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        # Enable alternative shell support in nix-darwin.
        # programs.fish.enable = true;

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 6;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";
        users.users.linyuntao.home = "/Users/linyuntao";

        # Add the home-manager vscode extensions market package set into the nixpkgs

        nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ];

      };
    in {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#hayashis-MacBook-Pro
      darwinConfigurations."hayashis-MacBook-Pro" =
        nix-darwin.lib.darwinSystem {
          modules = [
            configuration
            mac-app-util.darwinModules.default
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              # 这里的 ryan 也得替换成你的用户名
              # 这里的 import 函数在前面 Nix 语法中介绍过了，不再赘述
              home-manager.users.linyuntao = import ./home.nix;

              # 使用 home-manager.extraSpecialArgs 自定义传递给 ./home.nix 的参数
              # 取消注释下面这一行，就可以在 home.nix 中使用 flake 的所有 inputs 参数了
              home-manager.extraSpecialArgs = inputs;

              home-manager.sharedModules =
                [ mac-app-util.homeManagerModules.default ];
            }
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                # Install Homebrew under the default prefix
                enable = true;

                # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
                enableRosetta = true;

                # User owning the Homebrew prefix
                user = "linyuntao";

                # Optional: Declarative tap management
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                };

                # Optional: Enable fully-declarative tap management
                #
                # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
                mutableTaps = false;
              };
            }
          ];
        };
    };
}
