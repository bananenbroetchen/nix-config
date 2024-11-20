{ config, pkgs, ...}:
{
  environment.systemPackages = with pkgs; [
    tldr
    thefuck
    nix-output-monitor
    neofetch

  ];
}