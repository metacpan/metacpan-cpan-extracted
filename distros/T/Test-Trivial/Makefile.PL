use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR  => 'Cory Bennett <cpan@corybennett.org>',
    NAME            => 'Test::Trivial',
    VERSION_FROM    => 'lib/Test/Trivial.pm',
    LICENSE => 'artistic',
    PREREQ_PM => {
        "Test::More" => "0",
        "Regexp::Common" => "0",
        "Text::Diff" => "0",
        "Filter::Simple" => "0",
        "IO::Scalar" => "0",
        "IO::Tee" => "0",
    }
);
