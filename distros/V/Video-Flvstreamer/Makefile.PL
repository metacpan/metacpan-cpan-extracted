use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Video::Flvstreamer',
    AUTHOR              => q{Robin Clarke <robin@robinclarke.net>},
    VERSION_FROM        => 'lib/Video/Flvstreamer.pm',
    ABSTRACT_FROM       => 'lib/Video/Flvstreamer.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'IPC::Run'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Video-Flvstreamer-*' },
);
