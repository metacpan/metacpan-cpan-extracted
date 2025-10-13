use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Win32::Pipe::PP',
    VERSION_FROM => 'lib/Win32/Pipe/PP.pm',
    ABSTRACT     => 'Pure Perl Win32::Pipe replacement using Win32::API',
    AUTHOR       => 'J. Schneider',
    LICENSE      => 'mit',
    PREREQ_PM    => {
        'Carp'           => 0,
        'Exporter'       => 0,
        'Win32'          => 0,
        'Win32::API'     => 0,
        'Win32API::File' => 0,
        'Test::More'     => 0,
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/yourname/Win32-Pipe-PP',
            bugtracker => 'https://github.com/yourname/Win32-Pipe-PP/issues',
        },
    },
);
