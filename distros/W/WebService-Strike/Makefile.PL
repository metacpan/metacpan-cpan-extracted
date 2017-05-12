use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'WebService::Strike',
	VERSION_FROM      => 'lib/WebService/Strike.pm',
	ABSTRACT_FROM     => 'lib/WebService/Strike.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	BUILD_REQUIRES    => {
		qw/Test::RequiresInternet 0
		   Try::Tiny              0/,
	},
	PREREQ_PM         => {
		qw/HTTP::Tiny            0.014
		   Class::Accessor::Fast 0
		   IO::Socket::SSL       1.56
		   JSON::MaybeXS         0
		   Mozilla::CA           0
		   Net::SSLeay           1.49
		   Sort::ByExample       0
		   URI::Escape           0/,
	},
	META_ADD          => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=webservice-strike.git',
		}
	}
);
