# Treegraph - Draw a tree in a Canvas

use Tk ;
use Tk::TreeGraph ;

use vars qw/$TOP/;

sub draw 
  {
    my $tg = shift ;
    
    my $ref = [qw/some text/];
    
    $tg -> addNode 
      (
       nodeId => '1.0', 
       text => $ref
      ) ;
    
    $tg -> addNode 
      (
       after => '1.0', 
       nodeId => '1.1',
       text => $ref
      ) ;
    
    $tg -> addNode 
      (
       after => '1.1', 
       nodeId => '1.2',
       text => $ref
      ) ;
    
    $tg -> addNode 
      (
       after => '1.2', 
       nodeId => '1.3',
       text => $ref
      ) ;
    
    $tg -> addNode 
      (
       after => '1.3', 
       nodeId => '1.4',
       text => $ref
      ) ;
    
    $tg -> addNode 
      (
       after => '1.4', 
       nodeId => '1.5',
       text => $ref
      ) ;
    
    $tg -> addNode 
      (
       after => '1.4',
       nodeId => '1.4.1.1',
       text => $ref
      ) ;
    
    $tg -> addNode 
      (
       after => '1.4',
       nodeId => '1.4.2.1',
       text => $ref
      ) ;
    
    $tg -> addNode 
      (
       after => '1.4',
       nodeId => '1.4.3.1',
       text => $ref
      ) ;
    
    $tg -> addNode 
      (
       after => '1.1',
       nodeId => '1.1.1.1',
       text => $ref
      ) ;
    
    $tg -> addNode 
      (
       after => '1.1.1.1',
       nodeId => '1.1.1.2',
       text => $ref
      ) ;
    
    $tg -> addNode 
      (
       after => '1.0',
       nodeId => '1.0.2.1',
       text => $ref
      ) ;
    
    $tg -> addNode 
      (
       after => '1.0.2.1',
       nodeId => '1.0.2.2',
       text => $ref
      ) ;
    
    $tg -> addNode 
      (
       after => '1.0.2.2',
       nodeId => '1.0.2.3',
       text => $ref
      ) ;
    
    $tg -> addNode 
      (
       after => '1.0.2.1',
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
    
    $tg->addAllShortcuts() ;
    
    $tg->arrowBind
      (
       button => '<1>',
       color => 'yellow',
       command =>  sub{my %h = @_;
                       warn "clicked 1 arrow $h{from} -> $h{to}\n";}
      );
    
    $tg->nodeBind
      (
       button => '<2>',
       color => 'red',
       command => sub {my %h = @_;
                       warn "clicked 2 node $h{nodeId}\n";}
      );

    $tg->command( on => 'arrow', label => 'dummy 1', 
                  command => sub{warn "arrow menu dummy1\n";});
    $tg->command( on => 'arrow', label => 'dummy 2', 
                  command => sub{warn "arrow menu dummy2\n";});
    $tg->arrowBind(button => '<3>', color => 'green', 
                   command => sub{$tg->popupMenu(@_);});
    
    $tg->command(on => 'node', label => 'dummy 1', 
                 command => sub{warn "node menu dummy1\n";});
    $tg->command(on => 'node', label => 'dummy 2', 
                 command => sub{warn "node menu dummy2\n";});
    $tg->nodeBind(button => '<3>', color => 'green', 
                  command => sub{$tg->popupMenu(@_);});
  }

sub treegraph {
    my($demo) = @_;
    $TOP = $MW->WidgetDemo
      (
       -name => $demo,
       -text => ["TreeGraph - Draw a tree in a Canvas
Click on button 1 and 3 on arrows.
Click on button 1,2 and 3 on rectangles or embedded text.",
                 qw/-wraplength 600/],
       -geometry_manager => 'grid',
       -width => 600,
       -title => 'Draw a tree in a Canvas',
       -iconname => 'TreeGraphDemo'
      ) ;
    

    my $tg = $TOP->Scrolled
      (
       qw/TreeGraph -relief sunken -borderwidth 2 -animation 500 
       -width 500 -height 400/,
       -scrollregion => [0, 0, 600 , 400 ]
      ) ->grid ;

    &draw($tg);

    $tg->Tk::bind('<Key-z>',sub {print "hit z\n";
                                   $tg->scale("all",0,0,0.5,0.5);});

    $TOP->Label(-text => 'Click "See Code".')->grid;
}
