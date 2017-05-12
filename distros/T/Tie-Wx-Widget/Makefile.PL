use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tie::Wx::Widget',
    AUTHOR              => q{Herbert Breunung <lichtkind@cpan.org>},
    VERSION_FROM        => 'lib/Tie/Wx/Widget.pm',
    ABSTRACT_FROM       => 'lib/Tie/Wx/Widget.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
        'Test::Warn'      => 0,
        'Test::CheckManifest' => 0.9,
        'Test::Pod'       => 1.22,
        'Tie::Scalar'     => 0,
        'Wx'              => 0.74,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tie-Wx-Widget-*' },
);
