use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Session',
    AUTHOR              => q{Gligan Calin Horea <gliganh@gmail.com>},
    VERSION_FROM        => 'lib/WWW/Session.pm',
    ABSTRACT_FROM       => 'lib/WWW/Session.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Test::Exception' => 0,
		'Test::Deep' => 0,
		'JSON'	=> 0,
		'Storable' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Session-*' },
);
