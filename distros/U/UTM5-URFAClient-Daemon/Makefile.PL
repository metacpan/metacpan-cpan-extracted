use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'UTM5::URFAClient::Daemon',
    AUTHOR              => q{VeroLom <ver@0xff.su>},
    VERSION_FROM        => 'lib/UTM5/URFAClient/Daemon.pm',
    ABSTRACT_FROM       => 'lib/UTM5/URFAClient/Daemon.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    BUILD_REQUIRES => {
	'Test::Strict'	=> 0,
	'File::Spec'	=> 0
    },
    PREREQ_PM => {
        'Test::More'		=> 0,
        'RPC::XML::Server'	=> 0,
	'RPC::XML::Function'	=> 0,
        'XML::Writer'		=> 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'UTM5-URFAClient-Daemon-*' },
);
