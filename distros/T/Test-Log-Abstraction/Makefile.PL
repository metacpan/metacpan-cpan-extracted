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
	MIN_PERL_VERSION => '5.026',	# Params::Validate::Strict needs 5.26
	PREREQ_PM => {
		'autodie' => 0,
		'Carp' => 0,
		'Encode' => 0,
		'Hash::Util' => 0,
		'List::Util' => 1.33,	# any()
		'IPC::System::Simple' => 0,	# autodie qw(:all)
		'Params::Get' => 0.17,
		'Params::Validate::Strict' => 0.41,	# union types
		'Readonly' => 0,
		'Readonly::Values::Syslog' => 0.04,	# %SYSLOG_LEVELS
		'Scalar::Util' => 0,
		'Test::Builder' => 0,
		'strict' => 0,
		'version' => 0,
		'warnings' => 0,
	}, TEST_REQUIRES => {
		'B' => 0,
		'Cwd' => 0,
		'Errno' => 0,
		'Exporter' => 0,
		'File::Temp' => 0,
		'Log::Abstraction' => 0.41,
		'JSON::PP' => 0,
		'Test::Builder::Tester' => 0,
		'Test::Memory::Cycle' => 0,
		'Test::Permissions' => 0,
		'Test::Without::Module' => 0,
		'Time::HiRes' => 0,
		'Test::Mockingbird' => 0.14,
		'Test::Most' => 0,
		'Test::Returns' => 0.04,
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
