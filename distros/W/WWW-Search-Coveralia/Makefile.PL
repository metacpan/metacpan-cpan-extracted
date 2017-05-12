use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'WWW::Search::Coveralia',
	VERSION_FROM      => 'lib/WWW/Search/Coveralia.pm',
	ABSTRACT_FROM     => 'lib/WWW/Search/Coveralia.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	BUILD_REQUIRES    => {
		qw/Test::RequiresInternet 0
		   WWW::Search::Test 0/
	},
	PREREQ_PM         => {
		qw/HTML::TreeBuilder 0
		   List::MoreUtils 0
		   PerlX::Maybe 0
		   WWW::Search 0/
	},
	META_ADD          => {
		dynamic_config => 0,
		resources      => {
			repository => 'http://git.ieval.ro/?p=www-search-coveralia.git',
		}
	}
);
