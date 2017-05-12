use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'UTF8BOM',
    VERSION_FROM      => 'lib/UTF8BOM.pm', # finds $VERSION
    EXE_FILES         => ['bin/utf8bom'],
    PREREQ_PM         => {
        IO::File => 0,
        IO::Dir  => 0,
        File::Spec => 0,
    },
);
