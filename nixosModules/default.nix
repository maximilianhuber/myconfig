{ config, lib, pkgs, ... }:
let
  user = config.myconfig.user;
  modules = [ # modules
    ./core.nix
    ./dev
    ./exfat.nix
    ./gnupg.nix
    ./hardware.bluetooth
    ./make-linux-fast-again.nix
    ./mybackup.nix
    ./myconfig.service.deconz.nix
    ./nixos.gc.nix
    ./nixos.networking
    ./nixos.nix.nix
    ./nixos.user.nix
    ./programs.pass
    ./services.netdata.nix
    ./services.openssh.nix
    ./services.postgresql.nix
    ./services.syncthing.nix
    ./services.vsftp.nix
    ./services.xserver.autorandr.nix
    ./services.xserver.big-cursor.nix
    ./services.xserver.fonts.nix
    ./services.xserver.kernel.nix
    ./services.xserver.mkscreenshot.nix
    ./services.xserver.my-wallpapers
    ./services.xserver.nix
    ./services.xserver.printing.nix
    ./services.xserver.programs.chromium.nix
    ./services.xserver.programs.evolution.nix
    ./services.xserver.programs.kitty.nix
    ./services.xserver.programs.obs.nix
    ./services.xserver.programs.xss-lock.nix
    ./services.xserver.pulseaudio.nix
    ./services.xserver.st
    ./services.xserver.wacom.nix
    ./services.xserver.xclip.nix
    ./shell.common
    ./shell.programs.dic.nix
    ./shell.git
    ./shell.programs.tmux
    ./shell.programs.vim
    ./shell.zsh
    ./virtualization.docker
    ./virtualization.lxc.nix
    ./virtualization.qemu.nix
    ./virtualization.vbox.nix
  ];
  hm-modules = [ # home-manager modules
    ./shell.programs.bat.hm.nix
    ./shell.programs.exa.hm.nix
    ./services.xserver.programs.firefox.hm.nix
    ./services.xserver.programs.zathura.hm.nix
  ];
in {
  imports = [ ./myconfig ] ++ modules;
  config = {
    home-manager.users."${user}" = { imports = hm-modules; };
    assertions = [
      {
        assertion = config.networking.hostId != null;
        message = "config.networking.hostId should be set!";
      }
      {
        assertion = config.networking.hostName != "nixos";
        message = "config.networking.hostName should be set!";
      }
    ];
  };
}
