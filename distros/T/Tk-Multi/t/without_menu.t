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
use Tk::Multi::Manager;
use Tk::Multi::Text;
use Tk::Multi::Canvas; 
require Tk::ErrorDialog; 
$loaded = 1;
my $idx = 1;
print "ok ",$idx++,"\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict ;
my $toto ;

my $trace = shift || 0 ;

my $mw = MainWindow-> new ;


print "creating 2nd manager without menu\n" if $trace ;

my $popupSub = sub 
        {
          $mw ->Dialog('-title'=> "popup help", 
                       -text => 'dummy test help',
                       -bg => 'red'
                      ) -> Show();
        } ;

print "ok ",$idx++,"\n";
my $wmgr2 = $mw -> MultiManager ( 'title' => 'log test',
                                help => $popupSub ) 
  -> pack (qw/-fill both -expand 1/);
print "ok ",$idx++,"\n";
my $list2 = $wmgr2 -> newSlave('type'=>'MultiText',) ;
my $list3 = $wmgr2 -> newSlave('type'=>'MultiText', title =>'another list') ;

print "ok ",$idx++,"\n";

$mw -> Button (-text => 'quit', -command => sub {$mw->destroy;})-> pack ;

MainLoop ; # Tk's

print "ok ",$idx++,"\n";
