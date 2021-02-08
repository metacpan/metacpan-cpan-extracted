use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR		=> 'Ron Savage (ron@savage.net.au)',
		ABSTRACT	=> 'Provide fetchrow_hashref() for CSV files',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Text-CSV_PP-Iterator-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME  => 'Text-CSV_PP-Iterator',
	NAME      => 'Text::CSV_PP::Iterator',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Exception::Class'	=> 0,
		'Iterator'			=> 0,
		'Iterator::IO'		=> 0,
		'Test::More'		=> 0,
		'Test::Pod'			=> 0,
		'Text::CSV_PP'		=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 0,
		'Test::Pod'		=> 0,
	},
	VERSION_FROM	=> 'lib/Text/CSV_PP/Iterator.pm',
	INSTALLDIRS		=> 'site',
	EXE_FILES		=> [],
);

if ( ($ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/) && ($ExtUtils::MakeMaker::VERSION > 6.30) )
{
	$params{LICENSE} = 'perl';
}

if ($ExtUtils::MakeMaker::VERSION ge '6.46')
{
	$params{META_MERGE} =
	{
		'meta-spec' =>
		{
			version => 2,
		},
		resources   =>
		{
			bugtracker =>
			{
				web => 'https://github.com/ronsavage/Text-CSV_PP-Iterator/issues',
			},
			license		=> 'http://opensource.org/licenses/Perl',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Text-CSV_PP-Iterator.git',
				web		=> 'https://github.com/ronsavage/Text-CSV_PP-Iterator',
			},
		},
	};
}

WriteMakefile(%params);
