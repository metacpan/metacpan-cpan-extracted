use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'WebService::Scaleway',
	VERSION_FROM      => 'lib/WebService/Scaleway.pm',
	ABSTRACT_FROM     => 'lib/WebService/Scaleway.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/JSON::MaybeXS 0/,
	},
	META_MERGE        => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=webservice-scaleway.git',
		}
	}
);
