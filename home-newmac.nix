# home-newmac.nix — 远程登录瘦客户端配置
{
  pkgs,
  config,
  lib,
  ...
}:
let
  yazi_flavor_pkgs = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "flavors";
    rev = "main";
    sha256 = "sha256-nhIhCMBqr4VSzesplQRF6Ik55b3Ljae0dN+TYbzQb5s";
  };
  yazi_plugin_pkgs = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "main";
    sha256 = "sha256-LWN0riaUazQl3llTNNUMktG+7GLAHaG/IxNj1gFhDRE=";
  };
in
{
  home.username = "linyuntao";
  home.homeDirectory = "/Users/linyuntao";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    helix
    yazi
    git
    lazygit
    zsh
    tmux
    starship
    p7zip
    jq
    poppler
    fd
    ripgrep
    fzf
    zsh-fzf-tab
    zoxide
    eza
    nil
    nixfmt
  ];

  home.file = {
    ".vimrc".source = ./dot_file/vim_configuration;
  };

  programs.starship = {
    enable = true;
  };

  programs.tmux = {
    enable = true;
    extraConfig = ''
      # Remove the old prefix
      unbind C-b
      set -g prefix M-w
      bind M-w send-prefix    # Use alt+w as the send-prefix

      # Enable mouse support

      set -g mouse on

      # Key bindings
      bind w select-pane -U   # Use alt+w w to switch windows
      bind v split-window -h  # Use alt+w v to create a vertical split
      bind s split-window -v  # Use alt+w s to create a horizontal split
      bind o kill-pane -a     # Use alt+w o to close all panes except the current one
      bind h select-pane -R   # Use alt+w h to jump to the window left of the current one
      bind j select-pane -U   # Use alt+w j to jump to the window below the current one
      bind k select-pane -D   # Use alt+w k to jump to the window above the current one
      bind l select-pane -L   # Use alt+w l to jump to the window right of the current one

      # Swap windows
      bind J swap-pane -U     # Use alt+w J to swap with the window below
      bind K swap-pane -D     # Use alt+w K to swap with the window above

      # Kill current window
      bind q kill-pane # Use alt+w q to kill the current window

      bind L resize-pane -R 5 # Use alt+w L to resize the pane to right
      bind H resize-pane -L 5 # Use alt+w H to resize the pane to left
      set -g escape-time 10

      # Setting for yazi
      set -g allow-passthrough on
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM

      # Settings for support the popup window in tmux
      bind p if-shell -F '#{==:#{session_name},scratch}' {
        detach-client
      } {
        if-shell "tmux has-session -t scratch" {
          display-popup -E "tmux attach-session -t scratch"
        } {
          display-popup -E "tmux new-session -d -c '#{pane_current_path}' -s scratch && tmux set-option -t scratch status off && tmux attach-session -t scratch"
        }
      }
      set -g focus-event on
    '';
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      ls = "ls --color=auto";
      update = "sudo darwin-rebuild switch --flake ~/nix-darwin#newmac";
    };

    plugins = [
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
    ];

    initContent = ''
      autoload -U colors && colors
      setopt prompt_subst
      PROMPT='❰%{$fg[green]%}%n%{$reset_color%}|%{$fg[yellow]%}%1~%{$reset_color%}%{$fg[cyan]%}$(git branch --show-current 2&> /dev/null | xargs -I branch echo "(branch)")%{$reset_color%}❱ '
      bindkey '^ ' autosuggest-accept

      function y() {
      	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
      	yazi "$@" --cwd-file="$tmp"
      	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
      		builtin cd -- "$cwd"
      	fi
      	rm -f -- "$tmp"
      }
      eval "$(zoxide init zsh)"

      export PATH="/Users/linyuntao/.local/bin:$PATH"
    '';

    initExtra = ''
      zstyle ':fzf-tab:*' fzf-flags --height=12
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
    '';

    history.size = 10000;
  };

  programs.git = {
    enable = true;
    ignores = [ "ssh_folder" ];
    userEmail = "lin123456steve@outlook.com";
    userName = "YuntaoLincs";
  };

  programs.yazi = {
    enable = true;
    theme = {
      flavor = {
        dark = "catppuccin-frappe";
      };
    };
    flavors = {
      catppuccin-frappe = "${yazi_flavor_pkgs}/catppuccin-frappe.yazi";
    };
    plugins = {
      git = "${yazi_plugin_pkgs}/git.yazi";
      toggle-pane = "${yazi_plugin_pkgs}/toggle-pane.yazi";
      jump-to-char = "${yazi_plugin_pkgs}/jump-to-char.yazi";
      vcs-files = "${yazi_plugin_pkgs}/vcs-files.yazi";
      starship = pkgs.yaziPlugins.starship;
    };
    initLua = ''
      require("git"):setup{
        order = 0
      }
      require("starship"):setup()
    '';
    keymap = {
      prepend_keymap = [
        {
          on = "T";
          run = "plugin toggle-pane min-current";
          desc = "Show or hide the preview pane";
        }
        {
          on = "T";
          run = "plugin toggle-pane max-current";
          desc = "Maximize or restore the preview pane";
        }
        {
          on = "f";
          run = "plugin jump-to-char";
          desc = "Jump to char";
        }
        {
          on = [
            "g"
            "c"
          ];
          run = "plugin vcs-files";
          desc = "Show Git file changes";
        }
      ];
    };
    settings = {
      plugin.prepend_fetchers = [
        {
          id = "git";
          name = "*";
          run = "git";
        }
        {
          id = "git";
          name = "*/";
          run = "git";
        }
      ];
    };
  };

  programs.helix = {
    enable = true;
    defaultEditor = true;
    # 用 nixpkgs 自带的 helix（不再用 helix flake input 的 master），
    # 避免上游 tree-sitter grammar 仓库失效导致 build 失败
    settings = {
      theme = "dracula";
      editor = {
        cursor-shape = {
          normal = "block";
          insert = "bar";
          select = "underline";
        };
        statusline = {
          left = [
            "mode"
            "spinner"
            "version-control"
            "file-modification-indicator"
          ];
          center = [ "file-absolute-path" ];
          right = [
            "diagnostics"
            "position"
            "position-percentage"
          ];
        };
        auto-save = {
          focus-lost = true;
        };
        line-number = "relative";
        color-modes = true;
        lsp.display-inlay-hints = true;
        true-color = true;
        end-of-line-diagnostics = "error";
        inline-diagnostics = {
          cursor-line = "error";
        };
      };
    };
    languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
          language-servers = [ "nil" ];
        }
      ];
      language-server = {
        nil = {
          command = "${pkgs.nil}/bin/nil";
        };
      };
    };
    themes = {
      dracula = {
        "inherits" = "dracula";
      };
    };
  };

  programs.home-manager.enable = true;
}
