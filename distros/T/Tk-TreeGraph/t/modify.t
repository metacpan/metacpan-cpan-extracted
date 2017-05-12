# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
use warnings FATAL => qw(all);
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tk ;
use ExtUtils::testlib;
use Tk::TreeGraph ;
use vars qw/$tg/ ;
require Tk::ErrorDialog; 
$loaded = 1;
my $idx = 1;
print "ok ",$idx++,"\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict ;

sub draw 
  {
    my $pok = shift ;
    $tg -> addLabel (-text => 'Modify Node 1.1 with File->modify*');
    print "ok ",$idx++,"\n" if $pok;
    
    my $ref = [qw/some really_silly text with no tag/];
    
    $tg -> addNode 
      (
       -nodeId => '1.0', 
       -text => $ref
      ) ;
    
    print "ok ",$idx++,"\n" if $pok;
    
    $tg -> addNode 
      (
       -after => '1.0', 
       -nodeId => '1.1',
       -text => $ref
      ) ;
  }

my $trace = shift || 0 ;

my $mw = MainWindow-> new ;
$mw->geometry('600x450+10+10');

my $w_menu = $mw->Frame(-relief => 'raised', -borderwidth => 2);
$w_menu->pack(-fill => 'x');

my $f = $w_menu->Menubutton(-text => 'File', -underline => 0) 
  -> pack(-side => 'left' );

$tg = $mw -> Scrolled(qw/TreeGraph -nodeTag 1/);
$tg  ->pack(-expand => 1, -fill => 'both');

$tg->configure(qw/-animation 800/, -scrollregion => [0, 0, 600 , 400 ])
  unless $trace ;

&draw(1);

$f->command(-label => 'unselect nodes',  
            -command => sub{$tg->unselectAllNodes();} );
$f->command(-label => 'clear graph',  
            -command => sub{$tg->clear();} );
$f->command(-label => 'draw',  
            -command => sub{draw(0);} );

my $mod_text_color = 
  sub{$tg->modifyNode(-nodeId => '1.1', -nodeTextColor => 'red');};

my $mod_text = sub 
   {
     $tg->modifyNode 
       (
        -nodeId => '1.1', 
        -text => "another\nstupid\ntext\n"
       );
   };

my $mod_node_color = sub 
   {
     $tg->modifyNode 
       (
        -nodeId => '1.1', 
        -nodeColor => 'red', -nodeFill => 'LightGreen'
       );
   };

$f->command (-label => 'modify text color', -command => $mod_text_color);

$f->command (-label => 'modify text', -command => $mod_text);

$f->command (-label => 'modify node colors', -command => $mod_node_color);

$f->command(-label => 'Quit',  -command => sub{$mw->destroy();} );

my @array = $tg->bbox("all") ;
$tg->configure(-scrollregion => [0, 0, $array[2] + 50, $array[3] + 50 ]);

unless ($trace)
  {
    $tg->after(1000, $mod_text_color);
    $tg->after(2000, $mod_text);
    $tg->after(3000, $mod_node_color);
    $tg->after(4000, sub{$mw->destroy;});
  }

MainLoop ; # Tk's

print "ok ",$idx++,"\n";
