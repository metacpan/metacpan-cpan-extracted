#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;

use Tk;
use Tk::Pod::Text;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip no Test::More module\n";
	CORE::exit(0);
    }
}

use Tk;
my $mw = eval { MainWindow->new };
if (!$mw) {
    print "1..0 # cannot create MainWindow\n";
    CORE::exit(0);
}
$mw->geometry("+1+1"); # for twm

plan tests => 4;

my $pt = $mw->PodText->pack;
for my $pod ('perl',       # pod in perl.pod
	     'perldoc',    # pod in script itself
	     'strict',     # sample pragma pod
	     'File::Find', # sample module pod
	    ) {
    my $podpath = Tk::Pod::Text::Find($pod);
 SKIP: {
	skip "Pod for $pod not installed", 1
	    if !defined $podpath;
	$pt->configure(-file => $pod);
	is $pt->cget(-file), $pod, "Render $pod Pod in PodText";
    }
}

#MainLoop;

__END__
