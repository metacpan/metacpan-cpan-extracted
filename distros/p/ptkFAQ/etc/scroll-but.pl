#!/usr/local/bin/perl -w
########## compare to: #########################################
## !/usr/local/bin/wish -f
## This demonstrates how to create a scrollable canvas with multiple
## buttons. 
## (Tcl/Tk version)
## Author : Michael Moore  <mdm@stegosaur.cis.ohio-state.edu> 
## Date   : November 17, 1992
## @: http://www.cis.ohio-state.edu/hypertext/faq/usenet/tcl-faq/tk/part1/faq-doc-56.html
################################################################
#  Perl/Tk: Peter Prymmer <pvhp@lns62.lns.cornell.edu> 4 December 1995
# 

use strict;
use Tk;

#
# This procedure obtains all the items with the tag "active"
# and prints out their ids.
#
sub multi_action { my($canvas) = shift;
    my(@list) = $canvas -> find( 'withtag' => "active");
    print "Active Item Ids : \n";
    print join("\n",@list),"\n" if (@list);
}

# 
# This simulates the toggling of a command button...
# Note that it only works on a color display as is right now
# but the principle is the same for b&w screens.
# 
sub multi_activate { my ($num, $id, $canvas) = @_;
    my (@tags) = $canvas -> gettags($id);
    if (grep(/active/,@tags)) {
        $canvas -> dtag( $id => "active");
        $num -> configure( 
                     -background => '#060', 
                     -activebackground => '#080'); 
    } else {
        $canvas-> addtag ("active", 'withtag', $id);
        $num -> configure(
                     -background => '#600', 
                     -activebackground => '#800');
    }
} 

sub setup {
     my ($m) = MainWindow->new;
     my ($frame) = $m->Frame;

     my ($scroll) = $frame->Scrollbar(
         -relief => 'raised');

     my ($canvas) = $frame->Canvas(
         -yscrollcommand => ['set', $scroll],
         -scrollregion => [0, 0, 0, 650], 
         -relief => 'raised' ); 

     $scroll -> configure( -command => ['yview', $canvas]);

     $scroll->pack(-side => 'left', -anchor => 'center', -fill => 'y');
     $canvas->pack(-side => 'left', -anchor => 'center', -fill => 'both');
     $frame->pack(-side => 'left', -anchor => 'center', -fill => 'both');

     my ($action) = $canvas->Button(
         -relief => 'raised',
         -text => "Action", 
         -command => [\&multi_action, $canvas]);
     $canvas ->create(("window", 1, 25) , 
         -anchor => 'w',
         -window => $action);

     my ($i,$j,$id);
     for ($j = 2; $j < 26; $j++) {
         $i = $canvas->Button(
            -relief => 'raised',
            -background => '#060', 
            -foreground => 'wheat',
            -activebackground => '#080',
            -activeforeground => 'wheat',
            -text => "Button $j"); 
         $id = $canvas ->create( ('window', 1, $j*25),
            -anchor => 'w', 
            -window => $i);
         $i -> configure(
            -command => [\&multi_activate, $i, $id, $canvas] );
     }
}

&setup;
MainLoop;
