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
	PREREQ_PM => {
		'Carp' => 0,
		'Params::Get' => 0.13,
		'Params::Validate::Strict' => 0.13
	}, TEST_REQUIRES => {
		'autodie' => 0,
		'Class::Simple' => 0,
		'Data::Random' => 0,
		'File::Glob' => 0,
		'File::Slurp' => 0,
		'File::stat' => 0,
		'IPC::System::Simple' => 0,
		'JSON::MaybeXS' => 0,
		'POSIX' => 0,
		'Readonly' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Returns' => 0,
		'Test::Which' => 0
	}, dist => $dist,
	clean		=> { FILES => 'Text-Names-Abbreviate-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Text::Names::Abbreviate',
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Text-Name-Abbreviate.git',
				web => 'https://github.com/nigelhorne/Text-Name-Abbreviate',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Name-Abbreviate',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Name-Abbreviate',
				# web => 'https://github.com/nigelhorne/Text-Name-Abbreviate/issues',
				# url => 'https://github.com/nigelhorne/Text-Name-Abbreviate/issues',
				mailto => 'bug-Text-Name-Abbreviate@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
