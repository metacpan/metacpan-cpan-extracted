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
	NAME => 'Test::Which',
	VERSION_FROM => 'lib/Test/Which.pm',
	ABSTRACT_FROM => 'lib/Test/Which.pm',
	AUTHOR => 'Nigel Horne <njh@nigelhorne.com>',
	LICENSE => 'GPL',
	MIN_PERL_VERSION => '5.008',
	PREREQ_PM => {
		'File::Which' => 0,
	},
	TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
	}, dist => $dist,
	clean	 => { FILES => 'Test-Which-*' },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Test::Which',
			repository => {
				repository => 'https://github.com/nigelhorne/Test-Which',
				type => 'git',
				url => 'git://github.com/nigelhorne/Test-Which.git',
				web => 'https://github.com/nigelhorne/Test-Which',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-Test-Which@rt.cpan.org',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Which',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Which',
				# url => 'https://github.com/nigelhorne/Test-Which',
				# web => 'https://github.com/nigelhorne/Test-Which'
			}
		},
	},
);
