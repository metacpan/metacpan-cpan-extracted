use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'WWW::BackpackTF',
	VERSION_FROM      => 'lib/WWW/BackpackTF.pm',
	ABSTRACT_FROM     => 'lib/WWW/BackpackTF.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/JSON::MaybeXS 0
		   PerlX::Maybe 0/,
	},
	BUILD_REQUIRES    => {
		qw/Test::RequiresInternet 0/,
	},
	META_MERGE        => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=www-backpacktf.git',
		}
	}
);
