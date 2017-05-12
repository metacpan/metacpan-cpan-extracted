use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Test::Role',
    VERSION         => '0.12',
    PREREQ_PM       => {
                         Test::Builder         => 0.17,
                         Test::Builder::Tester => 0.09,
                         Class::Roles          => 0.20,
                       },
);


