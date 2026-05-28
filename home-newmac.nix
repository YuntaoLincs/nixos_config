# home-newmac.nix — 远程登录瘦客户端配置
{
  pkgs,
  config,
  lib,
  ...
}:
let
  # Pin 到具体 commit 而不是 main 分支，避免上游推新 commit 导致 sha256 失效
  yazi_flavor_pkgs = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "flavors";
    rev = "54ab389e4deb3d1bc1d8de18d99e825962a55da1";
    sha256 = "sha256-46x4K4dx4rlU108SXhctJOeGlO/W57Pnofb914Sa4vA=";
  };
  # Pin 到 0897e20（2026-02-27）；该 commit 的插件要求 yazi >= 26.1.22，
  # 正好匹配 nixpkgs 当前的 yazi 26.1.22。再新的 plugin commit 会要求
  # 26.5.6+，但 nixpkgs 还没跟上。
  yazi_plugin_pkgs = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "0897e20d41b79a5ec8e80e645b041bb950547a0b";
    sha256 = "sha256-tHOHWFH9E7aGrmHb8bUD1sLGU0OIdTjQ2p4SbJVfh/s=";
  };
  # Launch Helix in iTerm's "Helix" profile (LXGW WenKai Mono), restore the
  # "Default" profile on exit. A real script (not a shell function) so every
  # launch path — typing `hx`, $EDITOR, yazi's opener — gets the font switch.
  # Wraps the SetProfile escape in tmux passthrough when inside tmux.
  hxw = pkgs.writeShellScriptBin "hxw" ''
    setp=$'\e]1337;SetProfile=Helix\a'
    restp=$'\e]1337;SetProfile=Default\a'
    if [ -n "''${TMUX:-}" ]; then
      setp=$'\ePtmux;\e'"$setp"$'\e\\'
      restp=$'\ePtmux;\e'"$restp"$'\e\\'
    fi
    printf '%s' "$setp"
    ${pkgs.helix}/bin/hx "$@"
    rc=$?
    printf '%s' "$restp"
    exit $rc
  '';
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
    basedpyright
    ruff
    nerd-fonts.jetbrains-mono
    hxw
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

      # Open Helix via the font-switching wrapper (iTerm "Helix" profile =
      # LXGW WenKai Mono). hxw is a real script, so yazi/$EDITOR use it too.
      alias hx='hxw'
      export EDITOR=hxw VISUAL=hxw
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

  # Use the font-switching wrapper as the editor so yazi / git / etc. all open
  # Helix in the LXGW WenKai Mono profile (defaultEditor would force EDITOR=hx).
  home.sessionVariables = {
    EDITOR = "hxw";
    VISUAL = "hxw";
  };

  programs.helix = {
    enable = true;
    defaultEditor = false;
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
        {
          name = "python";
          auto-format = true;
          # ruff first so it owns formatting/organize-imports; basedpyright
          # provides types, completion, go-to-def and inlay hints.
          language-servers = [
            "ruff"
            "basedpyright"
          ];
        }
      ];
      language-server = {
        nil = {
          command = "${pkgs.nil}/bin/nil";
        };
        basedpyright = {
          command = "${pkgs.basedpyright}/bin/basedpyright-langserver";
          args = [ "--stdio" ];
          config.basedpyright.analysis = {
            autoImportCompletions = true;
            typeCheckingMode = "standard";
            diagnosticMode = "openFilesOnly";
            # Allow `import sibling` in scripts run directly (experiment files).
            diagnosticSeverityOverrides.reportImplicitRelativeImport = "none";
            inlayHints = {
              variableTypes = true;
              callArgumentNames = true;
              functionReturnTypes = true;
              genericTypes = true;
            };
          };
        };
        ruff = {
          command = "${pkgs.ruff}/bin/ruff";
          args = [ "server" ];
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
