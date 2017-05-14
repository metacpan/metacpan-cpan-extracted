
package ZooZ::Project;

use strict;
use Tk qw/:colors/;
use Tk::Tree;
use Tk::ItemStyle;
use Tk::ROText;
use Tk::ProgressBar;
use Tk::Pane;
use Tk::NoteBook;

use ZooZ::DefaultArgs;
use ZooZ::Forms;
use ZooZ::Options;
use ZooZ::Generic;

#############
#
# Global variables
#
#############
my $gridW = 90;     # width of each grid.
my $gridH = 50;     # height of each grid.
my $XoffS = 30;     # X offset of first grid.
my $YoffS = 30;     # Y offset of first grid.

my $maxR  = 20;    # max number of rows.
my $maxC  = 20;    # max number or cols.

my $isContainer  = qr/^(?:Tk::)?(?:Lab(?:el)?)?[Ff]rame$/;  # for container widgets.
my $isParasite   = qr/Scrollbar|Adjuster/;
my %scrollable   = ( # list of scrollable widgets
		    Text   => 1,
		    ROText => 1,
		    Pane   => 1,
		    Tree   => 1,
		    HList  => 1,
		   );

##############
#
# Constructor
#
##############

sub new {
  my ($self, %args) = @_;

  my $class = ref($self) || $self;

  my $obj = bless {
		   PROJID      => $args{-id},
		   PROJNAME    => $args{-name},
		   TOP         => $args{-top},
		   TITLE       => $args{-title},
		   ICONS       => $args{-icons},
		   SELECTED    => undef,                  # currently selected widget
		   MOVABLE     => undef,                  # currently movable widget
		   BALLOON     => $args{-top}->Balloon,
		   DRAGMODE    => 0,                      # if we are in drag mode.
		   HIERTOP     => $args{-hiertop}    || 'MainWindow',
		   ISCHILD     => $args{-ischild}    || 0,
		   LEVEL       => $args{-level}      || 'MainWindow',
		   ROWOPT      => [],
		   COLOPT      => [],
		   SHARED      => $args{-shared}     || {},   # all shared data between hiers
		  } => $class;

  $obj->_createGrid;
  $obj->_defineBindings;

  # create the hier list and preview window if we have to.
  if ($obj->{ISCHILD}) {
    $obj->{TREE}    = $args{-tree};
    $obj->{PREVIEW} = $args{-preview};
  } else {
    $obj->_createHierList;
    $obj->_createPreviewWindow;
    $obj->_unhideCanvas;
    $obj->{MWPROPS} = {
		       NAME    => 'MainWindow',
		       PREVIEW => $obj->{PREVIEW},
		       WCONF   => {},
		       PCONF   => {},
		       ECONF   => {},
		      };
  }

  $obj->{SHARED}{IDS}                ||= {};         # widget ids to use when creating unique names.
  $obj->{SHARED}{ALL_WIDGETS}        ||= {};
  $obj->{SHARED}{CUROBJ}               = $obj;
  $obj->{SHARED}{SUBHIERS}{MainWindow} = $obj if $obj->{HIERTOP} eq 'MainWindow';

  return $obj;
}

########################
#
# This sub creates the hierarchy Tk::Tree widget that displays
# the hierarchy of the added widgets.
#
########################

sub _createHierList {
  my $self = shift;

  # bind tree such that when we click on a widget, it is selected.
  my $tree = $self->{TOP}->Scrolled(Tree =>
				    -scrollbars  => 'se',
				    -borderwidth => 1,
				    -browsecmd   => sub {
				      return unless @_ == 1;

				      my $labS = shift;
				      my $self = $self->{SHARED}{CUROBJ};

				      $labS =~ s/(.*)\.// or do { # mainwindow
					$self->{SHARED}{CUROBJ}->unselectCurrentWidget;

					# show the proper canvas.
					unless ($self->{SHARED}{CUROBJ} == $self->{SHARED}{SUBHIERS}{MainWindow}) {
					  $self = $self->{SHARED}{SUBHIERS}{MainWindow}->_unhideCanvas;
					}

					$self->selectWidget('MainWindow');
					return;
				      };

				      # find out in which hierarchy this widget lies
				      my $hier = $1;
				      $hier =~ s/.*\.//;

				      # show the proper canvas.
				      unless ($self->{SHARED}{CUROBJ} == $self->{SHARED}{SUBHIERS}{$hier}) {
					$self = $self->{SHARED}{SUBHIERS}{$hier}->_unhideCanvas;
				      }

				      # $labS is just a string.
				      # get the actual label widget.
				      my ($r, $c) = @{$self->{LABEL2GRID}{$labS}};
				      my $lab = $self->{GRID}[$r][$c]{LABEL};

				      $self->selectWidget($lab);
				      $self->descendHier if exists $self->{SHARED}{SUBHIERS}{$lab};
				    },
				    -command => sub {
				      my $labS = shift;

				      #$labS =~ s/(.*)\.// or return; # MainWindow

				      $labS =~ s/(.*)\.// or do { # mainwindow
					$self->{SHARED}{CUROBJ}->unselectCurrentWidget;

					# show the proper canvas.
					unless ($self->{SHARED}{CUROBJ} == $self->{SHARED}{SUBHIERS}{MainWindow}) {
					  $self = $self->{SHARED}{SUBHIERS}{MainWindow}->_unhideCanvas;
					}

					$self->configureWidget('MainWindow');
					return;
				      };

				      my $self = $self->{SHARED}{CUROBJ};

				      # get the actual label widget.
				      my ($r, $c) = @{$self->{LABEL2GRID}{$labS}};
				      my $lab = $self->{GRID}[$r][$c]{LABEL};

				      # find out in which hierarchy this widget lies
				      my $hier = $1;
				      $hier =~ s/.*\.//;
				      $self = $self->{SHARED}{SUBHIERS}{$hier};

				      $self->configureWidget($lab);
				    },
				   )->pack(qw/-side right -fill y/);

  $self->{TOP}->Adjuster(-widget => $tree,
			 -side   => 'right',
			)->pack(qw/-side right -fill y/);

  $tree->Subwidget($_)->configure(-borderwidth => 1) for qw/xscrollbar yscrollbar/;

  # create the entry for the main window.
  $tree->add('MainWindow', -text => 'MainWindow', -style => 'container');

  # save it.
  $self->{TREE} = $tree;
}

###############
#
# This sub creates a new Toplevel that serves as a preview
# of the project.
#
###############

sub _createPreviewWindow {
  my $self = shift;

  my $t = $self->{PARENT}->Toplevel(Name => 'preview');
  $t->protocol(WM_DELETE_WINDOW => [$t => 'withdraw']);
  $t->title   ($self->{TITLE});

  #$t->optionClear;

  $self->{PREVIEW} = $t;
}

###############
#
# This sub hides/unhides the preview window
#
###############

sub togglePreview {
  my $self = shift;
  my $mode = shift || '';

  if      ($mode eq 'OFF') {
    $self->{PREVIEW}->withdraw;
  } elsif ($mode eq 'ON') {
    $self->{PREVIEW}->deiconify;
  } else {
    # toggle.
    if ($self->{PREVIEW}->ismapped) {
      $self->{PREVIEW}->withdraw;
    } else {
      $self->{PREVIEW}->deiconify;
    }
  }
}

###########
#
# This subroutine creates the grid canvas along with other
# canvas objects.
#
###########

sub _createGrid {
  my $self = shift;

  # create the notebook if we have to.
  #  unless ($self->{NB}) {
  #    $self->{NB} = $self->{TOP}->NoteBook(qw/-borderwidth 1/
  #)->pack(qw/-side left -fill both -expand 1/);
#    my $nb = $self->{TOP}->Scrolled(NoteBook => qw/-borderwidth 1/,
#				    -scrollbars => 'se',
#				   )->pack(qw/-side left -fill both -expand 1/);
#    $self->{NB} = $nb->Subwidget('notebook');
#  }

#  # add a page for this level.
#  $self->{PARENT} = $self->{NB}->add($self->{LEVEL},
#				     -label    => $self->{LEVEL},
#				     -raisecmd => sub {
#				       $self->{SHARED}{CUROBJ} = $self;
#				     },
#				    );

  unless ($self->{SHARED}{HIERLABEL}) {
    $self->{SHARED}{HIERLABEL} = $self->{TOP}->Label(-text => $self->{LEVEL},
						     -font => 'Level',
						    )->pack(qw/-side top -fill x/);
  }

  $self->{PARENT} = $self->{TOP}->Frame;#->pack(qw/-side left -fill both -expand 1/);

  # create the canvas.
  my $cv = $self->{CV} = $self->{PARENT}->Scrolled(Canvas   =>
						   -bg      => 'white',
						   -confine => 1,
						   -scrollbars => 'se',
						  )->pack(qw/-side left
							  -fill both
							  -expand 1/);

  # draw the grid.
  my $x = $XoffS;
  my $y = $YoffS;

  for my $r (0 .. $maxR - 1) {
    for my $c (0 .. $maxC - 1) {
      $self->{GRID}[$r][$c]{ID} =
	$cv->createRectangle($x, $y,
			     $x + $gridW, $y + $gridH,
			     -stipple => 'transparent',
			     -fill    => 'white',
			     -outline => 'grey',
			     -tags    => ['GRID', "GRID_$ {r}_$ {c}"]
			    );

      $x += $gridW;
    }

    $x = $XoffS;
    $y += $gridH;
  }

  { # Add the row/col numbers.
    my $x = $XoffS / 2;
    my $y = $YoffS + $gridH / 2;

    for my $r (0 .. $maxR - 1) {

      my $b = $cv->Button(-text               => $r,
			  -padx               => 2,
			  -pady               => 1,
			  -highlightthickness => 1,
			  -borderwidth        => 1,
			  -bg                 => 'white',
			  -relief             => 'flat',
			  -font               => 'Row/Col Num',
			  -command            => [$self, configureRow => $r],
			 );

      $cv->createWindow($x, $y,
			-window => $b,
		       );

      $self->{BALLOON}->attach($b, -balloonmsg => "Configure Row $r");

      $y += $gridH;
    }

    $x = $XoffS + $gridW / 2;
    $y = $YoffS / 2;

    for my $c (0 .. $maxC - 1) {
      my $b = $cv->Button(-text               => $c,
			  -padx               => 2,
			  -pady               => 1,
			  -highlightthickness => 1,
			  -borderwidth        => 1,
			  -bg                 => 'white',
			  -relief             => 'flat',
			  -font               => 'Row/Col Num',
			  -command            => [$self, configureCol => $c],
			 );

      $cv->createWindow($x, $y,
			-window => $b,
		       );

      $self->{BALLOON}->attach($b, -balloonmsg => "Configure Column $c");

      $x += $gridW;
    }
  }

  $cv->configure(-scrollregion => [0, 0, ($cv->bbox('all'))[2, 3]]);

  # create a dummy outline rectangle to display when moving widgets.
  $self->{DRAG_OUTLINE} = $cv->createRectangle(0, 0, 0, 0,
						 -width   => 2,
						 -outline => 'grey12',
						 -fill    => 'white',
						 -stipple => 'transparent',
						 -state   => 'hidden',
						);

  # create the expand/contract buttons.
  my @opts = (
	      -highlightthickness => 0,
	      -borderwidth        => 1,
	      -pady               => 0,
	      -relief             => 'flat',
	     );

  for (
       [qw/CONTRACT_H white leftArrow /, 'Decrease size horizontally by 1'],
       [qw/EXPAND_H   white rightArrow/, 'Increase size horizontally by 1'],
       [qw/CONTRACT_V white upArrow   /, 'Decrease size vertically by 1'  ],
       [qw/EXPAND_V   white downArrow /, 'Increase size vertically by 1'  ],
      ) {
    $self->{$_->[0]} = $cv->Label(
				  -bitmap => $_->[2],
				  -bg     => $_->[1],
				  @opts,
				 );

    $self->{BALLOON}->attach($self->{$_->[0]},
			     -balloonmsg => $_->[3],
			    );

    $self->{$_->[0]}->bind('<Enter>' => [$self->{$_->[0]}, 'configure', -bg => 'tan']);
    $self->{$_->[0]}->bind('<Leave>' => [$self->{$_->[0]}, 'configure', -bg => $_->[1]]);
    $self->{$_->[0]}->bind('<1>'     => [$self, 'resizeWidget', $_->[0]]);
  }

  # the DESCEND button (for containers only)
  $self->{DESCEND} = $cv->Label(-bitmap => 'box',
				-fg     => 'red',
				-bg     => 'white',
				@opts,
			       );
  $self->{BALLOON}->attach($self->{DESCEND},
			   -balloonmsg => "Manage this widget's children",
			  );
  $self->{DESCEND}->bind('<Enter>' => [$self->{DESCEND}, 'configure', -bg => 'tan']);
  $self->{DESCEND}->bind('<Leave>' => [$self->{DESCEND}, 'configure', -bg => 'white']);
  $self->{DESCEND}->bind('<1>'     => [$self, 'descendHier']);
}

##########
#
# defines all the default bindings for interactivity.
#
##########

sub _defineBindings {
  my $self = shift;

  my $cv = $self->{CV};

  $cv->CanvasBind('<1>' => [$self => 'unselectCurrentWidget']);
  #$cv->CanvasBind('<<DropWidget>>' => \&dropWidget);
}

############
#
# called when a user clicks on any of the resizing arrows.
#
############

sub resizeWidget {
  my ($self, $dir) = @_;

  my $cv = $self->{CV};

  # first thing, get the location of the widget to be resized.
  my $lab = $self->{SELECTED};
  my ($row, $col) = @{$self->{LABEL2GRID}{$lab}};

  my $gridRef = $self->{GRID}[$row][$col];
  my $rsize   = $gridRef->{ROWS};
  my $csize   = $gridRef->{COLS};

  if      ($dir eq 'EXPAND_H') {
    # check for edges.
    return if $row + $rsize == $maxR;

    # check if the column on the right is used or not.
    for my $r ($row .. $row + $rsize - 1) {
      return if $self->{GRID}[$r][$col + $csize]{WIDGET};
    }

    # we have space. let's expand it.
    $gridRef->{COLS}++;

    # get the bbox of the new area.
    my @tags = map {'GRID_' . $_ . '_' . ($col+$csize)} $row .. $row + $rsize - 1;
    my @new  = $cv->bbox(@tags);
    my @box  = $cv->bbox($gridRef->{WINDOW});

    $cv->coords($gridRef->{WINDOW},
		($box[0] + $new[2] - 1) / 2,
		($box[1] + $new[3] - 1) / 2,
	       );

    $cv->itemconfigure($gridRef->{WINDOW},
		       -width => $gridRef->{COLS} * $gridW,
		      );

    # indicate that the new location is used.
    for my $r ($row .. $row + $rsize - 1) {
      $self->{GRID}[$r][$col + $csize]{WIDGET} = $gridRef->{WIDGET};
      $self->{GRID}[$r][$col + $csize]{MASTER} = $lab;
    }

  } elsif ($dir eq 'CONTRACT_H') {
    # can't shrink if there is only one column.
    return if $csize == 1;

    # ok .. let's shrink.
    $gridRef->{COLS}--;

    my @tags = map {'GRID_' . $_ . '_' . ($col+$csize - 1)} $row .. $row + $rsize - 1;
    my @new  = $cv->bbox(@tags);
    my @box  = $cv->bbox($gridRef->{WINDOW});

    $cv->coords($gridRef->{WINDOW},
		($box[0] + $new[0]) / 2,
		($box[1] + $box[3] - 1) / 2,
	       );

    $cv->itemconfigure($gridRef->{WINDOW},
		       -width => $gridRef->{COLS} * $gridW,
		      );

    # empty the location.
    for my $r ($row .. $row + $rsize - 1) {
      $self->{GRID}[$r][$col + $csize - 1]{WIDGET} = undef;
      $self->{GRID}[$r][$col + $csize - 1]{MASTER} = undef;
    }

  } elsif ($dir eq 'EXPAND_V') {
    # check for edges.
    return if $col + $csize == $maxC;

    # check if the row below is used or not.
    for my $c ($col .. $col + $csize - 1) {
      return if $self->{GRID}[$row + $rsize][$c]{WIDGET};
    }

    # we have space. let's expand it.
    $gridRef->{ROWS}++;

    # get the bbox of the new area.
    my @tags = map {'GRID_' . ($row + $rsize) . '_' . $_} $col .. $col + $csize - 1;
    my @new  = $cv->bbox(@tags);
    my @box  = $cv->bbox($gridRef->{WINDOW});

    $cv->coords($gridRef->{WINDOW},
		($box[0] + $new[2] - 1) / 2,
		($box[1] + $new[3] - 1) / 2,
	       );

    $cv->itemconfigure($gridRef->{WINDOW},
		       -height => $gridRef->{ROWS} * $gridH,
		      );

    # indicate that the new location is used.
    for my $c ($col .. $col + $csize - 1) {
      $self->{GRID}[$row + $rsize][$c]{WIDGET} = $gridRef->{WIDGET};
      $self->{GRID}[$row + $rsize][$c]{MASTER} = $lab;
    }

  } else { # $dir eq 'CONTRACT_V'
    # can't shrink if there is only one row.
    return if $rsize == 1;

    # ok .. let's shrink.
    $gridRef->{ROWS}--;

    my @tags = map {'GRID_' . ($row+$rsize - 1) . '_' . $_} $col .. $col + $csize - 1;
    my @new  = $cv->bbox(@tags);
    my @box  = $cv->bbox($gridRef->{WINDOW});

    $cv->coords($gridRef->{WINDOW},
		($box[0] + $box[2] - 1) / 2,
		($box[1] + $new[1]) / 2,
	       );

    $cv->itemconfigure($gridRef->{WINDOW},
		       -height => $gridRef->{ROWS} * $gridH,
		      );

    # empty the location.
    for my $c ($col .. $col + $csize - 1) {
      $self->{GRID}[$row + $rsize - 1][$c]{WIDGET} = undef;
      $self->{GRID}[$row + $rsize - 1][$c]{MASTER} = undef;
    }

  }

  # update the preview
  $self->updatePreviewWindow;
}

#############################
#
# called when the user clicks on the canvas to drop a new widget.
# For new widgets, this is called directly from ZooZ.pl
# It simply makes sure the correct ZooZ::Project object is
# chosen and calls dropWidget().
#
#############################

sub dropWidgetInCurrentObject {
  @_ = ($_[0]{SHARED}{CUROBJ});
  goto &dropWidget;
}

#############
#
# This method adds a new widget to the project.
#
#############

sub dropWidget {
  my $self = shift;

  my $cv = $self->{CV};

  # check where the click happened.
  my ($id, $row, $col) = $self->_getGridClick;

  # didn't click on anything useful.
  ZooZ::Generic::popMessage(-over  => $::MW,
			    -font  => 'Level',
			    -bg    => 'White',
			    -msg   => 'Please click on a grid location.',
			    -delay => 1500) &&
			      return undef unless defined $id;

  my $ref = $self->{GRID}[$row][$col];

  # is it an empty location?
  # If NOT empty and widget to be dropped is a parasite
  # (ex. scrollbar), then add it to the currently placed widget.
  # If NOT empty and widget to be dropped is not a parasite
  # AND grid contains a container, then open up container view.

  if ($ref->{WIDGET}) {
    # not empty.
    # Go on ONLY if parasite on scrollable widget OR
    # non-parasite on a container.
    if ($::SELECTED =~ $isParasite) {

      # If scrollbar, then make object scrolled if it is scrollable.
      if ($::SELECTED_W =~ /scroll/i) {
	ZooZ::Generic::popMessage(-over  => $::MW,
				  -font  => 'Level',
				  -bg    => 'White',
				  -msg   => "Widget $ref->{WIDGET} is not scrollable!",
				  -delay => 1500) &&
				    return undef unless exists $scrollable{$ref->{WIDGET}};

	$ref->{ECONF}{SCROLLON} = 1;
      }

    } else {
      # not a parasite.
      # is it a container.
      ZooZ::Generic::popMessage(-over  => $::MW,
				-font  => 'Level',
				-bg    => 'White',
				-msg   => 'Please click on an empty grid location.',
				-delay => 1500) &&
				  return undef unless $ref->{WIDGET} =~ $isContainer;

      $self->descendHier($ref->{LABEL});
      return undef;
    }

    return 1;
  } else {
    # empty.
    # Go on ONLY if added widget is NOT a parasite.
    ZooZ::Generic::popMessage(-over  => $::MW,
			      -font  => 'Level',
			      -bg    => 'White',
			      -delay => 1500,
			      -msg   => <<EOT) && return undef if $::SELECTED_W =~ $isParasite;
A $::SELECTED_W widget can only be
used in conjunction with a scrollable widget.
EOT
  ;
  }

  # it is empty. Fill it up.
  $ref->{WIDGET}= $::SELECTED_W;

  # create a new and uniqe name.
  my $name = $::SELECTED_W . ++$self->{SHARED}{IDS}{$::SELECTED_W};

  # get coordinates of new window.
  my @c = $cv->coords($id);
  my $w = $c[2] - $c[0];
  my $h = $c[3] - $c[1];

  # create the label and window.
  my $frame = $cv->Frame(-relief => 'raised', -borderwidth => 1);
  my $label = $frame->Label->pack(qw/-fill both -expand 1/);

  $ref->{WINDOW} = $cv->createWindow($c[0] + $w / 2,
				     $c[1] + $h / 2,
				     -window => $frame,
				     -width  => $w,
				     -height => $h,
				    );

  $ref ->{NAME}                      = $name;
  $ref ->{LABEL}                     = $label;
  $ref ->{LABFRAME}                  = $frame;
  $ref ->{ROWS}                      = 1;
  $ref ->{COLS}                      = 1;
  $ref ->{PCONF}                     = {};
  $ref ->{WCONF}                     = {};
  $ref ->{ECONF}                     = {};
  $self->{LABEL2GRID}{$label}        = [$row, $col];
  $self->{SHARED}{NAME2LABEL}{$name} = $label;

  # create the compound image to place in the label.
  my $compound = $label->Compound;
  $label   ->configure(-image => $compound);
  if (exists $self->{ICONS}{lc $::SELECTED_W}) {
    $compound->Image(-image => $self->{ICONS}{lc $::SELECTED_W});
  } else {
    $compound->Bitmap(-bitmap => 'error');
  }
  $compound->Line;
  $compound->Text(-text => $name,
		  -font => 'WidgetName',
		 );

  $self->_bindWidgetLabel($label);

  # create the actual preview widget.
  my $type = $::SELECTED_W eq 'Image' ? 'Label' : $::SELECTED_W;
  my $args = ZooZ::DefaultArgs->getDefaultWidgetArgs($::SELECTED_W, $name);

  # Convert all frames to Panes.
  #$type = 'Pane' if $type eq 'Frame';
#  if ($type eq 'Frame') {
#    $type = 'Pane';
#    $self->{ROWOPT}{$row}{-weight} = 1;
#    $self->{COLOPT}{$col}{-weight} = 1;
#  }

  # Make it Scrolled .. just for the preview.
  if (exists $scrollable{$type}) {
    $ref->{PREVIEW} = $self->{PREVIEW}->Scrolled($type,
						 -scrollbars => '',
						 %$args
						);
    #print "scrolled = ", $ref->{PREVIEW}->Subwidget(lc $type)->configure(%$args), ".\n";
    #print "Propagate = ", $ref->{PREVIEW}->Subwidget(lc $type)->gridPropagate, ".\n";
  } else {
    $ref->{PREVIEW} = $self->{PREVIEW}->$type(%$args);
  }

  # add to the hier tree
  $self->{TREE}->add($self->{HIERTOP} . '.' . $label, -text => $name,
		     $::SELECTED_W =~ $isContainer ? (-style => 'container') : ()
		    );
  $self->{TREE}->autosetmode;

  # if it's a container, create the notebook tab for it.
  if ($::SELECTED_W =~ $isContainer) {
    my $proj = $self->new(-id         => $self->{PROJID},
			  -top        => $self->{TOP},
			  -name       => $self->{PROJNAME},
			  -title      => $self->{TITLE},
			  -icons      => $self->{ICONS},
			  -hiertop    => "$self->{HIERTOP}.$label",
			  -ischild    => 1,
			  -tree       => $self->{TREE},
			  -preview    => $self->{GRID}[$row][$col]{PREVIEW},
			  -level      => "$self->{LEVEL}.$self->{GRID}[$row][$col]{NAME}",
			  -shared     => $self->{SHARED},
			 );

    $self->{SHARED}{SUBHIERS}{$label} = $proj;

    # return the cur obj to the parent.
    $self->{SHARED}{CUROBJ}   = $self;
  }

  # select it
  $self->selectWidget($label);

  # update the default arguments.
  # this will tag them as 'changed' and will output them
  # in the project file and code dump.
  $ref->{WCONF}{$_} = $args->{$_} for keys %$args;

  # must update the preview window.
  $self->updatePreviewWindow;

  # add it to the global hash.
  $self->{SHARED}{ALL_WIDGETS}{$name} = $ref->{PREVIEW};

  return 1;
}

#############
#
# Returns a ref to the ALL_WIDGETS hash
#
#############

sub allWidgetsHash { $_[0]{SHARED}{ALL_WIDGETS} }

#############
#
# This sub sets up the bindings for moving a widget around.
#
#############

sub _bindWidgetLabel {
  my ($self, $lab) = @_;

  $lab->bind('<1>'                => [$self, 'selectWidget',    $lab   ]);
  $lab->bind('<B1-Motion>'        => [$self, 'dragWidget',      $lab   ]);
  $lab->bind('<B1-ButtonRelease>' => [$self, 'moveWidget',      $lab   ]);
#  $lab->bind('<Double-1>'         => [$self, 'configureWidget', $lab,  ]);
  $lab->bind('<Double-1>'         => sub {
	       $self->configureWidget($lab);
	       $self->descendHier if exists $self->{SHARED}{SUBHIERS}{$lab};
	     });
}

#####################
#
# This sub is called when a user ends the dragging of
# an already existing widget (dropping it) over the canvas.
#
#####################

sub moveWidget {
  my ($self, $lab) = @_;

  return unless $self->{MOVABLE};
  return unless $self->{DRAGMODE};

  $self->{DRAGMODE} = 0;

  my $cv = $self->{CV};

  $cv->itemconfigure($self->{DRAG_OUTLINE},
		     -state => 'hidden',
		    );

  # where did we release the button?
  my ($id, $row, $col) = $self->_getGridClick;

  # didn't click on anything useful.
  return undef unless defined $id;

  # get the old location first.
  my ($oldR, $oldC) = @{$self->{LABEL2GRID}{$lab}};

  # is it an empty location?
  # must check multiple locations if widget is larger than min.
  # it's ok if the new location is occupied by the movable label.
  {
    my ($r, $c)   = @{$self->{GRID}[$oldR][$oldC]}{qw/ROWS COLS/};
    for my $ri (0 .. $r - 1) {
      for my $ci (0 .. $c - 1) {
	next if $row + $ri == $oldR && $col + $ci == $oldC;
	return undef if
	  ($self->{GRID}[$row + $ri][$col + $ci]{WIDGET} and
	   !$self->{GRID}[$row + $ri][$col + $ci]{MASTER} ||
	   $self->{GRID}[$row + $ri][$col + $ci]{MASTER} != $lab);
      }
    }
  }

  # empty. re-position the widget.

  # now swap logically.
  $self->{GRID}[$row] [$col]  = $self->{GRID}[$oldR][$oldC];

  for my $r (0 .. $self->{GRID}[$row][$col]{ROWS} - 1) {
    for my $c (0 .. $self->{GRID}[$row][$col]{COLS} - 1) {
      next if $oldR + $r == $row && $oldC + $c == $col;

      $self->{GRID}[$oldR + $r][$oldC + $c] = {};
    }
  }

  for my $r (0 .. $self->{GRID}[$row][$col]{ROWS} - 1) {
    for my $c (0 .. $self->{GRID}[$row][$col]{COLS} - 1) {
      next if $r == 0 && $c == 0;

      $self->{GRID}[$row + $r][$col + $c]{WIDGET} = $self->{GRID}[$row] [$col]{WIDGET};
      $self->{GRID}[$row + $r][$col + $c]{MASTER} = $lab;
    }
  }

  $self->{LABEL2GRID}{$lab}                                    = [$row, $col];
  $self->{SHARED}{NAME2LABEL}{$self->{GRID}[$row][$col]{NAME}} = $lab;

  # and swap physically.
  my @c = $cv->coords($id);
  my $w = $self->{MOVABLE}->width;
  my $h = $self->{MOVABLE}->height;

  $cv->coords($self->{GRID}[$row][$col]{WINDOW},
	      $c[0] + $w / 2 + 1,
	      $c[1] + $h / 2 + 1,
	     );

  # update the resize buttons.
  $self->_showResizeButtons;

  # must update the preview window.
  $self->updatePreviewWindow;
}

###################
#
# This sub is called when the user drags an already existing
# widget over the canvas with the intention of moving it.
#
###################

sub dragWidget {
  my ($self, $lab) = @_;

  return unless $self->{MOVABLE};
  my $cv = $self->{CV};

  my $x = $cv->canvasx($cv->pointerx - $cv->rootx);
  my $y = $cv->canvasy($cv->pointery - $cv->rooty);

  $cv->itemconfigure($self->{DRAG_OUTLINE},
		     -state => 'normal',
		    );

  my $w = $self->{MOVABLE}->width;
  my $h = $self->{MOVABLE}->height;

  # mouse pointer is always at the center of the top left grid.
  $cv->coords($self->{DRAG_OUTLINE} =>
	      $x - $gridW / 2,
	      $y - $gridH / 2,
	      $x + $w - $gridW / 2,
	      $y + $h - $gridH / 2,
	     );

  $self->{DRAGMODE} = 1;
}

#############
#
# This sub is called when a user selects a widget by clicking on it.
#
#############

sub selectWidget {
  my ($self, $lab) = @_;

  if ($self->{SELECTED}) {
    # don't do anything if this is the currently selected widget already.
    return if $self->{SELECTED} == $lab;

    # manually unselect the older widget.
    $self->{SELECTED}->configure(-bg => NORMAL_BG) if ref $self->{SELECTED};
    $self->{DESCEND} ->placeForget;
  }


  $lab->configure(-bg => 'cornflowerblue') if ref $lab;
  $self->{SELECTED} = $lab;
  $self->{MOVABLE}  = ref $lab ? $lab : '';

  # must show the resize buttons.
  $self->_showResizeButtons if ref $lab;

  # reflect this in the hier tree.
  if (ref $lab) { # only if it's a widget. Else .. it's MainWindow
    $self->{TREE}->selectionClear;
    $self->{TREE}->selectionSet("$self->{HIERTOP}.$lab");
    $self->{TREE}->anchorSet   ("$self->{HIERTOP}.$lab");
  }

  # if the configure form is open, reflect there too.
  $self->configureWidget($lab, 1);
}

###############
#
# unselects currently selected widget
#
###############

sub unselectCurrentWidget {
  my $self = shift;

  my $lab  = $self->{SELECTED};
  $lab     or return;
  ref $lab or return;

  $lab->configure(-bg => NORMAL_BG);
  $self->{SELECTED} = '';
  $self->{MOVABLE}  = '';

  # must hide the resize buttons.
  $self->_hideResizeButtons;

  # reflect this in the hier tree.
  $self->{TREE}->selectionClear;
  $self->{TREE}->selectionSet($self->{HIERTOP});
  $self->{TREE}->anchorSet   ($self->{HIERTOP});

  return $lab;
}

#############
#
# this sub finds out the grid location we clicked on.
#
#############

sub _getGridClick {
  my $self = shift;
  my $cv   = $self->{CV};

  my $x  = $cv->canvasx($cv->pointerx - $cv->rootx);
  my $y  = $cv->canvasy($cv->pointery - $cv->rooty);

  for my $id ($cv->find(overlapping => $x, $y, $x, $y)) {
    my @t  = $cv->gettags($id);

    my ($r, $c) = "@t" =~ /\bGRID_(\d+)_(\d+)\b/;
    defined $r or next;

    return $self->_isGridVisible($id) ? ($id, $r, $c) : undef;
  }

  return undef;
}

sub _isGridVisible {
  my ($self, $id) = @_;

  my $c = $self->{CV};
  my $x1 = $c->canvasx($c->x);
  my $y1 = $c->canvasy($c->y);
  my $x2 = $c->canvasx($c->x + $c->width);
  my $y2 = $c->canvasy($c->y + $c->height);

  return 1 if grep $_ == $id, $c->find(overlapping => $x1, $y1, $x2, $y2);
  return 0;
}

###############
#
# This sub is called when a widget is selected.
# It displays the arrows used to resize the widget.
#
###############

sub _showResizeButtons {
  my $self = shift;

  my $cv = $self->{CV};

  # get the frame where the label is.
  my ($r, $c) = @{$self->{LABEL2GRID}{$self->{SELECTED}}};
  my $frame = $self->{GRID}[$r][$c]{LABFRAME};

  # place the buttons in $frame.
  $self->{EXPAND_H}  ->place(-in => $frame,
			     -x  => 23,
			     -y  => 2,
			    );
  $self->{CONTRACT_H}->place(-in => $frame,
			     -x  => 10,
			     -y  => 2,
			    );

  $self->{EXPAND_V}  ->place(-in => $frame,
			     -x  => 2,
			     -y  => 23,
			    );
  $self->{CONTRACT_V}->place(-in => $frame,
			     -x  => 2,
			     -y  => 10,
			    );

  # if it's a container, then show the box button.
  if ($self->{GRID}[$r][$c]{WIDGET} =~ $isContainer) {
    $self->{DESCEND}->place(-in => $frame,
			    -x  => 2,
			    -y  => 2,
			   );
  }

  $self->{$_}->raise for qw/EXPAND_H CONTRACT_H EXPAND_V CONTRACT_V DESCEND/;
}

###############
#
# This sub is called when a widget is unselected.
# It hides the arrows used to resize the widget.
#
###############

sub _hideResizeButtons {
  my $self = shift;

  $self->{$_}->placeForget for qw/EXPAND_H CONTRACT_H EXPAND_V CONTRACT_V DESCEND/;
}

###############
#
# This sub is called when the Delete key is pressed
# or when the delete toolbutton is invoked
#
###############

sub deleteSelectedWidget {
  my $self = $_[0]{SHARED}{CUROBJ};

  return unless $self->{SELECTED};
  my $lab = $self->unselectCurrentWidget;

  # delete the data structures.
  my $rc  = delete $self->{LABEL2GRID}{$lab};
  my $ref = delete $self->{GRID}[$rc->[0]][$rc->[1]];

  # delete the widgets.
  $_->destroy for $lab, $ref->{LABFRAME};
  $self->{CV}->delete($ref->{WINDOW});

  # free up the space.
  for my $r (0 .. $ref->{ROWS} - 1) {
    for my $c (0 .. $ref->{COLS} - 1) {
      $self->{GRID}[$rc->[0] + $r][$rc->[1] + $c] = {};
    }
  }

  # clean up the hier list.
  $self->{TREE}->delete(entry => "$self->{HIERTOP}.$ref->{LABEL}");

  # clean up the widget properties window.
  ZooZ::Forms->deleteWidget($self->{PROJID}, $ref->{NAME});

  # remove it from the shared hash
  delete $self->{SHARED}{ALL_WIDGETS}{$ref->{NAME}};

  # clean up the preview window.
  $ref->{PREVIEW}->destroy;

  # update the preview window.
  $self->updatePreviewWindow;
}

##############################
#
# This updates the preview window whenever
# something changes
#
##############################

sub updatePreviewWindow {
  my $self = shift;

  my $top = $self->{PREVIEW};

  # first, the title.
  $top->title($self->{TITLE}) unless $self->{ISCHILD};

  # now iterate through all the objects and update.
  for my $lab (keys %{$self->{LABEL2GRID}}) {
    my ($row, $col) = @{$self->{LABEL2GRID}{$lab}};

    my $ref = $self->{GRID}[$row][$col];

    $ref->{PREVIEW}->grid(-row        => $row,
			  -column     => $col,
			  -rowspan    => $ref->{ROWS},
			  -columnspan => $ref->{COLS},
			 );
  }

  $top->geometry('') unless $self->{ISCHILD};
}

######################
#
# This method creates the canvas (full-fledged ZooZ::Project object)
# for any container widgets when we want to add widgets to them.
#
######################

sub descendHier {
  my $self = shift;

  my $lab  = shift || $self->{SELECTED};

  # hide the current. unhide the child.
  #$self->_hideCanvas;
  $self->{SHARED}{SUBHIERS}{$lab}->_unhideCanvas;
}

#################
#
# This sub hides the canvas of the calling project
#
#################

#sub _hideCanvas   { $_[0]{CV}->packForget }
sub _hideCanvas {}

#################
#
# This sub unhides the canvas of the calling project.
# It is IMPORTANT that it returns the project itself.
#
#################

sub _unhideCanvas {
  my $self = shift;

  # show the animation.
  #ZooZ::Generic::animateOpen($self->{TOP}, 80, 80, $gridW, $gridH);
  my $curObj = $self->{SHARED}{CUROBJ};
  #print "Current obj is $curObj->{LEVEL}.\n" if $curObj;
  #ZooZ::Generic::animateOpen($curObj->{CV}) if $curObj;

  # show the correct frame.
  $curObj->{PARENT}->packForget if $curObj;
  #ref($_) eq 'Tk::Frame' && $_->packForget for $self->{TOP}->packSlaves;

  $self->{PARENT}->pack(qw/-fill both -expand 1/);
  $self->{SHARED}{HIERLABEL}->configure(-text => $self->{LEVEL});

  #$self->{CV}->pack(qw/-side left -fill both -expand 1/);
  $self->{SHARED}{CUROBJ} = $self;
  return $self;
}

#####################
#
# This calls the proper form in ZooZ::Forms to configure
# the given widget.
#
#####################

sub configureWidget {
  my ($self, $lab, $noforce) = @_;

  if (ref $lab) { # a widget
    my ($r, $c) = @{$self->{LABEL2GRID}{$lab}};
    my $ref     = $self->{GRID}[$r][$c];

    ZooZ::Forms->configureWidget(
				 $self,
				 $self->{PARENT},
				 $self->{PROJID},
				 $ref ->{NAME},
				 $ref ->{PREVIEW},
				 $ref ->{WCONF},
				 $ref ->{PCONF},
				 $ref ->{ECONF},
				 $noforce,
				 exists $scrollable{$ref->{WIDGET}},
				);
  } else {
    # MainWindow.
    my $ref = $self->{MWPROPS};
    ZooZ::Forms->configureWidget(
				 $self,
				 $self->{PARENT},
				 $self->{PROJID},
				 $ref ->{NAME},
				 $ref ->{PREVIEW},
				 $ref ->{WCONF},
				 undef,
				 undef,
				 $noforce,
				 0,
				);
  }
}

#################################
#
# This duplicates the placement options of the
# selected widget, according to the given
# argument. It is called from Forms.pm
#
#################################

sub duplicatePlacementOptions {
  my ($self, $r_how) = @_;

  # get the configuration options of the selected widget.
  my $lab     = $self->{SELECTED};
  my ($r, $c) = @{$self->{LABEL2GRID}{$lab}};
  my $opt     = $self->{GRID}[$r][$c]{PCONF};

  # get a list of the widgets to apply the options to.
  my $how = $$r_how;
  my @list;    # keep list of all widgets.
  if      ($how eq 'All Widgets') {
    for my $l (keys %{$self->{LABEL2GRID}}) {
      next if $l eq $lab;  # stringified
      next if $l eq $lab;

      my ($r, $c) = @{$self->{LABEL2GRID}{$l}};
      push @list => $self->{GRID}[$r][$c]{PCONF};
    }
  } elsif ($how eq 'Similar Widgets') {
    my $me = $self->{GRID}[$r][$c]{WIDGET};

    for my $l (keys %{$self->{LABEL2GRID}}) {
      next if $l eq $lab;  # stringified

      my ($r, $c) = @{$self->{LABEL2GRID}{$l}};
      my $ref     = $self->{GRID}[$r][$c];

      next unless $ref->{WIDGET} eq $me;

      push @list => $self->{GRID}[$r][$c]{PCONF};
    }
  } elsif ($how eq 'All Widgets in Same Row') {
    for my $l (keys %{$self->{LABEL2GRID}}) {
      next if $l eq $lab;  # stringified

      my ($r2, $c2) = @{$self->{LABEL2GRID}{$l}};
      next unless $r2 == $r;

      push @list => $self->{GRID}[$r2][$c2]{PCONF};
    }
  } elsif ($how eq 'All Widgets in Same Column') {
    for my $l (keys %{$self->{LABEL2GRID}}) {
      next if $l eq $lab;  # stringified

      my ($r2, $c2) = @{$self->{LABEL2GRID}{$l}};
      next unless $c2 == $c;

      push @list => $self->{GRID}[$r2][$c2]{PCONF};
    }
  } elsif ($how eq 'Similar Widgets in Same Row') {
    my $me = $self->{GRID}[$r][$c]{WIDGET};

    for my $l (keys %{$self->{LABEL2GRID}}) {
      next if $l eq $lab;  # stringified

      my ($r2, $c2) = @{$self->{LABEL2GRID}{$l}};
      next unless $r2 == $r;

      my $ref       = $self->{GRID}[$r2][$c2];
      next unless $ref->{WIDGET} eq $me;

      push @list => $ref->{PCONF};
    }
  } elsif ($how eq 'Similar Widgets in Same Column') {
    my $me = $self->{GRID}[$r][$c]{WIDGET};

    for my $l (keys %{$self->{LABEL2GRID}}) {
      next if $l eq $lab;  # stringified

      my ($r2, $c2) = @{$self->{LABEL2GRID}{$l}};
      next unless $c2 == $c;

      my $ref       = $self->{GRID}[$r2][$c2];
      next unless $ref->{WIDGET} eq $me;

      push @list => $ref->{PCONF};
    }
  } else {
    # WHAT? Impossible!!
  }

  for my $p (@list) {
    $p->{$_} = $opt->{$_} for qw/-sticky -ipadx -ipady -padx -pady n s e w/;
  }
}

##################
#
# Called by ZooZ.pl. Simple wrapper around configureWidget()
#
##################

sub configureSelectedWidget {
  my $self = $_[0]{SHARED}{CUROBJ};

  @_ = ($self, $self->{SELECTED}, $_[1] || 0);
  goto &configureWidget;
}

#####################
#
# This calls the proper form in ZooZ::Forms to configure
# the given row.
#
#####################

sub configureRow {
  my ($self, $row) = @_;

  ZooZ::Forms->configureRowCol(
			       $self->{PROJID},
			       $self->{LEVEL},
			       $self->{PREVIEW},
			       row => $row,
			       $self->{ROWOPT},
			      );
}

#####################
#
# This calls the proper form in ZooZ::Forms to configure
# the given column.
#
#####################

sub configureCol {
  my ($self, $col) = @_;

  ZooZ::Forms->configureRowCol(
			       $self->{PROJID},
			       $self->{LEVEL},
			       $self->{PREVIEW},
			       col => $col,
			       $self->{COLOPT},
			      );
}

#############################
#
# Method that loads the row/col constraints when loading a project.
#
#############################

sub loadRowCol {
  my ($self,
      $rowOrCol,
      $num,
      %data) = @_;

  my $top = delete $data{Parent};

  if ($top ne 'MainWindow') {
    $top = $self->{SHARED}{NAME2LABEL}{$top};
  }

  my $obj    = $self->{SHARED}{SUBHIERS}{$top};
  my $method = $rowOrCol eq 'Row'? 'gridRowconfigure' : 'gridColumnconfigure';

  $obj->{PREVIEW}->$method($num, %data);
  $obj->{uc($rowOrCol) . "OPT"}[$num]{$_} = $data{$_} for keys %data;
}

#############################
#
# Method to save project to file.
#
#############################

sub save {
  my ($self, $fh, $parent) = @_;

  # If it's the mainwindow, then save off the mw attributes.
#  unless ($self->{ISCHILD}) {
#    print $fh "[MainWindow]\n";
#    print $fh "Title ", $self->{PREVIEW}->title, "\n";
#  }

  $parent ||= 'MainWindow';

  for my $lab (MainWindow => keys %{$self->{LABEL2GRID}}) {
    my $ref;

    if ($lab eq 'MainWindow') {
      next if $self->{ISCHILD};

      $ref            = $self->{MWPROPS};
      print $fh "[MainWindow]\n";
      print $fh "Title ", $self->{PREVIEW}->title, "\n";

    } else {
      my ($row, $col) = @{$self->{LABEL2GRID}{$lab}};
      $ref            = $self->{GRID}[$row][$col];

      # print the basic info.
      print $fh <<EOT;
\[Widget $ref->{NAME}\]
Parent   $parent
Type     $ref->{WIDGET}
Row      $row
Col      $col
Rowspan  $ref->{ROWS}
Colspan  $ref->{COLS}
EOT
  ;
    }

    # now the options.
    for my $h (qw/WCONF PCONF ECONF/) {
      next unless defined $ref->{$h};

      for my $k (sort keys %{$ref->{$h}}) {
	next if $h eq 'PCONF' && $k =~ /^[nsew]$/;

	# consider only the ones that changed.
	my $tiedObj = tied $ref->{$h}{$k};
	next if $tiedObj && ref($tiedObj) eq 'ZooZ::TiedVar' && !$tiedObj->{C};
	
	my $v = $ref->{$h}{$k};

	# special treatment for images.
	# and for callbacks.

	if ($h eq 'WCONF' && $v && exists $ZooZ::Options::options{$k} &&
	    $ZooZ::Options::options{$k}[0] eq 'Image') {

	  eval {$v = $ref->{$h}{$k}->cget('-file')};

	} elsif ($h eq 'WCONF' && $v && exists $ZooZ::Options::options{$k} &&
		 $ZooZ::Options::options{$k}[0] eq 'Callback') {

	  $v = $::CALLBACKOBJ->code2name($v);
	  $v = '\&' . $v;
	} elsif ($h eq 'WCONF' && $v && exists $ZooZ::Options::options{$k} &&
		 $ZooZ::Options::options{$k}[0] eq 'VarRef') {

	  $v = "\\" . $::VARREFOBJ->ref2name($v);
	}

	$v = 'undef' unless defined $v;

	print $fh "$h  $k  $v\n";
      }
    }

    print $fh "[End Widget]\n\n";

    # if a container, then call recursively.
    if ($lab ne 'MainWindow' && exists $self->{SHARED}{SUBHIERS}{$lab}) {
      $self->{SHARED}{SUBHIERS}{$lab}->save($fh, $ref->{NAME});
    }
  }

  # Now spit out any row/col configurations ..
  {
    my ($cols, $rows) = $self->{PREVIEW}->gridSize;

    # first the columns.
    for my $col (0 .. $cols - 1) {
      # get the minsize/weight/pad data.
      my %data = $self->{PREVIEW}->gridColumnconfigure($col);

      my $data = join "\n" => map "$_\t$data{$_}" => grep $data{$_} => keys %data;
      $data or next;

      print $fh <<EOCOL;
\[Col $col\]
Parent $parent
$data
\[End Col\]

EOCOL
  ;
    }

    # then the rows.
    for my $row (0 .. $rows - 1) {
      # get the minsize/weight/pad data.
      my %data = $self->{PREVIEW}->gridRowconfigure($row);

      my $data = join "\n" => map "$_\t$data{$_}" => grep $data{$_} => keys %data;
      $data or next;

      print $fh <<EOROW;
\[Row $row\]
Parent $parent
$data
\[End Row\]

EOROW
  ;
    }
  }

}


#####################
#
# This method is called by ZooZ.pl when
# loading a project. It loads a single widget
# and updates its configuration.
# code dupe and UGLY :(
#
#####################

sub loadWidget {
  my ($self, $data) = @_;

  my $nam = delete $data->{NAME};
  my $row = delete $data->{Row};
  my $col = delete $data->{Col};
  my $top = delete $data->{Parent};
  my $typ = delete $data->{Type};
  my $rsp = delete $data->{Rowspan};
  my $csp = delete $data->{Colspan};

  # create widget in which object?
  if ($top ne 'MainWindow') {
    $top = $self->{SHARED}{NAME2LABEL}{$top};
  }

  my $obj = $self->{SHARED}{SUBHIERS}{$top};

  # create the widget.
  my $ref = $obj->{GRID}[$row][$col];
  $ref->{WIDGET} = $typ;
  $obj->{SHARED}{IDS}{$typ}++;

  # get coordinates of window.
  my $cv = $obj->{CV};
  my @c  = $cv->coords("GRID_$ {row}_$ {col}");
  my $w  = $c[2] - $c[0];
  my $h  = $c[3] - $c[1];

  # create the label and window.
  my $frame = $cv->Frame(-relief => 'raised', -bd => 1);
  my $label = $frame->Label->pack(qw/-fill both -expand 1/);

  $ref->{WINDOW} = $cv->createWindow($c[0] + $w / 2,
				     $c[1] + $h / 2,
				     -window => $frame,
				     -width  => $w,
				     -height => $h,
				    );

  $ref ->{NAME}                     = $nam;
  $ref ->{LABEL}                    = $label;
  $ref ->{LABFRAME}                 = $frame;
  $ref ->{ROWS}                     = 1;
  $ref ->{COLS}                     = 1;
  $ref ->{PCONF}                    = {};
  $ref ->{WCONF}                    = {};
  $ref ->{ECONF}                    = {};
  $obj ->{LABEL2GRID}{$label}       = [$row, $col];
  $obj ->{SHARED}{NAME2LABEL}{$nam} = $label;

  # create the compound image to place in the label.
  my $compound = $label->Compound;
  $label->configure(-image => $compound);
  if (exists $self->{ICONS}{lc $typ}) {
    $compound->Image(-image => $self->{ICONS}{lc $typ});
  } else {
    $compound->Bitmap(-bitmap => 'error');
  }
  $compound->Line;
  $compound->Text(-text => $nam,
		  -font => 'WidgetName',
		 );

  $obj->_bindWidgetLabel($label);

  # create the actual preview widget.
  my $type = $typ eq 'Image' ? 'Label' : $typ;
  my $args = ZooZ::DefaultArgs->getDefaultWidgetArgs($typ, $nam);

  # Convert all frames to Panes.
  #$type = 'Pane' if $type eq 'Frame';

  # Make it Scrolled .. just for the preview.
  if (exists $scrollable{$type}) {
    $ref->{PREVIEW} = $obj->{PREVIEW}->Scrolled($type,
						-scrollbars => '',
						%$args
					       );
    #print "scrolled = ", $ref->{PREVIEW}->Subwidget(lc $type)->configure(%$args), ".\n";
    #print "Propagate = ", $ref->{PREVIEW}->Subwidget(lc $type)->gridPropagate, ".\n";
  } else {
    $ref->{PREVIEW} = $obj->{PREVIEW}->$type(%$args);
  }

  # add to the hier tree
  $obj->{TREE}->add($obj->{HIERTOP} . '.' . $label, -text => $nam,
		    $typ =~ $isContainer ? (-style => 'container') : ()
		   );
  $obj->{TREE}->autosetmode;

  # if it's a container, create the notebook tab for it.
  if ($typ =~ $isContainer) {

    my $proj = $obj->new(-id         => $obj->{PROJID},
			 -top        => $obj->{TOP},
			 -name       => $obj->{PROJNAME},
			 -title      => $obj->{TITLE},
			 -icons      => $obj->{ICONS},
			 -hiertop    => "$obj->{HIERTOP}.$label",
			 -ischild    => 1,
			 -tree       => $obj->{TREE},
			 -preview    => $obj->{GRID}[$row][$col]{PREVIEW},
			 -level      => "$obj->{LEVEL}.$obj->{GRID}[$row][$col]{NAME}",
			 -shared     => $obj->{SHARED},
			);

    $obj->{SHARED}{SUBHIERS}{$label} = $proj;
  }

  # update all the configuration options.
  # we need to do this twice. Once before selecteWidget()
  # and again after. The reason is that selectWidget calls
  # the callbacks form in ZooZ::Forms which sets up the ties.
  # we need the vars updated BEFORE to update some option labels.
  # we need the vars updated AFTER to make sure everything reflects
  # properly (configure is called by the tieing class).

  for my $h (qw/WCONF PCONF/) {
    for my $k (keys %{$data->{$h}}) {

      if ($h eq 'PCONF' && $k eq '-sticky') {
	$ref->{$h}{$1} = $1 while $data->{$h}{$k} =~ /(.)/g;
      }

      $ref->{$h}{$k} = $data->{$h}{$k};
    }
  }

  # select it
  $obj->selectWidget($label);

  # update again.
  # no need to update [nsew] since they are not tied.
  !/^[nsew]$/ and $ref->{PCONF}{$_} = $data->{PCONF}{$_} for keys %{$ref->{PCONF}};

  for my $k (keys %{$ref->{WCONF}}) {
    my $v = $data->{WCONF}{$k};

    if ($v && $ZooZ::Options::options{$k}[0] eq 'Callback') {
      $v =~ y/\\&//d;
      $v = eval "\\&$v";

    } elsif ($v && $ZooZ::Options::options{$k}[0] eq 'Image') {
      if      ($v =~ /\.(?:gif|pgm|ppm)$/) {
	$v = $self->{PARENT}->Photo(-file => $v);
      } elsif ($v =~ /\.bmp$/) {
	$v = $self->{PARENT}->Bitmap(-file => $v);
      } elsif ($v =~ /\.xpm$/) {
	$v = $self->{PARENT}->Pixmap(-file => $v);
      } else { # reset
	$v = 'image-zooz';
      }

    } elsif ($v && $ZooZ::Options::options{$k}[0] eq 'VarRef') {
      no strict;
      $v =~ s/^..//;
      $v = \$ {"main::$v"};
    }

    $ref->{WCONF}{$k} = $v if defined $v;
  }

  for my $k (keys %{$ref->{ECONF}}) {
    my $v = $data->{ECONF}{$k};

    $ref->{ECONF}{$k} = $v if $v;
  }

  # make sure it is of the proper span.
  $obj->resizeWidget('EXPAND_H') for 1 .. $csp - 1;
  $obj->resizeWidget('EXPAND_V') for 1 .. $rsp - 1;

  # must update the preview window.
  $obj->updatePreviewWindow;

  # add it to the global hash.
  $obj->{SHARED}{ALL_WIDGETS}{$nam} = $ref->{PREVIEW};
}

#################
#
# This method takes a filehandle as input and dumps
# the Perl code for every widget in the project.
#
#################

sub dumpPerl {
  my ($self, $fh, $module, $parent) = @_;

  $parent ||= '$MW';

  my $spaces = $module ? '  ' : '';

  # initialize image controls.
  $self->{SHARED}{IMAGES}   ||= {};
  $self->{SHARED}{IMAGEIDS} ||= 0;

  # sort by col then row number.
  for my $lab (sort
	       {
		 $self->{LABEL2GRID}{$a}[1] <=> $self->{LABEL2GRID}{$b}[1]
		   or
		 $self->{LABEL2GRID}{$a}[0] <=> $self->{LABEL2GRID}{$b}[0];

	       } keys %{$self->{LABEL2GRID}}) {

    my ($row, $col) = @{$self->{LABEL2GRID}{$lab}};
    my $ref         = $self->{GRID}[$row][$col];

    # change image types to labels.
    my $type        = $ref->{WIDGET};
    $type           = 'Label' if $type eq 'Image';

    my @pairs;

    # Is it scrolled?
    if ($ref->{ECONF}{SCROLLON}) {

      # where to place the scrollbars?
      my $sloc = '';
      for my $dir (qw/H V/) {
	next unless $ref->{ECONF}{"$ {dir}SCROLLLOC"};
	$sloc .= 'o' if $ref->{ECONF}{"$ {dir}OPTIONAL"};
	$sloc .= $ref->{ECONF}{"$ {dir}SCROLLLOC"};
      }

      print $fh "

$spaces# Widget $ref->{NAME} isa $ref->{WIDGET}
$spaces\$ZWIDGETS{'$ref->{NAME}'} = $parent->Scrolled('$type',";

      push @pairs => [-scrollbars => "'$sloc'"];

    } else {
      print $fh "

$spaces# Widget $ref->{NAME} isa $ref->{WIDGET}
$spaces\$ZWIDGETS{'$ref->{NAME}'} = $parent->$type(";
    };

    for my $k (sort keys %{$ref->{WCONF}}) {

      # consider only the ones that changed.
      my $tiedObj = tied $ref->{WCONF}{$k};
      next if $tiedObj && ref($tiedObj) eq 'ZooZ::TiedVar' && !$tiedObj->{C};

      # Now get the value and ignore any undefined values.
      my $v = $ref->{WCONF}{$k};
      next unless defined $v && $v =~ /./;  # match 0

      # handle special cases:
      # 1. Image
      # 2. Callback
      # 3. Variable ref.

      if ($v && exists $ZooZ::Options::options{$k} &&
	  $ZooZ::Options::options{$k}[0] eq 'Image') {

	next if $v eq 'image-zooz'; # empty image.

	eval {$v = $ref->{WCONF}{$k}->cget('-file')};
	my $imageName;

	if (exists $self->{SHARED}{IMAGES}{$v}) {
	  $imageName = $self->{SHARED}{IMAGES}{$v};
	} else {
	  $imageName = "Zimage" . $self->{SHARED}{IMAGEIDS}++;
	  $self->{SHARED}{IMAGES}{$v} = $imageName;
	}

	$v = $imageName;
      } elsif ($v && exists $ZooZ::Options::options{$k} &&
	       $ZooZ::Options::options{$k}[0] eq 'Callback') {

	$v = $::CALLBACKOBJ->code2name($v);

      } elsif ($v && exists $ZooZ::Options::options{$k} &&
	       $ZooZ::Options::options{$k}[0] eq 'VarRef') {

	$v = "\\" . $::VARREFOBJ->ref2name($v);
	$v =~ s/main:://;
      }

      # quote it if it's a bareword. IE. Unless it's a ref or a number.
      $v =~ s/'/\\'/g, $v = "'$v'" unless $v =~ m{
						  ^[-\d]+$   # a number
						  |
						  ^\\       # a reference
						 }x;

      push @pairs => [$k, $v];
    }

    if (@pairs) {
      print $fh "\n", ZooZ::Generic::lineUpCommas(@pairs), "\n  )->grid(";

    } else {
      print $fh ")->grid(";
    }

    # Now place it via grid().
    @pairs = ([-row    => $row],
	      [-column => $col],
	     );

    push @pairs => [-rowspan    => $ref->{ROWS}] if $ref->{ROWS} > 1;
    push @pairs => [-columnspan => $ref->{COLS}] if $ref->{COLS} > 1;

    $ref->{PCONF}{$_} &&
      push @pairs => [$_ => $ref->{PCONF}{$_} =~ /^\d+$/ ?
		      $ref->{PCONF}{$_} : "'$ref->{PCONF}{$_}'"
		     ] for qw/-sticky -ipadx -ipady -padx -pady/;

    print $fh "\n", ZooZ::Generic::lineUpCommas(@pairs), "\n  );";

    # if a container, then call recursively.
    if (exists $self->{SHARED}{SUBHIERS}{$lab}) {
      $self->{SHARED}{SUBHIERS}{$lab}->dumpPerl($fh, $module, '$ZWIDGETS{' . $ref->{NAME} . '}');
    }
  }

  # Now output any row/col specific options like greediness, etc ..
  {
    my ($cols, $rows) = $self->{PREVIEW}->gridSize;

    # first the columns.
    for my $col (0 .. $cols - 1) {
      # get the minsize/weight/pad data.
      my %data = $self->{PREVIEW}->gridColumnconfigure($col);

      my @data = map [$_, $data{$_}] => grep $data{$_} => keys %data;
      @data or next;

      print $fh "\n$spaces$parent->gridColumnconfigure($col,\n",
	ZooZ::Generic::lineUpCommas(@data), "\n  );\n";
    }

    # then the rows.
    for my $row (0 .. $rows - 1) {
      # get the minsize/weight/pad data.
      my %data = $self->{PREVIEW}->gridRowconfigure($row);

      my @data = map [$_, $data{$_}] => grep $data{$_} => keys %data;
      @data or next;

      print $fh "\n$spaces$parent->gridRowconfigure($row,\n",
	ZooZ::Generic::lineUpCommas(@data), "\n  );\n";
    }
  }
}

#############
#
# This method is called when a user closes a project.
# It destroys everything.
#
#############

sub closeMe {
  my $self = shift;

  $_ = undef for values %{$self->{SHARED}{SUBHIERS}};

  # did I miss anything?
}

#############
#
# This method returns the images used in the project.
#
#############

sub getImageHash { $_[0]{SHARED}{IMAGES} }

#############
#
# Sub to rename a widget.
#
#############

sub renameWidget {
  my ($self, $oldName, $newName) = @_;

  return 0 unless        $newName;
  return 0 unless exists $self->{SHARED}{NAME2LABEL}{$oldName};
  return 0 if     exists $self->{SHARED}{NAME2LABEL}{$newName};

  # modify the db's keys and values.
  my $lab     = $self->{SHARED}{NAME2LABEL}{$newName}
              = delete $self->{SHARED}{NAME2LABEL}{$oldName};
  my ($r, $c) = @{$self->{LABEL2GRID}{$lab}};

  $self->{GRID}[$r][$c]{NAME}            = $newName;
  $self->{SHARED}{ALL_WIDGETS}{$newName} = delete $self->{SHARED}{ALL_WIDGETS}{$oldName};

  # update the tree text.
  $self->{TREE}->entryconfigure($self->{HIERTOP} . '.' . $lab,
				-text => $newName);

  # update the Icon label.
  {
    my $w = lc $self->{GRID}[$r][$c]{WIDGET};

    my $c = $lab->Compound;
    if (exists $self->{ICONS}{$w}) {
      $c->Image(-image => $self->{ICONS}{$w});
    } else {
      $c->Bitmap(-bitmap => 'error');
    }
    $c->Line;
    $c->Text(-text => $newName,
	     -font => 'WidgetName',
	    );
    my $o = $lab->cget('-image');
    $lab->configure(-image => $c);
    $o->destroy;
  }

  return 1;
}

#######################
#
# rename the project. Just symbolic.
#
#######################

sub renameProject {
  my ($self, $newName) = @_;

  $_->{PROJNAME} = $_->{TITLE} = $newName for values %{$self->{SHARED}{SUBHIERS}};

  $self->{PREVIEW}->title($newName);
}

###########################
#
# configure the main window preview
# based on the configuration in the .zooz file
#
###########################

sub setMW {
  my ($self, $args) = @_;

  my $t = delete $args->{title};

  $self->{PREVIEW}->configure(%$args);
  $self->{PREVIEW}->title($t) if defined $t;
}

##############################
#
# Data structures:
#
# $self->{TREE}                          = Hierarchy Tree.
# $self->{CV}                            = canvas object.
#
# $self->{GRID}[$row][$column]{ID}       = canvas ID of rectangle.
# $self->{GRID}[$row][$column]{WIDGET}   = Type of widget in that grid (if any).
# $self->{GRID}[$row][$column]{WINDOW}   = ID of canvas window object (if any).
# $self->{GRID}[$row][$column]{LABEL}    = Label of widget (what is inside the window)
# $self->{GRID}[$row][$column]{NAME}     = Name of widget (unique)
# $self->{GRID}[$row][$column]{LABFRAME} = frame widget where LABEL is
# $self->{GRID}[$row][$column]{ROWS}     = number of rows widget is occupying
# $self->{GRID}[$row][$column]{COLS}     = number of cols widget is occupying
# $self->{GRID}[$row][$column]{MASTER}   = label of widget in the top left grid
# $self->{GRID}[$row][$column]{PREVIEW}  = preview widget object
# $self->{GRID}[$row][$column]{WCONF}    = hash of widget configuration options.
# $self->{GRID}[$row][$column]{PCONF}    = hash of widget placement options.
# $self->{GRID}[$row][$column]{ECONF}    = hash of extra widget options.
#
# $self->{LABEL2GRID}{$label}            = [row, col] of labels of widgets
# $self->{SHARED}{NAME2LABEL}{$name}     = $label of widget
#
# $self->{DRAG_OUTLINE}                  = ID of dummy rectangle when moving widgets.
#
# $self->{EXPAND_H}                      = ID of resize button
# $self->{EXPAND_V}                      = ID of resize button
# $self->{CONTRACT_H}                    = ID of resize button
# $self->{CONTRACT_V}                    = ID of resize button
#
# $self->{SHARED}{CUROBJ}                = project object of currently visible hierarchy.
#                                          This is the project with the visible canvas.
# $self->{TREE}                          = hierarchy list
# $self->{SHARED}{SUBHIERS}{$label}      = project object of container widgets only.
# $self->{PREVIEW}                       = Toplevel (or parent frame) of preview window.
# $self->{LEVEL}                         = which hier level this object is at
#
# $self->{SHARED}{ALL_WIDGETS}{$name}    = Preview widget. For use in callbacks by users.
#
# $self->{ROWOPT}                        = hash of row config options.
# $self->{COLOPT}                        = hash of col config options.
#

1;
