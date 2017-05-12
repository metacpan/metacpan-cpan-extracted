use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::Class',
    AUTHOR              => 'Masafumi Yoshida <masafumi.yoshida820@gmail.com>',
    VERSION_FROM        => 'lib/WebService/Class.pm',
    ABSTRACT_FROM       => 'lib/WebService/Class.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'Cache::Memcached::Fast' =>0,
	'CGI' => 0,
	'LWP' => 0,
	'Digest::MD5' => 0,
	'XMLRPC::Lite'=> 0,
        'XML::Simple' => 0,
        'JSON' => 0,
        'Class::Accessor' => 0,
        'Class::Data::Inheritable' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-Class-*' },
);
