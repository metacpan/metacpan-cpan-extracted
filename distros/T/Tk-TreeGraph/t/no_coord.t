# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
use warnings FATAL => qw(all);
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
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

$mw->Label(-text => 'click on button 1 and 3 on arrows')->pack(-fill => 'x') ;
$mw->Label(-text => 'click on button 1,2 and 3 on rectangles or embedded text')
  ->pack(-fill => 'x') ;
$mw->Label(-text => 'Once you have selected several rectangles (button <1>),')
  ->pack(-fill => 'x') ;
$mw->Label(-text => 'You can unselect them all with menu File->unselect nodes')
  ->pack(-fill => 'x') ;

my $tg = $mw -> Scrolled(qw/TreeGraph -nodeColor red -nodeTextColor yellow
                         -nodeFill blue4/);
$tg->pack(-expand => 1, -fill => 'both');

$tg->configure(qw/-animation 800/, -scrollregion => [0, 0, 600 , 400 ])
  unless $trace ;

$tg -> addLabel (text => 'Looks like a VCS revision tree (hint hint)');
print "ok ",$idx++,"\n";

my $ref = [qw/some really_silly text/];

$tg -> addNode 
  (
   -nodeId => '1.0', 
   -text => $ref
  ) ;

print "ok ",$idx++,"\n";

$tg -> addDirectArrow
  (
   -from => '1.0', 
   -to => '1.1'
  ) ;

print "ok ",$idx++,"\n";

$tg -> addNode 
  (
   nodeId => '1.1',
   text => $ref
  ) ;

$tg -> addDirectArrow
  (
   from => '1.1',
   to => '1.2'
  ) ;

$tg -> addNode 
  (
   nodeId => '1.2',
   text => $ref
  ) ;

$tg -> addDirectArrow
  (
   from => '1.2',
   to => '1.3'
  ) ;

$tg -> addNode 
  (
   nodeId => '1.3',
   text => $ref
  ) ;

print "ok ",$idx++,"\n";

$tg -> addSlantedArrow
  (from => '1.1',
   to => '1.1.1.1'
  ) ;

print "ok ",$idx++,"\n";

$tg -> addNode 
  (
   nodeId => '1.1.1.1',
   text => $ref
  ) ;

$tg -> addDirectArrow
  (
   from => '1.1.1.1',
   to => '1.1.1.2'
  ) ;

$tg -> addNode 
  (
   nodeId => '1.1.1.2',
   text => $ref
  ) ;

$tg -> addSlantedArrow
  (
   from => '1.0',
   to => '1.0.2.1'
  ) ;

$tg -> addNode 
  (
   nodeId => '1.0.2.1',
   text => $ref
  ) ;

$tg -> addDirectArrow
  (
   from => '1.0.2.1',
   to => '1.0.2.2'
  ) ;

$tg -> addNode 
  (
   nodeId => '1.0.2.2',
   text => $ref
  ) ;

$tg -> addDirectArrow
  (
   from => '1.0.2.2',
   to => '1.0.2.3'
  ) ;

$tg -> addNode 
  (
   nodeId => '1.0.2.3',
   text => $ref
  ) ;

$tg -> addSlantedArrow
  (
   from => '1.0.2.1',
   to => '1.0.2.1.1.1'
  ) ;

$tg -> addNode 
  (
   nodeId => '1.0.2.1.1.1',
   text => $ref
  ) ;

$tg->addShortcutInfo
  (
   to => '1.2',
   from => '1.0.2.1'
  ) ;

$tg->addShortcutInfo
  (
   to => '1.3',
   from => '1.1.1.2'
  ) ;

print "ok ",$idx++,"\n";

$tg->addAllShortcuts() ;

print "ok ",$idx++,"\n";

$tg->arrowBind
  (
   -button => '<1>',
   -color => 'yellow',
   -command =>  sub{my %h = @_;
                   warn "clicked 1 arrow $h{from} -> $h{to}\n";}
  );

print "ok ",$idx++,"\n";

#$tg->arrowBind(button => '<2>', color => 'green',
#               command => sub {print "hit z\n";
#                               $tg->scale("all",0,0,0.5,0.5);});

$tg->nodeBind
  (
   -button => '<2>',
   -color => 'red',
   -command => sub {my %h = @_;
                   warn "clicked 2 node $h{nodeId}\n";}
  );

$tg->command( -on => 'arrow', -label => 'dummy 1', 
                 -command => sub{warn "arrow menu dummy1\n";});
$tg->command( -on => 'arrow', -label => 'dummy 2', 
                 -command => sub{warn "arrow menu dummy2\n";});
$tg->arrowBind(button => '<3>', color => 'green', 
              command => sub{$tg->popupMenu(@_);});

$tg->command(-on => 'node', -label => 'dummy 1', 
                 -command => sub{warn "node menu dummy1\n";});
$tg->command(-on => 'node', -label => 'dummy 2', 
                 -command => sub{warn "node menu dummy2\n";});
$tg->nodeBind(button => '<3>', color => 'green', 
              command => sub{$tg->popupMenu(@_);});

print "ok ",$idx++,"\n";

$f->command(-label => 'unselect nodes',  
            -command => sub{$tg->unselectAllNodes();} );
$f->command(-label => 'Quit',  -command => sub{$mw->destroy();} );

my @array = $tg->bbox("all") ;
$tg->configure(-scrollregion => [0, 0, $array[2] + 50, $array[3] + 50 ]);

unless ($trace)
  {
    $tg->after(2000, sub{$mw->destroy;});
  }


MainLoop ; # Tk's

print "ok ",$idx++,"\n";
