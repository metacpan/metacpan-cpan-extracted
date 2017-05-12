# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
use warnings FATAL => qw(all);
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# test Puppet::Any

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tk ;
use ExtUtils::testlib;
use Tk::Multi::Toplevel ;
use Tk::ErrorDialog; 
$loaded = 1;
print "ok 1\n";

my $trace = shift ;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict ;

my $mw = MainWindow-> new ;
$mw -> withdraw ; # hide the main window

my $p = $mw->MultiTop();
$p -> OnDestroy(sub{$mw->destroy});

#foreach (qw/baz/)
foreach (qw/foo bar baz toto titi/)
  {
    my $name = $_ ;
    $p->menuCommand(name => $_, menu => 'example', 
                    command => sub{warn "invoked $name\n";});
    
  }

$p->add(
        'command', 
        -label => 'remove baz', 
        -command => sub
        {
          $p->menuRemove(name => 'baz', menu => 'example');
          $p->delete('end') ; # not very clean ...
        }
       );

print "Creating sub window list\n" if $trace ;
my $list = $p -> newSlave
  (
   'type'=> 'MultiText', 
   title => 'list',
   data => ["This Multi widget is a toplevel window\n",
            "The main window was withdrawn"]
  ) ;

MainLoop ; # Tk's

