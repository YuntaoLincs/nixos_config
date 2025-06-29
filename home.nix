# home.nix
{ pkgs, helix, config, lib, ... }:
let
  yazi_flavor_pkgs = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "flavors";
    rev = "main";
    sha256 = "sha256-nhIhCMBqr4VSzesplQRF6Ik55b3Ljae0dN+TYbzQb5s";
    # sha256 = "sha256-nhIhCMBqr4VSzesplQRF6Ik55b3Ljae0dN+TYbzQb5s=";
  };
  yazi_plugin_pkgs = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "main";
    sha256 = "sha256-LWN0riaUazQl3llTNNUMktG+7GLAHaG/IxNj1gFhDRE=";
  };
  # yazi_plugin_pkgs2 = pkgs.fetchFromGitHub {
  #   owner = "Rolv-Apneseth"
  # }

in {
  # Home Manager options go here
  home.username = "linyuntao"; # Set the user name (change as needed)
  home.homeDirectory = "/Users/linyuntao"; # Set the home directory
  home.stateVersion = "25.05";

  # Example: Add some packages
  home.packages = with pkgs; [
    vscode # Install VSCode package here
    yazi
    helix
    git
    alacritty
    zed-editor
    zsh
    tmux
    mpv
    starship
    p7zip
    jq
    poppler
    fd
    ripgrep
    fzf
    zoxide
    typst
    graphviz
    # pdm
  ];

  programs.starship = { enable = true; };

  home.file = {
    ".vimrc".source = ./dot_file/vim_configuration;
    ".config/zed/keymap.json".source = ./dot_file/zed/keymap.json;
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
      # set -g window-status-style bg=yellow
      # set -g window-status-current-style bg=red,fg=white

      # Setting for yazi
      set -g allow-passthrough on
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM

      # Settings for support the popup window in tmux
      # alt+w p to create a pop-up window in current env
      # alt+w p to hide the pop-up window
      # ctrl+d to kill this pop-up window
      bind p if-shell -F '#{==:#{session_name},scratch}' { 
        detach-client 
      } { 
        if-shell "tmux has-session -t scratch" {
          display-popup -E "tmux attach-session -t scratch"
        } {
          display-popup -E "tmux new-session -d -c '#{pane_current_path}' -s scratch && tmux set-option -t scratch status off && tmux attach-session -t scratch"
        }
      }
      set -g focus-event on # enable the focus lost event in tmux (if iterm2 enable)
    '';
  };
  programs.zed-editor = {
    enable = true;
    # userKeymaps = import ./home-package/zed/keymap.nix;
    # # userSettings = import ./home-package/zed/setting.nix;
    userSettings = {
      vim_mode = true;
      ui_font_size = 24;
      buffer_font_size = 24;
      buffer_font_family = "JetBrainsMono Nerd Font";
    };
  };
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      ls = "ls --color=auto";
      update = "darwin-rebuild switch --flake ~/nix-darwin";
      x = "sh ~/nix-darwin/shells/exec_cmd.sh $1";
      lx = "sh ~/nix-darwin/shells/exec_lst_cmd.sh";
    };
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

      export PATH="/Users/linyuntao/.deno/bin:$PATH"
      export PATH="/Users/linyuntao/.local/bin:$PATH"
    '';

    # plugins = [{
    #   name = "zsh-z";
    #   src = "${pkgs.zsh-z}/share/zsh-z";
    # }];

    history.size = 10000;
  };

  programs.alacritty = {
    enable = true;
    settings = {
      window.dimensions = {
        lines = 40;
        columns = 120;
      };
      window.option_as_alt = "Both";
      window.padding = {
        x = 10;
        y = 10;
      };

      colors.primary = {
        background = "#1e1e1e";
        foreground = "#f0f0f0";
      };

      colors.normal = {
        black = "#000000";
        red = "#ff0000";
        green = "#00ff00";
        yellow = "#ffff00";
        blue = "#38a6c9";
        magenta = "#ff00ff";
        cyan = "#00ffff";
        white = "#ffffff";
      };
      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Italic";
        };
        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };

      };
    };
  };

  programs.git = {
    enable = true;
    ignores = [ "ssh_folder" ];
    userEmail = "lin123456steve@outlook.com";
    userName = "YuntaoLincs";
  };

  # Enable VSCode and configure extensions via Home Manager
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-marketplace; [
      # vscodevim.vim
      # Support for python 
      njpwerner.autodocstring
      visualstudioexptteam.vscodeintellicode
      visualstudioexptteam.intellicode-api-usage-examples
      wholroyd.jinja
      ms-python.python
      ms-python.vscode-pylance
      ms-python.debugpy
      batisteo.vscode-django
      kevinrose.vsc-python-indent
      donjayamanne.python-environment-manager
      jasew.vscode-helix-emulation
      # ms-vscode.cpptools
      ms-vscode.cpptools-themes
    ];

  };

  programs.yazi = {
    enable = true;
    theme = { flavor = { dark = "catppuccin-frappe"; }; };
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
      manager.prepend_keymap = [
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
          on = [ "g" "c" ];
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
    package = helix.packages.${pkgs.system}.default;
    settings = {
      # theme = "autumn_night_transparent";
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
          right = [ "diagnostics" "position" "position-percentage" ];
        };
        auto-save = { focus-lost = true; };

        color-modes = true;
        lsp.display-inlay-hints = true;
        true-color = true;
        end-of-line-diagnostics = "error";
        inline-diagnostics = { cursor-line = "error"; };
      };
      keys = {
        normal = {
          space = { l = ":sh  ~/nix-darwin/shells/exec_lst_cmd.sh"; };
          C-y = [
            ":sh rm -f /tmp/unique-file"
            ":insert-output yazi %{buffer_name} --chooser-file=/tmp/unique-file"
            '':insert-output echo "\x1b[?1049h\x1b[?2004h" > /dev/tty''
            ":open %sh{cat /tmp/unique-file}"
            ":redraw"
          ];
        };
      };
    };
    languages = {
      language = [
        {
          name = "python";
          auto-format = true;
          language-servers = [
            "ruff"

            "basedpyright"
          ];
          debugger = {
            name = "debugpy";
            transport = "stdio";
            # command = "${pkgs.python312Packages.debugpy}/bin/debugpy";
            # args = [  "debugpy.adapter" ];
            # command = "${pkgs.python3}/bin/python3}";
            command = "python";
            args = [ "-m" "debugpy.adapter" ];
            templates = [{
              name = "source";
              request = "launch";
              completion = [{
                name = "entrypoint";
                completion = "filename";
                default = ".";
              }];
              args = {
                mode = "debug";
                program = "{0}";
              };
            }];
          };
        }
        {
          name = "nix";
          auto-format = true;
          formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
          language-servers = [ "nil" ];
        }
        {
          name = "markdown";
          auto-format = true;
          formatter = {
            command = "${pkgs.dprint}/bin/dprint";
            args = [ "fmt" "--stdin" "md" ];
          };
          language-servers = [ "marksman" ];
        }
        {
          name = "typst";
          auto-format = true;
          language-servers = [ "tinymist" ];
          formatter = { command = "${pkgs.typstfmt}/bin/typstfmt"; };
        }
        {
          name = "cpp";
          indent = {
            tab-width = 2;
            unit = "	";
          };
        }
        {
          name = "json";
          language-servers = [ "vscode-json-language-server" ];
        }
      ];
      language-server = {
        vscode-json-language-server = {
          command =
            "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server";
        };
        basedpyright = {
          command = "${pkgs.basedpyright}/bin/basedpyright-langserver";
        };

        ruff = {
          command = "${pkgs.ruff}/bin/ruff";
          args = [ "server" ];
        };

        marksman = { command = "${pkgs.marksman}/bin/marksman"; };

        nil = { command = "${pkgs.nil}/bin/nil"; };

        tinymist = { command = "${pkgs.tinymist}/bin/tinymist"; };
      };
      # language-server.pylsp = {
      #  command = "${pkgs.pylsp}/bin/pylsp";
      #  config.pylsp = {

      #  }
      #  }

    };
    themes = {
      # autumn_night_transparent = {
      #   "inherits" = "autumn_night";
      #   "ui.background" = { };
      #   "ui.cursor" = {
      #     fg = "blue";
      #     modifiers = [ "reversed" ];
      #   "ui."
      #   };
      # };
      dracula = { "inherits" = "dracula"; };
      # python_no_hint = {
      #   "inherits" = "dracula";
      #   inline-diagnostics = { cursor-line = "error"; };

      # };
    };
  };
  programs.home-manager.enable = true;
}
