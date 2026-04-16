project(
    'hacker-network',
    'vala', 'c',
    version: '1.0.0',
    meson_version: '>= 0.57.0',
    default_options: [
        'warning_level=2',
        'buildtype=release',
    ]
)

# ─── Zależności ───────────────────────────────────────────────────────────────

gtk4_dep    = dependency('gtk4',       version: '>= 4.6')
glib_dep    = dependency('glib-2.0',   version: '>= 2.68')
gobject_dep = dependency('gobject-2.0')
gio_dep     = dependency('gio-2.0')

# ─── Pliki źródłowe ───────────────────────────────────────────────────────────

sources = files(
    'src/main.vala',
)

# ─── Binarka ──────────────────────────────────────────────────────────────────

executable(
    'hacker-network',
    sources,
    dependencies: [
        gtk4_dep,
        glib_dep,
        gobject_dep,
        gio_dep,
    ],
    vala_args: [
        '--target-glib=2.68',
        '--enable-checking',
    ],
    c_args: [
        '-w',   # wyłącz ostrzeżenia C (generowane przez Vala)
    ],
    install: true,
    install_dir: get_option('bindir'),
)

# ─── Desktop entry ────────────────────────────────────────────────────────────

install_data(
    'data/io.hackeros.network.desktop',
    install_dir: join_paths(get_option('datadir'), 'applications')
)

# ─── Ikona ────────────────────────────────────────────────────────────────────

install_data(
    'data/io.hackeros.network.svg',
    install_dir: join_paths(
        get_option('datadir'),
        'icons', 'hicolor', 'scalable', 'apps'
    )
)
