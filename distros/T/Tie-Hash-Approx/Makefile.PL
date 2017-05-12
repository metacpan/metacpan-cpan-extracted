use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Tie::Hash::Approx',
    VERSION_FROM => 'lib/Tie/Hash/Approx.pm',
    PREREQ_PM    => {
        'Test::More'     => 0,
        'String::Approx' => 0,
    },
    ABSTRACT_FROM => 'lib/Tie/Hash/Approx.pm',
    AUTHOR        => 'Briac Pilpré <briac@cpan.org>',
);
