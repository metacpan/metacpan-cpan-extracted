use ExtUtils::MakeMaker;

WriteMakefile
(
    NAME            => 'Xcalibur::Rawfile',
    VERSION_FROM    => 'Rawfile.pm',
    (
        $] >= 5.8.0
        ? (ABSTRACT   => 'Making use of the Xcalibur XDK',
           AUTHOR     => 'Mark Southern (msouthern@exsar.com)')
        : ()
    ),
    PREREQ_PM => { 
                    Win32::OLE => undef,
                    Win32::OLE::Variant => undef
                 },
    'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'},
);
