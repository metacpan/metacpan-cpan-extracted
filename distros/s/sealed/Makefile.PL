use ExtUtils::MakeMaker;

WriteMakefile(
        NAME => "sealed",
        VERSION_FROM => "lib/sealed.pm",
        ABSTRACT_FROM => "lib/sealed.pm",
        MIN_PERL_VERSION => "5.28.0",
        LICENSE => "apache_2_0",
        PREREQ_PM => {
          'B::Generate' => 0,
          'Lexical::Types' => 0,
        },
        test => { TESTS => "t/*.pl" },
        SIGN => 1,
);
