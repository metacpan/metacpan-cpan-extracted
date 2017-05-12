# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
use warnings FATAL => qw(all);
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tk ;
use ExtUtils::testlib;
use Tk::TreeGraph ;
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
$mw->geometry('600x450+10+10');

my $w_menu = $mw->Frame(-relief => 'raised', -borderwidth => 2);
$w_menu->pack(-fill => 'x');

my $f = $w_menu->Menubutton(-text => 'File', -underline => 0) 
  -> pack(-side => 'left' );
$f->command(-label => 'Quit',  -command => sub{$mw->destroy();} );

$mw->Label(-text => 'tree graph with option -shortcutStyle set to spline')
  ->pack(-fill => 'x') ;
$mw->Label(-text => 'Courtesy of Ralf Valerien')
  ->pack(-fill => 'x') ;

my $tg = $mw->Scrolled( 'TreeGraph', -shortcutStyle => 'spline',
                      -animation => 800 )
  ->pack( -expand => 1, -fill => 'both' );
print "ok ",$idx++,"\n";

$tg->configure(qw/-animation 800/, -scrollregion => [0, 0, 600 , 400 ])
  unless $trace ;

$tg->addLabel( text => 'some tree');

my $ref = [qw/some really_silly text/];
$tg->addNode( nodeId => '1.0',  text => $ref );

# EITHER add the arrow and the node
#$tg->addDirectArrow( from => '1.0',  to => '1.1' );
#$tg->addNode( nodeId => '1.1',  text => ['some','text'] );

# OR add a node after another one, in this case the widget will draw the arrow
$tg->addNode( after =>'1.0',  nodeId => '1.1A',  text => ['some','text'] );
$tg->addNode( after =>'1.0',  nodeId => '1.1B',  text => ['some more','text'] );

$tg->addNode( after =>'1.1A',  nodeId => '2.1A',  text => ['some','text'] );
$tg->addNode( after =>'1.1B',  nodeId => '2.1B',  text => ['some','text'] );
$tg->addNode( after =>'2.1B',  nodeId => '3.1B',  text => ['some','text'] );

$tg->addNode( after =>'1.1B',  nodeId => '1.1C',  text => ['some','text'] );
$tg->addNode( after =>'1.1C',  nodeId => '2.1C',  text => "some\nstring\ntext" );

$tg->addShortcutInfo( from =>'1.0',  to => '2.1A' );
$tg->addShortcutInfo( from =>'1.0',  to => '3.1B' );
$tg->addShortcutInfo( from =>'1.1A',  to => '2.1C' );
#---ugly---
 $tg->addShortcutInfo( from =>'1.1A',  to => '1.1B' );
#---ugly--- 
$tg->addShortcutInfo( from =>'2.1A',  to => '1.1B' );
$tg->addAllShortcuts();
print "ok ",$idx++,"\n";

$tg->arrowBind( button => '<1>', color => 'orange',
  command =>  sub{my %h = @_; warn "clicked 1 arrow $h{from} -> $h{to}\n";}
);

$tg->nodeBind( button => '<2>', color => 'red',
  command => sub {my %h = @_; warn "clicked 2 node $h{nodeId}\n";}
);

$tg->command( -on => 'arrow', -label => 'dummy 2',
  -command => sub{warn "arrow menu dummy2\n";}  );
$tg->arrowBind( -button => '<3>', -color => 'green',
  -command => sub{$tg->popupMenu(@_);}   );

$tg->command( -on => 'node', -label => 'dummy 1',
  -command => sub{warn "node menu dummy1\n";}   );
$tg->nodeBind( button => '<3>', color => 'green',
  command => sub{$tg->popupMenu(@_);}   );
print "ok ",$idx++,"\n";

my @array = $tg->bbox("all") ;
$tg->configure(-scrollregion => [0, 0, $array[2] + 50, $array[3] + 50 ]);

unless ($trace)
  {
    $tg->after(2000, sub{$mw->destroy;});
  }

MainLoop ; # Tk's

print "ok ",$idx++,"\n";
 

