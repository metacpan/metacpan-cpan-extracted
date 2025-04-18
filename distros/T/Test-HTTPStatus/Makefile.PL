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
	NAME		 => 'Test::HTTPStatus',
	VERSION_FROM => 'lib/Test/HTTPStatus.pm', # Automatically extracts $VERSION
	ABSTRACT	 => 'Test HTTP status codes of URLs',
	AUTHOR	 => 'brian d foy <bdfoy@cpan.org>, Nigel Horne <njh@bandsman.co.uk>',
	LICENSE	=> 'artistic_2',
	PL_FILES	=> {}, CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64	# Minimum version for TEST_REQUIRES
	}, PREREQ_PM	=> {				 # Required dependencies
		# 'HTTP::SimpleLinkChecker' => 0,	# Specify minimum version if needed
		'Mojo::URL'			=> 0,
		'Mojo::UserAgent' => 0,
		'Test::Builder::Module' => 0,
		'Carp'			 => 0,
		'warnings'			 => 0,
	},
	TEST_REQUIRES => {					# Dependencies needed for testing
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::RequiresInternet' => 0
	},
	META_MERGE	=> {					# Additional metadata
		resources => {
			homepage => 'https://metacpan.org/release/Test-HTTPStatus',
			bugtracker => 'https://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-HTTPStatus',
			repository => 'https://github.com/nigelhorne/Test-HTTPStatus', # Update as necessary
		},
	},
	EXE_FILES	=> [],		 # Executable scripts (if any)
	MIN_PERL_VERSION => '5.10.1',	 # Minimum Perl version
	clean	=> { FILES => 'Test-HTTPStatus-*' }, # Files to clean
	dist => $dist
);
