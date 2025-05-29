use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
    NAME         => 'Text::Names::Abbreviate',
    VERSION_FROM => 'lib/Text/Names/Abbreviate.pm',
    ABSTRACT     => 'Generate abbreviated forms of personal names',
    AUTHOR       => 'Nigel Horne <njh@nigelhorne.com>',
    LICENSE      => 'GPL',
	TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'Text-Names-Abbreviate-*' },
	META_MERGE => {
		resources => {
			repository => 'https://github.com/nigelhorne/Text-Names-Abbreviate',
			bugtracker => 'https://github.com/nigelhorne/Text-Names-Abbreviate/issues',
		},
	}
);
