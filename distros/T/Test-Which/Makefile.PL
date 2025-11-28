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
	MIN_PERL_VERSION => '5.014',
	PREREQ_PM => {
		'autodie' => 0,
		'Carp' => 0,
		'Config::Abstraction' => 0.36,
		'Data::Dumper' => 0,
		'Data::Section::Simple' => 0,
		'File::Spec' => 0,
		'Getopt::Long' => 0,
		'Module::Load::Conditional' => 0,
		'Params::Get' => 0.13,
		'Params::Validate::Strict' => 0.23,
		'PPI' => 0,
		'Pod::Simple' => 0,
		'Pod::Usage' => 0,
		'Return::Set' => 0.03,
		'Template' => 0,
		'YAML::XS' => 0
	},
	TEST_REQUIRES => {
		'Cwd' => 0,
		'Data::Random' => 0,
		'Data::Random::String' => 0,
		'Data::Random::String::Matches' => 0.02,
		'Data::Random::Structure' => 0,
		'Encode' => 0,
		'File::Temp' => 0,
		'IPC::Run3' => 0,
		'IPC::System::Simple' => 0,
		'JSON::MaybeXS' => 0,
		'Test::DescribeMe' => 0,
		'Test::LectroTest' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Returns' => 0.02
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
