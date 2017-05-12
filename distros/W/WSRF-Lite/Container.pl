#! /usr/bin/env perl  
#
#
# COPYRIGHT UNIVERSITY OF MANCHESTER, 2003
#
# Author: Mark Mc Keown
# mark.mckeown@man.ac.uk
#
# LICENCE TERMS
#
# WSRF::Lite is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
#
# forking Container script - this script forks a new process to
# handle each new client connection. Based on HTTP server example
# from Perl Cookbook - changes where need to deal with SIGNAL
# issues in Perl 5.8

use HTTP::Daemon;
use Sys::Hostname::Long;
use WSRF::Lite;
use POSIX ":sys_wait_h";
use strict;

my $TIMEOUT = "120";

$ENV{'TZ'}   = "GMT";
$ENV{'PATH'} = "";

#Check that the path to the service Modules is set
if ( !defined( $ENV{'WSRF_MODULES'} ) ) {
	die "Enviromental Variable WSRF_MODULES not defined";
}

my @nsconfig = do $ENV{'WSRF_MODULES'} . "/modnscfg.pl";
for (@nsconfig) {
	my $ns     = $_->{'namespace'};
	my $module = $_->{'module'};
	$WSRF::Constants::ModuleNamespaceMap{$ns} = $module;
}

print "Mapping of namespaces to modules:\n";
foreach my $ns ( keys %WSRF::Constants::ModuleNamespaceMap ) {
	print "  NS: " . $ns
	  . " => Module: "
	  . $WSRF::Constants::ModuleNamespaceMap{$ns} . "\n";
}

if ( defined( $ENV{'WSRF_SOCKETS'} ) ) {
	$WSRF::Constants::SOCKETS_DIRECTORY = $ENV{'WSRF_SOCKETS'};
}

if ( defined( $ENV{'WSRF_DATA'} ) ) {
	$WSRF::Constants::Data = $ENV{'WSRF_DATA'};
} else {
	$WSRF::Constants::Data = $WSRF::Constants::SOCKETS_DIRECTORY . "/data/";
}

#check the user has set up the directories for holding
#the sockets and state files.
if ( !-d $WSRF::Constants::SOCKETS_DIRECTORY ) {
	die "Directory $WSRF::Constants::SOCKETS_DIRECTORY does not exist\n";
}
if ( !-d $WSRF::Constants::Data ) {
	die "Directory $WSRF::Constants::Data does not exist\n";
}

my $port = 50000;

my ( $hostname, $daemon );
while ( my $arg = shift @ARGV ) {
	if ( $arg =~ m/-p/o ) {
		$port = shift @ARGV;    
		die "No Port number provided with -p option\n" unless defined $port;
		die "\"$port\" does not look like a port number\n"
		  unless ( $port =~ /\d+/o );
	} elsif ( $arg =~ m/-h/o ) {
		$hostname = shift @ARGV;
		die "No hostname provided with -h option\n" unless defined $hostname;
	} elsif ( $arg =~ m/-d/o ) {
		$daemon = 1;
	}
}

# REAPER kills of stray children.
sub REAPER {
	local $!;
	waitpid( -1, 0 );
	$SIG{CHLD} = \&REAPER;    # still loathe sysV
}

# set thes signal handler to deal with dead children
$SIG{CHLD} = \&REAPER;

sub HUPPER {
	local $SIG{HUP} = 'IGNORE';
	kill( 1, -$$ );
	exit;
}

$SIG{HUP} = \&HUPPER;

sub become_daemon {
	my $child = fork;
	die "Can't fork: $!" unless defined($child);
	exit(0) if $child;    # parent dies;
	POSIX::setsid();      # become session leader
	open( STDIN,  "</dev/null" );
	open( STDOUT, ">/dev/null" );
	open( STDERR, '>&STDOUT' );
	chdir '/';            # change working directory
	$ENV{PATH} = '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin';
	delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };
}

if ( defined($daemon) ) {
	print STDOUT "Running as daemon process\n";
	become_daemon();
}

#create the Service Container - just a Web Server
my $d = HTTP::Daemon->new(
						   LocalPort => $port,
						   Listen    => SOMAXCONN,
						   Reuse     => 1
  )
  || die "ERROR $!\n";

#Store the Container Address in the ENV variables - child
#processes can then pick it up and use it
$hostname = Sys::Hostname::Long::hostname_long() unless defined $hostname;
$hostname = "localhost" unless defined $hostname;
$ENV{'URL'} = "http://" . $hostname . ":" . $port . "/";

#Override the above if you do not like the URL
# $d->url has given you
#   $ENV{'URL'} = "http://localhost:50000/";

print "\nContainer Contact Address: " . $ENV{'URL'} . "\n";

# HTTP::Daemon ISA IO::Socket::INET so treat like a socket
# Thanks to Jonathan Chin for $!{EINTR}
while ( my $client = $d->accept || $!{EINTR} ) {
	next if $!{EINTR};    # just a child exiting, go back to sleep.
	print "$$ Got Connection\n";
	if ( my $pid = fork ) {    #fork a process to deal with request
		print "$$ Parent forked\n";    #parent should go back to accept now
		print "$$ Closing socket\n";
		$client->close;
		undef $client;
		print "$$ Going back to accept\n";
	} elsif ( defined($pid) )    #child
	{
		print "$$ Child created " . scalar( localtime(time) ) . "\n";
		print "$$ Closing server socket " . $d->close . " $?\n";
		undef($d);

		#clients may want to keep the HTTP connection open
		#however we put in a timeout
		while ( my $r = $client->get_request ) {
			my $crap     = alarm 0;
			my $response =
			  WSRF::Container::handle( $r, $client );    #handle request
			my $err = $client->send_response($response);
			print "$$ Sent response $err\n";
			alarm($TIMEOUT);
		}
		print "$$ Child closing socket\n";
		$client->close;
		undef($client);
		print "$$ Exiting\n";
		exit;
	} else {    #fork failed
		print "$$ Fork failed\n";
	}
}

