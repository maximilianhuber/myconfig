with (import ../lib.nix);
mkHostNixops "pi4"
( {lib, ...}:
  { imports =
      [ (fixIp "pi4" "eth0")
        # ../../secrets/common/wifi.QS3j.nix
      ];
  }
)
