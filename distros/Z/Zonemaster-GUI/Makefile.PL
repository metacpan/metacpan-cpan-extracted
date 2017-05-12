use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Zonemaster::GUI',
    AUTHOR              => q{Michal TOMA <toma@nic.fr>},
    VERSION_FROM        => 'lib/Zonemaster/GUI.pm',
    ABSTRACT            => 'The Zonemaster project Web Frontend',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Starman' => 0,
        'Template' => 0,
        'LWP::UserAgent' => 0,
        'Time::HiRes' => 0,
        'Plack::Builder' => 0,
        'Text::Markdown' => 0,
        'HTML::Entities' => 0,
        'JSON' => 0,
        'Test::More' => 0,
        'YAML'       => 0,
        'Dancer'     => 1.3095,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Zonemaster_Dancer-*' },
);
