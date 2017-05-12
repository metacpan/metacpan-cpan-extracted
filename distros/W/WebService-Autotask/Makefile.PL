use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'WebService::Autotask',
	AUTHOR        => [q{Derek Wueppelmann <derek@roaringpenguin.com>},
			  q{Chris Adams <cmadams@hiwaay.net>}],
	VERSION_FROM  => 'lib/WebService/Autotask.pm',
	ABSTRACT_FROM => 'lib/WebService/Autotask.pm',
	PL_FILES      => {},
	PREREQ_PM     => {
		'SOAP::Lite' => 0,
		'XML::LibXML' => 0,
		'Crypt::SSLeay' => 0,
		'MIME::Base64' => 0,
		'MIME::Lite' => 0,
		'XML::LibXML' => 0,
		'File::Find::Rule' => 0,
		'Test::Class' => 0,
		'Test::MockObject' => 0
	},
	dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean         => { FILES => 'WebService-Autotask-*' },
);
