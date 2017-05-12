use ExtUtils::MakeMaker;

WriteMakefile
(
    NAME            => 'Win32::NetName',
    VERSION_FROM    => 'lib/Win32/NetName.pm',
    (
        $] >= 5.8.0
        ? (ABSTRACT   => 'A more universal way of obtaining the UNC names of local paths',
           AUTHOR     => 'Mark Southern (msouthern@exsar.com)')
        : ()
    ),
    PREREQ_PM => { 
                    Win32::API => 0.41,
                    Win32::Lanman => undef
                 },
    'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'},
);
