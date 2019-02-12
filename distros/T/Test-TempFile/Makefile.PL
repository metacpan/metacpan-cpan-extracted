require 5.000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => "Test::TempFile",
    VERSION_FROM => "lib/Test/TempFile.pm",
    PREREQ_PM => {
        'Test::More' => 0.96,
        'Path::Tiny' => 0,
        'YAML::Tiny' => 0,
        'JSON::MaybeXS' => 0,
        'Test::Builder::Module' => 0,
        # Used by tests
        'Test::Exception' => 0,
        'Test2::API' => 0,
    },
    ($] >= 5.005 ? (
        ABSTRACT => 'Helper library for testing code that uses temp files',
        AUTHOR => 'Richard Harris <rjh@netcraft.com>',
    ) : ()),
);
