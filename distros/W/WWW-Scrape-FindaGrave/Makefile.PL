#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;	# Technique inspired by IO::Lambda
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES
use IO::Socket::INET;

my $online_tests;

if($ENV{RELEASE_TESTING}) {
	$online_tests = are_online();
} elsif($ENV{AUTOMATED_TESTING} || $ENV{NO_NETWORK_TESTING}) {
	$online_tests = 0;
} else {
	Getopt::Long::GetOptions('online-tests!' => \$online_tests);

	if(!defined($online_tests)) {
		$online_tests = are_online();
	}
}

if($online_tests) {
	open(my $enabled, '>', 't/online.enabled') || die "Can't touch t/online.enabled $!";
	close($enabled) || die "Can't touch t/online.enabled $!";
} else {
	unlink('t/online.enabled');
	print STDERR "NA: WWW::Scrape::FindaGrave needs a permanent connexion to the Internet\n";
	exit(0);
}

WriteMakefile(
    NAME		=> 'WWW::Scrape::FindaGrave',
    AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM	=> 'lib/WWW/Scrape/FindaGrave.pm',
    ABSTRACT_FROM       => 'lib/WWW/Scrape/FindaGrave.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES	=> {},
    TEST_REQUIRES => {
	'Test::Most' => 0,
	'Test::NoWarnings' => 0,
	'Test::URI' => 0,
	# 'Test::Kwalitee' => 0,
    },
    PREREQ_PM => {
	'WWW::Mechanize::GZip' => 0,
	'LWP::UserAgent' => 0,
	'HTML::SimpleLinkExtor' => 0,
	'LWP::Protocol::https' => 0,
    },
    dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean		=> { FILES => 'WWW-Scrape-FindaGrave-*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/WWW-Scrape-FindaGrave.git',
			web => 'https://github.com/nigelhorne/WWW-Scrape-FindaGrave',
    		},
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);

sub are_online
{
	my $host = 'www.findagrave.com:80';

	if($ENV{'http_proxy'} && ($ENV{'http_proxy'} =~ /^.+\/\/(\w+:\d+)$/)) {
		$host = $1;
	} elsif($ENV{'HTTP_PROXY'} && ($ENV{'HTTP_PROXY'} =~ /^.+\/\/(\w+:\d+)$/)) {
		$host = $1;
	}
	my $s = IO::Socket::INET->new(
		# PeerAddr => 'www.ripe.net:43',
		# PeerAddr => 'whois.apnic.net:43',
		PeerAddr => $host,
		Timeout => 5
	);
	if($s) {
		print <<EOF;

You appear to be directly connected to the Internet.  I have some tests
that connect to www.findagrave.com.

EOF
		close($s);

		# Timeout inspired by Mail::IMAPClient
		my $rc;
		eval {
			local $SIG{ALRM} = sub { die "alarm\n" };
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
