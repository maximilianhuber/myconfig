{ stdenv, fetchFromGitHub, meson, ninja, pkgconfig, appstream-glib
, wrapGAppsHook, pythonPackages, gtk3, gnome3, gobject-introspection
, libnotify, libsecret, gst_all_1 }:

pythonPackages.buildPythonApplication rec {
  pname = "pithos";
  version = "1.4.1";

  src = fetchFromGitHub {
    owner = pname;
    repo  = pname;
    rev = version;
    sha256 = "0vaw0rfcdh4bsp9b8la9bs36kw0iwia54y5x060byxhff9av6nj4";
  };

  format = "other";

  postPatch = ''
    chmod +x meson_post_install.py
    patchShebangs meson_post_install.py
  '';

  nativeBuildInputs = [ meson ninja pkgconfig appstream-glib wrapGAppsHook ];

  propagatedBuildInputs =
    [ gtk3 gobject-introspection libnotify libsecret gnome3.adwaita-icon-theme ] ++
    (with gst_all_1; [ gstreamer gst-plugins-base gst-plugins-good gst-plugins-ugly gst-plugins-bad ]) ++
    (with pythonPackages; [ pygobject3 pylast ]);

  meta = with stdenv.lib; {
    description = "Pandora Internet Radio player for GNOME";
    homepage = https://pithos.github.io/;
    license = licenses.gpl3;
    maintainers = with maintainers; [ obadz ];
  };
}