#!/usr/bin/perl

use strict;
use warnings;

use POSIX;
use LWP::UserAgent;
use Time::HiRes qw/sleep/;
use Data::Dumper;
use Test::More;
use t::dance;
use Test::Lithium;

my $DANCER_PORT  = 16211;
my $PHANTOM_PORT =  8910;
my $phantom = "/usr/bin/phantomjs";
my $phantom_args = "--webdriver=$PHANTOM_PORT --webdriver-loglevel='INFO' --ignore-ssl-errors=yes >/dev/null 2>&1";
my %WEBDRIVER_CONFIG = (
	site     => undef,
	browser  => undef,
	host     => undef,
	port     => undef,
);

my $MASTER = $$;

END {
	&stop_depends if $$ == $MASTER;
}

# Set up default webdriver configuration
$ENV{BROWSER} ||= "phantomjs";
if ($ENV{BROWSER} eq "phantomjs") {
	note "Using phantomjs for testing";
	plan skip_all => 'Install phantomjs' unless -x '/usr/bin/phantomjs';
	$WEBDRIVER_CONFIG{browser} = "phantomjs";
	$WEBDRIVER_CONFIG{host}    = "localhost";
	$WEBDRIVER_CONFIG{port}    = 8910;
} elsif ($ENV{BROWSER} eq "webdriverrc") {
	note "Using ~/.webdriverrc to determine testing";
	# Revert setting overrides to pull in defaults
	delete $ENV{BROWSER};
	$WEBDRIVER_CONFIG{$_} = undef for grep { ! /^site$/ } keys %WEBDRIVER_CONFIG;
} else {
	note "Using $ENV{BROWSER} for testing";
	$WEBDRIVER_CONFIG{host}     = "ae01.buf.synacor.com";
	$WEBDRIVER_CONFIG{port}     = 4451;
	$WEBDRIVER_CONFIG{browser}  = $ENV{BROWSER};
	$WEBDRIVER_CONFIG{platform} = "MAC";
}

my $T = Test::Builder->new;
my %PIDS;

sub sel_conf
{
	my (%overrides) = @_;
	$WEBDRIVER_CONFIG{$_} = $overrides{$_} for keys %overrides;
	return %WEBDRIVER_CONFIG;
}

sub is_phantom
{
	my $driver = webdriver_driver;
	return ($driver->{browser} eq "phantomjs")
		if $driver;
	return ($ENV{BROWSER} eq "phantomjs") if $ENV{BROWSER};
	return undef;
}

sub start_depends
{
	set_port($DANCER_PORT);
	my $target = &test_site;

	# Fire up Dancer
	$PIDS{dancer} = fork;
	die "Failed to fork Dancer app: $!\n" if $PIDS{dancer} < 0;
	if ($PIDS{dancer}) {
		# pause until we can connect to ourselves
		my $ua = LWP::UserAgent->new();
		my $up = 0;
		for (1 .. 30) {
			my $res = $ua->get($target);
			$up = $res->is_success; last if $up;
			sleep 1;
		}
		$T->ok($up, "Dancer is up and running at $target")
			or BAIL_OUT "Test website could not be started from Dancer";

		# Fire up Phantom
		if ($ENV{BROWSER} eq "phantomjs") {
			$PIDS{phantom} = fork;
			die "Failed to fork phantomjs: $!\n" if $PIDS{phantom} < 0;
			if ($PIDS{phantom}) {
				# pause until we can connect to webdriver
				my $ua = LWP::UserAgent->new();
				my $up = 0;
				for (1 .. 30) {
					my $res = $ua->get("http://127.0.0.1:$PHANTOM_PORT/sessions");
					$up = $res->is_success; last if $up;
					sleep 1;
				}
				$T->ok($up, "PhantomJS is up and running at http://127.0.0.1:$PHANTOM_PORT")
					or BAIL_OUT "PhantomJS could not start properly, giving up";
			} else {
				# Close stdout/stderr from phantom
				close STDOUT;
				close STDERR;
				exec $phantom, split(/ /, $phantom_args);
				exit 1;
			}
		}
		return $target;
	} else {
		close STDERR;
		start_dancing;
		exit 1;
	}
	return;
}

sub killproc
{
	my ($pid) = @_;
	kill "TERM", $pid;
	return 0 if waitpid($pid, POSIX::WNOHANG);
	sleep 1;

	return 0 if waitpid($pid, POSIX::WNOHANG);
	sleep 1;

	# Commented out because somehow this kills jenkins
	#kill "KILL", $pid;
	return 0;
}

sub stop_depends
{
	stop_webdriver;
	for (keys %PIDS) {
		killproc $PIDS{$_};
		delete $PIDS{$_};
	}
}

sub dancer_port
{
	my $port = shift;
	$DANCER_PORT = $port if defined $port;
	$DANCER_PORT;
}

sub test_site
{
	my $hostname = `hostname`;
	chomp $hostname;
	return "http://$hostname:$DANCER_PORT/";
}

=head1 NAME

t::common

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 start_depends

=head2 stop_depends

=head2 spawn

=head2 reap

=head1 AUTHOR

Written by Dan Molik <dmolik@synacor.com>

=cut

1;
