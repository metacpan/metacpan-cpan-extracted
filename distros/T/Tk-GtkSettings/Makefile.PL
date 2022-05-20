use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Tk::GtkSettings',
    VERSION_FROM      => 'lib/Tk/GtkSettings.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'Test::More' => 0,
        'File::Basename' => 0,
        'File::Copy' => 0,
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Tk/GtkSettings.pm', # retrieve abstract from module
    AUTHOR            => 'Hans Jeuken <jeuken.hans@gmail.com>',
    LICENSE           => 'perl',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
          resources => {
              repository => {
                 type => 'git',
		 url  => 'git://github.com/haje61/Tk-GtkSettings.git',
                 web  => 'https://github.com/haje61/Tk-GtkSettings',
              },
          }})
      : ()
    ),
);
