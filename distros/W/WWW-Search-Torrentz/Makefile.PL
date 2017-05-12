use ExtUtils::MakeMaker;
use 5.014000;

WriteMakefile(
	NAME              => 'WWW::Search::Torrentz',
	VERSION_FROM      => 'lib/WWW/Search/Torrentz.pm',
	ABSTRACT_FROM     => 'lib/WWW/Search/Torrentz.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	BUILD_REQUIRES    => {
		qw/WWW::Search::Test 0/,
	},
	PREREQ_PM         => {
		qw/HTML::TreeBuilder 0
		   URI::Escape       0
		   WWW::Search       0/,
	},
	META_MERGE        => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=www-search-torrentz.git'
		}
	}
);
