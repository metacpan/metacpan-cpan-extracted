use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $release = '0.02';
my %MF = (
	NAME             => 'WebService::AbuseIPDB',
	AUTHOR           => 'Pete Houston <cpan@openstrike.co.uk>',
	VERSION_FROM     => 'lib/WebService/AbuseIPDB.pm',
	ABSTRACT_FROM    => 'lib/WebService/AbuseIPDB.pm',
	LICENSE          => 'gpl_2',
	PL_FILES         => {},
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources   => {
			bugtracker => {
				web => 'http://rt.cpan.org/Public/Dist/Display.html?Name=WebService-AbuseIPDB'
			},
			repository => {
				type => 'git',
				url  => 'git://gitlab.com/openstrike/abuseipdb-client.git',
				web  => 'https://gitlab.com/openstrike/abuseipdb-client',
			},
		},
		provides => {
			'WebService::AbuseIPDB' => {
				file    => 'lib/WebService/AbuseIPDB.pm',
				version => $release
			},
			'WebService::AbuseIPDB::Category' => {
				file    => 'lib/WebService/AbuseIPDB/Category.pm',
				version => $release
			},
			'WebService::AbuseIPDB::Response' => {
				file    => 'lib/WebService/AbuseIPDB/Response.pm',
				version => $release
			},
			'WebService::AbuseIPDB::CheckResponse' => {
				file    => 'lib/WebService/AbuseIPDB/CheckResponse.pm',
				version => $release
			},
			'WebService::AbuseIPDB::ReportResponse' => {
				file    => 'lib/WebService/AbuseIPDB/ReportResponse.pm',
				version => $release
			},
		},
	},
	MIN_PERL_VERSION => '5.010',
	CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => '0'},
	TEST_REQUIRES    => {
		'Test::More'       => '0.41',
		'Test::Fatal'      => '0',
		'Test::MockModule' => '0.14',
	},
	PREREQ_PM => {
		'IO::Socket::SSL'      => '1.31',
		'REST::Client'         => '272',
		'Carp'                 => '1.11',
		'JSON::XS'             => '2.34',
		'LWP::Protocol::https' => '6.04',
		'Scalar::Util'         => '1.14',
		'URI'                  => '1.60'
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'WebService-AbuseIPDB-*' },
);

# Extra tests
if ($ENV{RELEASE_TESTING}   ||
	$ENV{AUTOMATED_TESTING} ||
	$ENV{AUTHOR_TESTING}) {
	$MF{test} = { TESTS => 't/*.t xt/*.t' };
}

# Remove entries from the hash where version of ExtUtils::MakeMaker is
# too old to support them
if ($ExtUtils::MakeMaker::VERSION lt 6.63_03) {
	my $req = $ExtUtils::MakeMaker::VERSION lt 6.55 ?
		'PREREQ_PM' : 'BUILD_REQUIRES';
	# Move test prereqs into appropriate target
	for my $key (keys %{$MF{TEST_REQUIRES}}) {
		$MF{$req}{$key} = $MF{TEST_REQUIRES}{$key};
	}
	delete $MF{TEST_REQUIRES};
}
if ($ExtUtils::MakeMaker::VERSION lt 6.48) { delete $MF{MIN_PERL_VERSION}; }
if ($ExtUtils::MakeMaker::VERSION lt 6.46) { delete $MF{META_MERGE};       }
if ($ExtUtils::MakeMaker::VERSION lt 6.31) { delete $MF{LICENSE};          }

WriteMakefile (%MF);

unless (exists $ENV{AIPDB_KEY}) {
	print <<EOT;

It is highly recommended that you set the environment variable
AIPDB_KEY to be your v2 key for the API prior to running "make
test". Doing so allows the full suite of tests to be run. See
https://www.abuseipdb.com/account/api for details of the API and to
obtain a key if you do not yet have one.

Note that the full test suite currently creates a report for a private
IP. There is no way to undo this in the API, so please remove it via
the web interface at https://www.abuseipdb.com/account/reports when you
are done.

EOT
}

