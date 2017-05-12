use 5.014000;
use ExtUtils::MakeMaker;

my $has_tr = $ExtUtils::MakeMaker::VERSION >= 6.64;
my @tr = (($has_tr ? 'TEST_REQUIRES' : 'BUILD_REQUIRES') => {
	qw/Test::RequiresInternet 0/,
});

WriteMakefile(
	NAME              => 'WebService::TDWTF',
	VERSION_FROM      => 'lib/WebService/TDWTF.pm',
	ABSTRACT_FROM     => 'lib/WebService/TDWTF.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	EXE_FILES         => ['tdwtf'],
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/Class::Accessor::Fast 0
		   HTML::FormatText      0
		   JSON::MaybeXS         0/,
	},
	@tr,
	META_ADD         => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=webservice-tdwtf.git',
		},
	}
);
