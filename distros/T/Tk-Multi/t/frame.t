# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
use warnings FATAL => qw(all);
# `make test'. After `make install' it should work as `perl test.pl'

# Tk::Multi test

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tk ;
use ExtUtils::testlib;
use Tk::Multi::Manager;
use Tk::Multi::Text;
use Tk::Multi::Frame; 
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

print "creating manager\n" if $trace ;
my $wmgr = $mw -> MultiManager 
  ( 
   'title' => 'log test' ,
   'menu' => $w_menu,
   'trace' => $trace,
   'help' => undef  # special case, may happen
  ) -> pack (qw/-fill both -expand 1/);

print "ok ",$idx++,"\n";

print "Creating 10 frame sub windows \n" if $trace ;

foreach my $fidx (1 .. 10)
  {
    my $frame = $wmgr -> newSlave
      (
       'type'=>'MultiFrame',
       title => "frame $fidx",
       # this will be sent to the printer ...
       print => sub {return "dummy print of data\n";}, 
       bg => 'yellow'
      ) ;
    $frame -> Label(-text => "some label inside for frame nb $fidx")->pack ;

    print "ok ",$idx++,"\n";
  }

MainLoop ; # Tk's

print "ok ",$idx++,"\n";
