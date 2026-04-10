use strict;
use warnings;
use ExtUtils::MakeMaker;
use Getopt::Long;	# Technique inspired by IO::Lambda
use IO::Socket::INET;

my $online_tests;

# Test for broken smokers that don't set AUTOMATED_TESTING
if(my $reporter = $ENV{'PERL_CPAN_REPORTER_CONFIG'}) {
	if($reporter =~ /smoker/i) {
		warn 'AUTOMATED_TESTING added for you';
		$ENV{'AUTOMATED_TESTING'} = 1;
	}
}

if($ENV{AUTHOR_TESTING}) {
	$online_tests = are_online();
} else {
	Getopt::Long::GetOptions('online-tests!' => \$online_tests);

	if(!defined($online_tests)) {
		$online_tests = are_online();
	}
	if(!$online_tests) {
		print "On-line tests have been disabled\n";
		$online_tests = 0;
	}
}

my $test_requires = {
	'autodie' => 0,
	'File::Glob' => 0,
	'File::stat' => 0,
	'File::Slurp' => 0,
	'Geo::Location::Point' => 0.09,
	'IPC::System::Simple' => 0,	# http://www.cpantesters.org/cpan/report/0b994acc-7a03-11e8-a944-5f7713bf8fb6
	'POSIX' => 0,
	'Readonly' => 0,
	'Test::Carp' => 0,
	'Test::Compile' => 0,
	'Test::DescribeMe' => 0,
	'Test::MockModule' => 0,
	'Test::Most' => 0,
	'Test::Needs' => 0,
	'Test::NoWarnings' => 0,
	'WWW::RT::CPAN' => 0
};

if($online_tests) {
	open(my $enabled, '>', 't/online.enabled') || die "Can't touch t/online.enabled $!";
	close($enabled) || die "Can't touch t/online.enabled $!";
	$test_requires->{'Test::LWP::UserAgent'} = 0;
	$test_requires->{'DateTime'} = 0;
	if(defined($ENV{'TIMEZONEDB_KEY'})) {
		$test_requires->{'TimeZone::TimeZoneDB'} = 0;
	}
} else {
	unlink('t/online.enabled');
}

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		=> 'Weather::Meteo',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/Weather/Meteo.pm',
	ABSTRACT_FROM	=> 'lib/Weather/Meteo.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	EXE_FILES => [ 'bin/weather' ],
	PL_FILES	=> {},
	TEST_REQUIRES => $test_requires,
	PREREQ_PM => {
		'constant' => 0,
		'CHI' => 0,
		'Encode' => 0,
		'ExtUtils::MakeMaker' => 6.64,	# 6.64 for TEST_REQUIRES
		'JSON::MaybeXS' => 0,
		'LWP::UserAgent' => 0,
		'LWP::Protocol::https' => 0,
		'Object::Configure' => 0,
		'Params::Get' => 0.13,
		'Params::Validate::Strict' => 0,
		'Return::Set' => 0,
		'Scalar::Util' => 0,
		'Time::HiRes' => 0,
		'URI' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'Weather-Meteo-*' },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Weather-Meteo.git',
				web => 'https://github.com/nigelhorne/Weather-Meteo',
				repository => 'https://github.com/nigelhorne/Weather-Meteo',
			}, bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Weather-Meteo',
				web => 'https://github.com/nigelhorne/Weather-Meteo/issues',
				url => 'https://github.com/nigelhorne/Weather-Meteo/issues',
				mailto => 'bug-Weather-Meteo@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);

sub are_online
{
	# See https://www.cpantesters.org/cpan/report/b38913a6-8e30-11ee-884e-494b6e8775
	return 0 if($ENV{'NO_NETWORK_TESTING'} || $ENV{'CIRCLECI'} || $ENV{'TRAVIS_PERL_VERSION'} || $ENV{'AUTOMATED_TESTING'} || $ENV{'NONINTERACTIVE_TESTING'} || (!-t STDIN));

	if(my $s = IO::Socket::INET->new(
		PeerAddr => 'open-meteo.com:443',
		Timeout => 10
	)) {
		if($ENV{'PERL_MM_USE_DEFAULT'}) {
			close($s);
			return 1;
		}

		print <<EOF;

You appear to be directly connected to the Internet.  I have some tests
that try to query open-meteo.com.

EOF
		close($s);

		# Timeout inspired by Mail::IMAPClient
		my $rc;
		eval {
			local $SIG{ALRM} = sub { die 'alarm' };
			alarm(60);
			$rc = prompt('Do you want to enable these tests?', 'y') =~ /^y/i ? 1 : 0;
			alarm(0);
		};
		if($@) {
			print "\n";
			return 1;	# The default is 'y'
		}
		return $rc;
	}
	print "On-line tests disabled because I couldn't detect an Internet connexion\n";
	return 0;
}
