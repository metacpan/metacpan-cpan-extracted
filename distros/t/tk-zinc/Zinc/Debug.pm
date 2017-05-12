#        Tk::Zinc::Debug Perl Module :
#
#        For debugging/analysing a Zinc application.
#
#        Author : Daniel Etienne <etienne@cena.fr>
#
# $Id: Debug.pm,v 1.58 2005/05/12 15:51:12 etienne Exp $
#---------------------------------------------------------------------------
package Tk::Zinc::Debug;

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.58 $ =~ /(\d+)\.(\d+)/);

use strict 'vars';
use vars qw(@ISA @EXPORT @EXPORT_OK $WARNING $endoptions);
use Carp;
use English;
require Exporter;
use File::Basename;
use Tk::Dialog;
use Tk::Tree;
use Tk::ItemStyle;
use Tk::Pane;
use Tk::FBox;
use Tk::Balloon;

@ISA = qw(Exporter);
@EXPORT = qw(finditems snapshot tree init);
@EXPORT_OK = qw(finditems snapshot tree init);

my ($itemstyle, $groupstyle, $step);
my (%result_tl, $result_fm, $search_tl, $helptree_tl, %coords_tl, %transfo_tl,
    $helpcoords_tl, $searchtree_tl, $tree_tl, %alloptions_tl, $tree,
    $cursorxy_tl, $cursorxy);
my $showitemflag;
my ($x0, $y0);
my ($help_print, $imagecounter, $saving) = (0, 0, 0);
my %searchEntryValue;
my $searchTreeEntryValue;
my %wwidth;
my %wheight;
my $preload;
my %defaultoptions;
my %instances;
my @instances;
my %cmdoptions;
my $initobjectfunction;
my %userbindings;
my $selectedzinc;
my $control_tl;
my %button;
my %on_command;
my %off_command;
my @znpackinfo;
my $screenwidth;
my $balloonhelp;
#---------------------------------------------------------------------------
#
# Initialisation functions for plugin usage
#
#---------------------------------------------------------------------------

# Hack to overload the Tk::Zinc::InitObject method
#
BEGIN {
    
    # test if Tk::Zinc::Debug is loaded using the -M perl option
    $preload = 1 if (caller(2))[2] == 0;
    return unless $preload;
    # parse Tk::Zinc::Debug options
    require Getopt::Long;
    Getopt::Long::Configure('pass_through');
    Getopt::Long::GetOptions(\%cmdoptions, 'optionsToDisplay=s', 'optionsFormat=s',
			     'snapshotBasename=s', 'expandTagsField=i');
    # save current Tk::Zinc::InitObject function; it will be invoked in
    # overloaded one (see below)
    use Tk;
    use Tk::Zinc;
    $initobjectfunction = Tk::Zinc->can('InitObject');
    
} # end BEGIN


# Hack to capture the instance(s) of zinc. Tk::Zinc::Debug init function
# is invoked here.
#
sub Tk::Zinc::InitObject {
    
    # invoke function possibly overloaded in other modules
    &$initobjectfunction(@_) if $initobjectfunction;
    return unless $preload;
    my $zinc = $_[0];
    &init($zinc);
   
} # end Tk::Zinc::InitObject


#---------------------------------------------------------------------------
#
# Initialisation function
#
#---------------------------------------------------------------------------

sub init {

    my $zinc = shift;
    $screenwidth = $zinc->screenwidth;
    my %options = @_;
    for my $opt (keys(%options)) {
        carp "in Tk::Zinc::Debug initialisation function, unknown option $opt\n"
            unless $opt eq '-optionsToDisplay' or $opt eq '-optionsFormat'
		or $opt eq '-snapshotBasename' or $opt eq '-expandTagsField' ;
    }
    $cmdoptions{optionsToDisplay} = $options{-optionsToDisplay} if
	not defined $cmdoptions{optionsToDisplay} and
	    defined $options{-optionsToDisplay};
    $cmdoptions{optionsFormat} = $options{-optionsFormat} if
	not defined $cmdoptions{optionsFormat} and
	    defined $options{-optionsFormat};
    $cmdoptions{snapshotBasename} = $options{-snapshotBasename} if
	not defined $cmdoptions{snapshotBasename} and
	    defined $options{-snapshotBasename};
    $cmdoptions{expandTagsField} = $options{-expandTagsField} if
	not defined $cmdoptions{expandTagsField} and
	    defined $options{-expandTagsField};
	
    &newinstance($zinc);
    return if Tk::Exists($control_tl);
    print "Tk::Zinc::Debug is ON\n";
    my $bitmaps = &createBitmaps($zinc);
    $control_tl = $zinc->Toplevel;
    $control_tl->title("Tk::Zinc::Debug (V $VERSION)");
    my $fm1 = $control_tl->Frame()->pack(-side => 'left', -padx => 0);
    my $fm2 = $control_tl->Frame()->pack(-side => 'left', -padx => 20);
    my $fm3 = $control_tl->Frame()->pack(-side => 'left', -padx => 0);
    
    for (qw(zn findenclosed findoverlap tree item id snapshot cursorxy)) {
	$button{$_} = $fm1->Checkbutton(-image => $bitmaps->{$_},
					-indicatoron => 0,
					-foreground => 'gray20')->pack(-side => 'left');
    }
    for (qw(zoomminus zoomplus move)) {
	$button{$_} = $fm2->Checkbutton(-image => $bitmaps->{$_},
					-indicatoron => 0,
					-foreground => 'gray20')->pack(-side => 'left');
    }
    for (qw(balloon close)) {
	$button{$_} = $fm3->Checkbutton(-image => $bitmaps->{$_},
					-indicatoron => 0,
					-foreground => 'gray20')->pack(-side => 'left');
    }
    my $bg = $button{zn}->cget(-background);
    for (values(%button)) {
	$_->configure(-selectcolor => $bg);
    }
    $balloonhelp = &balloonhelp();
    $button{balloon}->toggle;
    $control_tl->withdraw();
    $button{zn}->configure(-command => \&focuscommand);
    $button{balloon}->configure(-command => sub {
				    if ($button{balloon}->{Value} == 0) {
					$balloonhelp->configure(-state => 'none');
				    } else {
					$balloonhelp->configure(-state => 'balloon');
				    }
			 });
    #--------------------------------------------------
    # on/off commands for exclusive modes :
    #--------------------------------------------------
    
    # findenclosed mode
    $on_command{findenclosed} = sub {
	&saveDragAndDropBindings($selectedzinc);
	$button{findenclosed}->{Value} = 1;
	$selectedzinc->Tk::bind("<ButtonPress-1>",
				[\&startrectangle, 'simple', 'Enclosed',
				       'sienna']);
	$selectedzinc->Tk::bind("<B1-Motion>", \&resizerectangle);
	$selectedzinc->Tk::bind("<ButtonRelease-1>",
				[\&stoprectangle, 'enclosed',
				 'Items enclosed in rectangle']);
    };
    $off_command{findenclosed} = sub {
	$button{findenclosed}->{Value} = 0;
	&restoreDragAndDropBindings($selectedzinc);
	$selectedzinc->remove("zincdebugrectangle", "zincdebuglabel");
    };
    # findoverlap mode
    $on_command{findoverlap} = sub {
	&saveDragAndDropBindings($selectedzinc);
	$button{findoverlap}->{Value} = 1;
	$selectedzinc->Tk::bind("<ButtonPress-1>", [\&startrectangle, 'mixed',
						    'Overlap', 'sienna']);
	$selectedzinc->Tk::bind("<B1-Motion>", \&resizerectangle);
	$selectedzinc->Tk::bind("<ButtonRelease-1>",
				[\&stoprectangle, 'overlapping',
				 'Items which overlap rectangle']);
    };
    $off_command{findoverlap} = sub {
	$button{findoverlap}->{Value} = 0;
	&restoreDragAndDropBindings($selectedzinc);
	$selectedzinc->remove("zincdebugrectangle", "zincdebuglabel");
    };
    # item mode
    $on_command{item} = sub {
	&saveDragAndDropBindings($selectedzinc);
	$button{item}->{Value} = 1;
	$selectedzinc->Tk::bind("<ButtonPress-1>", [\&findintree]);
    };
    $off_command{item} = sub {
	$button{item}->{Value} = 0;
	&restoreDragAndDropBindings($selectedzinc);
    };
    # cursor device position mode
    $on_command{cursorxy} = sub {
	&saveMotionBinding($selectedzinc);
	$button{cursorxy}->{Value} = 1;
	&cursorxyOpen;
	$selectedzinc->Tk::bind("<Motion>", [\&cursorxy]);
    };
    $off_command{cursorxy} = sub {
	$button{cursorxy}->{Value} = 0;
	&cursorxyClose;
	&restoreMotionBinding($selectedzinc);
    };
    
    # move mode
    $on_command{move} = sub {
	&saveDragAndDropBindings($selectedzinc);
	$button{move}->{Value} = 1;
	my ($x0, $y0);
	$selectedzinc->Tk::bind('<ButtonPress-1>', sub {
	    my $ev = $selectedzinc->XEvent;
	    ($x0, $y0) = ($ev->x, $ev->y);
	});
	$selectedzinc->Tk::bind('<B1-Motion>', sub {
	    my $ev = $selectedzinc->XEvent;
	    my ($x, $y) = ($ev->x, $ev->y);
	    $selectedzinc->translate(1, $x-$x0, $y-$y0) if defined $x0;
	    ($x0, $y0) = ($x, $y);
	});
    };
    $off_command{move} = sub {
	$button{move}->{Value} = 0;
	&restoreDragAndDropBindings($selectedzinc);
    };
    # zn mode
    $on_command{zn} = sub {
	$button{zn}->{Value} = 1;
	for my $zinc (&instances) {
	    $zinc->remove("zincdebugrectangle", "zincdebuglabel");
	    &saveDragAndDropBindings($zinc);
	    my $r;
	    $zinc->Tk::bind("<ButtonPress-1>", sub {
		$zinc->update;
		my ($w, $h) = ($zinc->cget(-width), $zinc->cget(-height));
		$zinc->tsave(1, 'transfoTopgroup', 1);
		$r = $zinc->add('rectangle', 1, [30, 30, $w-30, $h-30],
				-linecolor => 'red',
				-linewidth => 10);
		$zinc->trestore($r, 'transfoTopgroup');
		$zinc->raise($r);
		$selectedzinc = $zinc;
	    });
	    $zinc->Tk::bind("<ButtonRelease-1>", sub {
		$zinc->remove($r);
	    });
	}
    };
    $off_command{zn} = sub {
	$button{zn}->{Value} = 0;
        for my $zinc (&instances) {
	    &restoreDragAndDropBindings($zinc);
	}
    };

    my @but = qw(findenclosed findoverlap item move zn cursorxy);
    for my $name (@but) {
	$button{$name}->configure(-command => sub {
	    if ($button{$name}->{Value} == 1) {
		for my $other (@but) {
		    &{$off_command{$other}} unless $other eq $name;
		}
	    &{$on_command{$name}};
	    } else {
		&{$off_command{$name}};
	    }});
    }

    $button{id}->configure(-command => sub {
	$button{id}->update;
	&searchentry($zinc);
	$button{id}->toggle;
    });
    
    $button{snapshot}->configure(-command => sub {
	$button{snapshot}->update;
	&printWindow($zinc);
	$button{snapshot}->toggle;
    });
    
    $button{zoomminus}->configure(-command => sub {
	$button{zoomminus}->update;
	my $w = $selectedzinc->cget(-width);
	my $h = $selectedzinc->cget(-height);
	$selectedzinc->translate(1, -$w/2, -$h/2);
	$selectedzinc->scale(1, 1/1.1, 1/1.1);
	$selectedzinc->translate(1, $w/2, $h/2);
	$button{zoomminus}->toggle;
	});
    
    $button{zoomplus}->configure(-command => sub {
	$button{zoomplus}->update;
	my $w = $selectedzinc->cget(-width);
	my $h = $selectedzinc->cget(-height);
	$selectedzinc->translate(1, -$w/2, -$h/2);
	$selectedzinc->scale(1, 1.1, 1.1);
	$selectedzinc->translate(1, $w/2, $h/2);
	$button{zoomplus}->toggle;
	});
        
    $button{tree}->configure(-command => sub {
	$button{tree}->update;
	&showtree($selectedzinc);
	$button{tree}->toggle;
	});
    
    $button{close}->configure(-command => sub {
	$button{close}->update;
	&Tk::Zinc::Debug::iconify;
	&restoreDragAndDropBindings($selectedzinc);
	for my $name (@but) {
	    &{$off_command{$name}};
	}
	$button{close}->toggle;
    });
    
} # end init


#---------------------------------------------------------------------------
#
# Deprecated functions
#
#---------------------------------------------------------------------------

sub tree {
    
    carp "in Tk::Zinc::Debug module, tree() function is deprecated.\n";
    &init($_[0]);
    
} # end tree


sub finditems {
    
    carp "in Tk::Zinc::Debug module, finditems() function is deprecated.\n";
    &init($_[0]);
    
} # end finditems



sub snapshot {
    
    carp "in Tk::Zinc::Debug module, snapshot() function is deprecated.\n";
    &init($_[0]);

} # end snapshot


#---------------------------------------------------------------------------
#
# Functions related to cursor position
#
#---------------------------------------------------------------------------
sub cursorxy {

    my $ev = shift->XEvent;
    $cursorxy = $ev->x.", ".$ev->y;
    
} # end cursorxy


sub cursorxyOpen {

    if (Tk::Exists($cursorxy_tl)) {
	$cursorxy_tl->raise;
	return;
    }
    $cursorxy_tl = $control_tl->Toplevel;
    $cursorxy_tl->Label(-text => "Cursor device position")->pack;
    $cursorxy_tl->Label(-textvariable => \$cursorxy)->pack;
    $cursorxy_tl->minsize(150, 40);
    $cursorxy_tl->raise;
    
} # end cursorxyOpen


sub cursorxyClose {

    $cursorxy_tl->destroy if Tk::Exists($cursorxy_tl);

} # end cursorxyClose


#---------------------------------------------------------------------------
#
# Functions related to items tree
#
#---------------------------------------------------------------------------

# build or rebuild the items tree
sub showtree {
    
    my $zinc = shift;
    my $optionstodisplay = $cmdoptions{optionsToDisplay};
    my $optionsFormat = $cmdoptions{optionsFormat};
    # styles definition
    $itemstyle =
	$zinc->ItemStyle('text', -stylename => "item", -foreground => 'black')
	    unless $itemstyle;
    $groupstyle =
	$zinc->ItemStyle('text', -stylename => "group", -foreground => 'black')
	    unless $groupstyle;

    $WARNING = 0;
    my @optionstodisplay = split(/,/, $optionstodisplay);
    $WARNING = 1;
    &hidetree();
    $tree_tl = $control_tl->Toplevel;
    $tree_tl->minsize(280, 200);
    $tree_tl->title("Zinc Items Tree");
    $tree = $tree_tl->Scrolled('Tree',
			       -scrollbars => 'se',
			       -height => 40,
			       -width => 50,
			       -itemtype => 'text',
			       -selectmode => 'single',
			       -separator => '.',
			       -drawbranch => 1,
			       -indent => 30,
			       -command => sub {
				   my $path = shift;
				   my $item = (split(/\./, $path))[-1];
				   &showresult("Attributes of item $item", $zinc, $item);
				   $zinc->after(100, sub {
				       &undohighlightitem(undef, $zinc)});
			       },
			       );
    &wheelmousebindings($tree);
    $tree->bind('<1>', [sub {
	my $path = $tree->nearest($_[1]);
	my $item = (split(/\./, $path))[-1];
	&highlightitem($tree, $zinc, $item, 0);
		       
    }, Ev('y')]);
    
    $tree->bind('<2>', [sub {
	my $path = $tree->nearest($_[1]);
	return if $path eq 1;
	$tree->selectionClear;
	$tree->selectionSet($path);
	$tree->anchorSet($path);
	my $item = (split(/\./, $path))[-1];
	&highlightitem($tree, $zinc, $item, 1);
		       
    }, Ev('y')]);

    $tree->bind('<3>', [sub {
	my $path = $tree->nearest($_[1]);
	return if $path eq 1;
	$tree->selectionClear;
	$tree->selectionSet($path);
	$tree->anchorSet($path);
	my $item = (split(/\./, $path))[-1];
	&highlightitem($tree, $zinc, $item, 2);
		       
    }, Ev('y')]);
    
    $tree->add("1", -text => "Group(1)", -state => 'disabled');
    &scangroup($zinc, $tree, 1, "1", $optionsFormat, @optionstodisplay);
    $tree->autosetmode;
    # control buttons frame
    my $tree_butt_fm = $tree_tl->Frame(-height => 40)->pack(-side => 'bottom',
							    -fill => 'y');
    $tree_butt_fm->Button(-text => 'Help',
			  -command => [\&showHelpAboutTree, $zinc],
			  )->pack(-side => 'left', -pady => 10,
				  -padx => 10, -fill => 'both');
    
    $tree_butt_fm->Button(-text => 'Search',
			  -command => [\&searchInTree, $zinc],
			  )->pack(-side => 'left', -pady => 10,
				  -padx => 10, -fill => 'both');
    $tree_butt_fm->Button(-text => "Build\ncode",
			  -command => [\&buildCode, $zinc, $tree],
			  )->pack(-side => 'left', -pady => 10,
				  -padx => 10, -fill => 'both');
    
    $tree_butt_fm->Button(-text => "Attributes",
			  -command => sub {
			      my $path = $tree->selectionGet;
			      $path = 1 unless $path;
			      my $item = (split(/\./, $path))[-1];
			      &showresult("Attributes of item $item", $zinc, $item);
			  },
			  )->pack(-side => 'left', -pady => 10,
				  -padx => 10, -fill => 'both');
    

    $tree_butt_fm->Button(-text => 'Close',
			  -command => sub {$zinc->remove("zincdebug");
					   $tree_tl->destroy},
			  )->pack(-side => 'left', -pady => 10,
				  -padx => 20, -fill => 'both');
    # pack tree
    $tree->pack(-padx => 10, -pady => 10,
		-ipadx => 10,
		-side => 'top',
		-fill => 'both',
		-expand => 1,
		);
    

} # end showtree


# destroy the items tree
sub hidetree {
    
    $tree_tl->destroy if $tree_tl and Tk::Exists($tree_tl);
    
} # end hidetree


# find a pointed item in the items tree
sub findintree {
    
    my $zinc = shift;
    if (not Tk::Exists($tree_tl)) {
	&showtree($zinc);
    }
    my $ev = $zinc->XEvent;
    ($x0, $y0) = ($ev->x, $ev->y);
    my @atomicgroups = &unsetAtomicity($zinc);
    my $item = $zinc->find('closest', $x0, $y0);
    &restoreAtomicity($zinc, @atomicgroups);
    return unless $item > 1;
    my @ancestors = reverse($zinc->find('ancestors', $item));
    my $path = join('.', @ancestors).".".$item;
    # tree is rebuilded unless path exists
    unless ($tree->info('exists', $path)) {
	$tree_tl->destroy;
	#print "path=$path rebuild tree\n";
	&showtree($zinc);
    }
    $tree->see($path);
    $tree->selectionClear;
    $tree->anchorSet($path);
    $tree->selectionSet($path);
    &surrounditem($zinc, $item);
    $tree->focus;

} # end findintree


sub searchInTree {
    
    my $zinc = shift;
    $searchtree_tl->destroy if $searchtree_tl and Tk::Exists($searchtree_tl);
    $searchtree_tl = $tree_tl->Toplevel;
    $searchtree_tl->transient($tree_tl);
    $searchtree_tl->title("Find string in tree");
    my $fm = $searchtree_tl->Frame->pack(-side => 'top');
    $fm->Label(-text => "Find : ",
	       )->pack(-side => 'left', -padx => 10, -pady => 10);
    my $entry = $fm->Entry(-width => 20)->pack(-side => 'left',
					       -padx => 10, -pady => 10);
    my $status = $searchtree_tl->Label(-foreground => 'sienna',
				   )->pack(-side => 'top');
    my $ep = 1;
    my $searchfunc =  sub {
	my $side = shift;
	my $found = 0;
        #print "ep=$ep side=$side\n";
	$status->configure(-text => "");
	$status->update;
	$searchTreeEntryValue = $entry->get();
	$searchTreeEntryValue = quotemeta($searchTreeEntryValue);
	my $text;
	while ($ep) {
 	    $ep = $tree->info($side, $ep);
	    unless ($ep) {
		$ep = 1;
		$found = 0;
		last;
	    }
	    $text = $tree->entrycget($ep, -text);
	    if ($text =~ /$searchTreeEntryValue/) {
		$tree->see($ep);
		$tree->selectionClear;
		$tree->anchorSet($ep);
		$tree->selectionSet($ep);
		$found = 1;
		last;
	    }
	}
	#print "searchTreeEntryValue=$searchTreeEntryValue found=$found\n";
	$status->configure(-text => "Search string not found") unless $found > 0;
    };

    my $fm2 = $searchtree_tl->Frame->pack(-side => 'top');
    $fm2->Button(-text => 'Prev',
		 -command => sub {&$searchfunc('prev');},
		 )->pack(-side => 'left', -pady => 10);
    $fm2->Button(-text => 'Next',
		 -command => sub {&$searchfunc('next');},
		 )->pack(-side => 'left', -pady => 10);
    $fm2->Button(-text => 'Close',
		 -command => sub {$searchtree_tl->destroy},
		 )->pack(-side => 'right', -pady => 10);
    $entry->focus;
    $entry->delete(0, 'end');
    $entry->insert(0, $searchTreeEntryValue) if $searchTreeEntryValue;
    $entry->bind('<Key-Return>', sub {&$searchfunc('next');});
    
} # end searchInTree


sub extractinfo {
    my $zinc = shift;
    my $item = shift;
    my $format = shift;
    my $option = shift;
    my $titleflag = shift;
    $option =~ s/^\s+//;
    $option =~ s/\s+$//;
    #print "option=[$option]\n";
    my @info;
    $WARNING = 0;
    eval {@info = $zinc->itemcget($item, $option)};
    #print "eval $option = (@info) $@\n";
    return if $@;
    return if @info == 0;
    my $info;
    my $sep = ($format eq 'column') ? "\n  " : ", ";
    if ($titleflag) {
	$info = $sep."[$option] ".$info[0];
    } else {
	$info = $sep.$info[0];
    }
    if (@info > 1) {
	shift(@info);
	for (@info) {
	    if ($format eq 'column') {
		if (length($info." ".$_) > 40) {
		    if ($titleflag) {
			$info .= $sep."[$option] ".$_;
		    } else {
			$info .= $sep.$_;
		    }
		} else {
		    $info .= ", $_";
		}
	    } else {
		$info .= $sep.$_;
	    }
	}
    }
    $WARNING = 1;
    return $info;
    
} # end extractinfo


sub scangroup {
    
    my ($zinc, $tree, $group, $path, $format, @optionstodisplay) = @_;
    my @items = $zinc->find('withtag', "$group.");
    for my $item (@items) {
	my $Type = ucfirst($zinc->type($item));
	my $info = " ";
	if (@optionstodisplay == 1) {
	    $info .= &extractinfo($zinc, $item, $format, $optionstodisplay[0]);
	} elsif (@optionstodisplay > 1) {
	    for my $opt (@optionstodisplay) {
		$info .= &extractinfo($zinc, $item, $format, $opt, 1);
	    }
	}
	if ($Type eq "Group") {
	    $tree->add($path.".".$item,
		       -text => "$Type($item)$info",
		       -style => 'group',
		       );
	    &scangroup($zinc, $tree, $item, $path.".".$item, $format, @optionstodisplay);
	} else {
	    $tree->add($path.".".$item,
		       -text => "$Type($item)$info",
		       -style => 'item',
		       );
	}
    }

} # end scangroup

#---------------------------------------------------------------------------
#
# Functions used to build code
#
#---------------------------------------------------------------------------

# build perl code corresponding to a branch of the items tree
sub buildCode {
    
    my $zinc = shift;
    my $tree = shift;
    my @code;
    push(@code, 'use Tk;');
    push(@code, 'use Tk::Zinc;');
    push(@code, 'my $mw = MainWindow->new();');
    push(@code, 'my $zinc = $mw->Zinc(-render => '.$zinc->cget(-render).
	 ')->pack(-expand => 1, -fill => "both");');
    push(@code, '# hash %items : keys are original items ID, values are built items ID');
    push(@code, 'my %items;');
    push(@code, '');
    my $path = $tree->selectionGet;
    $path = 1 unless $path;
    my $item = (split(/\./, $path))[-1];
    $endoptions = [];
    if ($zinc->type($item) eq 'group') {
	push(@code, &buildGroup($zinc, $item, 1));
	for(@$endoptions) {
	    my ($item, $option, $value) = @$_;
	    push(@code,
		 '$zinc->itemconfigure('.$item.', '.$option.' => '.$value.');');
	}
    } else {
	push(@code, &buildItem($zinc, $item, 1));
    }
    push(@code, &buildEnd);
    
    my $file = $zinc->getSaveFile(-filetypes => [['Perl Files',   '.pl'],
                                               ['All Files',   '*']],
				  -initialfile => 'zincdebug.pl',
				  -title => 'Save code',
				  );
    return unless defined $file;
    $zinc->Busy;
    open (OUT, ">$file");
    for (@code) {
	print OUT $_."\n";
    }
    close(OUT);
    $zinc->Unbusy;
    
} # end buildCode


sub buildEnd {

    my @code;
    push(@code, 'for (keys(%items)) {');
    push(@code, '   $zinc->addtag(\'orig\'.$_, "withtag", $items{$_});');
    push(@code, '}');
    push(@code, 'MainLoop;');
    return @code
	
} # end buildEnd


# build a node of tree (corresponding to a TkZinc group item)
sub buildGroup {
    
    my $zinc = shift;
    my $item = shift;
    my $group = shift;
    my @code;
    # creation
    push(@code, '$items{'.$item.'}=$zinc->add("group", '.$group.', ');
    # options
    push(@code, &buildOptions($zinc, $item));
    push(@code, ');');
    push(@code, '');
    # coords
    push(@code, '$zinc->coords($items{'.$item.'}, ['.
	 join(',', $zinc->coords($item)).']);');
    # transformations
    push(@code, &buildTransformations($zinc, $item));
    
    my @items = $zinc->find('withtag', "$item.");
    for my $it (reverse(@items)) {
	if ($zinc->type($it) eq 'group') {
	    push(@code, &buildGroup($zinc, $it, '$items{'.$item.'}'));
	} else {
	    push(@code, &buildItem($zinc, $it, '$items{'.$item.'}'));
	}
    }
    return @code;

} # end buildGroup


# build a leaf of tree (corresponding to a TkZinc non-group item)
sub buildItem {
    
    my $zinc = shift;
    my $item = shift;
    my $group = shift;
    my $type = $zinc->type($item);
    my @code;
    my $numfields = 0;
    my $numcontours = 0;
    # creation    
    my $initstring = '$items{'.$item.'}=$zinc->add("'.$type.'", '.$group.', ';
    if ($type eq 'tabular' or $type eq 'track' or $type eq 'waypoint') {
	$numfields = $zinc->itemcget($item, -numfields);
	$initstring .= $numfields.' ,';
    } elsif ($type eq 'curve' or $type eq 'triangles' or
	     $type eq 'arc' or $type eq 'rectangle') {
	$initstring .= "[ ";
	my (@coords) = $zinc->coords($item);
	if (ref($coords[0]) eq 'ARRAY') {
	    my @coords2;
	    for my $c (@coords) {
		if (@$c > 2) {
		     push(@coords2, '['.$c->[0].', '.$c->[1].', "'.$c->[2].'"]');
		} else {
		     push(@coords2, '['.$c->[0].', '.$c->[1].']');
		    
		}
	    }
	    $initstring .= join(', ', @coords2);
	} else {
	    $initstring .= join(', ', @coords);
	}
	$initstring .= " ], ";
	$numcontours = $zinc->contour($item);
    } 
    push(@code, $initstring);
    # options
    push(@code, &buildOptions($zinc, $item));
    push(@code, ');');
    push(@code, '');
    # fields
    if ($numfields > 0) {
    	for (my $i=0; $i < $numfields; $i++) {
	    push(@code, &buildField($zinc, $item, $i));
	}
    }
    # contours
    if ($numcontours > 1) {
	for (my $i=1; $i < $numcontours; $i++) {
	    my (@coords) = $zinc->coords($item);
	    my @coords2;
	    for my $c (@coords) {
		if (@$c > 2) {
		    push(@coords2, '['.$c->[0].', '.$c->[1].', "'.$c->[2].'"]');
		} else {
		    push(@coords2, '['.$c->[0].', '.$c->[1].']');
		}
	    }
	    my $coordstr = '[ '.join(', ', @coords2).' ]';
	    push(@code, '$zinc->contour($items{'.$item.'}, "add", 0, ');
	    push(@code, '            '.$coordstr.');');
	}
    }
    # transformations
    push(@code, &buildTransformations($zinc, $item));
    
    return @code;

} # end buildItem


# add an information field to an item of the tree
sub buildField {
    
    my $zinc = shift;
    my $item = shift;
    my $field = shift;
    my @code;
    # type group and initargs
    push(@code, '$zinc->itemconfigure($items{'.$item.'}, '.$field.', ');
    # options
    push(@code, &buildOptions($zinc, $item, $field));
    push(@code, ');');
    push(@code, '');
    return @code;

} # end buildField


sub buildTransformations {

    my $zinc = shift;
    my $item = shift;
    my @tr = $zinc->tget($item);
    my @code;
    return ('$zinc->tset($items{'.$item.'}, '.join(", ", @tr).');');

} # end buildTransformations


sub buildOptions {
    
    my $zinc = shift;
    my $item = shift;
    my $field = shift;
    my @code;
    my @args = defined($field) ? ($item, $field) : ($item);
    my @options = $zinc->itemconfigure(@args);
    for my $elem (@options) {
	my ($option, $type, $readonly, $value) = (@$elem)[0, 1, 2, 4];
	next if $value eq '';
	next if $readonly;
	if ($type eq 'point') {
	    push(@code, "           ".$option." => [".join(',', @$value)."], ");
	    
	} elsif (($type eq 'bitmap' or $type eq 'image') and $value !~ /^AtcSymbol/
	    and $value !~ /^AlphaStipple/) {
	    push(@code, "#           ".$option." => '".$value."', ");
	    
	} elsif ($type eq 'item') {
	    $endoptions->[@$endoptions] =
		['$items{'.$item.'}', $option, '$items{'.$value.'}'];
	    
	} elsif ($option eq '-text') {
	    $value =~ s/\"/\\"/;       # comment for emacs legibility => "
	    push(@code, "           ".$option.' => "'.$value.'", ');

	} elsif (ref($value) eq 'ARRAY') {
	    push(@code, "           ".$option." => [qw(".join(' ', @$value).")], ");

	} else {
	    push(@code, "           ".$option." => '".$value."', ");
	}
    }
    return @code;

} # end buildOptions

#---------------------------------------------------------------------------
#
# Functions related to search in a rectangular area
#
#---------------------------------------------------------------------------

# begin to draw rectangular area for search
sub startrectangle {
    
    my ($zinc, $style, $text, $color) = @_;
    $zinc->remove("zincdebugrectangle", "zincdebuglabel");
    my $ev = $zinc->XEvent;
    ($x0, $y0) = ($ev->x, $ev->y);
    # store and name the inverted transformation of top group
    $zinc->tsave(1, 'zoom+move', 1);
    $zinc->add('rectangle', 1, [$x0, $y0, $x0, $y0],
	       -linecolor => $color,
	       -linewidth => 2,
	       -linestyle => $style,
	       -tags => ["zincdebugrectangle"],
			       );
    $zinc->add('text', 1,
	       -color => $color,
	       -font => '7x13',
	       -position => [$x0+5, $y0-15],
	       -text => $text,
	       -tags => ["zincdebuglabel"],
	       );
    # apply to new rectangle the (inverted) transformation stored below
    $zinc->trestore("zincdebugrectangle", 'zoom+move');
    $zinc->trestore("zincdebuglabel", 'zoom+move');
  
} # end startrectangle


# resize the rectangular area for search
sub resizerectangle {
    
    my $zinc = shift;
    my $ev = $zinc->XEvent;
    my ($x, $y) = ($ev->x, $ev->y);
    return unless ($zinc->find('withtag', "zincdebugrectangle"));

    $zinc->coords("zincdebugrectangle", 1, 1, [$x, $y]);
    if ($x < $x0) {
	if ($y < $y0) {
	    $zinc->coords("zincdebuglabel", [$x+5, $y-15]);
	} else {
	    $zinc->coords("zincdebuglabel", [$x+5, $y0-15]);
	}
    } else {
	if ($y < $y0) {
	    $zinc->coords("zincdebuglabel", [$x0+5, $y-15]);
	} else {
	    $zinc->coords("zincdebuglabel", [$x0+5, $y0-15]);
	}
    }
    $zinc->raise("zincdebugrectangle");
    $zinc->raise("zincdebuglabel");

} # end resizerectangle


# stop drawing rectangular area for search
sub stoprectangle {
    
    my ($zinc, $searchtype, $text) = @_;
    return unless ($zinc->find('withtag', "zincdebugrectangle"));

    my @atomicgroups = &unsetAtomicity($zinc);
    $zinc->update;
    my ($c0, $c1) = $zinc->coords("zincdebugrectangle");
    my @coords = (@$c0, @$c1);
    my @items;
    for my $item ($zinc->find($searchtype, @coords, 1, 1)) {
	push (@items, $item) unless $zinc->hastag($item, "zincdebugrectangle") or
	    $zinc->hastag($item, "zincdebuglabel");
    }
    &restoreAtomicity($zinc, @atomicgroups);
    if (@items) {
	&showresult($text, $zinc, @items);
    } else {
	$zinc->remove("zincdebugrectangle", "zincdebuglabel");
    }

} # end stoprectangle


# in order to avoid find problems with group atomicity, we set all -atomic
# attributes to 0
sub unsetAtomicity {
    
    my $zinc = shift;
    my @groups = $zinc->find('withtype', 'group');
    my @atomicgroups;
    for my $group (@groups) {
	if ($zinc->itemcget($group, -atomic)) {
	    push(@atomicgroups, $group);
	    $zinc->itemconfigure($group, -atomic => 0);
	}
    }
    return @atomicgroups;
    
} # end unsetAtomicity


sub restoreAtomicity {
    
    my $zinc = shift;
    my @atomicgroups = @_;
    for my $group (@atomicgroups) {
	$zinc->itemconfigure($group, -atomic => 1);
    }

} # end restoreAtomicity


#---------------------------------------------------------------------------
#
# Function related to item's id search 
#
#---------------------------------------------------------------------------

sub searchentry {
    
    my $zinc = shift;
    $search_tl->destroy if $search_tl and Tk::Exists($search_tl);
    $search_tl = $control_tl->Toplevel;
    $search_tl->title("Specific search");
    my $fm = $search_tl->Frame->pack(-side => 'top');
    $fm->Label(-text => "Item TagOrId : ",
	       )->pack(-side => 'left', -padx => 10, -pady => 10);
    my $entry = $fm->Entry(-width => 20)->pack(-side => 'left',
					       -padx => 10, -pady => 10);
    my $status = $search_tl->Label(-foreground => 'sienna',
				   )->pack(-side => 'top');
    $search_tl->Button(-text => 'Close',
		       -command => sub {$search_tl->destroy},
		       )->pack(-side => 'top', -pady => 10);
    $entry->focus;
    $entry->delete(0, 'end');
    $entry->insert(0, $searchEntryValue{$zinc}) if $searchEntryValue{$zinc};
    $entry->bind('<Key-Return>', [sub {
	$status->configure(-text => "");
	$status->update;
	$searchEntryValue{$zinc} = $entry->get();
	my @items = $zinc->find('withtag', $searchEntryValue{$zinc});
	if (@items) {
	    my $label;
	    if ($searchEntryValue{$zinc} =~ /^\d/) {
		$label = "Attributes of item $searchEntryValue{$zinc}";
	    } else {
		$label = "Attributes of item(s) with tag $searchEntryValue{$zinc}"
	    }
	    &showresult($label, $zinc, @items);
	} else {
	    $status->configure(-text => "No such tagOrId ($searchEntryValue{$zinc})");
	}
    }]);
    
} # end searchentry


#---------------------------------------------------------------------------
#
# Functions related to transformations parameters
#
#---------------------------------------------------------------------------

sub showtransfoparams {

    my ($label, $zinc, $item) = @_;
    my @m = $zinc->tget($item);
    my ($m00, $m01, $m10, $m11, $m20, $m21) = @m;
    my ($xt, $yt, $xsc, $ysc, $a, $xsk, $ysk) = $zinc->tget($item, 'all');
    # bug zinc 
    $ysk = 0 unless defined $ysk;
    for ($m00, $m01, $m10, $m11, $m20, $m21, $xt, $yt, $xsc, $ysc, $a, $xsk, $ysk) {
	$_ = sprintf("%.2f", $_) if /^-?\d+\.\d/;
    }
    $transfo_tl{$item}->destroy if Tk::Exists($transfo_tl{$item});
    $transfo_tl{$item} = $control_tl->Toplevel();
    $transfo_tl{$item}->transient($result_tl{$label})
	if Tk::Exists($result_tl{$label});
    my $title = "Transformations of item $item";
    $transfo_tl{$item}->title($title);
    my $bgcolor = 'ivory';
    my $fm1 = $transfo_tl{$item}->Frame()->pack(-side => 'top',
						-padx => 20,
						-pady => 10,
						-expand => 1,
						-fill => 'x',
						);
    # set transformation to ident
    my $btn = $fm1->Button(-text => "Show item with transformation\nset to identity",
			   -bg => $bgcolor,
			   )->pack(-side => 'top', -padx => 5, -pady => 10);
    $balloonhelp->attach($btn,-balloonmsg =>
			 "Click and maintain to show the transformation  \n".
			 "animation. Use btn1, btn2 or btn3 to select the\n".
			 "best background color for a good visibility.   ");
    $btn->bind('<1>', [\&showtransfo, $zinc, $item, 0]);
    $btn->bind('<2>', [\&showtransfo, $zinc, $item, 1]);
    $btn->bind('<3>', [\&showtransfo, $zinc, $item, 2]);
    
    my $fm11 = $fm1->Frame()->pack(-side => 'left',
				   -padx => 20,
				   );

    my ($set_cb, $reset_cb, $upd_cb);
    
    # matrix
    my $r = 0;
    my $c = 0;
    $fm11->Label(-text => 'matrix', -relief => 'ridge', -bg => $bgcolor)
	->grid(-row => $r++, -columnspan => 2,
	       -ipady => 5, -ipadx => 5, -sticky => 'nswe');
    $fm11->Label(-textvariable => \$m00, -relief => 'ridge')
	->grid(-row => $r, -column => $c,
	       -ipady => 5, -ipadx => 5, -sticky => 'nswe');
    $fm11->Label(-textvariable => \$m01, -relief => 'ridge')
	->grid(-row => $r++, -column => $c+1,
	       -ipady => 5, -ipadx => 5, -sticky => 'nswe');
    $fm11->Label(-textvariable => \$m10, -relief => 'ridge')
	->grid(-row => $r, -column => $c,
	       -ipady => 5, -ipadx => 5, -sticky => 'nswe');
    $fm11->Label(-textvariable => \$m11, -relief => 'ridge')
	->grid(-row => $r++, -column => $c+1,
	       -ipady => 5, -ipadx => 5, -sticky => 'nswe');
    $fm11->Label(-textvariable => \$m20, -relief => 'ridge')
	->grid(-row => $r, -column => $c,
	       -ipady => 5, -ipadx => 5, -sticky => 'nswe');
    $fm11->Label(-textvariable => \$m21, -relief => 'ridge')
	->grid(-row => $r++, -column => $c+1,
	       -ipady => 5, -ipadx => 5, -sticky => 'nswe');
    


    my $fm12 = $fm1->Frame()->pack(-side => 'left',
				   -padx => 20,
				   );
    my ($e_xt, $e_yt, $e_xsc, $e_ysc, $e_a, $e_xsk, $e_ysk);

    $set_cb = sub {
	$zinc->treset($item);
	$zinc->translate($item, $e_xt, $e_yt);
	$zinc->rotate($item, $e_a);
	$zinc->scale($item, $e_xsc, $e_ysc);
	$zinc->skew($item, $e_xsk, $e_ysk);
	($m00, $m01, $m10, $m11, $m20, $m21) = $zinc->tget($item);
	for ($m00, $m01, $m10, $m11, $m20, $m21) {
	    $_ = sprintf("%.2f", $_) if /^-?\d+\.\d/;
	}
    };

    # translate params
    $r = 0;
    $c = 0;    
    $fm12->Label(-text => 'translate', -relief => 'ridge', -bg => $bgcolor)
	->grid(-row => $r, -column => $c++,
	       -ipady => 5, -ipadx => 5, -sticky => 'nswe');

    &entrytransfo($fm12, $item, $zinc, 'xt', $xt, \$e_xt, 4, $set_cb)
    	->grid(-row => $r, -column => $c++,
	       -ipady => 5, -ipadx => 5, -sticky => 'nswe');
    
    &entrytransfo($fm12, $item, $zinc, 'yt', $yt, \$e_yt, 4, $set_cb)
	->grid(-row => $r++, -column => $c++,
	       -ipady => 5, -ipadx => 5, -sticky => 'nswe');
    
    # rotate params
    $c = 0;
    $fm12->Label(-text => 'rotate', -relief => 'ridge', -bg => $bgcolor)
	->grid(-row => $r, -column => $c++,
	       -ipady => 5, -ipadx => 5, -sticky => 'nswe');

    &entrytransfo($fm12, $item, $zinc, 'a', $a, \$e_a, 4, $set_cb)
	->grid(-row => $r++, -column => $c++,
	       -ipady => 5, -ipadx => 5, -sticky => 'nswe');

    # scale params
    $c = 0;
    $fm12->Label(-text => 'scale', -relief => 'ridge', -bg => $bgcolor)
	->grid(-row => $r, -column => $c++,
	       -ipady => 5, -ipadx => 5, -sticky => 'nswe');

    &entrytransfo($fm12, $item, $zinc, 'xsc', $xsc, \$e_xsc, 4, $set_cb)
	->grid(-row => $r, -column => $c++,
	       -ipady => 5, -ipadx => 5, -sticky => 'nswe');
    &entrytransfo($fm12, $item, $zinc, 'ysc', $ysc, \$e_ysc, 4, $set_cb)
	->grid(-row => $r++, -column => $c++,
	       -ipady => 5, -ipadx => 5, -sticky => 'nswe');
    
    # skew params
    $c = 0;
    $fm12->Label(-text => 'skew', -relief => 'ridge', -bg => $bgcolor)
	->grid(-row => $r, -column => $c++,
	       -ipady => 5, -ipadx => 5, -sticky => 'nswe');
    
    &entrytransfo($fm12, $item, $zinc, 'xsk', $xsk, \$e_xsk, 4, $set_cb)
	->grid(-row => $r, -column => $c++,
	       -ipady => 5, -ipadx => 5, -sticky => 'nswe');
    &entrytransfo($fm12, $item, $zinc, 'ysk', $ysk, \$e_ysk, 4, $set_cb)
	->grid(-row => $r++, -column => $c++,
	       -ipady => 5, -ipadx => 5, -sticky => 'nswe');


    my $fm2 = $transfo_tl{$item}->Frame()->pack(-side => 'top',
						-padx => 20,
						-pady => 0,
						);
    $fm2->Button(-text => 'Close',
		-command => sub {
		    $transfo_tl{$item}->destroy;
		    delete $transfo_tl{$item};
		})->pack(-side => 'top', -padx => 40, -pady => 20);
    
    
    
} # end showtransfoparams


#---------------------------------------------------------------------------
#
# Functions related to results tables display
#
#---------------------------------------------------------------------------

# display in a toplevel the result of search ; a new toplevel destroyes the
# previous one
sub showresult {
    
    my ($label, $zinc, @items) = @_;
    # toplevel (re-)creation
    $result_tl{$label}->destroy if Tk::Exists($result_tl{$label});
    $result_tl{$label} = $control_tl->Toplevel();
    my $title = "TK::Zinc Debug";
    $title .= " - $label" if $label;
    $result_tl{$label}->title($title);
    $result_tl{$label}->geometry('+10+20');
    $control_tl->raise;
    my $fm = $result_tl{$label}->Frame()->pack(-side => 'bottom',
				       );
    $fm->Button(-text => 'Close',
		-command => sub {
		    $result_tl{$label}->destroy;
		    delete $result_tl{$label};
		    $zinc->remove("zincdebugrectangle", "zincdebuglabel");
		})->pack(-side => 'left', -padx => 40, -pady => 10);
    
    # scrolled pane creation
    $result_fm = $result_tl{$label}->Scrolled('Pane',
					      -scrollbars => 'osoe',
					      -height => 200,
					      -width => 1024,
					      );
    &wheelmousebindings($result_fm);
    my $fm2 = $result_fm->Frame->pack;
    # attributes display
    &showattributes($zinc, $fm2, $label, \@items);
    $result_fm->update;
    $fm2->update;
    my $width = $fm2->width + 10;
    $width = $screenwidth if $width > $screenwidth;
    $result_fm->configure(-width => $width);
    $result_fm->pack(-padx => 10, -pady => 10,
		     -ipadx => 10,
		     -fill => 'both',
		     -expand => 1,
		     );

} # end showresult

# display table containing additionnal options/values
sub showalloptions {
    
    my ($label, $zinc, $item, $fmp) = @_;
    $alloptions_tl{$item}->destroy if Tk::Exists($alloptions_tl{$item});
    $alloptions_tl{$item} = $control_tl->Toplevel();
    $alloptions_tl{$item}->transient($result_tl{$label})
	if Tk::Exists($result_tl{$label});
    my $tl = $alloptions_tl{$item};
    my $title = "All options of item $item";
    $tl->title($title);
    $tl->geometry('-10+0');
    

    # footer
    #----------------
    $tl->Button(-text => 'Close',
		-command => sub {
		    $alloptions_tl{$item}->destroy;
		    delete $alloptions_tl{$item};
		})->pack(-side => 'bottom');
    # option scrolled frame
    #-----------------------
    my $fm = $tl->Scrolled('Pane',
			   -scrollbars => 'oe',
			   -height => 500,
			   )->pack(-padx => 10, -pady => 10,
				   -ipadx => 10,
				   -expand => 1,
				   -fill => 'both');
    
    my $bgcolor = 'ivory';
    my $i = 1;
    $fm->Label(-text => $title, -background => $bgcolor,
	       -fg => 'sienna', -relief => 'ridge')
	->grid(-row => $i++, -column => 1, -ipady => 5, -ipadx => 5,
	       -columnspan => 2, -sticky => 'nswe') if $label;
    $fm->Label(-text => 'Option', -background => $bgcolor, -relief => 'ridge')
	->grid(-row => $i, -column => 1, -ipady => 10, -ipadx => 5, -sticky => 'nswe');
    $fm->Label(-text => 'Value', -background => $bgcolor, -relief => 'ridge')
	->grid(-row => $i++, -column => 2, -ipady => 10, -ipadx => 5, -sticky => 'nswe');

    my @options = $zinc->itemconfigure($item);
    for my $elem (@options) {
	my ($option, $type, $value) = (@$elem)[0,1,4];
	$fm->Label(-text => $option, -relief => 'ridge')
	    ->grid(-row => $i, -column => 1,
		   -ipady => 5, -ipadx => 5, -sticky => 'nswe');
	if ($option eq '-tags') {
	    &entryoption($fm, $item, $zinc, $option,
			 join("\n", @$value), 30, 30, scalar @$value)
		->grid(-row => $i, -column => 2, -ipady => 5,
		       -ipadx => 5, -sticky => 'nswe');
	} else {
	    &entryoption($fm, $item, $zinc, $option, undef, 50, 25)
		->grid(-row => $i, -column => 2, -ipady => 5,
		       -ipadx => 5, -sticky => 'nswe');
	}
	$i++;
    }
    
} # end showalloptions


# display device coords table
sub showdevicecoords {
    
    my ($label, $zinc, $item) = @_;
    &showcoords($label, $zinc, $item, 1);

} # end showdevicecoords


# display coords table
sub showcoords {
    
    my ($label, $zinc, $item, $deviceflag) = @_;
    my $bgcolor = 'ivory';
    my $bgcolor2 = 'gray75';
    $coords_tl{$item}->destroy if Tk::Exists($coords_tl{$item}) and not $deviceflag;
    $coords_tl{$item} = $control_tl->Toplevel();
    $coords_tl{$item}->transient($result_tl{$label}) if Tk::Exists($result_tl{$label});
    my $title = "Zinc Debug";
    if ($deviceflag) {
	$title .= " - Coords of item $item";
    } else {
	$title .= " - Device coords of item $item";
    }
    $coords_tl{$item}->title($title);
    $coords_tl{$item}->geometry('+10+20');
    my $coords_fm0 = $coords_tl{$item}->Frame()->pack(-side => 'bottom');
    $coords_fm0->Button(-text => 'Help',
			-command => [\&showHelpAboutCoords, $zinc]
			)->pack(-side => 'left', -padx => 40, -pady => 10);
    $coords_fm0->Button(-text => 'Close',
			-command => sub {
			    &hidecontour($zinc);
			    $coords_tl{$item}->destroy;
			    delete $coords_tl{$item};
			})->pack(-side => 'left', -padx => 40, -pady => 10);
    # scrolled pane creation
    my $coords_fm = $coords_tl{$item}->Scrolled('Pane',
					 -scrollbars => 'oe',
					 -height => 200,
					 )->pack(-padx => 10, -pady => 10,
						 -ipadx => 10,
						 -expand => 1,
						 -fill => 'both');
    my @contour;
    my $contournum = $zinc->contour($item);
    for (my $i=0; $i < $contournum; $i++) {
	my @coords = $zinc->coords($item, $i);
	if (!ref $coords[0]) {
	    ## The first item of the list is not a reference, so the
	    ## list is guarranted to be a flat list (x, y, ...)
	    ## normaly of only one pair of (x y)
	    @coords = $zinc->transform($item, 'device', [@coords])
		if $deviceflag;
	    for (my $j=0; $j < @coords; $j += 2) {
		push(@{$contour[$i]}, [$coords[$j], $coords[$j+1]]);
	    }
	}
	else {
	    ## the first element is an array reference, as every
	    ## other elements of the list
	    for (my $j=0; $j < @coords; $j ++) {
		my @c = @{$coords[$j]};
		@c = $zinc->transform($item, 'device', [@c])
		    if $deviceflag;
		push(@{$contour[$i]}, [@c]);
	    }
	}
    }
    my $row = 1;
    my $col = 1;
    for (my $i=0; $i < @contour; $i++) {
	$col = 1;
	my $lab = $coords_fm->Label(-text => "Contour $i",
				    -background => $bgcolor,
				    -relief => 'ridge')->grid(-row => $row,
							      -column => $col,
							      -ipadx => 5,
							      -ipady => 5,
							      -sticky => 'nswe');
	$lab->bind('<1>', [\&showcontour, $zinc, 'black', $item, $contour[$i],
			   $deviceflag]);
	$lab->bind('<2>', [\&showcontour, $zinc, 'white', $item, $contour[$i],
			   $deviceflag]);
	$lab->bind('<3>', [\&showcontour, $zinc, 'red', $item, $contour[$i],
			   $deviceflag]);
	$lab->bind('<ButtonRelease-1>', sub { &hidecontour($zinc); });
	$lab->bind('<ButtonRelease-2>', sub { &hidecontour($zinc); });
	$lab->bind('<ButtonRelease-3>', sub { &hidecontour($zinc); });
	my $lab1 = $coords_fm->Label(-text => scalar(@{$contour[$i]})." points",
				     -background => $bgcolor,
				     -relief => 'ridge')->grid(-row => $row+1,
							       -column => $col,
							       -ipadx => 5,
							       -ipady => 5,
							       -sticky => 'nswe');
	$lab1->bind('<1>', [\&showcontourpts, $zinc, 'black', $item, $contour[$i],
			    $deviceflag]);
	$lab1->bind('<2>', [\&showcontourpts, $zinc, 'white', $item, $contour[$i],
			    $deviceflag]);
	$lab1->bind('<3>', [\&showcontourpts, $zinc, 'red', $item, $contour[$i],
			    $deviceflag]);
	$lab1->bind('<ButtonRelease-1>', sub { &hidecontour($zinc); });
	$lab1->bind('<ButtonRelease-2>', sub { &hidecontour($zinc); });
	$lab1->bind('<ButtonRelease-3>', sub { &hidecontour($zinc); });
	$col++;
	my @lab;
	for my $coords (@{$contour[$i]}) {
	    if ($col > 10) {
		$col = 2;
		$row++;
	    }
	    $coords->[0] =~ s/\.(\d\d).*/\.$1/;
	    $coords->[1] =~ s/\.(\d\d).*/\.$1/;
	    my @opt;
	    if (defined $coords->[2]) {
		@opt = (-text => sprintf('%s, %s, %s', @$coords),
			-underline => length(join(',', @$coords)) + 1,
			);
	    } else {
		@opt = (-text => sprintf('%s, %s', @{$coords}[0,1]));
	    }
	    push (@lab, $coords_fm->Label(@opt,
					  -width => 15,
					  -relief => 'ridge')->grid(-row => $row,
								    -ipadx => 5,
								    -ipady => 5,
								    -column => $col++,
								    -sticky => 'nswe'));
	}
	$row++ if (@{$contour[$i]} < 10);
	$row++;
	my $j = 0;
	for (@lab) {
	    $_->bind('<1>', [\&showcontourpt, $zinc, 'black',
			     $item, $j, $deviceflag, \@lab, @{$contour[$i]}]);
	    $_->bind('<2>', [\&showcontourpt, $zinc, 'white',
			     $item, $j, $deviceflag, \@lab, @{$contour[$i]}]);
	    $_->bind('<3>', [\&showcontourpt, $zinc, 'red',
			     $item, $j, $deviceflag, \@lab, @{$contour[$i]}]);
	    $j++;
	}

    }

} # end showcoords



# display in a grid the values of most important attributes 
sub showattributes {
    
    my ($zinc, $fm, $label, $items, $expandTagsFlag) = @_;
    $expandTagsFlag = 1;
    &getsize($zinc);
    my $bgcolor = 'ivory';
    my $i = 1;
    $fm->Label(-text => $label, -background => $bgcolor,
	       -fg => 'sienna', -relief => 'ridge')
	->grid(-row => $i++, -column => 0, -ipady => 0, -ipadx => 5,
	       -columnspan => 7, -sticky => 'nswe') if $label;

    &showbanner($fm, $i++);
    $i++;
    for my $item (@$items) {
	my $c = 0;
	my $type = $zinc->type($item);
	# id
	my $idbtn =
	    $fm->Button(-text => $item,
			-foreground => 'sienna'
			)->grid(-row => $i, -column => $c++, -sticky => 'nswe',
				-ipadx => 5);
	$idbtn->bind('<1>', [\&highlightitem, $zinc, $item, 0]);
	$idbtn->bind('<2>', [\&highlightitem, $zinc, $item, 1]);
	$idbtn->bind('<3>', [\&highlightitem, $zinc, $item, 2]);
	$balloonhelp->attach($idbtn,-balloonmsg =>
			     "Click and maintain to show the item.     \n".
			     "Use btn1, btn2 or btn3 to select the best\n".
			     "background color for a good visibility.  ");
	# type
	if ($type eq 'group') {
	    my $gbtn =
		$fm->Button(-text => $type,
			    -command => sub {
				my @items = $zinc->find('withtag', $item.".");
				&showresult("Content of group $item", $zinc, @items);
			    });
	    $gbtn->grid(-row => $i, -column => $c++, -sticky => 'nswe', -ipadx => 5);
	    $balloonhelp->attach($gbtn,-balloonmsg =>
				 "Click to display the group's content.");
	} else {
	    $fm->Label(-text => $type, -relief => 'ridge')
		->grid(-row => $i, -column => $c++, -sticky => 'nswe', -ipadx => 5);
	}
	# parent group
	my $group = $zinc->group($item);
	my $pgbtn =
	    $fm->Button(-text => $group,
			-command => [\&showresult,
				     "Attributes of group $group (parent of $item)",
				     $zinc, $group]);
	$pgbtn->grid(-row => $i, -column => $c++, -sticky => 'nswe', -ipadx => 5);
	$balloonhelp->attach($pgbtn,-balloonmsg =>
			     "Click to display the parent group's attributes.");
	# priority
	&entryoption($fm, $item, $zinc, -priority)
	    ->grid(-row => $i, -column => $c++, -sticky => 'nswe', -ipadx => 2);
	# sensitiveness
	&entryoption($fm, $item, $zinc, -sensitive)
	    ->grid(-row => $i, -column => $c++, -sticky => 'nswe', -ipadx => 2);
	# visibility
	&entryoption($fm, $item, $zinc, -visible)
	    ->grid(-row => $i, -column => $c++, -sticky => 'nswe', -ipadx => 2);
	# other options
	$fm->Button(-text => 'show',
		    -command => [\&showalloptions, $label, $zinc, $item, $fm])
	    ->grid(-row => $i, -column => $c++, -sticky => 'nswe', -ipadx => 5);
	# transformations
	my $tlabel = 'yes';
	my ($xt, $yt, $xsc, $ysc, $a, $xsk) = $zinc->tget($item, 'all');
	$tlabel = 'no' if ($xt == 0 and $yt == 0 and $xsc == 1 and $ysc == 1 and
			   $a == 0 and $xsk == 0);
	my $tbtn =
	    $fm->Button(-text => $tlabel, 
			-command => [\&showtransfoparams, $label, $zinc, $item],
			);
	$tbtn->grid(-row => $i, -column => $c++, -sticky => 'nswe', -ipadx => 5);
	$balloonhelp->attach($tbtn,-balloonmsg =>
			     "Click to display transformation parameters.\n".
			     "Some of them can be updated.               ");
	
	# coords
	my @coords = $zinc->coords($item);
	my $coords;
	if (!ref $coords[0]) {
	    my $x0 = int($coords[0]);
	    my $y0 = int($coords[1]);
	    $coords = "($x0, $y0)";
	} else {
	    my @points0 = @{$coords[0]};
	    my $n = $#coords;
	    my @pointsN = @{$coords[$n]};
	    my $x0 = int($points0[0]);
	    my $y0 = int($points0[1]);
	    my $xn = int($pointsN[0]);
	    my $yn = int($pointsN[1]);
	    if ($n == 1) { ## a couple of points
		$coords = "($x0, $y0, $xn, $yn)";
	    } else {
		$coords = "P0=($x0, $y0), ..., P".$n."=($xn, $yn)";
	    }
	}
	if (@coords > 2) {
	    my $cbtn = $fm->Button(-text => $coords,
				   -command => [\&showcoords, $label, $zinc, $item]);
	    $cbtn->grid(-row => $i, -column => $c++, -sticky => 'nswe', -ipadx => 2);
	    $balloonhelp->attach($cbtn,-balloonmsg =>
				 "Click to show all coordinates.");
	} else {
	    $fm->Label(-text => $coords, -relief => 'ridge')
		->grid(-row => $i, -column => $c++, -sticky => 'nswe', -ipadx => 5);
	}
	# device coords
	@coords = $zinc->transform($item, 'device', [@coords]);
	if (!ref $coords[0]) {
	    my $x0 = int($coords[0]);
	    my $y0 = int($coords[1]);
	    $coords = "($x0, $y0)";
	} else {
	    my @points0 = @{$coords[0]};
	    my $n = $#coords;
	    my @pointsN = @{$coords[$n]};
	    my $x0 = int($points0[0]);
	    my $y0 = int($points0[1]);
	    my $xn = int($pointsN[0]);
	    my $yn = int($pointsN[1]);
	    if ($n == 1) { ## a couple of points
		$coords = "($x0, $y0, $xn, $yn)";
	    } else {
		$coords = "P0=($x0, $y0), ..., P".$n."=($xn, $yn)";
	    }
	}
	if (@coords > 2) {
	    my $dcbtn =
		$fm->Button(-text => $coords,
			    -command => [\&showdevicecoords, $label, $zinc, $item]);
	    $dcbtn->grid(-row => $i, -column => $c++, -sticky => 'nswe', -ipadx => 2);
	    $balloonhelp->attach($dcbtn,-balloonmsg =>
				 "Click to show all device coordinates.");
	} else {
	    $fm->Label(-text => $coords, -relief => 'ridge')
		->grid(-row => $i, -column => $c++, -sticky => 'nswe', -ipadx => 5);
	}
	# bounding box
	my @bbox = $zinc->bbox($item);
	if (@bbox == 4) {
	    my ($b0, $b1, $b2, $b3) = @bbox;
	    $b0 = sprintf("%.2f", $b0) if int($b0) ne $b0;
	    $b1 = sprintf("%.2f", $b1) if int($b1) ne $b1;
	    $b2 = sprintf("%.2f", $b2) if int($b2) ne $b2;
	    $b3 = sprintf("%.2f", $b3) if int($b3) ne $b3;
	    my $btn = $fm->Button(-text => "($b0, $b1), ($b2, $b3)")
		->grid(-row => $i, -column => $c++, -sticky => 'nswe', -ipadx => 5);
	    $btn->bind('<1>', [\&showbbox, $zinc, $item]);
	    $btn->bind('<ButtonRelease-1>', [\&hidebbox, $zinc]) ;
	    $balloonhelp->attach($btn,-balloonmsg =>
				 "Click to show the bounding box.");
	} else {
	    $fm->Label(-text => "--", , -relief => 'ridge')
		->grid(-row => $i, -column => $c++, -sticky => 'nswe', -ipadx => 5);
	}
	# tags
  	my @tags = $zinc->gettags($item);
	my $height = 2;
	$height = scalar @tags if $cmdoptions{expandTagsField};
	&entryoption($fm, $item, $zinc, -tags, join("\n", @tags), 30, 30, $height)
	    ->grid(-row => $i, -column => $c++, -sticky => 'nswe', -ipadx => 5);

	$i++;
	&showbanner($fm, $i++) if ($i % 15 == 0);
    }
    
} # end showattributes


sub showbanner {
    
    my $fm = shift;
    my $i = shift;
    my $bgcolor = 'ivory';
    my $c = 0;
    $fm->Label(-text => "Item\nId", -background => $bgcolor, -relief => 'ridge')
	->grid(-row => $i, -column => $c++, -ipady => 5, -ipadx => 5, -sticky => 'nswe');
    $fm->Label(-text => "Item\nType", -background => $bgcolor, -relief => 'ridge')
	->grid(-row => $i, -column => $c++, -ipady => 5, -ipadx => 5, -sticky => 'nswe');
    $fm->Label(-text => "Parent\ngroup", -background => $bgcolor, -relief => 'ridge')
	->grid(-row => $i, -column => $c++, -ipady => 5, -ipadx => 5, -sticky => 'nswe');
    $fm->Label(-text => "P\nr\ni\no", -background => $bgcolor, -relief => 'ridge')
	->grid(-row => $i, -column => $c++, -ipady => 2, -ipadx => 5, -sticky => 'nswe');
    $fm->Label(-text => "S\ne\nn\ns", -background => $bgcolor, -relief => 'ridge')
	->grid(-row => $i, -column => $c++, -ipady => 2, -ipadx => 5, -sticky => 'nswe');
    $fm->Label(-text => "V\ni\ns\ni", -background => $bgcolor, -relief => 'ridge')
	->grid(-row => $i, -column => $c++, -ipady => 2, -ipadx => 5, -sticky => 'nswe');
    $fm->Label(-text => "All\noptions", -background => $bgcolor, -relief => 'ridge')
	->grid(-row => $i, -column => $c++,
	       -ipady => 5, -ipadx => 5, -sticky => 'nswe');
    $fm->Label(-text => "Transfo", -background => $bgcolor, -relief => 'ridge')
	->grid(-row => $i, -column => $c++,
	       -ipady => 10, -ipadx => 5, -sticky => 'nswe');
    $fm->Label(-text => 'Coords', -background => $bgcolor, -relief => 'ridge')
	->grid(-row => $i, -column => $c++,
	       -ipady => 10, -ipadx => 5, -sticky => 'nswe');
    $fm->Label(-text => 'Device coords', -background => $bgcolor, -relief => 'ridge')
	->grid(-row => $i, -column => $c++,
	       -ipady => 10, -ipadx => 5, -sticky => 'nswe');
    $fm->Label(-text => 'Bounding box', -background => $bgcolor, -relief => 'ridge')
	->grid(-row => $i, -column => $c++,
	       -ipady => 10, -ipadx => 5, -sticky => 'nswe');
    $fm->Label(-text => 'Tags', -background => $bgcolor, -relief => 'ridge')
	->grid(-row => $i, -column => $c++,
	       -ipady => 10, -ipadx => 5, -sticky => 'nswe');
    $fm->Label()->grid(-row => 1, -column => $c++, -pady => 10);

} # end showbanner


#---------------------------------------------------------------------------
#
# Functions related to contours display
#
#---------------------------------------------------------------------------

# display contour (as simple curve)
sub showcontour {
    my ($widget, $zinc, $color, $item, $contourcoords, $deviceflag) = @_;
    if ($deviceflag) {
	$zinc->add('curve', 1, $contourcoords,
		   -filled => 0,
		   -linecolor => $color,
		   -tags => ['zincdebugcontour']);

    } else {
	$zinc->add('curve', 1, [$zinc->transform($item, 1, $contourcoords)],
		   -filled => 0,
		   -linecolor => $color,
		   -tags => ['zincdebugcontour']);
    }
    $zinc->raise('zincdebugcontour');
    
} # end showcontour


sub hidecontour {
    
    my ($zinc) = @_;
    $zinc->remove('zincdebugcontour');
    
} # end hidecontour


# display contours points (one rectangle per point)
sub showcontourpts {
    my ($widget, $zinc, $color, $item, $contourcoords, $deviceflag) = @_;
    my $i = 0;
    for my $coords (@$contourcoords) {
	my ($x, $y);
	if ($deviceflag) {
	    ($x, $y) = @$coords;
	} else {
	    ($x, $y) = $zinc->transform($item, 1, $coords);
	}
	if ($i == 0) {
	    $zinc->add('arc', 1, [$x-10, $y-10, $x+10, $y+10],
		       -filled => 0,
		       -linewidth => 1,
		       -linecolor => $color,
		       -tags => ['zincdebugcontour']);
	} elsif ($i == @$contourcoords -1) {
	    $zinc->add('arc', 1, [$x-10, $y-10, $x+10, $y+10],
		       -filled => 0,
		       -linewidth => 1,
		       -linecolor => $color,
		       -tags => ['zincdebugcontour']);
	    $zinc->add('arc', 1, [$x-13, $y-13, $x+13, $y+13],
		       -filled => 0,
		       -linewidth => 1,
		       -linecolor => $color,
		       -tags => ['zincdebugcontour']);
	}
	my $dx = 3;
	if (@$coords > 2) {
	    $zinc->add('rectangle', 1, [$x-$dx, $y-$dx, $x+$dx, $y+$dx],
		       -filled => 0,
		       -linewidth => 1,
		       -linecolor => $color,
		       -tags => ['zincdebugcontour']);
	} else {
	    $zinc->add('rectangle', 1, [$x-$dx, $y-$dx, $x+$dx, $y+$dx],
		       -filled => 1,
		       -linewidth => 1,
		       -fillcolor => $color,
		       -linecolor => $color,
		       -tags => ['zincdebugcontour']);
	}
	$i++;
    }
    $zinc->raise('zincdebugcontour');
    
} # end showcontourpts


# display one point of a contour (as a rectangle)
sub showcontourpt {
    
    my ($widget, $zinc, $color, $item, $index, $deviceflag, $labels, @contour) = @_;
    $widget->focus;
    if ($index < 0 or $index >= @contour) {
	$widget->bell;
	return;
    }
    &hidecontour($zinc);
    my $bgcolor = ($labels->[0]->configure(-background))[3];
    for (@$labels) {
	$_->configure(-background => $bgcolor);
    }
    $labels->[$index]->configure(-background => 'bisque');
    my @coords = @{$contour[$index]};
    my ($x, $y);
    if ($deviceflag) {
	($x, $y) = @coords;
    } else {
	($x, $y) = $zinc->transform($item, 1, [@coords]);
    }
    my $dx = 3;
    if (@coords > 2) {
	$zinc->add('rectangle', 1, [$x-$dx, $y-$dx, $x+$dx, $y+$dx],
		   -filled => 0,
		   -linewidth => 1,
		   -linecolor => $color,
		   -tags => ['zincdebugcontour']);
    } else {
	$zinc->add('rectangle', 1, [$x-$dx, $y-$dx, $x+$dx, $y+$dx],
		   -filled => 1,
		   -linewidth => 1,
		   -fillcolor => $color,
		   -linecolor => $color,
		   -tags => ['zincdebugcontour']);
    }
    $widget->bind('<Key-Down>', [\&showcontourpt, $zinc, $color,
				 $item, $index+1, $deviceflag, $labels, @contour]);
    $widget->bind('<Key-Right>', [\&showcontourpt, $zinc, $color,
				 $item, $index+1, $deviceflag, $labels, @contour]);
    $widget->bind('<Key-Up>', [\&showcontourpt, $zinc, $color,
				$item, $index-1, $deviceflag, $labels, @contour]);
    $widget->bind('<Key-Left>', [\&showcontourpt, $zinc, $color,
				$item, $index-1, $deviceflag, $labels, @contour]);
    $zinc->raise('zincdebugcontour');

} # end showcontourpt


#---------------------------------------------------------------------------
#
# Functions related to items graphical presentation
#
#---------------------------------------------------------------------------

# display the bbox of a group item
sub showbbox {
    
    my ($btn, $zinc, $item) = @_;
    $zinc->tsave(1, 'zoom+move', 1);
    my @bbox  = $zinc->bbox($item);
    if (scalar @bbox == 4) {
	# If item is visible, rectangle is drawm surround it.
	# Else, a warning is displayed.
	unless (&itemisoutside($zinc, @bbox)) {
	    my $i = -2;
	    for ('white', 'blue', 'white') {
		$zinc->add('rectangle', 1,
			   [$bbox[0] + $i, $bbox[1] + $i,
			    $bbox[2] - $i, $bbox[3] - $i],
			   -linecolor => $_,
			   -linewidth => 1,
			   -tags => ['zincdebugbbox']);
		$i += 2;
	    }
	}
    }
    $zinc->trestore('zincdebugbbox', 'zoom+move');
    $zinc->raise('zincdebugbbox');

} # end showbbox


sub hidebbox {
    
    my ($btn, $zinc) = @_;
    $zinc->remove("zincdebugbbox");

} # end hidebbox


# display a message box when an item is not visible because outside window
sub itemisoutside {
    
    my $zinc = shift;
    my @bbox = @_;
    return unless @bbox == 4;
    &getsize($zinc);
    #print "bbox=(@bbox) wheight=$wheight{$zinc} wwidth=$wwidth{$zinc}\n";
    my $outflag;
    $WARNING = 0;
    if ($bbox[2] < 0) {
	if ($bbox[1] >  $wheight{$zinc}) {
	    $outflag = 'left+bottom';
	} elsif ($bbox[3] < 0) {
	    $outflag = 'left+top';
	} else {
	    $outflag = 'left';
	} 
    } elsif ($bbox[0] > $wwidth{$zinc}) {
	if ($bbox[1] >  $wheight{$zinc}) {
	    $outflag = 'right+bottom';
	} elsif ($bbox[3] < 0) {
	    $outflag = 'right+top';
	} else {
	    $outflag = 'right';
	}
    } elsif ($bbox[3] < 0) {
	$outflag = 'top';
    } elsif ($bbox[1] > $wheight{$zinc}) {
	$outflag = 'bottom';
    }
    #print "outflag=$outflag bbox=@bbox\n";
    return 0 unless $outflag;
    # create first group which will be translated. We will apply to this group
    # the reverse transformation of topgroup. 
    my $g = $zinc->add('group', 1, -tags => ['zincdebug']);
    # create child group which won't be affected by ancestor's scale.
    my $g1 = $zinc->add('group', $g, -composescale => 0);
    my $hw = 110;
    my $hh = 80;
    my $r = 5;
    $zinc->add('rectangle', $g1, [-$hw, -$hh, $hw, $hh],
	       -filled => 1,
	       -linecolor => 'sienna',
	       -linewidth => 3,
	       -fillcolor => 'bisque',
	       -priority => 1,
	       );
    $zinc->add('text', $g1,
	       -position => [0, 0],
	       -color => 'sienna',
	       -font => '-b&h-lucida-bold-i-normal-sans-34-240-*-*-p-*-iso8859-1',
	       -anchor => 'center',
	       -priority => 2,
	       -text => "Item is\noutside\nwindow\n");
    my ($x, $y);
    if ($outflag eq 'bottom') {
	$x = $bbox[0] + ($bbox[2]-$bbox[0])/2;
	$x = $hw + 10 if $x < $hw + 10;
	$x = $wwidth{$zinc} - $hw - 10 if $x > $wwidth{$zinc} - $hw - 10;
	$y = $wheight{$zinc} - $hh - 10;
    } elsif ($outflag eq 'top') {
	$x = $bbox[0] + ($bbox[2]-$bbox[0])/2;
	$x = $hw + 10 if $x < $hw + 10;
	$x = $wwidth{$zinc} - $hw - 10if $x > $wwidth{$zinc} - $hw - 10;
	$y = $hh + 10;
    } elsif ($outflag eq 'left') {
	$x = $hw + 10;
	$y = $bbox[1] + ($bbox[3]-$bbox[1])/2;
	$y = $hh + 10 if $y < $hh + 10;
	$y = $wheight{$zinc} - $hh - 10 if $y > $wheight{$zinc} - $hh - 10;
    } elsif ($outflag eq 'right') {
	$x = $wwidth{$zinc} - $hw - 10;
	$y = $bbox[1] + ($bbox[3]-$bbox[1])/2;
	$y = $hh + 10 if $y < $hh + 10;
	$y = $wheight{$zinc} - $hh - 10 if $y > $wheight{$zinc} - $hh - 10;
    } elsif ($outflag eq 'left+top') {
	$x = $hw + 10;
	$y = $hh + 10;
    } elsif ($outflag eq 'left+bottom') {
	$x = $hw + 10;
	$y = $wheight{$zinc} - $hh - 10;
    } elsif ($outflag eq 'right+top') {
	$x = $wwidth{$zinc} - $hw - 10;
	$y = $hh + 10;
    } elsif ($outflag eq 'right+bottom') {
	$x = $wwidth{$zinc} - $hw - 10;
	$y = $wheight{$zinc} - $hh - 10;
    }
    # apply the reverse transformation of topgroup to group $g
    $zinc->tsave(1, 'transfo', 1);
    $zinc->trestore($g, 'transfo');
    # then translate group $g1
    $zinc->coords($g1, [$x, $y]);
    $zinc->raise('zincdebug');
    
} # end itemisoutside



# highlight an item (by cloning it and hiding other found items)
# why cloning? because we can't simply make visible an item which
# belongs to an invisible group.
sub highlightitem {
    
    my ($btn, $zinc, $item, $level) = @_;
    return if $showitemflag or $item == 1;
    $showitemflag = 1;
    &surrounditem($zinc, $item, $level);
    
    $btn->bind('<ButtonRelease>', [\&undohighlightitem, $zinc]) if $btn;

} # end highlightitem


sub undohighlightitem {
    
    my ($btn, $zinc) = @_;
    #print "undohighlightitem\n";
    $btn->bind('ReleaseButton', '') if $btn;
    $zinc->remove('zincdebug');
    $showitemflag = 0;

} # end undohighlightitem


sub surrounditem {
    
    my ($zinc, $item, $level) = @_;
    $zinc->remove("zincdebug");
    # cloning
    my $clone = $zinc->clone($item, -visible => 1, -tags => ['zincdebug']);
    $zinc->tsave(1, 'zoom+move', 1);
    $zinc->chggroup($clone, 1, 1);
    my @bbox = $zinc->bbox($clone);
    # create a rectangle around 
    if (scalar @bbox == 4) {
	# If item is visible, rectangle is drawm surround it.
	# Else, a warning is displayed.
	unless (&itemisoutside($zinc, @bbox)) {
	    if (defined($level) and $level > 0) {
		my $r = $zinc->add('rectangle', 1,
				   [$bbox[0] - 10, $bbox[1] - 10,
				    $bbox[2] + 10, $bbox[3] + 10],
				   -linewidth => 0,
				   -filled => 1,
				   -tags => ['zincdebug', 'zincdebugdecorator'],
				   -fillcolor => "gray20");
		$zinc->itemconfigure($r, -fillcolor => "gray80") if $level == 1;
	    } 
	    my $i = 0;
	    for ('white', 'red', 'white') {
		$zinc->add('rectangle', 1,
			   [$bbox[0] - 5 - 2*$i, $bbox[1] - 5 - 2*$i,
			    $bbox[2] + 5 + 2*$i, $bbox[3] + 5 + 2*$i],
			   -linecolor => $_,
			   -linewidth => 1,
			   -tags => ['zincdebug', 'zincdebugdecorator']);
		$i++;
	    }
	}
    }
    # raise
    $zinc->trestore('zincdebugdecorator', 'zoom+move');
    $zinc->raise('zincdebug');
    $zinc->raise($clone);

} # end surrounditem


# functions related to transformation animations
sub showtransfo {
    
    my ($btn, $zinc, $item, $level) = @_;
    my $anim = &highlighttransfo($zinc, $item, $level);
    $btn->bind('<ButtonRelease>', [\&undohighlighttransfo, $zinc, $anim]) if $btn;

} # end showtransfo


sub highlighttransfo {
    
    my ($zinc, $item, $level) = @_;
    $zinc->remove("zincdebug");
    my $g = $zinc->add('group', 1);
    my $g0 = $zinc->add('group', $g, -alpha => 0);
    my $g1 = $zinc->add('group', $g);
    # clone item and reset its transformation
    my $clone0 = $zinc->clone($item, -visible => 1, -tags =>['zincdebug']);
    $zinc->treset($clone0);
    # clone item and preserve its transformation
    my $clone1 = $zinc->clone($item, -visible => 1, -tags => ['zincdebug']);
    # move clones is dedicated group
    $zinc->chggroup($clone0, $g0, 1);
    $zinc->chggroup($clone1, $g1, 1);
    # create a rectangle around 
    my @bbox0  = $zinc->bbox($g);
    if (scalar @bbox0 == 4) {
	$zinc->tsave(1, 'transfo', 1);
	my @bbox = $zinc->transform(1, $g, [@bbox0]);
	# If item is visible, rectangle is drawm surround it.
	# Else, a warning is displayed.
	unless (&itemisoutside($zinc, @bbox0)) {
	    my $r = $zinc->add('rectangle', $g,
			       [$bbox[0] - 10, $bbox[1] - 10,
				$bbox[2] + 10, $bbox[3] + 10],
			       -filled => 1,
			       -linewidth => 0,
			       -tags => ['zincdebug'],
			       -fillcolor => "gray90");
	    $zinc->itemconfigure($r, -fillcolor => "gray50") if $level == 1;
	    $zinc->itemconfigure($r, -fillcolor => "gray20") if $level == 2;
	    $zinc->trestore($r, 'transfo');
	}
    }
    # raise
    $zinc->raise($g);
    $zinc->raise($g0);
    $zinc->raise($g1);
    # animation
    my $anim;
    if ($zinc->cget(-render) == 0) {
	$anim = $zinc->after(150, [sub {
	    $zinc->itemconfigure($g1, -visible => 0);
	    $zinc->itemconfigure($g0, -visible => 1);
	    $zinc->update;
	}]);
    } else {
	my $maxsteps = 5;
	$step = $maxsteps;
	$anim = $zinc->repeat(100, [sub {
	    return if $step < 0;
	    $zinc->itemconfigure($g1, -alpha => ($step)*100/$maxsteps);
	    $zinc->itemconfigure($g0, -alpha => ($maxsteps-$step)*100/$maxsteps);
	    $zinc->update;
	    $step--;
	}]);


    }
    return $anim;

} # end highlighttransfo


sub undohighlighttransfo {
    
    my ($btn, $zinc, $anim) = @_;
    $btn->bind('ReleaseButton', '') if $btn;
    $zinc->remove('zincdebug');
    $zinc->afterCancel($anim);

} # end undohighlighttransfo


#---------------------------------------------------------------------------
#
# Snapshot functions
#
#---------------------------------------------------------------------------

# print a zinc window in png format
sub printWindow {
    
    exit if $saving;
    $saving = 1;
    my ($zinc) = @_;
    my $basename = $cmdoptions{snapshotBasename};
    my $id = $zinc->id;
    my $filename = $basename . $imagecounter . ".png";
    $imagecounter++;
    my $original_cursor = ($zinc->configure(-cursor))[3];
    $zinc->configure(-cursor => 'watch');
    $zinc->update;
    my $res = system("import", -window, $id, $filename);
    $zinc->configure(-cursor => $original_cursor);
    
    $saving = 0;
    if ($res) {
	&showErrorWhilePrinting($zinc, $res)
	}
    else {
	my $dir = `pwd`; chomp ($dir);
	print "Tk::Zinc::Debug: Zinc window snapshot saved in $dir". "/$filename\n";
    }

} # end printWindow


# display complete help screen
sub showErrorWhilePrinting {
    
    my ($zinc, $res) = @_;
    my $dir = `pwd`; chomp ($dir);
    $help_print->destroy if $help_print and Tk::Exists($help_print);
    $help_print = $zinc->Dialog(-title => 'Zinc Print info',
				-text =>
				"To acquire a TkZinc window snapshot, you must " .
				"have access to the import command, which is ".
				"part of imageMagic package\n\n".
				"You must also have the rights to write ".
				"in the current dir : $dir",
				-bitmap => 'warning',
				);
    $help_print->after(300, sub {$help_print->grabRelease});
    $help_print->Show();

} # end showErrorWhilePrinting

#---------------------------------------------------------------------------
#
# Help functions
#
#---------------------------------------------------------------------------

# display help about tree
sub showHelpAboutTree {
    
    my $zinc = shift;
    $helptree_tl->destroy if $helptree_tl and Tk::Exists($helptree_tl);
    $helptree_tl = $tree_tl->Toplevel;
    $helptree_tl->title("Help about Tree");

    my $text = $helptree_tl->Scrolled('Text',
					-font => scalar $zinc->cget(-font),
					-wrap => 'word',
					-foreground => 'gray10',
					-scrollbars => 'osoe',
					);
    &wheelmousebindings($text);
    $text->tagConfigure('keyword', -foreground => 'darkblue');
    $text->insert('end', "\nNAVIGATION IN TREE\n\n");
    $text->insert('end', "<Up>", "keyword");
    $text->insert('end', " arrow key moves the anchor point to the item right on ".
		  "top of the current anchor item. ");
    $text->insert('end', "<Down>", "keyword");
    $text->insert('end', " arrow key moves the anchor point to the item right below ".
		  "the current anchor item. ");
    $text->insert('end', "<Left>", "keyword");
    $text->insert('end', " arrow key moves the anchor to the parent item of the ".
		  "current anchor item. ");
    $text->insert('end', "<Right>", "keyword");
    $text->insert('end', " moves the anchor to the first child of the current anchor ".
		  "item. If the current anchor item does not have any children, moves ".
		  "the anchor to the item right below the current anchor item.\n\n");
    $text->insert('end', "\nHIGHLIGHTING ITEMS\n\n");
    $text->insert('end', "To display item's features, ");
    $text->insert('end', "double-click", "keyword");
    $text->insert('end', " on it, press ");
    $text->insert('end', "<Return>", "keyword");
    $text->insert('end', " key or click on the ");
    $text->insert('end', "Attributes", "keyword");
    $text->insert('end', " button.\n\n");
    $text->insert('end', "To highlight item in the application, simply ");
    $text->insert('end', "click", "keyword");
    $text->insert('end', " on it.");
    &infoAboutHighlighting($text);
    $text->insert('end', "\n\n\nBUILDING CODE\n\n");
    $text->insert('end', "To build perl code, select a branch or a leaf ".
		  "and click on the ");
    $text->insert('end', "Build code", "keyword");
    $text->insert('end', " button. Then select an output file with the ".
		  "file selector.\n\n");
     $text->configure(-state => 'disabled');
    
    $helptree_tl->Button(-command => sub {$helptree_tl->destroy},
			 -text => 'Close')->pack(-side => 'bottom',
						 -pady => 10);
    $text->pack->pack(-side => 'top', -pady => 10, -padx => 10);

} # end showHelpAboutTree


sub showHelpAboutCoords {
    
    my $zinc = shift;
    $helpcoords_tl->destroy if $helpcoords_tl and Tk::Exists($helpcoords_tl);
    $helpcoords_tl = $zinc->Toplevel;
    $helpcoords_tl->title("Help about coordinates");

    my $text = $helpcoords_tl->Scrolled('Text',
				      -font => scalar $zinc->cget(-font),
				      -wrap => 'word',
				      -height => 30,
				      -foreground => 'gray10',
				      -scrollbars => 'oe',
				      );
    &wheelmousebindings($text);
    $text->tagConfigure('keyword', -foreground => 'darkblue');
    $text->tagConfigure('title', -foreground => 'ivory',
			-background => 'gray60',
			-spacing1 => 3,
			-spacing3 => 3);

    
    $text->insert('end', " To display a contour\n", 'title');
    $text->insert('end', "Press button labeled ");
    $text->insert('end', 'Contour i', 'keyword');
    $text->insert('end', " (*). Release it to hide contour.");
    $text->insert('end', "\n\n");
    $text->insert('end', " To display all the points of a contour\n", 'title');
    $text->insert('end', "Press button labeled ");
    $text->insert('end', 'n points', 'keyword');
    $text->insert('end', " (*). Release it to hide points. First plot is ".
		  "particularized by a circle, last one by a double circle. ".
		  "Non-filled plots represent control points of a Bezier curve.");
    $text->insert('end', "\n\n");
    $text->insert('end', " To navigate in the contour\n", 'title');
    $text->insert('end', "Select first a point by clicking in the coordinates table ");
    $text->insert('end', "(*). Th corresponding plot is displayed. Then use the ");
    $text->insert('end', "Up/Down", 'keyword');
    $text->insert('end', " (or ");
    $text->insert('end', "Left/Right", 'keyword');
    $text->insert('end', ") arrows keys to navigate in the contour");
    $text->insert('end', "\n\n");
    $text->insert('end', "\n\n");
    $text->insert('end', "(*) The color of displayed elements depends on the mouse ".
		  "button you press.");
    $text->insert('end', "\n\n");
    $text->configure(-state => 'disabled');
    
    $helpcoords_tl->Button(-command => sub {$helpcoords_tl->destroy},
			 -text => 'Close')->pack(-side => 'bottom',
						 -pady => 10);
    $text->pack->pack(-side => 'top', -pady => 10, -padx => 10);

} # end showHelpAboutCoords



sub infoAboutHighlighting {
    
    my $text = shift;
    $text->insert('end', "By default, using ");
    $text->insert('end', "left mouse button", "keyword");
    $text->insert('end', ", highlighting is done by raising selected item and drawing ".
		  "a rectangle arround. ");
    $text->insert('end', "In order to improve visibility, ");
    $text->insert('end', "item will be light backgrounded if you use ");
    $text->insert('end', "center mouse button", "keyword");
    $text->insert('end', " and dark backgrounded if you use ");
    $text->insert('end', "right mouse button", "keyword");
    $text->insert('end', ". ");
    
} # end infoAboutHighlighting


sub entryballoonhelp {

    my $e = shift;
    my $msg = shift;
    $msg .= "Editable field. To restore the inital value\n".
	    "after edition, enter <Control-z> sequence. ";
    $balloonhelp->attach($e, -balloonposition => 'mouse',
			 -balloonmsg => $msg);
    
} # end entryballoonhelp


sub balloonhelp {
    
    my $b = $control_tl->Balloon(-balloonposition => 'widget',
				 -font => '6x13');
    $b->attach($button{zn},-balloonmsg =>
	       "Widget instance selector. Use it when \n".
	       "your application takes more than one  \n".
	       "TkZinc instance. When this mode is on,\n".
	       "select the TkZinc instance you want   \n".
	       "inspect just by clicking on it.       ");
    $b->attach($button{findenclosed}, -balloonmsg =>
	       "Inspect all items *enclosed* in a  \n".
	       "rectangular area. When this mode is\n".
	       "selected, draw rectangle using left\n".
	       "mouse button.                      ");
    $b->attach($button{findoverlap}, -balloonmsg =>
	       "Inspect all items which *overlap* \n".
	       "a rectangular area. When this mode\n".
	       "is selected, draw rectangle using \n".
	       "left mouse button.                ");
    $b->attach($button{tree}, -balloonmsg =>
	       #"Display the items hierarchy. Can\n".
	       #"build perl code corresponding to\n".
	       #"a specific branch.              ");
	       "Display the items hierarchy. Provide\n".
	       "some related functions, like building\n".
	       "perl code corresponding to a branch.");
    $b->attach($button{item}, -balloonmsg =>
	       "Locate an item in the items tree.  \n".
	       "When this mode is on, select in   \n".
	       "your application the item you want\n".
	       "to inspect just by clicking on it.");
    $b->attach($button{id}, -balloonmsg =>
	       "Open an entry field in which you will  \n".
	       "enter an item's id you want to inspect.");
    $b->attach($button{snapshot}, -balloonmsg =>
	       "Snapshot the application window.");
    $b->attach($button{cursorxy}, -balloonmsg =>
	       "Display the device coordinates\n".
	       "of the X cursor.              ");
    $b->attach($button{zoomminus}, -balloonmsg =>
	       "Shrink the top group.");
    $b->attach($button{zoomplus}, -balloonmsg =>
	       "Expand the top group.");
    $b->attach($button{move}, -balloonmsg =>
	       "Translate the top group. When this\n".
	       "mode is selected, move the top    \n".
	       "group using left mouse button.    ");
    $b->attach($button{balloon},-balloonmsg =>
	       "Balloon help toggle.");
    $b->attach($button{close},-balloonmsg =>
	       "Close this buttons bar.");
    return $b;

} # end balloonhelp



#---------------------------------------------------------------------------
#
# Bitmaps creation for the buttons of the control bar 
#
#---------------------------------------------------------------------------

sub createBitmaps {

    my $zinc = shift;
    my $bitmaps;
    
    $bitmaps->{close} = $zinc->toplevel->Bitmap(-data => <<EOF);
#define close_width 29
#define close_height 29
static unsigned char close_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x08, 0x00,
   0x00, 0x07, 0x1c, 0x00, 0x00, 0x0e, 0x0e, 0x00, 0x00, 0x1c, 0x07, 0x00,
   0x00, 0xb8, 0x03, 0x00, 0x00, 0xf0, 0x01, 0x00, 0x00, 0xe0, 0x00, 0x00,
   0x00, 0xf0, 0x01, 0x00, 0x00, 0xb8, 0x03, 0x00, 0x00, 0x1c, 0x07, 0x00,
   0x00, 0x0e, 0x0e, 0x00, 0x00, 0x07, 0x1c, 0x00, 0x00, 0x02, 0x08, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
EOF
    $bitmaps->{zn} = $zinc->toplevel->Bitmap(-data => <<EOF);
#define focus_width 29
#define focus_height 29
static unsigned char focus_bits[] = {
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0xe0, 0x3f, 0x00, 0x00, 0x60, 0x38, 0x00, 0x00,
  0x20, 0x18, 0x00, 0x00, 0x00, 0x1c, 0x00, 0x00, 0x00, 0x8e, 0x33, 0x00,
  0x00, 0x06, 0x7b, 0x00, 0x00, 0x07, 0x67, 0x00, 0x80, 0x03, 0x63, 0x00,
  0xc0, 0x01, 0x63, 0x00, 0xc0, 0x00, 0x63, 0x00, 0xe0, 0x20, 0x63, 0x00,
  0x70, 0x30, 0x63, 0x00, 0xf0, 0xbf, 0xe7, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, };
EOF
    $bitmaps->{findenclosed} = $zinc->toplevel->Bitmap(-data => <<EOF);
#define findenclosed_width 29
#define findenclosed_height 29
static unsigned char findenclosed_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3c, 0x00, 0x00, 0x00,
   0xfc, 0xff, 0xff, 0x03, 0xfc, 0xff, 0xff, 0x03, 0x3c, 0x00, 0x00, 0x03,
   0x18, 0x00, 0x00, 0x03, 0x18, 0x00, 0x00, 0x03, 0x18, 0x00, 0x00, 0x03,
   0x18, 0x00, 0x00, 0x03, 0x18, 0x00, 0x00, 0x03, 0x18, 0x00, 0x00, 0x03,
   0x18, 0x00, 0x00, 0x03, 0x18, 0x00, 0x00, 0x03, 0x18, 0x00, 0x00, 0x03,
   0x18, 0x80, 0x00, 0x03, 0x18, 0x00, 0x01, 0x03, 0x18, 0x00, 0x22, 0x03,
   0x18, 0x00, 0x24, 0x03, 0x18, 0x00, 0x28, 0x03, 0x18, 0x00, 0x20, 0x03,
   0x18, 0x00, 0x3e, 0x03, 0x18, 0x00, 0x00, 0x03, 0x18, 0x00, 0x00, 0x03,
   0xf8, 0xff, 0xff, 0x03, 0xf8, 0xff, 0xff, 0x03, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
EOF
    $bitmaps->{findoverlap} = $zinc->toplevel->Bitmap(-data => <<EOF);
#define findoverlap_width 29
#define findoverlap_height 29
static unsigned char findoverlap_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3c, 0x00, 0x00, 0x00,
   0xfc, 0xb6, 0x6d, 0x03, 0xfc, 0xb6, 0x6d, 0x03, 0x3c, 0x00, 0x00, 0x00,
   0x18, 0x00, 0x00, 0x03, 0x18, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00,
   0x18, 0x00, 0x00, 0x03, 0x18, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00,
   0x18, 0x00, 0x00, 0x03, 0x18, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00,
   0x18, 0x80, 0x00, 0x03, 0x18, 0x00, 0x01, 0x03, 0x00, 0x00, 0x22, 0x00,
   0x18, 0x00, 0x24, 0x03, 0x18, 0x00, 0x28, 0x03, 0x00, 0x00, 0x20, 0x00,
   0x18, 0x00, 0x3e, 0x03, 0x18, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00,
   0xd8, 0xb6, 0x6d, 0x03, 0xd8, 0xb6, 0x6d, 0x03, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
EOF
    $bitmaps->{tree} = $zinc->toplevel->Bitmap(-data => <<EOF);
#define tree_width 29
#define tree_height 29
static unsigned char tree_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0xf0, 0x07, 0x00, 0x00, 0x10, 0x04, 0x00, 0x00, 0x10, 0x04, 0x00,
   0xc0, 0x1f, 0x04, 0x00, 0x40, 0x10, 0x04, 0x00, 0x40, 0x10, 0x04, 0x00,
   0x40, 0xf0, 0x07, 0x00, 0x40, 0x00, 0x00, 0x00, 0x40, 0x00, 0xe0, 0x0f,
   0x40, 0x00, 0x20, 0x08, 0x7c, 0x00, 0x20, 0x08, 0x40, 0x00, 0x3f, 0x08,
   0x40, 0x00, 0x21, 0x08, 0x40, 0x00, 0x21, 0x08, 0x40, 0x00, 0xe1, 0x0f,
   0x40, 0x00, 0x01, 0x00, 0x40, 0x00, 0x01, 0x00, 0xc0, 0xff, 0x01, 0x00,
   0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00,
   0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x5f, 0x01, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
EOF
    $bitmaps->{item} = $zinc->toplevel->Bitmap(-data => <<EOF);
#define item_width 29
#define item_height 29
static unsigned char item_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x08, 0x00, 0x00, 0x00, 0x30, 0x00, 0x00, 0x00, 0xf0, 0x00, 0x00, 0x00,
   0xe0, 0x03, 0x00, 0x00, 0xe0, 0x07, 0x00, 0x00, 0xc0, 0x1f, 0x00, 0x00,
   0xc0, 0x7f, 0x00, 0x00, 0x80, 0xff, 0x01, 0x00, 0x00, 0xff, 0x03, 0x00,
   0x00, 0xff, 0x00, 0x00, 0x00, 0x7e, 0x00, 0x00, 0x00, 0xfe, 0x00, 0x00,
   0x00, 0xdc, 0x01, 0x00, 0x00, 0x8c, 0x03, 0x00, 0x00, 0x08, 0x07, 0x00,
   0x00, 0x00, 0x0e, 0x00, 0x00, 0x00, 0x1c, 0x00, 0x00, 0x00, 0x38, 0x00,
   0x00, 0x00, 0x70, 0x00, 0x00, 0x00, 0xe0, 0x00, 0x00, 0x00, 0x40, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
EOF
    $bitmaps->{id} = $zinc->toplevel->Bitmap(-data => <<EOF);
#define id_width 29
#define id_height 29
static unsigned char id_bits[] = {
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0x0e, 0x00, 0x00, 0x06, 0x0c, 0x00,
  0x00, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x00, 0x87, 0x0f, 0x00,
  0x00, 0xc6, 0x0c, 0x00, 0x00, 0x66, 0x0c, 0x00, 0x00, 0x66, 0x0c, 0x00,
  0x00, 0x66, 0x0c, 0x00, 0x00, 0x66, 0x0c, 0x00, 0x00, 0x66, 0x0c, 0x00,
  0x00, 0xc6, 0x0c, 0x00, 0x00, 0x8f, 0x1f, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, };
EOF
    $bitmaps->{snapshot} = $zinc->toplevel->Bitmap(-data => <<EOF);
#define snapshot_width 29
#define snapshot_height 29
static unsigned char snapshot_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x03, 0x1f, 0x00,
   0x80, 0x03, 0x11, 0x00, 0xe0, 0xff, 0xf1, 0x00, 0xf0, 0xff, 0xff, 0x01,
   0xf0, 0xff, 0xff, 0x01, 0xf0, 0xff, 0xff, 0x01, 0xf0, 0x0f, 0xfe, 0x01,
   0xf0, 0xe7, 0xfc, 0x01, 0xf0, 0x13, 0xf9, 0x01, 0xf0, 0x09, 0xf2, 0x01,
   0xf0, 0x05, 0xf4, 0x01, 0xf0, 0x05, 0xf4, 0x01, 0xf0, 0x05, 0xf4, 0x01,
   0xf0, 0x09, 0xf2, 0x01, 0xf0, 0x13, 0xf9, 0x01, 0xf0, 0xe7, 0xfc, 0x01,
   0xf0, 0x0f, 0xfe, 0x01, 0xf0, 0xff, 0xff, 0x01, 0xe0, 0xff, 0xff, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
EOF
    $bitmaps->{zoomminus} = $zinc->toplevel->Bitmap(-data => <<EOF);
#define zoomminus_width 29
#define zoomminus_height 29
static unsigned char zoomminus_bits[] = {
   0x00, 0x0e, 0x00, 0x00, 0xc0, 0x71, 0x00, 0x00, 0x30, 0x80, 0x01, 0x00,
   0x08, 0x00, 0x02, 0x00, 0x04, 0x00, 0x04, 0x00, 0x04, 0x00, 0x04, 0x00,
   0x02, 0x00, 0x08, 0x00, 0x02, 0x00, 0x08, 0x00, 0x02, 0x00, 0x08, 0x00,
   0xe1, 0xff, 0x10, 0x00, 0xe1, 0xff, 0x10, 0x00, 0xe1, 0xff, 0x10, 0x00,
   0x02, 0x00, 0x08, 0x00, 0x02, 0x00, 0x08, 0x00, 0x02, 0x00, 0x08, 0x00,
   0x04, 0x00, 0x04, 0x00, 0x04, 0x00, 0x04, 0x00, 0x08, 0x00, 0x02, 0x00,
   0x30, 0x80, 0x05, 0x00, 0xc0, 0x71, 0x28, 0x00, 0x00, 0x0e, 0x70, 0x00,
   0x00, 0x00, 0xf8, 0x00, 0x00, 0x00, 0xf0, 0x01, 0x00, 0x00, 0xe0, 0x03,
   0x00, 0x00, 0xc0, 0x07, 0x00, 0x00, 0x80, 0x0f, 0x00, 0x00, 0x00, 0x1f,
   0x00, 0x00, 0x00, 0x0e, 0x00, 0x00, 0x00, 0x04};
EOF

    $bitmaps->{zoomplus} = $zinc->toplevel->Bitmap(-data => <<EOF);
#define zoomplus_width 29
#define zoomplus_height 29
static unsigned char zoomplus_bits[] = {
   0x00, 0x0e, 0x00, 0x00, 0xc0, 0x71, 0x00, 0x00, 0x30, 0x80, 0x01, 0x00,
   0x08, 0x00, 0x02, 0x00, 0x04, 0x00, 0x04, 0x00, 0x04, 0x0e, 0x04, 0x00,
   0x02, 0x0e, 0x08, 0x00, 0x02, 0x0e, 0x08, 0x00, 0x02, 0x0e, 0x08, 0x00,
   0xe1, 0xff, 0x10, 0x00, 0xe1, 0xff, 0x10, 0x00, 0xe1, 0xff, 0x10, 0x00,
   0x02, 0x0e, 0x08, 0x00, 0x02, 0x0e, 0x08, 0x00, 0x02, 0x0e, 0x08, 0x00,
   0x04, 0x0e, 0x04, 0x00, 0x04, 0x00, 0x04, 0x00, 0x08, 0x00, 0x02, 0x00,
   0x30, 0x80, 0x05, 0x00, 0xc0, 0x71, 0x28, 0x00, 0x00, 0x0e, 0x70, 0x00,
   0x00, 0x00, 0xf8, 0x00, 0x00, 0x00, 0xf0, 0x01, 0x00, 0x00, 0xe0, 0x03,
   0x00, 0x00, 0xc0, 0x07, 0x00, 0x00, 0x80, 0x0f, 0x00, 0x00, 0x00, 0x1f,
   0x00, 0x00, 0x00, 0x0e, 0x00, 0x00, 0x00, 0x04};
EOF

    $bitmaps->{move} = $zinc->toplevel->Bitmap(-data => <<EOF);
#define hand_width 29
#define hand_height 29
static unsigned char hand_bits[] = {
   0x00, 0xe0, 0x00, 0x00, 0x00, 0x10, 0x01, 0x00, 0x80, 0x13, 0x0f, 0x00,
   0x40, 0x12, 0x11, 0x00, 0x40, 0x14, 0x11, 0x00, 0x40, 0x14, 0xd1, 0x01,
   0x80, 0x14, 0x31, 0x02, 0x80, 0x14, 0x31, 0x02, 0x80, 0x18, 0x31, 0x02,
   0x80, 0x18, 0x31, 0x02, 0x00, 0x11, 0x31, 0x02, 0x00, 0x11, 0x11, 0x01,
   0x1c, 0x11, 0x11, 0x01, 0x22, 0x01, 0x11, 0x01, 0x42, 0x01, 0x10, 0x01,
   0x84, 0x01, 0x00, 0x01, 0x88, 0x01, 0x00, 0x01, 0x08, 0x01, 0x00, 0x02,
   0x08, 0x02, 0x00, 0x02, 0x10, 0x00, 0x00, 0x02, 0x20, 0x00, 0x00, 0x02,
   0x20, 0x00, 0x00, 0x02, 0x40, 0x00, 0x00, 0x02, 0x40, 0x00, 0x00, 0x01,
   0x80, 0x00, 0x80, 0x00, 0x00, 0x01, 0x80, 0x00, 0x00, 0x06, 0x40, 0x00,
   0x00, 0x08, 0x40, 0x00, 0x00, 0x08, 0x40, 0x00};
EOF

    $bitmaps->{balloon} = $zinc->toplevel->Bitmap(-data => <<EOF);
#define balloon_width 29
#define balloon_height 29
static unsigned char balloon_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe0, 0xff, 0xff, 0x00,
   0x10, 0x00, 0x00, 0x01, 0x08, 0x00, 0x00, 0x02, 0x08, 0x00, 0x00, 0x02,
   0x08, 0x00, 0x00, 0x02, 0x08, 0x00, 0x00, 0x02, 0x08, 0x00, 0x00, 0x02,
   0x08, 0x00, 0x00, 0x02, 0x08, 0x00, 0x00, 0x02, 0x08, 0x00, 0x00, 0x02,
   0x08, 0x00, 0x00, 0x02, 0x08, 0x00, 0x00, 0x02, 0x08, 0x00, 0x00, 0x02,
   0x10, 0x00, 0x00, 0x01, 0xe0, 0xe0, 0xff, 0x00, 0x00, 0x11, 0x00, 0x00,
   0x00, 0x09, 0x00, 0x00, 0x80, 0x04, 0x00, 0x00, 0x80, 0x02, 0x00, 0x00,
   0x40, 0x01, 0x00, 0x00, 0xc0, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
EOF

    $bitmaps->{cursorxy} = $zinc->toplevel->Bitmap(-data => <<EOF);
#define balloon_width 29
#define balloon_height 29
static unsigned char balloon_bits[] = {
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
  0x00, 0x06, 0x00, 0x00, 0x00, 0x1e, 0x00, 0x00, 0x00, 0x7c, 0x00, 0x00,
  0x00, 0x1c, 0x00, 0x00, 0x00, 0x28, 0x00, 0x00, 0x00, 0x48, 0x00, 0x00,
  0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x02, 0x00,
  0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x30, 0x06, 0x8c, 0x01, 0x70, 0x07, 0x8c, 0x01, 0x60, 0x03, 0x8c, 0x01,
  0xc0, 0x01, 0xd8, 0x00, 0xc0, 0x01, 0xd8, 0x00, 0x60, 0xe3, 0xd8, 0x00,
  0x70, 0x66, 0x70, 0x00, 0x30, 0x66, 0x70, 0x00, 0x00, 0x30, 0x60, 0x00,
  0x00, 0x30, 0x30, 0x00, 0x00, 0x00, 0x30, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, };
EOF

    return $bitmaps;
   
} # end  createBitmaps


#---------------------------------------------------------------------------
#
# Miscellaneous
#
#---------------------------------------------------------------------------

sub getsize {
    
    my $zinc = shift;
    $wwidth{$zinc} = $zinc->cget(-width);
    $wheight{$zinc} = $zinc->cget(-height);
        
} # end getsize


sub entryoption {
    
    my ($fm, $item, $zinc, $option, $def, $widthmax, $widthmin, $height) = @_;
    my $arrayflag;
    unless (defined $def) {
	my @def = $zinc->itemcget($item, $option);
	if (@def > 1) {
	    $arrayflag = 1;
	    $def = join(', ', @def);
	} else {
	    $def = $def[0];
	}
    }
    $def = "" unless defined $def;
    my $i0;
    my $e;
    if ($def =~ /\n/) {
	$height = 1 unless defined($height);
	$e = $fm->Text(-height => $height, -width => 1, -wrap => 'none');
	$i0 = '0.0';
    } else {
	$e = $fm->Entry();
	$i0 = 0;
    }
    &entryballoonhelp($e);
    my $width = length($def);
    $width = $widthmax if defined($widthmax) and $width > $widthmax;
    $width = $widthmin if defined($widthmin) and $width < $widthmin;
    $e->configure(-width => $width);
    if ($defaultoptions{$item}->{$option} and
	$def ne $defaultoptions{$item}->{$option}) {
	$e->configure(-foreground => 'blue');
    }
    
    $e->insert($i0, $def);
    $e->bind('<Control-z>', sub {
	return unless defined $defaultoptions{$item}->{$option};
	my $bg = $e->cget(-background);
	$zinc->itemconfigure($item, $option => $defaultoptions{$item}->{$option});
	$e->delete($i0, 'end');
	$e->insert($i0, $defaultoptions{$item}->{$option});
	$e->configure(-background => 'ivory');
	$e->after(80, sub {$e->configure(-background => $bg, -foreground => 'black')});
    });
    $e->bind('<Key-Return>',
	     sub {my $val = $e->get;
		  my $bg = $e->cget(-background);
		  $e->configure(-background => 'ivory');
		  if ($def ne $val) {
		      $defaultoptions{$item}->{$option} = $def
			  unless $defaultoptions{$item}->{$option};
		  }
		  my $fg = ($val ne $defaultoptions{$item}->{$option}) ?
		      'blue' : 'black';
		  $e->after(80, sub {
		      $e->configure(-background => $bg, -foreground => $fg);
		  });
		  if ($arrayflag) {
		      $zinc->itemconfigure($item, $option => [split(/,/, $val)]);
		  } else {
		      $zinc->itemconfigure($item, $option => $val);
		  }
	      });

    return $e;

} # end entryoption


sub entrytransfo {
    
    my ($fm, $item, $zinc, $attr, $def, $var, $width, $set_cb) = @_;
    my $i0;
    my $e;
    $e = $fm->Entry(-textvariable => $var);
    &entryballoonhelp($e);
    $i0 = 0;
    $width = length($def) unless $width;
    $e->configure(-width => $width);   
    $e->insert($i0, $def);
    $e->bind('<Control-z>', sub {
	my $bg = $e->cget(-background);
	$e->delete($i0, 'end');
	$e->insert($i0, $def);
	$e->configure(-background => 'ivory');
	$e->after(80, sub {$e->configure(-background => $bg, -foreground => 'black')});
	&$set_cb;
    });
    $e->bind('<Key-Return>',
	     sub {my $val = $e->get;
		  my $bg = $e->cget(-background);
		  $e->configure(-background => 'ivory');
		  my $fg = ($val ne $def) ? 'blue' : 'black';
		  $e->after(80, sub {
		      $e->configure(-background => $bg, -foreground => $fg);
		  });
		  &$set_cb;
	      });

    return $e;

} # end entrytransfo


sub instances {
    
    return @instances;
    
} # end instances


sub saveMotionBinding {

    my ($zinc) = @_;
    for my $seq ('Motion') {
	$userbindings{$zinc}->{$seq} = $zinc->Tk::bind('<'.$seq.'>')
	    unless defined $userbindings{$zinc}->{$seq};
	$userbindings{$zinc}->{$seq} = "" unless defined $userbindings{$zinc}->{$seq};
	$zinc->Tk::bind('<'.$seq.'>', "");
    }
    
} # end saveMotionBinding


sub restoreMotionBinding {

    my ($zinc) = @_;
    for my $seq ('Motion') {
	next unless defined $userbindings{$zinc}->{$seq};
	$zinc->Tk::bind('<'.$seq.'>', $userbindings{$zinc}->{$seq});
	delete $userbindings{$zinc}->{$seq};
    }
    
} # end restoreMotionBinding


sub saveDragAndDropBindings {

    my ($zinc) = @_;
    for my $seq ('ButtonPress-1', 'B1-Motion', 'ButtonRelease-1') {
	$userbindings{$zinc}->{$seq} = $zinc->Tk::bind('<'.$seq.'>')
	    unless defined $userbindings{$zinc}->{$seq};
	$userbindings{$zinc}->{$seq} = "" unless defined $userbindings{$zinc}->{$seq};
	#print "saveDragAndDropBindings seq=$seq cb=$userbindings{$zinc}->{$seq}\n";
	$zinc->Tk::bind('<'.$seq.'>', "");
    }
    
} # end saveDragAndDropBindings


sub restoreDragAndDropBindings {

    my ($zinc) = @_;
    for my $seq ('ButtonPress-1', 'B1-Motion', 'ButtonRelease-1') {
	next unless defined $userbindings{$zinc}->{$seq};
	$zinc->Tk::bind('<'.$seq.'>', $userbindings{$zinc}->{$seq});
	#print "restoreDragAndDropBindings seq=$seq cb=$userbindings{$zinc}->{$seq}\n";
	delete $userbindings{$zinc}->{$seq};
    }
    
} # end restoreDragAndDropBindings


sub newinstance {
    
    my $zinc = shift;
    return if $instances{$zinc};
    $zinc->toplevel->Tk::bind('<Key-Escape>', \&Tk::Zinc::Debug::deiconify);
    $instances{$zinc} = 1;    
    push(@instances, $zinc);
    $zinc->Tk::focus;
    $selectedzinc = $zinc;
    
} # end newinstance


sub deiconify {

    $button{zn}->destroy() if @instances == 1 and Tk::Exists($button{zn});
    $control_tl->deiconify();
    for (values %result_tl) {
	$_->deiconify if Tk::Exists($_);
    }
    for (values %coords_tl) {
	$_->deiconify if Tk::Exists($_);
    }
    for (values %alloptions_tl) {
	$_->deiconify if Tk::Exists($_);
    }
    $tree_tl->deiconify if Tk::Exists($tree_tl);
    $search_tl->deiconify if Tk::Exists($search_tl);
    $searchtree_tl->deiconify if Tk::Exists($searchtree_tl);
    $cursorxy_tl->deiconify if Tk::Exists($cursorxy_tl);
    $control_tl->raise();

} # end deiconify


sub iconify {

    for (values %result_tl) {
	$_->withdraw if Tk::Exists($_);
    }
    for (values %coords_tl) {
	$_->withdraw if Tk::Exists($_);
    }
    for (values %alloptions_tl) {
	$_->withdraw if Tk::Exists($_);
    }
    $tree_tl->withdraw if Tk::Exists($tree_tl);
    $search_tl->withdraw if Tk::Exists($search_tl);
    $searchtree_tl->withdraw if Tk::Exists($searchtree_tl);
    $cursorxy_tl->withdraw if Tk::Exists($cursorxy_tl);
    $control_tl->withdraw();

} # end iconify

# wheelmousebindings doesn't work for Tk::Pane widgets...
sub wheelmousebindings {
    my $w = shift;
    my $count = shift;
    $count = 3 unless $count > 0;

    $w->bind('<Control-ButtonPress-4>', sub {$w->yview('scroll', -1, 'page')});
    $w->bind('<Shift-ButtonPress-4>', sub {$w->yview('scroll', -1, 'unit')});
    $w->bind('<ButtonPress-4>', sub {$w->yview('scroll', -$count, 'unit')});
    
    $w->bind('<Control-ButtonPress-5>', sub {$w->yview('scroll', 1, 'page')});
    $w->bind('<Shift-ButtonPress-5>', sub {$w->yview('scroll', 1, 'unit')});
    $w->bind('<ButtonPress-5>', sub {$w->yview('scroll', $count, 'unit')});

} # end wheelmousebindings

1;

__END__

    
=head1 NAME

Tk::Zinc::Debug - a perl module for analysing a Zinc application. 


=head1 SYNOPSIS

 perl -MTk::Zinc::Debug zincscript [zincscript-opts] [Debug-initopts]
    
     or
    
 use Tk::Zinc::Debug;
 my $zinc = MainWindow->new()->Zinc()->pack;
 Tk::Zinc::Debug::init($zinc, [options]);


=head1 DESCRIPTION

Tk::Zinc::Debug provides an interface to help developers to inspect Zinc applications.

Press the B<Escape> key in the toplevel of your application to display the Tk::Zinc::Debug buttons bar.


Features :

=over
    
=item B<o> scan a rectangular area

Scan all items which are enclosed in a rectangular area you have first drawn by drag & drop, or all items which overlap it. Result is a Tk table which presents details (options, coordinates, ...) about found items; you can also highlight a particular item, even if it's not visible, by clicking on its corresponding button in the table. You can also display particular item's features by entering this id in dedicated entry field

=item B<o> display items hierarchy

You can find a particular item's position in the tree and you can highlight items and see their features as described above. You can also generate the perl code corresponding to a selected branch (but images can't be reproduced).

=item B<o> snapshot the application window

In order to illustrate a graphical bug for example.
    
=item B<o> display coordinates of the X cursor.
    
=item B<o> zoom/translate the top group
    
=back


=head2 Loading Tk::Zinc::Debug as a plugin
    
If you load Tk::Zinc::Debug using the -M perl option, B<nothing needs to be added to your code>. In this case, the B<init()> function is automatically invoked with its default attributes for each instance of Zinc widget. You can overload these by passing the same options to the command. 

=head1 FUNCTION


=over

=item B<init>($zinc, ?option => value, ...?)

This function creates required Tk bindings to permit items search. You can specify the following options :

=over

=item E<32>E<32>E<32>B<-optionsToDisplay> => opt1[,..,optN]

Used to display some option's values associated to items of the tree. Expected argument is a string of commas separated options.

=item E<32>E<32>E<32>B<-optionsFormat> => row | column

Defines the display format of option's values. Default is 'row'.
    
=item E<32>E<32>E<32>B<-snapshotBasename> => string

Defines the basename used for the file containing the snaphshot. The filename will be <current­dir>/basename<n>.png  Defaulted to 'zincsnapshot'.

=item E<32>E<32>E<32>B<-expandTagsField> => 0 | 1

Specifies if the tags field in the attributes window will be expanded to show all the items tags (it should take up a lot of space). In the default case (value is set to 0), only the head of the list is displayed.


=back


=back
    

=head1 AUTHOR

Daniel Etienne <etienne@cena.fr>

    
=head1 HISTORY

Oct 5 2004 : transformations are correctly managed in built code. Transfo parameters can be displayed and set. new mode to display coordinateds of X cursor.

Oct 14 2003 : add a control bar, and zoom/translate new functionalities. finditems(), tree(), snapshot() functions become deprecated, initialisation is done using the new init() function.

Oct 07 2003 : contours of curves can be displayed and explored.

Sep 15 2003 : due to CPAN-isation, the ZincDebug module has been renamed Tk::Zinc::Debug

May 20 2003 : perl code can be generated from the items tree, with some limitations concerning transformations and images.

Mar 11 2003 : ZincDebug can manage several instances of Zinc widget. Options of ZincDebug functions can be set on the command line. 

Jan 20 2003 : item's attributes can be edited.

Jan 14 2003 : ZincDebug can be loaded at runtime using the -M perl option without any change in the application's code.

Nov 6 2002 : some additional informations (like tags or other attributes values) can be displayed in the items tree. Add feedback when selected item is not visible because outside window.

Sep 2 2002 : add the tree() function

May 27 2002 : add the snapshot() function contributed by Ch. Mertz.
    
Jan 28 2002 : Zincdebug provides the finditems() function and can manage only one instance of Zinc widget. 
