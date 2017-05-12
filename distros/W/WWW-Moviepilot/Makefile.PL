use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Moviepilot',
    AUTHOR              => q{Frank Wiegand <frank.wiegand@gmail.com>},
    VERSION_FROM        => 'lib/WWW/Moviepilot.pm',
    ABSTRACT_FROM       => 'lib/WWW/Moviepilot.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        'JSON::Any'      => 0,
        'LWP::UserAgent' => 0,
        'URI'            => 0,
        'URI::Escape'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Moviepilot-*' },
    ($ExtUtils::MakeMaker::VERSION >= 6.4502
      ? ( META_ADD => { resources => { repository => "git://github.com/haoess/perl-www-moviepilot.git" } } )
      : ()),
);
