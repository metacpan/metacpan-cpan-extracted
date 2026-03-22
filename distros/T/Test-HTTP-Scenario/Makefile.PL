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
	NAME		=> 'Test::HTTP::Scenario',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/Test/HTTP/Scenario.pm',
	ABSTRACT_FROM	=> 'lib/Test/HTTP/Scenario.pm',
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
		'HTTP::Server::Simple::CGI' => 0,
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
		'File::Slurper' => 0,
		'IO::Socket::INET' => 0,
		'LWP::UserAgent' => 0,
		'Scalar::Util' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'Test::HTTP::Scenario-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Test/HTTP/Scenario',
			repository => {
				repository => 'https://github.com/nigelhorne/Test::HTTP::Scenario',
				type => 'git',
				url => 'git://github.com/nigelhorne/Test::HTTP::Scenario.git',
				web => 'https://github.com/nigelhorne/Test::HTTP::Scenario',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Test::HTTP::Scenario',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Test::HTTP::Scenario',
				# web => 'https://github.com/nigelhorne/Test::HTTP::Scenario/issues',
				# url => 'https://github.com/nigelhorne/Test::HTTP::Scenario/issues',
				mailto => 'bug-Test::HTTP::Scenario@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
