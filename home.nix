# home.nix
{ pkgs, config, ... }: {
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
  ];

  home.file = { ".vimrc".source = ./dot_file/vim_configuration; };

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
        blue = "#0000ff";
        magenta = "#ff00ff";
        cyan = "#00ffff";
        white = "#ffffff";
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
    extensions = with pkgs.vscode-extensions; [
      vscodevim.vim
      bbenoist.nix
      ms-python.python

      visualstudioexptteam.vscodeintellicode
    ];
  };

  programs.yazi = { enable = true; };

  programs.helix = {
    enable = true;
    settings = {
      theme = "autumn_night_transparent";
      editor.cursor-shape = {
        normal = "block";
        insert = "bar";
        select = "underline";
      };
    };
    languages = {
      language = [
        {
          name = "python";
          auto-format = true;
          formatter = { command = "${pkgs.black}/bin/black"; };
          language-servers = [ "pylsp" ];
        }
        {
          name = "nix";
          auto-format = true;
          formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
        }
      ];
      # language-server.pylsp = {
      #  command = "${pkgs.pylsp}/bin/pylsp";
      #  config.pylsp = {

      #  }
      #  }

    };
    themes = {
      autumn_night_transparent = {
        "inherits" = "autumn_night";
        "ui.background" = { };
      };
    };
  };

  programs.home-manager.enable = true;

}
