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
	NAME		=> 'Test::Most::Explain',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/Test/Most/Explain.pm',
	ABSTRACT_FROM	=> 'lib/Test/Most/Explain.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	PL_FILES	=> {},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, TEST_REQUIRES => {
		'Test::Compile' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Returns' => 0,
		'Test::Strict' => 0,
		'Test::Vars' => 0,
		'Test::Warnings' => 0,
	}, PREREQ_PM => {
		'autodie' => 0,
		'strict' => 0,
		'warnings' => 0,
		'Carp' => 0,
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, dist => $dist,
	clean		=> { FILES => 'Test::Most::Explain-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Test/Most/Explain',
			repository => {
				repository => 'https://github.com/nigelhorne/Test::Most::Explain',
				type => 'git',
				url => 'git://github.com/nigelhorne/Test::Most::Explain.git',
				web => 'https://github.com/nigelhorne/Test::Most::Explain',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Test::Most::Explain',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Test::Most::Explain',
				# web => 'https://github.com/nigelhorne/Test::Most::Explain/issues',
				# url => 'https://github.com/nigelhorne/Test::Most::Explain/issues',
				mailto => 'bug-Test::Most::Explain@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
