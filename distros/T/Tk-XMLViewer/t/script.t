#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: script.t,v 1.4 2008/12/04 18:43:17 eserte Exp $
# Author: Slaven Rezic
#

use strict;
use File::Spec;
use FindBin;

BEGIN {
    if (!eval q{
	use Test::More;
	use POSIX ":sys_wait_h";
	1;
    }) {
	print "1..0 # skip: no Test::More module\n";
	exit;
    }
    if ($ENV{BATCH} || $^O eq 'MSWin32') {
	print "1..0 # skip: not on Windows or in BATCH mode\n";
	exit;
    }
}

my $DEBUG = 0;
my $script = 'blib/script/tkxmlview';

use Getopt::Long;
GetOptions("d" => \$DEBUG)
    or die "usage: $0 [-d]";

my @opt = ([],
	   ['-indent', 8],
	   ['-mainbg', 'blue'],
	   ['-loaddtd'],
	   ['-showxpath'],
	  );

{
    use Tk;
    my $top = eval { new MainWindow };
    if (!$top) {
	plan skip_all => $@;
	exit;
    }
    $top->destroy;
}

plan tests => scalar @opt;

OPT:
for my $opt (@opt) {
    push @$opt, "$FindBin::RealBin/test.xml";
    my $pid = fork;
    if ($pid == 0) {
	my @cmd = ($^X, "-Mblib", $script, "-geometry", "+10+10", @$opt);
	warn "@cmd\n" if $DEBUG;
	open(STDERR, ">" . File::Spec->devnull);
	exec @cmd;
	die $!;
    }
    if ($DEBUG) {
	sleep 2;
    }
    for (1..10) {
	select(undef,undef,undef,0.1);
	my $kid = waitpid($pid, WNOHANG);
	if ($kid) {
	    is($?, 0, "Trying tkxmlview with @$opt");
	    next OPT;
	}
    }
    kill TERM => $pid;
    for (1..10) {
	select(undef,undef,undef,0.1);
	if (!kill 0 => $pid) {
	    pass("Trying tkxmlview with @$opt");
	    next OPT;
	}
    }
    kill KILL => $pid;
    pass("Trying tkxmlview with @$opt");
}

__END__
