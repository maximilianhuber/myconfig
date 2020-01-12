{ stdenv
, fetchurl

, meson
, ninja
, pkgconfig
, gobject-introspection
, gsettings-desktop-schemas
, makeWrapper

, dbus
, glib
, libX11
, libXtst # at-spi2-core can be build without X support, but due it is a client-side library, GUI-less usage is a very rare case
, libXi
, fixDarwinDylibNames

, gnome3 # To pass updateScript
}:

stdenv.mkDerivation rec {
  pname = "at-spi2-core";
  version = "2.32.1";

  src = fetchurl {
    url = "mirror://gnome/sources/${pname}/${stdenv.lib.versions.majorMinor version}/${pname}-${version}.tar.xz";
    sha256 = "0lqd7gsl471v6538iighkvb21gjglcb9pklvas32rjpsxcvsjaiw";
  };

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [ meson ninja pkgconfig gobject-introspection makeWrapper ]
    # Fixup rpaths because of meson, remove with meson-0.47
    ++ stdenv.lib.optional stdenv.isDarwin fixDarwinDylibNames;
  buildInputs = [ dbus glib libX11 libXtst libXi ];

  doCheck = false; # fails with "AT-SPI: Couldn't connect to accessibility bus. Is at-spi-bus-launcher running?"

  # Provide dbus-daemon fallback when it is not already running when
  # at-spi2-bus-launcher is executed. This allows us to avoid
  # including the entire dbus closure in libraries linked with
  # the at-spi2-core libraries.
  mesonFlags = [ "-Ddbus_daemon=/run/current-system/sw/bin/dbus-daemon" ];

  passthru = {
    updateScript = gnome3.updateScript {
      packageName = pname;
    };
  };

  postFixup = ''
    # Cannot use wrapGAppsHook'due to a dependency cycle
    wrapProgram $out/libexec/at-spi-bus-launcher \
      --prefix GIO_EXTRA_MODULES : "${stdenv.lib.getLib gnome3.dconf}/lib/gio/modules" \
      --prefix XDG_DATA_DIRS : ${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}
  '';

  meta = with stdenv.lib; {
    description = "Assistive Technology Service Provider Interface protocol definitions and daemon for D-Bus";
    homepage = https://gitlab.gnome.org/GNOME/at-spi2-core;
    license = licenses.lgpl2Plus; # NOTE: 2018-06-06: Please check the license when upstream sorts-out licensing: https://gitlab.gnome.org/GNOME/at-spi2-core/issues/2
    maintainers = gnome3.maintainers;
    platforms = platforms.unix;
  };
}