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

  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, homebrew-core
    , homebrew-cask, home-manager, nix-vscode-extensions, mac-app-util, ... }:
    let
      configuration = { pkgs, config, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        nixpkgs.config.allowUnfree = true;
        environment.systemPackages = [
          pkgs.vim
          pkgs.mkalias
          pkgs.obsidian
          pkgs.google-chrome
          pkgs.uv
          pkgs.clang
          pkgs.gcc
          pkgs.ollama

          pkgs.python3

          pkgs.nerd-font-patcher
          pkgs.ffmpeg
          pkgs.imagemagick

          # pkgs.nerd-fonts._0xproto
          # pkgs.nerd-fonts._3270
          # pkgs.nerd-fonts.agave
          # pkgs.nerd-fonts.anonymice
          # pkgs.nerd-fonts.arimo
          # pkgs.nerd-fonts.aurulent-sans-mono
          # pkgs.nerd-fonts.bigblue-terminal
          # pkgs.nerd-fonts.bitstream-vera-sans-mono
          # pkgs.nerd-fonts.blex-mono
          # pkgs.nerd-fonts.caskaydia-cove
          # pkgs.nerd-fonts.caskaydia-mono
          # pkgs.nerd-fonts.code-new-roman
          # pkgs.nerd-fonts.comic-shanns-mono
          # pkgs.nerd-fonts.commit-mono
          # pkgs.nerd-fonts.cousine
          # pkgs.nerd-fonts.d2coding
          # pkgs.nerd-fonts.daddy-time-mono
          # pkgs.nerd-fonts.departure-mono
          # pkgs.nerd-fonts.dejavu-sans-mono
          # pkgs.nerd-fonts.droid-sans-mono
          # pkgs.nerd-fonts.envy-code-r
          # pkgs.nerd-fonts.fantasque-sans-mono
          # pkgs.nerd-fonts.fira-code
          # pkgs.nerd-fonts.fira-mono
          # pkgs.nerd-fonts.geist-mono
          # pkgs.nerd-fonts.go-mono
          # pkgs.nerd-fonts.gohufont
          # pkgs.nerd-fonts.hack
          # pkgs.nerd-fonts.hasklug
          # pkgs.nerd-fonts.heavy-data
          # pkgs.nerd-fonts.hurmit
          # pkgs.nerd-fonts.im-writing
          # pkgs.nerd-fonts.inconsolata
          # pkgs.nerd-fonts.inconsolata-go
          # pkgs.nerd-fonts.inconsolata-lgc
          # pkgs.nerd-fonts.intone-mono
          # pkgs.nerd-fonts.iosevka
          # pkgs.nerd-fonts.iosevka-term
          # pkgs.nerd-fonts.iosevka-term-slab
          pkgs.nerd-fonts.jetbrains-mono
          # pkgs.nerd-fonts.lekton
          # pkgs.nerd-fonts.liberation
          # pkgs.nerd-fonts.lilex
          # pkgs.nerd-fonts.martian-mono
          # pkgs.nerd-fonts.meslo-lg
          # pkgs.nerd-fonts.monaspace
          # pkgs.nerd-fonts.monofur
          # pkgs.nerd-fonts.monoid
          # pkgs.nerd-fonts.mononoki
          # pkgs.nerd-fonts.mplus
          # pkgs.nerd-fonts.noto
          # pkgs.nerd-fonts.open-dyslexic
          # pkgs.nerd-fonts.overpass
          # pkgs.nerd-fonts.profont
          # pkgs.nerd-fonts.proggy-clean-tt
          # pkgs.nerd-fonts.recursive-mono
          # pkgs.nerd-fonts.roboto-mono
          # pkgs.nerd-fonts.shure-tech-mono
          # pkgs.nerd-fonts.sauce-code-pro
          # pkgs.nerd-fonts.space-mono
          # pkgs.nerd-fonts.symbols-only
          # pkgs.nerd-fonts.terminess-ttf
          # pkgs.nerd-fonts.tinos
          pkgs.nerd-fonts.ubuntu
          pkgs.nerd-fonts.ubuntu-mono
          pkgs.nerd-fonts.ubuntu-sans
          pkgs.nerd-fonts.victor-mono
          pkgs.nerd-fonts.zed-mono
        ];
        homebrew = {
          enable = true;
          casks = [ "chatgpt" "wechat" "qqmusic" "qq" "steam" "iina" "iterm2" ];
          # TODO: Need to be enable if mas list bug finished.
          # brews = [ "mas" ];
          # masApps = { "vivid" = 6443470555; };
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
        system.defaults = { dock.autohide = true; };

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
