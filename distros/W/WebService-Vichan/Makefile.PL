use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'WebService::Vichan',
	VERSION_FROM      => 'lib/WebService/Vichan.pm',
	ABSTRACT_FROM     => 'lib/WebService/Vichan.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/Hash::Inflator  0
		   JSON::MaybeXS   0

		   IO::Socket::SSL 1.56
		   Mozilla::CA     0
		   Net::SSLeay     1.49/,
	},
	TEST_REQUIRES     => {
		qw/Test::RequiresInternet 0/,
	},
	META_ADD         => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=webservice-vichan.git',
		},
	}
);
