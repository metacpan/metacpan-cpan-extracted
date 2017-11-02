use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'WWW::Oxontime',
	VERSION_FROM      => 'lib/WWW/Oxontime.pm',
	ABSTRACT_FROM     => 'lib/WWW/Oxontime.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/HTML::Tree    0
		   JSON::MaybeXS 0/,
	},
	TEST_REQUIRES     => {
		qw/Test::RequiresInternet 0/,
	},
	META_ADD          => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=www-oxontime.git',
		},
	}
);
