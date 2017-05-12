package Tk::TreeGraph;

use strict;
use vars qw($VERSION @ISA);

use Carp ;
use Tk::Derived ;
use Tk::Canvas ;
use Tk::Frame;
use AutoLoader qw/AUTOLOAD/ ;


@ISA = qw(Tk::Derived Tk::Canvas);

$VERSION = sprintf "%d.%03d", q$Revision: 1.30 $ =~ /(\d+)\.(\d+)/;

Tk::Widget->Construct('TreeGraph');

sub InitObject {
    my ($dw,$args) = @_ ;

    # this should get a reasonable default ...
    my $defc = $dw->parent->cget('-foreground');
    $dw->ConfigSpecs (
       '-shortcutColor'    => ['PASSIVE', undef, undef, 'orange'   ],
       '-shortcutStyle'    => ['PASSIVE', undef, undef, 'straight' ],
       '-animation'        => ['PASSIVE', undef, undef, 0          ],
       '-nodeColor'        => ['PASSIVE', undef, undef, $defc      ],
       '-nodeFill'         => ['PASSIVE', undef, undef, undef      ],
       '-arrowColor'       => ['PASSIVE', undef, undef, $defc      ],
       '-nodeTextColor'    => ['PASSIVE', undef, undef, $defc      ],
       '-labelColor'       => ['PASSIVE', undef, undef, $defc      ],

       # add node Id to text
       '-nodeTag'          => ['PASSIVE', undef, undef, 1          ],
       # use this to tune the shape of nodes and arrows
       '-arrowDeltaY'      => ['PASSIVE', undef, undef,  40        ],
       '-branchSeparation' => ['PASSIVE', undef, undef, 120        ],
       '-x_start'          => ['PASSIVE', undef, undef,  40        ],
       '-y_start'          => ['PASSIVE', undef, undef, 100        ],
      );

    # bind button <1> on nodes to select a version
    $dw->bind ('node', 
               '<1>' => sub {$dw->toggleNode(color => 'blue')});

    $dw->{currentBranch} = 'b000';
    $dw->{column}{$dw->{currentBranch}} = 0;

    $dw->SUPER::InitObject($args) ;
}


1;

__END__



=head1 NAME

Tk::TreeGraph - Tk widget to draw a tree in a Canvas

=head1 SYNOPSIS

 use Tk ;
 use Tk::TreeGraph ;

 use strict ;

 my $mw = MainWindow-> new ;

 my $tg = $mw -> Scrolled('TreeGraph') ->
  pack(-expand => 1, -fill => 'both');

 $tg -> addLabel (text => 'some tree');

 my $ref = [qw/some really_silly text/];

 $tg -> addNode 
  (
   nodeId => '1.0', 
   text => $ref
  ) ;

 # EITHER add the arrow and the node
 $tg -> addDirectArrow
  (
   from => '1.0', 
   to => '1.1'
  ) ;

 $tg->addNode
  (
   nodeId => '1.1',
   text => ['some','text']
  ) ;

 # OR add a node after another one, in this case the widget 
 # will draw the arrow
 $tg->addNode
  (
   after =>'1.0',
   nodeId => '1.1',
   text => ['some','text']
  );

 $tg->arrowBind
  (
   button => '<1>',
   color => 'orange',
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

 $tg->command( on => 'arrow', label => 'dummy 2', 
                 command => sub{warn "arrow menu dummy2\n";});

 $tg->arrowBind(button => '<3>', color => 'green', 
              command => sub{$tg->popupMenu(@_);});

 $tg->command(on => 'node', label => 'dummy 1', 
                 command => sub{warn "node menu dummy1\n";});

 $tg->nodeBind(button => '<3>', color => 'green', 
              command => sub{$tg->popupMenu(@_);});

 # adjust scrolled area with some margin
 my @array = $tg->bbox("all") ;
 $tg->configure(-scrollregion => 
                [0, 0, $array[2] + 50, $array[3] + 50 ]);

 MainLoop ; # Tk's

=head1 DESCRIPTION

Tk::TreeGraph is a Canvas specialized to draw trees on a Canvas using
arrows and nodes. A node is simply some text imbedded in a rectangular shape.

TreeGraph is able to draw the following items:

=over 4

=item *

node: some text in a rectangular shape.

=item *

direct arrow: an arrow to go from one node to the following one.

=item *

slanted arrow: an arrow to make a new branch.

=item *

shortcuts arrow: an arrow to represent a shortcut between 2 nodes from
different branches.

=back

TreeGraph also provides :

=over 4

=item *

a binding on nodes on button 1 to 'select' them.

=item *

Methods to bind nodes and arrows on user's call-back.

=back

=head1 CAVEATS

You might say that the tree is a weird tree since it is drawn downward
and assymetric and adding branches leaves a some void between them.

You'd be right. I'm not a specialist in tree drawing algorithms but
the crude algorithm used here works quite fine with drawing id trees
for VCS system. But as usual, I'm always listening for suggestions or
even better, patches ;-) .

Note that the tree MUST be drawn from top to bottom and from left to
right. Unless you may get a very confusing drawing of a tree.

=head1 About Scrolling

First versions of TreeGraph used to tinker with a -scrollregion option
each time addNode was called. This was not consistent since the
scrollbars are added by the user when calling TreeGraph (using
Scrolled('TreeGraph')). Hence from now on, it will be the
responsability of the user to set a satisfying -scrollregion.

The user may write this after all nodes are drawn to set the scrollregion :

 my @array = $tg->bbox("all") ;
 $tg->configure(-scrollregion => [0, 0, $array[2] + 50, $array[3] + 50 ]);

Furthermore, since configure will called only once, the resulting code
will be faster.

=head1 Widget Options

=over 4

=item -nodeColor: 

Color of the node rectangle.

=item -nodeTextColor:

Color of the text within the nodes

=item -labelColor

Color of the label.

=item -arrowColor

Color of the arrow.

=item -shortcutColor:

Color of the shortcut arrow (default 'orange')

=item -shortcutStyle:

Style of the shortcut arrow. The arrow can be drawn as a 'straight'
arrow or a 'spline'. (default 'straight')

=item -nodeTag:

Boolean. By default the nodeId is added at the beginning of the node
text.

=item -arrowDeltaY:

Length of direct arrows (downward). default 40

=item -branchSeparation: 

Minimum width between 2 branches of the tree (default 120) 

=item -x_start:

x coordinate of the root of the tree. (default 100)

=item -y_start: 

y coordinate of the root of the tree.(default 100)

=item -animation: 

Delay (in ms), if delay is positive, TreeGraph will update the canvas
widget any time the addNode method is called and wait delay ms. This
enable to make pretty animation when drawing complex trees. This
feature will work only if a scrollregion is set before calling
addNode.

=back

=cut

=head1 Drawing Methods added to Canvas

You draw the tree node after node with addNode using the 'after' 
parameter. Then the object will infer the kind of arrow needed between the
2 nodes. Using the 'after' parameter, you no longer need
to call youself the addSlantedArrow or addDirectArrow methods.

=head2 addNode(...)

Parameters are:

=over 4

=item *

nodeId: string to identify this node.

=item *

text: text string or array ref. This text will be written inside the rectangle

=item *

after: Either a [x,y] array ref setting the coordinate of the root
of the tree (this can be used to draw the a first tree in the canvas and/or
to draw a second tree in the canvas). If after is a nodeId, an arrow
(direct or slanted) will be drawn from the 'after' node to this new node.

=back

Will add a new node (made of a rectangle with the text inside). 

Note that this method will add the nodeId on top of the passed text
('text' parameter).

=head2 modifyNode(...)

Parameters are:

=over 4

=item *

nodeId: string to identify the node to modify (mandatory).

=item *

text: text string or array ref. This text will be overwritten inside
the rectangle. Note that modifyNode will refuse to change the text if
the new text has more lines than the older text (because the text
would not fit in the rectangle).

=item *

nodeColor: new color of the outline of the rectangle.

=item *

nodeTextColor: new color of the text of the node.

=item *

nodeFill: new color filling the rectangle.

=back

Will modify an existing node. Note that the geometry of the node will not
be changed.

=head2 viewNode(nodeId)

Will move the canvas so that the node is visible within the scrolled area.
(do nothing if the scroll region is not defined TBD XXX)

=head2 flashNode(...)

Parameters are:

=over 4

=item *

nodeId: string to identify the node to modify (mandatory).

=item *

time: time in ms between each flash (default 500 ms)

=item *

nodeColor: new color of the outline of the rectangle.

=item *

nodeTextColor: new color of the text of the node.

=item *

nodeFill: new color filling the rectangle.

=back

Will make an existing node flash. Calling a second time this method on
a node will make the flashing stop.

=head2 addDirectArrow(...)

You can use this method if you want to change the default aspect of
the direct arrow. In this case do not use the 'after' parameter of the
addNode() method. Parameters are:

=over 4

=item *

from: node id where the arrow starts

=item *

to: node id where the arrow ends

=back

Add a new straight (i.e. vertical) arrow starting from a node. Note that
the 'from' nodeId must be defined. The 'to' nodeId must NOT be defined.
(Remember that you must draw the tree from top to bottom)

=head2 addSlantedArrow(...)

You can use this method if you want to change the default aspect of
the slanted arrow. In this case do not use the 'after' parameter of the
addNode() method.

Parameters are:

=over 4

=item *

from: node id where the arrow starts

=item *

to: node id where the arrow ends

=back

Add a new branch connecting node 'id' to node 'id2'.  Note that the
'from' nodeId must be defined. The 'to' nodeId must NOT be defined.
(Remember that you must draw the tree from left to right)

=head2 addLabel(...)

Put some text on the top of the graph. Parameters are:

=over 4

=item *

text: text to be inserted on the top of the graph.

=back

=head2 addShortcutInfo(...)

Parameters are:

=over 4

=item *

from: node id where the arrow starts

=item *

to: node id where the arrow ends

=back

Declare that a shortcut arrow will be drawn from node 'arrow_start' and 
'arrow_end'.

=head2 addAllShortcuts()

This method is to be called once all nodes, direct arrow and branch arrows
are drawn and all relevant calls to addShortcutInfo are done.
 
It will draw shortcut arrows between the ids declared with 
the addShortcutInfo method.

=head2 clear()

Clear the graph.

=head1 Management methods

=head2 nodeBind(...)

Parameters are:

=over 4

=item *

button: button name to bind (e.g. '<1>') 

=item *

color: color of the node when it is clicked on.

=item *

command: sub ref 

=back

Bind the 'button' on all nodes. When 'button' is clicked, the node
text color will change to 'color' and the callback sub will be called
with these parameters: 

 (on => 'node', nodeId => $nodeId)

=head2 arrowBind(...)

Parameters are:

=over 4

=item *

button: button name to bind (e.g. '<1>') 

=item *

color: color of the node when it is clicked on.

=item *

command: sub ref 

=back

Bind the 'button' on arrows. When 'button' is clicked, the arrow color will
change to 'color' and the callback sub will be called with these parameters:

 (
   on   => 'arrow', 
   from => nodeId_on_arrow_start, 
   to   => nodeId_on_arrow_tip
 ) 

=head2 unselectAllNodes()

Unselect all previously selected nodes (see button <1> binding)

=head2 getSelectedNodes()

Return an array containing nodeIds of all nodes currently selected.

=head2 getNodeRectangle(...)

Returns the rectangle reference of the passed nodeId or of the 
node selected by the user.

Parameters are :

=over 4

=item *

nodeId: nodeId attached to the rectangle

=back 

=head2 command(...)

This will add a new entry on a Popup menu which can be raised on a node
or an arrow.

Parameters are :

=over 4

=item *

on: either 'node' or 'arrow'

=item *

label: Label of the Popup menu entry

=item *

command: sub ref runned when the menu is invoked

=back

The callback will be invoked with these parameters when the command is
set for B<nodes> :

 (on => 'node', nodeId => $nodeId)

The callback will be invoked with these parameters when the command is
set for B<arrows> :

 (
   on   => 'arrow', 
   from => nodeId_on_arrow_start, 
   to   => nodeId_on_arrow_tip
 ) 


=head1 Private methods

These functions are documented only for people wanting to improve or
inherit this widget.

=head2 setArrow(...)

Parameters are:

=over 4

=item *

color: color of the arrow when selected.

=back

Reset any previously selected arrow to default color and set the current 
arrow to the color. This function should be used with a bind.

Returns (from => $endNodeId, to => $tipNodeId) to specify the nodes 
the arrow is attached to.

=head2 setNode()

Parameters are:

=over 4

=item *

color: color of the arrow when selected.

=item *

nodeId: nodeId to select (optional, default to the node under the mouse 
pointer)

=back

Set node either from passed nodeId or from the mouse pointer.
When a node is set, only the text is highlighted

Returns the nodeId of the current node (i.e. the node clicked by the user
if this function was used in a bind)

=head2 toggleNode(...)

Parameters are:

=over 4

=item *

color: color of the arrow when selected.

=item *

nodeId: nodeId to select (optional, default to the node under the mouse 
pointer)

=back

Will toggle the node rectangle between 'color' and default.


=cut

## data structures (i.e $dw->{...})

# arrow -> start -> hash : key is arrow widget id, 
#                          value is node Id where the arrow starts
# arrow -> tip   -> hash : key is arrow widget id, 
#                          value is node Id where the arrow ends

# node -> text      : text widget ref
# node -> rectangle : rectangle widget ref

# nodeId->hash ref: key is text or rectangle widget id, value: nodeId

# tset -> hash ref : (toggle set) key is nodeId set by the user, value is
#                    the rectangle widget id

# xset -> arrow: (eXclusive set) : arrow widget id of the arrow set by the user
# xset -> node : (eXclusive set) : nodeId of the node set by the user

# shortcutFrom -> hash : key is the nodeId of the start of the shortcut,
#                        value is the nodeId of the end of the shortcut

## General functions

sub clear
  {
    my $dw = shift ;
    
    foreach (qw/arrow node nodeId tset xset shortcutFrom x y 
             tree_start after limit column next_limit/)
      {
        delete $dw->{$_};
      }

    $dw->delete('all');

    $dw->{currentBranch} = 'b000';
    $dw->{column}{$dw->{currentBranch}} = 0;
  }

sub addLabel
  {
    my $dw = shift ;
    my %args = @_ ;
    my $text = defined $args{-text} ?  $args{-text} : $args{text} ;
    
    my $defc = $dw->cget('-labelColor') ;
    $dw->create('text', '7c' , 5 , -anchor => 'n' , -fill => $defc,
                               -text=> $text, -justify => 'center') ;
  }

sub checkOverlay
  {
    my $dw = shift ;
    my $y = shift ;

    my $c= $dw->{column}{$dw->{currentBranch}};

    #print "checking branch $dw->{currentBranch} col $c for y $y\n";

    return 0 unless defined $dw->{limit}[$c];
    #print "limit for col $c is $dw->{limit}[$c]\n";
    return 0 unless $y > $dw->{limit}[$c]; 

    my $old_c = $c ;
    # must move the branch
    while (defined $dw->{limit}[$c] and $y > $dw->{limit}[$c])
      {
        $c++ ;
      }

    #print "must move from column $old_c to $c\n";

    my $b=$dw->{currentBranch} ;
    my $dx = $dw->cget('-branchSeparation')*($c-$old_c) ;

    # shift the whole branch
    $dw->move($dw->{currentBranch},$dx,0) ; 

    # shift the tip of the arrow
    my @coord = $dw->coords("arrow".$dw->{currentBranch}) ;
    $coord[2]+= $dx ;
    $dw->coords("arrow".$dw->{currentBranch}, @coord) ; 

    # set the new limits to the bottom of the node from where the branch 
    # starts
    foreach my $idx ($old_c .. $c - 1)
      {
        #print "auto setting limit for col $idx at $coord[1]\n";
        $dw->{limit}[$idx] = $coord[1] ;
      }
    
    # update the cache the new column occupied by this branch 
    $dw->{next_limit} = [ $c,  $coord[1] ];

    # update current column
    $dw->{column}{$dw->{currentBranch}} = $c;
    
    $dw->checkOverlay($y) ;
  }

## Arrow functions

# add a an arrow for a regular revision, return the new $$yr at the bottom of
# the arrow
sub addDirectArrow
  {
    my $dw = shift ;
    my %args = @_ ;
    my $nodeId = defined $args{-from} ? $args{-from}:  $args{from};
    my $lowerNodeId = defined $args{-to} ? $args{-to} : $args{to};

    $dw->{after}{$nodeId}=1;
    my $branch_dx= $dw->cget('-branchSeparation');
    my $c = $dw->{column}{$dw->{currentBranch}} ;
    my $x = $branch_dx * $c + $dw->{tree_start} + $branch_dx/2 - 10 ;
    my $old_y = $dw->{y};

    $dw->BackTrace("addDirectArrow: unknown 'from' nodeId: $nodeId\n")
      unless defined $dw->{node}{rectangle}{$nodeId};
    
    my $y = $old_y + $dw->cget('-arrowDeltaY') ; # give length of arrow

    my $defc = $dw->cget('-arrowColor'); 
    my $itemId = $dw->create
      ('line', $x, $old_y, $x, $y , 
       -fill => $defc, 
       -tags => ["arrow",$dw->{currentBranch}],
       -arrow =>'last'); 

    $dw->{arrow}{start}{$itemId} = $nodeId ; 
    $dw->{arrow}{tip}{$itemId} = $lowerNodeId ; 

    $dw->{'y'} = $y ;
  }

 # will call-back sub with ($start_nodeId,$tip_nodeId) nodeId 
sub arrowBind 
  { 
    my $dw = shift ; 
    my %args = @_ ; 
    my $button = defined $args{-button} ? $args{-button} : $args{button}; 
    my $color  = defined $args{-color}  ? $args{-color}  : $args{color}; 
    my $callback = defined $args{-command} ? $args{-command} : $args{command} ;

    # bind button <1> on arrows to display history information
    $dw->bind
      (
       'arrow', $button => sub 
       {
         my @ids = $dw->setArrow(color => $color) ;
         $dw->idletasks;
         &$callback(on => 'arrow', @ids) ;
       });

    $dw->bind
      (
       'scutarrow', $button => sub 
       {
         my @ids = $dw->setArrow(color => $color) ;
         $dw->idletasks;
         &$callback(on => 'arrow',@ids) ;
       });
  }

# will return with ($start_revision,$tip_revison) rev numbers
# setArrow
sub setArrow
  {
    my $dw = shift ;
    my %args = @_ ;
    my $color = defined $args{-color} ? $args{-color} : $args{color};
    
    # reset any selected arrow
    if (defined $dw->{xset}{arrow})
      {
        my $tag = $dw->gettags($dw->{xset}{arrow});
        my $defc = $tag eq 'scutarrow'? 
          $dw->cget('-shortcutColor') :  $dw->cget('-arrowColor');

        $dw->itemconfigure($dw->{xset}{arrow}, -fill => $defc);
      }

    my ($itemId) = $dw->find('withtag' => 'current');
    $dw->{xset}{arrow} = $itemId ;
    $dw->itemconfigure($itemId, -fill => $color) ;
    my $tipNodeId = $dw->{arrow}{tip}{$itemId} ;
    my $endNodeId = $dw->{arrow}{start}{$itemId} ;

    return (from => $endNodeId, to => $tipNodeId) ;
  }

## Slanted Arrows

sub addSlantedArrow
  {
    my $dw = shift ;
    my %args = @_ ;
    my $nodeId = defined $args{-from} ? $args{-from} : $args{from};
    my $branch = defined  $args{-to} ? $args{-to} : $args{to} ;
    my $y = $dw->{'y'} ;

    $dw->BackTrace("AddSlantedArrow: unknown 'from' nodeId: $nodeId\n")
      unless defined $dw->{node}{rectangle}{$nodeId};

    my $nodeBranch = $dw -> {node}{branch}{$nodeId};
    my $old_c = $dw->{column}{$nodeBranch} ;
    my ($old_x, $old_y) = ($dw->coords($dw->{node}{rectangle}{$nodeId}))[0,3];

    $y = $old_y + $dw->cget('-arrowDeltaY') ; # give length of arrow

    # create the new branch on the next column
    $dw->{currentBranch}++;
    $dw->{column}{$dw->{currentBranch}} = $old_c + 1 ;

    my $branch_dx= $dw->cget('-branchSeparation');
    my $x = $branch_dx * ($old_c+1) + $dw->{tree_start}  ;

    my $defc = $dw->cget('-arrowColor');
    my $itemId = $dw->create('line', 
                             $old_x + $branch_dx/2 - 10, $old_y, 
                             $x + $branch_dx/2 - 10, $y,
                             -fill => $defc,
                             -tags => ["arrow","arrow".$dw->{currentBranch}],
                             -arrow =>'last'); 

    $dw->{arrow}{start}{$itemId} = $nodeId ;
    $dw->{arrow}{tip}{$itemId} = $branch ;

    if (defined $dw->{next_limit})
      {
        my ($c,$l) = @{$dw->{next_limit}};
        #print "setting limit for col $c at $l\n";
        $dw->{limit}[$c] =  $l ;
      }
    
    # cache the limit for that we don't limit the drawing of this branch
    #print "setting next limit for col ",$old_c+1, " at $old_y\n";
    $dw->{next_limit} = [ $old_c + 1,  $old_y ];

    $dw->{y} = $y ;
  }

## Short Cut Arrows 

sub addShortcutInfo
  {
    my $dw = shift ;
    my %args = @_ ;
    my $nodeId = defined $args{-from} ? $args{-from} : $args{from} ;
    my $mNodeId = defined  $args{-to} ? $args{-to} : $args{to} ;

    push( @{$dw->{shortcutFrom}{$nodeId}}, $mNodeId );
  }

sub addAllShortcuts
  {
    my $dw = shift ;

    my $color = $dw->cget('-shortcutColor') || $dw->cget('-foreground');

    my $dx= $dw->cget('-branchSeparation')/2 - 10;
    my $branch_dx= $dw->cget('-branchSeparation');
    my $style = $dw->cget('-shortcutStyle') ;

    foreach my $nodeId (keys %{$dw->{shortcutFrom}})
      {
        next unless defined $dw->{node}{rectangle}{$nodeId} ;
	
        foreach my $mNodeId (@{$dw->{shortcutFrom}{$nodeId}})
          {
            next unless defined $dw->{node}{rectangle}{$mNodeId} ;
            # beginning of arrow
            my ($bx, $by) = ($dw->coords($dw->{node}{rectangle}{$nodeId}))[0,3] ;
            # end of arrow
            my ($ex, $ey) =($dw->coords($dw->{node}{rectangle}{$mNodeId}))[0,1] ;
            my @opt = ($bx + $dx, $by); # arrow start

            # intermediate points for multi-segment line
            push @opt, ($bx+ $dx + $ex +$dx - $branch_dx)/2, ($by+$ey)/2 
              if $style eq 'spline' ;

            push @opt , $ex + $dx, $ey ; # arrow end

            push @opt ,qw/-smooth on/ if $style eq 'spline'; # spline mode 

            my $itemId = $dw->create
              (
               'line', @opt ,
               -arrow => 'last', 
               -tag => 'scutarrow',
               -fill=>$color
              );
            $dw->{arrow}{start}{$itemId} = $nodeId;
            $dw->{arrow}{tip}{$itemId} = $mNodeId ;
	  }
      }
  }

## Node functions

# draw a node, return the y coord of the bottom of the node 
#($x does not change)
sub addNode
  {
    my $dw = shift ;
    my %args = @_ ;

    my $nodeId = $args{-nodeId} || $args{nodeId} ;
    my $text_parm = defined $args{-text} ? $args{-text} : $args{text} ;
    my $text = ref $text_parm ? join("\n",@$text_parm) : $text_parm ;
    chomp $text;

    #print "Drawing node $nodeId\n";
    my $after = defined $args{-after} ? $args{-after} : $args{after};
    if (defined $after)
      {
        if (ref($after) eq 'ARRAY')
          {
            # re-start another tree
            ($dw->{tree_start},$dw->{y}) = @$after;
          }
        elsif (defined $dw->{after}{$after})
          {
            $dw->addSlantedArrow('from' => $after, to => $nodeId);
          }
        else
          {
            $dw->addDirectArrow('from' => $after, to => $nodeId);
          }
      }
    
    # initialization
    $dw->{tree_start}=$dw->cget('-x_start') unless defined $dw->{tree_start};
    
    # compute text to draw
    $text = "$nodeId\n". $text if $dw->cget('-nodeTag') ;

    # first compute y coord 
    my $oldy = $dw->{y} || $dw->cget('-y_start');
    my $y = $oldy + 5 ; # give some breathing space 

    # then compute the x coordinate
    my $branch_dx= $dw->cget('-branchSeparation');
    my $c = $dw->{column}{$dw->{currentBranch}} ;
    my $x = $branch_dx * $c + $dw->{tree_start}  ;

    # compute y coord
    # draw node text
    my $defc = $args{-nodeTextColor} || $args{nodeTextColor} 
      || $dw->cget('-nodeTextColor');

    my $tid = $dw->create('text', $x + $branch_dx/2 - 10, $oldy + 5, 
                          -text => $text,  -fill => $defc,
                          qw/-justify center -anchor n -width 12c/,
                          -tags => ['node', $dw->{currentBranch}]) ;

    # compute y according to the text drawn
    my @box = $dw->bbox($tid) ;
    $y = $box[3] + 5 ;

    # draw node rectangle
    $defc = $args{-nodeColor} || $args{nodeColor} || $dw->cget('-nodeColor');
    my $bgc = $args{-nodeFill} || $args{nodeFill} 
      || $dw->cget('-nodeFill');
    my $newx = $x + $branch_dx   - 20 ;
    my $rid = $dw->create('rectangle',
                          $x , $oldy,
                          $newx , $y,
                          -outline => $defc, -width => 2 , -fill => $bgc ,
                          -tags => ['node', $dw->{currentBranch}]
                        ) ;
    
    $dw->raise($tid,$rid); # the text is hidden below if forgotten

    # check if we have not drawn over something
    $dw->checkOverlay($y);

    $dw -> {nodeId}{$tid}=$nodeId ; 
    $dw -> {nodeId}{$rid}=$nodeId ; # also stored
    $dw -> {node}{text}{$nodeId}=$tid ;
    $dw -> {node}{rectangle}{$nodeId}=$rid ;
    $dw -> {node}{branch}{$nodeId}= $dw->{currentBranch} ;

    $dw->{x} = $x;
    $dw->{y} = $y ;

    my $delay = $dw->cget('-animation') ;

    if ($delay)
      {
        $dw->viewNode($nodeId) and $dw->after($delay);
      }
  }

sub viewNode
  {
    my $dw = shift ;
    my $nodeId = shift;

    my @sc = $dw->cget('-scrollregion');

    # even if the scrollregion is not defined, the array has 4 elements
    # so i must tesst one of the elements of the array
    return 0 unless (defined $sc[0]) ; # 

    my @bb = $dw->bbox("all") ;

    # adjust scroll region is something is outside of it
    foreach my $i (0,1)
      {
        $sc[$i] = $bb[$i] - 50 if ($bb[$i] < $sc[$i]);
      }
    foreach my $i (2,3)
      {
        $sc[$i] = $bb[$i] + 50 if ($bb[$i] > $sc[$i]);
      }

    $dw->configure(-scrollregion => \@sc );

    # get the rectangle coordinates
    my $rectangle_id = $dw -> {node}{rectangle}{$nodeId};
    my ($rx1,$ry1,$rx2,$ry2)= $dw->coords($rectangle_id);

    # get the full canvas coordinates
    my ($cx1,$cy1,$cx2,$cy2) = @sc;
    # compute where is the node within this widget (fraction)
    my ($xf1,$yf1,$xf2,$yf2) = 
      ($rx1/($cx2-$cx1), $ry1/($cy2-$cy1), $rx2/($cx2-$cx1), $ry2/($cy2-$cy1));

    # check if xf is out of view
    my ($xvleft,$xvright) = $dw->xview ;
    my $deltax = $xvright - $xvleft ;

    # put the widget at the center (x wise)
    $dw->xview(moveto=> (($xf1 + $xf2 - $deltax) / 2) )
      if ($xf1< $xvleft or $xf2> $xvright);

    # check if yf is out of view
    my ($yvtop,$yvbottom) = $dw->yview ;
    my $deltay = $yvbottom - $yvtop ;
    $dw->yview(moveto=>(($yf1 + $yf2 - $deltay) / 2 ) )
      if ($yf1 < $yvtop or $yf2 > $yvbottom);

    # print "delay $x $y, fx $xf fy $yf\n" ;
    $dw->idletasks;

    return 1 ;
  }

sub modifyNode
  {
    my $dw = shift ;
    my %args = @_ ;

    my $nodeId = $args{-nodeId} || $args{nodeId} || $dw->getCurrentNodeId; # optional

    croak "modifyNode: missing nodeId parameter" 
      unless defined $nodeId;

    my $rid = $dw->{node}{rectangle}{$nodeId} ; # retrieve id of rectangle
    my $tid = $dw->{node}{text}{$nodeId} ; 

    croak "modifyNode: unknown nodeId : $nodeId" unless defined $rid ;

    my $nc = $args{-nodeColor} || $args{nodeColor} ;
    if (defined $nc)
      {
        $dw->itemconfigure($rid, -outline => $nc) ;
      }

    my $text_parm = defined $args{-text} ? $args{-text} : $args{text} ;
    if (defined $text_parm)
      {
        my $text = ref $text_parm ? join("\n",$text_parm) : $text_parm;
        chomp $text ;

        $text = $nodeId."\n$text" if $dw->cget('-nodeTag') ;
        my $count = $text ;
        $count =~ s/[^\n]// ;

        my $oldText = $dw->itemcget($tid, '-text' ) ;
        $oldText =~ s/[^\n]// ;

        if (length($count) > length($oldText))
          {
            croak "modifyNode error: New text is longer than the old one. It will no fit in the node" ;
          }

        $dw->itemconfigure($tid, -text => $text) ;
      }

    my $ntc = $args{-nodeTextColor} || $args{nodeTextColor} ;
    if (defined $ntc)
      {
        $dw->itemconfigure($tid, -fill => $ntc) ;
      }

    my $nf = $args{-nodeFill} || $args{nodeFill} ;
    if (defined $nf)
      {
        $dw->itemconfigure($rid, -fill => $nf) ;
      }
  }

sub flashNode
  {
    my $dw = shift ;
    my %args = @_ ;

    my $nodeId = $args{-nodeId} || $args{nodeId} || $dw->getCurrentNodeId; # optional
    croak "modifyNode: missing nodeId parameter" 
      unless defined $nodeId;

    my $rid = $dw->{node}{rectangle}{$nodeId} ; # retrieve id of rectangle
    my $tid = $dw->{node}{text}{$nodeId} ; 

    croak "modifyNode: unknown nodeId : $nodeId" unless defined $rid ;

    if (defined $dw -> {node}{flash} and 
        defined $dw -> {node}{flash}{$nodeId} and 
        $dw -> {node}{flash}{$nodeId})
      {
        $dw -> {node}{flash}{$nodeId} = 0;
        return ;
      }
    
    $dw->viewNode($nodeId) ;

    my $time = $args{-time} || $args{time} || 500 ;
    $dw -> {node}{flash}{$nodeId} = 1 ;

    my $oldNodeColor = $dw->itemcget($rid, '-outline') ;
    my $oldNodeTextColor = $dw->itemcget($tid, '-fill') ;
    my $oldNodeFill = $dw->itemcget($rid, '-fill') ;

    my $newNodeColor = $args{-nodeColor} || $args{nodeColor} || $oldNodeColor ;
    my $newNodeTextColor = $args{-nodeTextColor} ||$args{nodeTextColor} 
      || $oldNodeTextColor ;
    my $newNodeFill = $args{-nodeFill} || $args{nodeFill} || $oldNodeFill ;

    my ($on,$off) ;

    $on = sub 
      {
        $dw->itemconfigure($rid, -outline => $newNodeColor) ;
        $dw->itemconfigure($tid, -fill =>    $newNodeTextColor) ;
        $dw->itemconfigure($rid, -fill =>    $newNodeFill) ;
        $dw->after($time,$off) ; # always call off
      };

    $off = sub 
      {
        $dw->itemconfigure($rid, -outline => $oldNodeColor) ;
        $dw->itemconfigure($tid, -fill =>    $oldNodeTextColor) ;
        $dw->itemconfigure($rid, -fill =>    $oldNodeFill) ;
        $dw->after($time,$on) if $dw -> {node}{flash}{$nodeId} ;
      };

    &$on ;
  }

# will return with node Id
# when toggling a node, only the rectangle is highlighted
sub toggleNode
  {
    my $dw = shift ;
    my %args = @_ ;
    my $color = $args{-color} || $args{color} ;
    my $nodeId = $args{-nodeId} || $args{nodeId} || $dw->getCurrentNodeId; # optional

    my $rid = $dw->{node}{rectangle}{$nodeId} ; # retrieve id of rectangle

    if (defined $dw->{tset}{node}{$nodeId})
      {
        my $defc = $dw->cget('-nodeColor');
        $dw->itemconfigure($rid, -outline => $defc) ; #unselect
        delete $dw->{tset}{node}{$nodeId} ;
      } 
    else
      {
        die "Error no color specified while selecting node\n"
          unless defined $color ;
        $dw->itemconfigure($rid, -outline => $color) ;
        $dw->{tset}{node}{$nodeId} = $rid ; # store id of rectangle
      } 

    $dw->idletasks;
    return $nodeId ;
  }

sub getNodeRectangle
  {
    my $dw = shift ;
    my %args = @_ ;
    my $nodeId = $args{-nodeId} || $args{nodeId} || $dw->getCurrentNodeId; # optional
    return $dw->{node}{rectangle}{$nodeId} ;
  }

sub getSelectedNodes
  {
    my $dw = shift ;
    return keys %{$dw->{tset}{node}} ;
  }

sub unselectAllNodes
  {
    my $dw = shift ;

    my $defc = $dw->cget('-nodeColor');
    foreach (values %{$dw->{tset}{node}})
      {
        $dw->itemconfigure($_, -outline => $defc) ; #unselect
      }
    delete $dw->{tset}{node} ;
  }

sub getCurrentNodeId
  {
    my $dw = shift ;

    my ($selected) = $dw->find('withtag' => 'current');

    unless (defined $selected)
      {
        $dw->bell ; $dw->bell ; # twice for debug ...
        return undef ;
      }

    return $dw->{nodeId}{$selected} ;
  }

# set node either from passed nodeId or from the mouse pointer
# when a node is set, only the text is highlighted
sub setNode
  {
    my $dw = shift ;
    my %args = @_ ;

    my $color = $args{-color} || $args{color} ;
    my $nodeId = $args{-nodeId} || $args{nodeId} || $dw->getCurrentNodeId ; # optional

    if (defined $dw->{xset}{node})
      {
        my $defc = $dw->cget('-nodeTextColor') || $dw->cget('-nodeColor');
        $dw->itemconfigure($dw->{xset}{node},fill => $defc);
      }

    my $itemId = $dw->{node}{text}{$nodeId} ;
    $dw->{xset}{node} = $itemId ;
    $dw->itemconfigure($itemId, fill => $color) ;

    return $dw->{nodeId}{$itemId} ;
  }


# will call-back sub with node $rev
sub nodeBind
  {
    my $dw = shift ;
    my %args = @_ ;
    my $color = $args{-color} || $args{color} ;
    my $button = $args{-button} || $args{button} ;
    my $callback = $args{-command} || $args{command} ;

    $dw->bind
      (
       'node', $button => sub 
       {
         my $id = $dw->setNode(color => $color) ;
         $dw->idletasks;
         &$callback(on => 'node', nodeId => $id) ;
       });

  }

## Popup menu commands

# will call-back sub with ($start_nodeId,$tip_nodeId) node Ids
sub command
  {
    my $dw = shift ;
    my %args = @_ ;
    my $on = $args{-on} || $args{on};
    my $label = $args{-label}  || $args{label} ;
    my $sub = $args{-command}  || $args{command} ;
    
    $dw->{command}{$on}{$label} = $sub ;
  }

sub popupMenu
  {
    my $dw = shift ;
    my %args = @_ ;
    my $on = delete $args{-on} || delete $args{on} ;

    my $menu = $dw-> Menu; 
    foreach (keys %{$dw->{command}{$on}})
      {
        my $s = $dw->{command}{$on}{$_};
        $menu -> add 
          (
           'command',
           '-label' => $_, 
           '-command' => sub {&$s(%args) ;}
          );
    }

    $menu->Popup(-popover => 'cursor', -popanchor => 'nw');
  }


=head3 draw_tree_from_ref( $tree_aref )

Draws a tree from a structure like this:
my $tree_aref = [['Root', ['Terminal', ['Nonterminal', ['Terminal']]]]];

=cut

sub draw_tree_from_ref {
    my $self            = shift;
    my $tree_aref       = shift;

    my $root_node_id    = '1.0';

    $self->clear() ;

    # Debug:
    #print Dumper $root_node_id;
    #print Dumper $tree_aref;

    # -- ckeck input
    if( ref $tree_aref ne 'ARRAY' ){
	croak("draw_tree_from_ref: the tree must be an array ref");
    }
    else {
	# -- draw root-node and recurse with rest
	$self->addNode(
		       nodeId  => $root_node_id,
		       text    => $tree_aref->[0]->[0],
		      );

	$self->_draw_tree_from_ref_recursive($tree_aref->[0]->[1],
					     $root_node_id);
    }

} # /draw_tree_from_ref

=head3 _draw_tree_from_ref_recursive( $tree_aref, $root_node_id )

This is the private method we use to draw the tree recursively. It is called
by draw_tree_from_ref($tree_aref). As this method is private, it is not
indended to be called directly.

$tree_aref has to be a tree-structure as the following expamle:

 my $tree_aref = [['Root', ['Terminal', ['Nonterminal', ['Terminal']]]]] ;

=cut

sub _draw_tree_from_ref_recursive {
    my $self            = shift;
    my $tree_aref       = shift;
    my $root_node_id    = shift;

    ## Debug:
    #print Dumper $root_node_id;
    #print Dumper $tree_aref;

    # -- iterate throuh the children of the actual root-node
    foreach my $pos ( 0 ..  (@$tree_aref-1) ) {
	my $e = $tree_aref->[$pos];

	if( ref $e eq 'ARRAY' ) {

	    # -- calculate new id
	    my $new_id = $self->_calcNewTreeId($root_node_id, $pos);

	    # -- draw node containing nonterminal
	    $self->addNode(
			   after   => $root_node_id,
			   nodeId  => $new_id,
			   text    => $e->[0],
			  );

	    # -- recurse with rest
	    $self->_draw_tree_from_ref_recursive($e->[1], $new_id);

	}
	else {

	    # -- build new id
	    my $new_id = $self->_calcNewTreeId($root_node_id, $pos);

	    # -- draw node containing terminal
	    $self->addNode(
			   after   => $root_node_id,
			   nodeId  => $new_id,
			   text    => $e,
			  );

	}
    }

} # /_draw_tree_from_ref_recursive

=head3 _calcNewTreeId( $motherId, $pos_in_tree_level )

Method used in draw_tree_from_ref. Calculates the id of a child in a
subtree-level and returns it. Needs the id of the root-node of the
sub-tree and the position of the element.

=cut

sub _calcNewTreeId {
    my $self                = shift;
    my $mother_id           = shift;
    my $pos_in_tree_level   = shift; # tree-item-count starts at 0.
    my $new_id              = undef;

    if( $mother_id =~ m/(.+)\.0$/ ) {
	$new_id = $1 . '.' . ($pos_in_tree_level+1);
    }
    else {
	$new_id = $mother_id . '.' . ($pos_in_tree_level+1);
    }

    return $new_id;
} # /

=head1 AUTHOR

Dominique Dumont, ddumont at cpan dot org.

Copyright (c) 1998-2004,2007 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Thanks to Alexander Becker for the method to draw a tree from an array
ref.

=head1 SEE ALSO

L<Tk>, L<Tk::Canvas>

=cut
