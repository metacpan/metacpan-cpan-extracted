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
	NAME		 => 'Text::Names::Canonicalize',
	ABSTRACT_FROM => 'lib/Text/Names/Canonicalize.pm',
	VERSION_FROM => 'lib/Text/Names/Canonicalize.pm',
	AUTHOR	   => 'Nigel Horne (njh@nigelhorne.com)',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	PREREQ_PM	=> {
		'Exporter' => 0,
		'JSON::MaybeXS' => 0,
		'Scalar::Util' => 0,
		'YAML::XS' => 0,
	}, CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'Text-Names-Canonicalize-*' },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Text::Names::Canonicalize',
			repository => {
				repository => 'https://github.com/nigelhorne/Text-Names-Canonicalize',
				type => 'git',
				url => 'git://github.com/nigelhorne/Text-Names-Canonicalize.git',
				web => 'https://github.com/nigelhorne/Text-Names-Canonicalize',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Names-Canonicalize',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Names-Canonicalize',
				# web => 'https://github.com/nigelhorne/Text-Names-Canonicalize/issues',
				# url => 'https://github.com/nigelhorne/Text-Names-Canonicalize/issues',
				mailto => 'bug-Text-Names-Canonicalize@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
