Newsgroups: comp.lang.perl.tk
Path: lnsnews.lns.cornell.edu!newsstand.cit.cornell.edu!news.kei.com!uhog.mit.edu!news.mathworks.com!gatech!newsfeed.internetmci.com!in2.uu.net!bcstec!bcstec.ca.boeing.com!corbin
From: corbin@nemo.fteil.ca.boeing.com (Ali Corbin)
Subject: Re: Getting bindings for a class
Message-ID: <CORBIN.96Jan26102149@nemo.fteil.ca.boeing.com>
Sender: nntp@bcstec.ca.boeing.com (NNTP News Access)
Organization: The Boeing Company
References: <4e8nlk$gq3@monk.mps.ohio-state.edu>
Date: Fri, 26 Jan 1996 18:21:49 GMT
Lines: 63

In article <4e8nlk$gq3@monk.mps.ohio-state.edu> ilya@math.ohio-state.edu (Ilya Zakharevich) writes:

   Xref: bcstec comp.lang.perl.tk:878
   Path: bcstec!uunet!in2.uu.net!newsfeed.internetmci.com!news.msfc.nasa.gov!news.larc.nasa.gov!lerc.nasa.gov!magnus.acs.ohio-state.edu!math.ohio-state.edu!not-for-mail
   From: ilya@math.ohio-state.edu (Ilya Zakharevich)
   Newsgroups: comp.lang.perl.tk
   Date: 25 Jan 1996 15:03:00 -0500
   Organization: Department of Mathematics, The Ohio State University
   Lines: 16
   NNTP-Posting-Host: monk.mps.ohio-state.edu


   I cannot find a way to find bindings for Text widget (I'm debugging
   Home key not working on Sun 5 keyboard).

   I tried:

	 DB<3> x Tk::Text->bind
   Can't locate object method "bind" via package "Tk::Text" at (eval 163) line 2.
	 DB<7> x $top->bind('Tk::Text')
   empty array
	 DB<8> x $top->bind('Tk::Text', "<Home>")
   empty array
	 DB<9> x $top->bind('Tk::Text', "<Delete>")
   empty array

   Ilya


I used the following script to figure out how all of the keys were defined:

===========================================================================

#!/usr/local/bin/perl -w

use Tk;

$top = MainWindow->new();

$frame = $top->Frame( -height => '6c', -width => '6c',
                        -background => 'black', -cursor => 'gobbler' );
$frame->pack;

$top->bind( '<Any-KeyPress>' => sub
{
    my($c) = @_;
    my $e = $c->XEvent;
    my( $x, $y, $W, $K, $A ) = ( $e->x, $e->y, $e->K, $e->W, $e->A );

    print "A key was pressed:\n";
    print "  x = $x\n";
    print "  y = $y\n";
    print "  W = $K\n";
    print "  K = $W\n";
    print "  A = $A\n";
} );

MainLoop();

============================================================================

Ali Corbin
corbin@adsw.fteil.ca.boeing.com
