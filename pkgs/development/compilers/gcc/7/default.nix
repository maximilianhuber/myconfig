{ stdenv, targetPackages, fetchurl, fetchpatch, noSysDirs
, langC ? true, langCC ? true, langFortran ? false
, langObjC ? stdenv.targetPlatform.isDarwin
, langObjCpp ? stdenv.targetPlatform.isDarwin
, langGo ? false
, profiledCompiler ? false
, staticCompiler ? false
, enableShared ? true
, texinfo ? null
, perl ? null # optional, for texi2pod (then pod2man)
, gmp, mpfr, libmpc, gettext, which
, libelf                      # optional, for link-time optimizations (LTO)
, isl ? null # optional, for the Graphite optimization framework.
, zlib ? null
, enableMultilib ? false
, enablePlugin ? stdenv.hostPlatform == stdenv.buildPlatform # Whether to support user-supplied plug-ins
, name ? "gcc"
, libcCross ? null
, threadsCross ? null # for MinGW
, crossStageStatic ? false
, # Strip kills static libs of other archs (hence no cross)
  stripped ? stdenv.hostPlatform == stdenv.buildPlatform
          && stdenv.targetPlatform == stdenv.hostPlatform
, gnused ? null
, cloog # unused; just for compat with gcc4, as we override the parameter on some places
, buildPackages
}:

# LTO needs libelf and zlib.
assert libelf != null -> zlib != null;

# Make sure we get GNU sed.
assert stdenv.hostPlatform.isDarwin -> gnused != null;

# The go frontend is written in c++
assert langGo -> langCC;

# threadsCross is just for MinGW
assert threadsCross != null -> stdenv.targetPlatform.isWindows;

with stdenv.lib;
with builtins;

let majorVersion = "7";
    version = "${majorVersion}.4.0";

    inherit (stdenv) buildPlatform hostPlatform targetPlatform;

    patches =
      [ # https://gcc.gnu.org/ml/gcc-patches/2018-02/msg00633.html
        ./riscv-pthread-reentrant.patch
        # https://gcc.gnu.org/ml/gcc-patches/2018-03/msg00297.html
        ./riscv-no-relax.patch
      ]
      ++ optional (targetPlatform != hostPlatform) ../libstdc++-target.patch
      ++ optionals targetPlatform.isNetBSD [
        ../libstdc++-netbsd-ctypes.patch
      ]
      ++ optional noSysDirs ../no-sys-dirs.patch
      ++ optional (hostPlatform != buildPlatform) (fetchpatch { # XXX: Refine when this should be applied
        url = "https://git.busybox.net/buildroot/plain/package/gcc/7.1.0/0900-remove-selftests.patch?id=11271540bfe6adafbc133caf6b5b902a816f5f02";
        sha256 = "0mrvxsdwip2p3l17dscpc1x8vhdsciqw1z5q9i6p5g9yg1cqnmgs";
      })
      ++ optional langFortran ../gfortran-driving.patch
      ++ optional (targetPlatform.libc == "musl" && targetPlatform.isPower) ../ppc-musl.patch
      ++ optional (targetPlatform.libc == "musl") ../libgomp-dont-force-initial-exec.patch
      ++ optional (!crossStageStatic && targetPlatform.isMinGW) (fetchpatch {
        url = "https://raw.githubusercontent.com/lhmouse/MINGW-packages/${import ../common/mfcgthreads-patches-repo.nix}/mingw-w64-gcc-git/9000-gcc-${majorVersion}-branch-Added-mcf-thread-model-support-from-mcfgthread.patch";
        sha256 = "1nyjnshpq5gbcbbpfv27hy4ajvycmgkpiabkjlxnnrnq1d99k1ay";
      });

    /* Cross-gcc settings (build == host != target) */
    crossMingw = targetPlatform != hostPlatform && targetPlatform.libc == "msvcrt";
    stageNameAddon = if crossStageStatic then "stage-static" else "stage-final";
    crossNameAddon = optionalString (targetPlatform != hostPlatform) "${targetPlatform.config}-${stageNameAddon}-";

in

stdenv.mkDerivation ({
  name = "${crossNameAddon}${name}${if stripped then "" else "-debug"}-${version}";

  builder = ../builder.sh;

  src = fetchurl {
    url = "mirror://gcc/releases/gcc-${version}/gcc-${version}.tar.xz";
    sha256 = "0lgy170b0pp60j9cczqkmaqyjjb584vfamj4c30swd7k0j6y5pgd";
  };

  inherit patches;

  outputs = [ "out" "lib" "man" "info" ];
  setOutputFlags = false;
  NIX_NO_SELF_RPATH = true;

  libc_dev = stdenv.cc.libc_dev;

  hardeningDisable = [ "format" "pie" ];

  # This should kill all the stdinc frameworks that gcc and friends like to
  # insert into default search paths.
  prePatch = stdenv.lib.optionalString hostPlatform.isDarwin ''
    substituteInPlace gcc/config/darwin-c.c \
      --replace 'if (stdinc)' 'if (0)'

    substituteInPlace libgcc/config/t-slibgcc-darwin \
      --replace "-install_name @shlib_slibdir@/\$(SHLIB_INSTALL_NAME)" "-install_name $lib/lib/\$(SHLIB_INSTALL_NAME)"

    substituteInPlace libgfortran/configure \
      --replace "-install_name \\\$rpath/\\\$soname" "-install_name $lib/lib/\\\$soname"
  '';

  postPatch = ''
    configureScripts=$(find . -name configure)
    for configureScript in $configureScripts; do
      patchShebangs $configureScript
    done
  '' + (
    if targetPlatform != hostPlatform || stdenv.cc.libc != null then
      # On NixOS, use the right path to the dynamic linker instead of
      # `/lib/ld*.so'.
      let
        libc = if libcCross != null then libcCross else stdenv.cc.libc;
      in
        (
        '' echo "fixing the \`GLIBC_DYNAMIC_LINKER', \`UCLIBC_DYNAMIC_LINKER', and \`MUSL_DYNAMIC_LINKER' macros..."
           for header in "gcc/config/"*-gnu.h "gcc/config/"*"/"*.h
           do
             grep -q _DYNAMIC_LINKER "$header" || continue
             echo "  fixing \`$header'..."
             sed -i "$header" \
                 -e 's|define[[:blank:]]*\([UCG]\+\)LIBC_DYNAMIC_LINKER\([0-9]*\)[[:blank:]]"\([^\"]\+\)"$|define \1LIBC_DYNAMIC_LINKER\2 "${libc.out}\3"|g' \
                 -e 's|define[[:blank:]]*MUSL_DYNAMIC_LINKER\([0-9]*\)[[:blank:]]"\([^\"]\+\)"$|define MUSL_DYNAMIC_LINKER\1 "${libc.out}\2"|g'
           done
        ''
        + stdenv.lib.optionalString (targetPlatform.libc == "musl")
        ''
            sed -i gcc/config/linux.h -e '1i#undef LOCAL_INCLUDE_DIR'
        ''
        )
    else "")
      + stdenv.lib.optionalString targetPlatform.isAvr ''
        makeFlagsArray+=(
           'LIMITS_H_TEST=false'
        )
      '';

  inherit noSysDirs staticCompiler crossStageStatic
    libcCross crossMingw;

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ texinfo which gettext ]
    ++ (optional (perl != null) perl);

  # For building runtime libs
  depsBuildTarget =
    if hostPlatform == buildPlatform then [
      targetPackages.stdenv.cc.bintools # newly-built gcc will be used
    ] else assert targetPlatform == hostPlatform; [ # build != host == target
      stdenv.cc
    ];

  buildInputs = [
    gmp mpfr libmpc libelf
    targetPackages.stdenv.cc.bintools # For linking code at run-time
  ] ++ (optional (isl != null) isl)
    ++ (optional (zlib != null) zlib)
    # The builder relies on GNU sed (for instance, Darwin's `sed' fails with
    # "-i may not be used with stdin"), and `stdenvNative' doesn't provide it.
    ++ (optional hostPlatform.isDarwin gnused)
    ;

  depsTargetTarget = optional (!crossStageStatic && threadsCross != null) threadsCross;

  NIX_CFLAGS_COMPILE = stdenv.lib.optionalString (stdenv.cc.isClang && langFortran) "-Wno-unused-command-line-argument";
  NIX_LDFLAGS = stdenv.lib.optionalString  hostPlatform.isSunOS "-lm -ldl";

  preConfigure = import ../common/pre-configure.nix {
    inherit (stdenv) lib;
    inherit version hostPlatform langGo;
  };

  dontDisableStatic = true;

  # TODO(@Ericson2314): Always pass "--target" and always prefix.
  configurePlatforms = [ "build" "host" ] ++ stdenv.lib.optional (targetPlatform != hostPlatform) "target";

  configureFlags = import ../common/configure-flags.nix {
    inherit
      stdenv
      targetPackages
      crossStageStatic libcCross
      version

      gmp mpfr libmpc libelf isl

      enablePlugin
      enableMultilib
      enableShared

      langC
      langCC
      langFortran
      langGo
      langObjC
      langObjCpp
      ;
  } ++ optional (targetPlatform.isAarch64) "--enable-fix-cortex-a53-843419"
    ++ optional targetPlatform.isNetBSD "--disable-libcilkrts"
  ;

  targetConfig = if targetPlatform != hostPlatform then targetPlatform.config else null;

  buildFlags = optional
    (targetPlatform == hostPlatform && hostPlatform == buildPlatform)
    (if profiledCompiler then "profiledbootstrap" else "bootstrap");

  dontStrip = !stripped;

  doCheck = false; # requires a lot of tools, causes a dependency cycle for stdenv

  installTargets =
    if stripped
    then "install-strip"
    else "install";

  # https://gcc.gnu.org/install/specific.html#x86-64-x-solaris210
  ${if hostPlatform.system == "x86_64-solaris" then "CC" else null} = "gcc -m64";

  # Setting $CPATH and $LIBRARY_PATH to make sure both `gcc' and `xgcc' find the
  # library headers and binaries, regarless of the language being compiled.
  #
  # Likewise, the LTO code doesn't find zlib.
  #
  # Cross-compiling, we need gcc not to read ./specs in order to build the g++
  # compiler (after the specs for the cross-gcc are created). Having
  # LIBRARY_PATH= makes gcc read the specs from ., and the build breaks.

  CPATH = optionals (targetPlatform == hostPlatform) (makeSearchPathOutput "dev" "include" ([]
    ++ optional (zlib != null) zlib
  ));

  LIBRARY_PATH = optionals (targetPlatform == hostPlatform) (makeLibraryPath (optional (zlib != null) zlib));

  inherit
    (import ../common/extra-target-flags.nix {
      inherit stdenv crossStageStatic libcCross threadsCross;
    })
    EXTRA_TARGET_FLAGS
    EXTRA_TARGET_LDFLAGS
    ;

  passthru = {
    inherit langC langCC langObjC langObjCpp langFortran langGo version;
    isGNU = true;
  };

  enableParallelBuilding = true;
  inherit enableMultilib;

  inherit (stdenv) is64bit;

  meta = {
    homepage = https://gcc.gnu.org/;
    license = stdenv.lib.licenses.gpl3Plus;  # runtime support libraries are typically LGPLv3+
    description = "GNU Compiler Collection, version ${version}"
      + (if stripped then "" else " (with debugging info)");

    longDescription = ''
      The GNU Compiler Collection includes compiler front ends for C, C++,
      Objective-C, Fortran, OpenMP for C/C++/Fortran, and Ada, as well as
      libraries for these languages (libstdc++, libgomp,...).

      GCC development is a part of the GNU Project, aiming to improve the
      compiler used in the GNU system including the GNU/Linux variant.
    '';

    maintainers = with stdenv.lib.maintainers; [ ];

    platforms =
      stdenv.lib.platforms.linux ++
      stdenv.lib.platforms.freebsd ++
      stdenv.lib.platforms.illumos ++
      stdenv.lib.platforms.darwin;
  };
}

// optionalAttrs (targetPlatform != hostPlatform && targetPlatform.libc == "msvcrt" && crossStageStatic) {
  makeFlags = [ "all-gcc" "all-target-libgcc" ];
  installTargets = "install-gcc install-target-libgcc";
}

// optionalAttrs (enableMultilib) { dontMoveLib64 = true; }
)
