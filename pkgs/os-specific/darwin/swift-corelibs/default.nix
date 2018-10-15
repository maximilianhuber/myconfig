{callPackage, darwin}:

rec {
  corefoundation = callPackage ./corefoundation.nix {};
  libdispatch = callPackage ./libdispatch.nix {
   inherit (darwin) apple_sdk_sierra xnu;
  };
}
