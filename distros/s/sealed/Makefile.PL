use ExtUtils::MakeMaker;

WriteMakefile(
        NAME => "sealed",
        VERSION_FROM => "lib/sealed.pm",
        ABSTRACT_FROM => "lib/sealed.pm",
        MIN_PERL_VERSION => "5.22.0",
        PREREQ_PM => {
          'B::Generate' => 0,
        },
        test => { TESTS => "t/*.pl" },
        SIGN => 1,
);
