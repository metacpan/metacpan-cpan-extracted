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
	NAME => 'Test::NoShadow',
	VERSION_FROM => 'lib/Test/NoShadow.pm',
	ABSTRACT_FROM => 'lib/Test/NoShadow.pm',
	AUTHOR => 'Nigel Horne <njh@nigelhorne.com>',
	LICENSE => 'gpl_2',
	MIN_PERL_VERSION => '5.008',
	PREREQ_PM => {
		'Cwd' => 0,
		'File::Find' => 0,
		'File::Spec' => 0,
		'Test::Builder' => 0,
	},
	TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Tester' => 0,
	}, dist => $dist,
	clean	 => { FILES => 'Test-NoShadow-*' },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Test::NoShadow',
			repository => {
				repository => 'https://github.com/nigelhorne/Test-NoShadow',
				type => 'git',
				url => 'git://github.com/nigelhorne/Test-NoShadow.git',
				web => 'https://github.com/nigelhorne/Test-NoShadow',
			}, bugtracker => {
				mailto => 'bug-Test-NoShadow@rt.cpan.org',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Test-NoShadow',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Test-NoShadow',
			}
		},
	},
);
