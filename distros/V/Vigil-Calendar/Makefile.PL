use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Vigil::Calendar',
    VERSION_FROM => 'lib/Vigil/Calendar.pm',
    AUTHOR       => 'Jim Melanson <jmelanson1965@gmail.com>',
    ABSTRACT     => 'Calendar module for Perl applications',
    LICENSE      => 'perl',
    PREREQ_PM    => { 'Time::Local' => 0 },
    MIN_PERL_VERSION => '5.10.0',
);