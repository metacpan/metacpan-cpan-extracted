# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
use warnings FATAL => qw(all);
# `make test'. After `make install' it should work as `perl test.pl'

# Tk::Multi test

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tk ;
use ExtUtils::testlib;
use Tk::Multi::Text;
require Tk::ErrorDialog; 
$loaded = 1;
my $idx = 1;
print "ok ",$idx++,"\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict ;

my $trace = shift || 0 ;

my $mw = MainWindow-> new ;

my $w_menu = $mw->Frame(-relief => 'raised', -borderwidth => 2);
$w_menu->pack(-fill => 'x');

my $f = $w_menu->Menubutton(-text => 'File', -underline => 0) 
  -> pack(-side => 'left' );
$f->command(-label => 'Quit',  -command => sub{$mw->destroy;} );

my $lm = $w_menu->Menubutton(-text => 'list menu', -underline => 0) 
  -> pack(-side => 'left' );
print "Creating sub window list\n" if $trace ;
my $list = $mw -> MultiText( title => 'list',
                             'menu_button' => $lm->menu ,
                             'borderwidth' => 5,
                             'relief' => 'raised',
                            # height => '15', 
                             data => [1 .. 20] 
                           ) -> packAdjust(qw/-fill both -expand 1/);
                           #) -> pack(qw/-fill both -expand 1/);

# This is a nasty trick, but DoWhenIdle does not work ...
$list->after(500,sub{$list->packPropagate(0);}) ;

$list->command(-label => 'add dummy text',  
               -command => sub{$list->insertText("added dummy\n");} );

print "ok ",$idx++,"\n";

print "Creating sub window debug\n" if $trace ;
my $dm = $w_menu->Menubutton(-text => 'debug menu', -underline => 0) 
  -> pack(-side => 'left' );
my $debug = $mw -> MultiText( 
                             'relief' => 'sunken' ,
                             'menu_button' => $dm->menu ,
                             'borderwidth' => 3,
                             title => 'sunken debug'
                            ) -> pack(qw/-fill both -expand 1/);
#$debug->packPropagate(0);

print "ok ",$idx++,"\n";

print "print Line try\n"  if $trace ;
$list -> insertText("Salut les copains\n");

print "ok ",$idx++,"\n";
MainLoop ; # Tk's

print "ok ",$idx++,"\n";
