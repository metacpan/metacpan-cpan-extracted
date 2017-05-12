use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'WWW::Facebook::Go::SGF',
    VERSION_FROM => 'lib/WWW/Facebook/Go/SGF.pm',
    PREREQ_PM    => {
        'LWP::Simple' => 0
    },
    EXE_FILES    => [qw(
        bin/facebook2sgf
    )],

);
