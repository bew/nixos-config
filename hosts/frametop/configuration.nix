# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../modules/better-nix-settings.nix
    # Disable the KDE file indexer `baloo`, when I add/delete/change a lot of small files
    # (e.g: when cloning / compressing / deleting the nixpkgs repo) baloo seems to update
    # its cache like crazy by writing 100M/s on the disk for many minutes (10-15?)...
    # And I actually never use file search that needs pre-indexing, so bye bye o/
    ../../modules/disable-kde-file-indexer.nix

    ../../modules/for-zsa-keyboards.nix
    ../../modules/input-remaps.nix

    # Play with kubernetes :)
    # ../../modules/k3s-playground.nix
    # Play with rootless docker :)
    # ../../modules/podman-docker-virtu.nix
  ];

  # IDEA: 'options' that act as hardware reference, to be able to access the hardware info in a pure way at eval time,
  # to allow writing this option relative to hardware info:
  # nix.settings.cores = config.hardware-reference.cpuCount / 2;
  nix.settings.cores = 8;

  nix.settings.experimental-features = "nix-command flakes";

  nix.gc = {
    automatic = true; # Let's try!
    dates = "weekly";
    # NOTE: Ideally I'd like to keep at least the last N known-to-work configs
    # See related notes in 20220919T2145 to tag working config.
    options = "--delete-old --delete-older-than 30d";
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.tmp.useTmpfs = true;
  boot.tmp.tmpfsSize = "10G";
  # Make nix-daemon use a larger directory than /tmp for builds
  # ref: https://github.com/NixOS/nix/issues/2098
  systemd = let nix-daemon-tmp-dir = "/nix/tmp"; in {
    services.nix-daemon.environment.TMPDIR = nix-daemon-tmp-dir;
    tmpfiles.rules = [
      # https://discourse.nixos.org/t/27846/6
      # https://www.freedesktop.org/software/systemd/man/tmpfiles.d.html
      "d ${nix-daemon-tmp-dir} 0755 root root"
    ];
  };

  networking.hostName = "frametop";
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = let
    nativeLang = "fr_FR.UTF-8";
  in {
    LC_MEASUREMENT = nativeLang;
    LC_MONETARY = nativeLang;
    LC_NUMERIC = nativeLang;
    LC_PAPER = nativeLang;
    LC_TELEPHONE = nativeLang;
    LC_TIME = nativeLang;
    # NOTE: `LC_ALL` should only be set for troubleshooting, it overrides every
    # local settings, can be set to C.UTF-8 for simple debugs (while still
    # supporting unicode chars).
  };

  console = {
    font = "Lat2-Terminus16";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the Plasma 5 Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Configure keymap in X11
  services.xserver.layout = "fr";

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;
  services.xserver.libinput.touchpad = {
    # FIXME: Is there a way to configure the timeout until the touchpad is re-enabled again?
    #   Or a way to disable taps for a bit longer? (drag is not an issue)
    #   -> Or even disable touchpad tap (click) when a non-modifier key is pressed until I drag the mouse around.
    #      => TODO: open an dedicated issue for this?
    # On the Framework, the touchpad is BIG, and not exactly centered w.r.t. `f` & `j` keys,
    # and when I type, the internal edge of my right palm is actually over the touchpad.
    # => It happens too often that I tap the touchpad with it by mistake,
    #    moving the cursor to unwanted / surprising locations..
    # Disabling mouse action in vim's insert mode is not enough, it also happens on normal mode and
    # in other GUI programs, and have been destructive more than once!
    #
    # Upstream feature request issues:
    # - https://gitlab.freedesktop.org/libinput/libinput/-/issues/379
    # - https://gitlab.freedesktop.org/libinput/libinput/-/issues/619
    disableWhileTyping = true;

    tappingDragLock = false; # It's just annoying to have it and be surprised when doing fast movements..
    additionalOptions = ''
      # Tapping with 1/2/3 fingers give left/middle/right buttons respectively
      # Ref: https://wiki.archlinux.org/title/libinput#Tapping_button_re-mapping
      Option "TappingButtonMap" "lmr"
    '';
  };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;  # Disabled, pipewire config should take care of this
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    # FIXME: When connecting to an HDMI monitor (over USB-C hub, didn't test without),
    # the HDMI audio profile is not activated by default.
    # When I activate it, and later disconnect the monitor, the audio doesn't auto switch
    # back to `Analog Stereo Duplex`.
    #
    # This issue was mentionned in NixOS's Tracking issue for pipewire:
    # https://github.com/NixOS/nixpkgs/issues/102547#issuecomment-1277892311
    # (with next comments giving some info, not tried yet)
    #
    # Upstream issues that might be related: (I subscribed to them)
    # - https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/2545
    # - https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/2951
  };

  services.flatpak.enable = true;
  # FIXME: Add a way to declaratively track & configure flatpak apps?
  # Way to declare which remote repo of flatpaks to track (flathub / ..)
  # Ways to declaratively describe which flatpaks I want to track? (system level / user level)
  #   (and make wrappers or `@flat wrapper` to easily call them?)
  #   Way to check / test an app work on upgrade?
  #   Allow them to update themself using some flatpak cmds? or have a version/hash of a specific version I want?
  # Could also setup overrides globally / per app:
  #   https://docs.flatpak.org/en/latest/flatpak-command-reference.html#flatpak-override
  #
  # This might be useful to better share system fonts & icons:
  #   https://github.com/NixOS/nixpkgs/issues/119433#issuecomment-1326957279
  #   although it might be simpler to use `mount --bind ...` call instead of `bindfs`

  programs.kdeconnect.enable = true;

  # `dconf` is necessary by gtk-based programs to save their settings, otherwise you get the
  # following warning:
  # `failed to commit changes to dconf: GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name ca.desrt.dconf was not provided by any .service files`
  programs.dconf.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.bew = {
    isNormalUser = true;
    # note: nice reference of system groups:
    # https://wiki.debian.org/SystemGroups#Groups_without_an_associated_user
    extraGroups = [
      "wheel" # Enable *sudo* for the user.
      "plugdev" # Allow to mount/unmount removable devices (necessary for some ZSA features)
    ];
  };

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs; [
    # -- CLI

    vim # at the very least
    wget
    file
    git
    zip
    unzip
    _7zz # 7z (not sure why the drv is named that way...)
    appimage-run # to easily run downloaded appimage files

    # -- Desktop

    ark # a nice archive gui, usually used in KDE
    libreoffice
    firefox
    nomacs

    gparted
    ntfs3g

    # -- Media / Other
    kdenlive
    # Install with the system to ensure the same qt version is used,
    # to avoid qt stuff loading error on start.
    # See <20230328T1209#incompatible-qt>
    transmission-qt

    prusa-slicer
  ];

  boot.kernelPackages = pkgs.linuxPackages_6_6; # Linux 6.6 is LTS

  # This will regularly tell the SSD which blocks are deleted on the filesystem side,
  # so these blocks can be used for other things by the SSD controller.
  # => Helps SSD performance & lifespan!
  # See: https://en.wikipedia.org/wiki/Trim_(computing)
  services.fstrim.enable = true; # Runs weekly

  # Let's monitor my PC!
  # TODO(later): send metrics to some external server? cloud service?
  #   and monitor some things?
  services.netdata.enable = true;
  # NOTE: easily check current config at <http://localhost:19999/netdata.conf>
  services.netdata.config = {
    # Enable more metrics around power supply
    "plugin:proc:/sys/class/power_supply" = {
      "battery capacity" = "yes"; # the default
      "battery charge" = "yes";
      "battery energy" = "yes";
      "power supply voltage" = "yes";
    };
  };

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  # Bluetooth
  #   In GUI, KDE has nice bluedevil UI in panel widget & settings
  #   In cli, `bluetoothctl` can inspect & do BT-related actions
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true; # power default controller on boot / resume from suspend

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    1234 # usually used for SHORT-TERM tests, should be open if used!
  ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
