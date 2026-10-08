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
	NAME => 'Test::Log::Abstraction',
	VERSION_FROM => 'lib/Test/Log/Abstraction.pm',
	ABSTRACT_FROM => 'lib/Test/Log/Abstraction.pm',
	AUTHOR => 'Nigel Horne <njh@nigelhorne.com>',
	LICENSE => 'GPL',
	MIN_PERL_VERSION => '5.008',
	PREREQ_PM => {
		'Carp' => 0,
		'Scalar::Util' => 0,
		'Test::Builder' => 0,
		'warnings' => 0,
		'strict' => 0,
	},
	TEST_REQUIRES => {
		'Test::Most' => 0,
		'Test::Warnings' => 0,
	}, dist => $dist,
	clean	 => { FILES => 'Test-Log-Abstraction-*' },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Test::Log::Abstraction',
			repository => {
				repository => 'https://github.com/nigelhorne/Test-Log-Abstraction',
				type => 'git',
				url => 'git://github.com/nigelhorne/Test-Log-Abstraction.git',
				web => 'https://github.com/nigelhorne/Test-Log-Abstraction',
			}, bugtracker => {
				mailto => 'bug-Test-Log-Abstraction@rt.cpan.org',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Log-Abstraction',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Log-Abstraction',
			}
		},
	},
);
