use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		=> 'Web::VWF',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	ABSTRACT_FROM	=> 'lib/Web/VWF.pm',
	VERSION_FROM	=> 'lib/Web/VWF.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, PREREQ_PM => {
		'Carp' => 0,
		'Carp::Always' => 0,
		'CGI::ACL' => 0.06,		# For deny_cloud
		'CGI::Carp' => 0,
		'CGI::IDS' => 0,		# Intrusion detection, used by Allow.pm and Display.pm
		'CGI::Info' => 1.14,		# 1.14 for is_ai()
		'CGI::Lingua' => 0.61,
		'CHI' => 0,
		'Class::Simple' => 0,
		'Config::Abstraction' => 0,
		'Config::Auto' => 0,		# Display/table.pm
		'Crypt::URandom' => 0,		# CSPRNG for CSRF tokens
		'Data::Dumper' => 0,
		'Data::Throttler' => 0,
		'Database::Abstraction' => 0,
		'DBD::CSV' => 0,
		'DBI' => 0,
		'Digest::MD5' => 0,
		'Digest::SHA' => 0,
		'Error' => 0,
		'FCGI' => 0,
		'FCGI::Buffer' => 0,
		'File::HomeDir' => 0,
		'File::pfopen' => 0,
		'File::Slurp' => 0,		# Display/table.pm
		'File::Spec' => 0,
		# Filesys::Df refuses to configure for MSWin32 - its own Makefile.PL says
		# "This module does not support Windows" and points at
		# Filesys::DfPortable - so it cannot be a prerequisite there.  Declaring
		# it would make `cpanm --installdeps` fail and stop Web::VWF from
		# installing at all.  Display/meta_data.pm leaves the disk figure out
		# when it is missing.
		(($^O ne 'MSWin32') ? ('Filesys::Df' => 0) : ()),
		'HTML::D3' => 0,		# Display/meta_data.pm
		'HTML::SocialMedia' => 0,
		'HTTP::Date' => 0,		# For the Last-Modified header
		'HTTP::Status' => 0,
		'JSON::MaybeXS' => 0,
		'Log::Abstraction' => 0,
		'Log::WarnDie' => 0.09,
		'LWP::UserAgent' => 0,
		'Module::Runtime' => 0,		# Safe dynamic loading; avoids string eval
		'Object::Configure' => 0,
		'Params::Get' => 0.13,
		'Params::Validate::Strict' => 0,
		'Readonly' => 0,
		'Scalar::Util' => 0,
		'String::Random' => 0,
		'Sys::MemInfo' => 0,
		'Sys::Uptime' => 0,
		'System::Info' => 0,
		'Template' => 0,		# The rendering engine behind the .tmpl files
		'Template::Filters' => 0,
		'Template::Plugin::EnvHash' => 0,
		'Template::Plugin::JSON' => 0,
		'Template::Plugin::Math' => 0,
		'Text::xSV::Slurp' => 0,
		'Time::HiRes' => 0,
		'Time::Piece' => 0,
		'Time::Seconds' => 0,
		'Timer::Simple' => 0,
		'Try::Tiny' => 0,
		'version'       => '0.77',
	}, TEST_REQUIRES => {
		'Data::Validate::URI' => 0,
		'DateTime' => 0,
		'HTTP::Response' => 0,
		'LWP::Simple::WithCache' => 0,
		'Test::Memory::Cycle' => 0,
		'Test::Mockingbird' => 0,
		'Test::Most' => 0,
		'Test::Returns' => 0,
		'XML::LibXML' => 0,	# t/function.t builds and parses test documents
		'YAML' => 0,
	}, dist => $dist,
	clean => { FILES => 'Web-VWF-*' },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		# On Windows Filesys::Df is not required, because it cannot be
		# installed there - so say what it is for instead (see PREREQ_PM).
		(($^O eq 'MSWin32')
			? (prereqs => { runtime => { recommends => { 'Filesys::Df' => 0 } } })
			: ()),
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Web-VWF.git',
				web => 'https://github.com/nigelhorne/Web-VWF',
			}, bugtracker => {
				web => 'https://github.com/nigelhorne/Web-VWF/issues',
				url => 'https://github.com/nigelhorne/Web-VWF/issues',
			}
		},
	},
	MIN_PERL_VERSION => '5.20.0',	# For `use feature qw(signatures)`
);
