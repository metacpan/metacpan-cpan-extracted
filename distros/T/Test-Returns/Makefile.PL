use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME	 => 'Test::Returns',
	AUTHOR	 => q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM => 'lib/Test/Returns.pm',
	ABSTRACT_FROM => 'lib/Test/Returns.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	PL_FILES => {},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
	}, PREREQ_PM => {
		'Carp' => 0,
		'Exporter' => 0,
		'Return::Set' => 0.01,
	}, dist => $dist,
	clean => { FILES => 'Test-Returns-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Test::Returns',
			repository => {
				repository => 'https://github.com/nigelhorne/Test-Returns',
				type => 'git',
				url => 'git://github.com/nigelhorne/Test-Returns.git',
				web => 'https://github.com/nigelhorne/Test-Returns',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-Test-Returns@rt.cpan.org',
				url => 'https://github.com/nigelhorne/Test-Returns/issues',
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Returns',
				web => 'https://github.com/nigelhorne/Test-Returns/issues'
			}
		},
	},
	MIN_PERL_VERSION => '5.008'
);
