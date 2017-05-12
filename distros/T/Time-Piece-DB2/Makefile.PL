use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Time::Piece::DB2',
    VERSION_FROM => 'lib/Time/Piece/DB2.pm',
    PREREQ_PM    => { 'Time::Piece' => 1.03, 'Test::More' => 0.47 },
    ( $] >= 5.005
    ? (    # Add these new keywords supported since 5.005
          ABSTRACT_FROM => 'lib/Time/Piece/DB2.pm',
          AUTHOR        =>
          'Mark Ferris <mark.ferris@geac.com>',
    )
    : () ),
);
