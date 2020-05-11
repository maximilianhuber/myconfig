# let
#   workstationAsBuildMachine =
#     { nix.buildMachines =
#         [{ hostName = "workstation";
#            system = "x86_64-linux";
#            maxJobs = 6;
#            speedFactor = 2;
#            supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
#            mandatoryFeatures = [ ];
#         }];
#       nix.distributedBuilds = true;
#       # optional, useful when the builder has a faster internet connection than yours
#       nix.extraOptions =
#         '' builders-use-substitutes = true
#         '';
#     };
# in
with (import ./lib.nix);
{ network.description = "myconfig";
  x1extremeG2 = mkHost "x1extremeG2"
    ( {lib, ...}:
      { config =
          { deployment.targetHost = lib.mkDefault "10.199.199.2";
            environment.shellAliases =
              { upg-workstation = "upg-fast --target workstation";
                upg-workstation-reboot = "upg-fast --target workstation --reboot";
                upg-vserver = "upg-fast --target vserver";
                upg-vserver-reboot = "upg-fast --target vserver --reboot";
              };
            nix.sshServe.enable = true;
            nix.sshServe.keys =
              [ (getSecret "workstation" "ssh/id_rsa.pub")
                (getSecret "vserver" "ssh/id_rsa.pub")
              ];
          };
        imports =
          [ (deployWireguardKeys "x1extremeG2")
            (deploySSHUserKeys "x1extremeG2" "rsa")
            (deploySSHUserKeys "x1extremeG2" "ed25519")
            (deploySSHUserKeys "x1extremeG2" "dsa")
            (deploySSHUserKeys "x1extremeG2" "ecdsa")
          ];
       });
  workstation = mkHost "workstation"
    ( {lib, ...}:
      { config =
          { deployment.targetHost =  lib.mkDefault "10.199.199.5";
            nix.sshServe.enable = true;
            nix.sshServe.keys =
              [ (getSecret "x1extremeG2" "ssh/id_rsa.pub")
                (getSecret "x1extremeG2" "ssh/id_ed2519.pub")
                (getSecret "x1extremeG2" "ssh/id_dsa.pub")
                (getSecret "x1extremeG2" "ssh/id_ecdsa.pub")
                (getSecret "vserver" "ssh/id_rsa.pub")
              ];
          };
        imports =
          [ (deployWireguardKeys "workstation")
            (deploySSHUserKeys "workstation" "rsa")
          ];
      });
  vserver = mkHost "vserver"
    ( {lib, ...}:
      { config =
          { deployment.targetHost = lib.mkDefault "10.199.199.1";
          };
        imports =
          [ (deployWireguardKeys "vserver")
            (deploySSHUserKeys "vserver" "rsa")
          ];
      });
  # T470p = mkHost "T470p"
  #   ({...}: {});
  # T470s = mkHost "T470s"
  #   ({...}: {});
}
