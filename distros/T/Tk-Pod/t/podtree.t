#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;

use Tk;
use Tk::Pod::Tree;
use Tk::Pod::FindPods;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "# tests only work with installed Test::More module\n";
	print "1..1\n";
	print "ok 1\n";
	CORE::exit(0);
    }
}

my $mw = eval { tkinit };
if (!$mw) {
    print "1..0 # cannot create MainWindow\n";
    CORE::exit(0);
}
$mw->geometry("+1+1"); # for twm

plan tests => 5;

my $pt;
$pt = $mw->Scrolled("PodTree",
		    -scrollbars => "osow",
		    -showcommand => sub {
			warn $_[1]->{File};
		    },
		   )->grid(-sticky => "esnw");
$mw->gridColumnconfigure(0, -weight => 1);
$mw->gridRowconfigure(0, -weight => 1);

diag <<EOF;
#
# Tests may take a long time (up to 10 minutes or so) if you have a lot
# of modules installed.
EOF

ok Tk::Exists($pt), 'PodTree widget exists';
$pt->Fill;
pass 'after calling Fill method';

my $FindPods = Tk::Pod::FindPods->new;
isa_ok $FindPods, 'Tk::Pod::FindPods';
my $pods = $FindPods->pod_find(-categorized => 1, -usecache => 1);
isa_ok $pods, 'HASH';
my $path = $pods->{perl}{ (keys %{ $pods->{perl} })[0] };
$pt->SeePath($path);
pass 'after calling SeePath method';

$mw->afterIdle(sub{$mw->destroy});
MainLoop;

__END__
