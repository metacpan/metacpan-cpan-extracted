use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Time::Piece::MySQL',
    VERSION_FROM => 'lib/Time/Piece/MySQL.pm',
    PREREQ_PM    => { 'Time::Piece' => 1.03, 'Test::More' => 0.47 },
    ABSTRACT_FROM => 'lib/Time/Piece/MySQL.pm',
    AUTHOR => 'Marty Pauley <marty+perl@kasei.com>',
);
