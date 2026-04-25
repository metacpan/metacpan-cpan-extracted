use strict;
use warnings;

use ExtUtils::MakeMaker;
my %conf = (
	NAME          => "Test::IsAny",
	AUTHOR        => 'Gabor Szabo <szabgab@cpan.org>',
	VERSION_FROM  => 'lib/Test/IsAny.pm',
	ABSTRACT_FROM => 'lib/Test/IsAny.pm',
	EXE_FILES     => [],
	PREREQ_PM     => {
		'Test::Builder'   => 1.001,
		'Carp'            => 0,
		'Data::Dumper'    => 0,
		'Exporter'        => 0,
		'List::MoreUtils' => 0,
	},
);

if ( eval { ExtUtils::MakeMaker->VERSION(6.3002) } ) {
	$conf{LICENSE} = 'perl';
}

if ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ) {
	$conf{META_MERGE} = {
		'meta-spec' => { version => 2 },
		resources   => {
			repository => {
				type    => 'git',
				url     => 'https://github.com/szabgab/Test-IsAny.git',
				web     => 'https://github.com/szabgab/Test-IsAny',
				license => 'https://dev.perl.org/licenses/',
			},
			bugtracker => {
				web => 'https://github.com/szabgab/Test-IsAny',
			},
		},
		x_contributors => [ 'Gabor Szabo <szabgab@cpan.org>', ],
	};
}

my %configure_requires = ( 'ExtUtils::MakeMaker' => '6.64', );
my %build_requires     = (
	'Test::Code::TidyAll' => 0,
	'Test::Perl::Critic'  => 0,
);
my %test_requires = ( 'Test::More' => '1.00', );

###   merging data "standard code"
if ( eval { ExtUtils::MakeMaker->VERSION(6.52) } ) {
	$conf{CONFIGURE_REQUIRES} = \%configure_requires;
}
else {
	%{ $conf{PREREQ_PM} } = ( %{ $conf{PREREQ_PM} }, %configure_requires );
}

if ( eval { ExtUtils::MakeMaker->VERSION(6.5503) } ) {
	$conf{BUILD_REQUIRES} = \%build_requires;
}
else {
	%{ $conf{PREREQ_PM} } = ( %{ $conf{PREREQ_PM} }, %build_requires );
}
if ( eval { ExtUtils::MakeMaker->VERSION(6.64) } ) {
	$conf{TEST_REQUIRES} = \%test_requires;
}
else {
	%{ $conf{PREREQ_PM} } = ( %{ $conf{PREREQ_PM} }, %test_requires );
}

WriteMakefile(%conf);

