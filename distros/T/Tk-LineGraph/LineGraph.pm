$Tk::LineGraph::VERSION = '0.01';

package Tk::LineGraph;

use POSIX;
use Carp;
use Tk::widgets qw/Canvas/;
use base qw/Tk::Derived Tk::Canvas/;
require Tk::DialogBox; 
require Tk::BrowseEntry;
use strict;

Construct Tk::Widget 'LineGraph';
# Tk::Widget->Construct('LineGraph');

sub ClassInit {

    my($class, $mw ) = @_;
    $class->SUPER::ClassInit($mw);

    $Tk::LineGraph::MW = $mw;   # save the main window 
}

# Class data to track mega-item items. Not used as yet.
my $id = 0;
my %ids = ();

my $MW;    # main window refer to by $Tk::LineGraph::MW

sub Populate {
  
  my($self, $args) = @_;
  $self->SUPER::Populate($args);


  my @def_colors = qw/ gray SlateBlue1 blue1 DodgerBlue4  DeepSkyBlue2  SeaGreen3 green4 khaki4 gold3 gold1 firebrick1 brown4 magenta1 purple1 HotPink1 chocolate1 black/;
  $self->ConfigSpecs
    (
     -colors       => ['PASSIVE', 'colors',        'Colors',     \@def_colors],
     -boarder      => ['PASSIVE', 'boarder',       'Boarder',    [25,50,100,50] ],
     -scale        => ['PASSIVE', 'scale',         'Scale',      [0,100, 10, 0, 100, 10, 0, 100, 10] ],  
     -zoom         => ['PASSIVE', 'zoom',          'Zoom',       [0, 0, 0, 0, 0] ],
     -plotTitle    => ['PASSIVE', 'plottitle',     'PlotTitle',  ['Default Plot Title',7 ] ],
     -xlabel       => ['PASSIVE', 'xlabel',        'Xlabel',     'X Axis Default Label'],
     -ylabel       => ['PASSIVE', 'ylabel',        'Ylabel',     'Y Axis Default Label'],
     -y1label      => ['PASSIVE', 'Y1label',       'Y1label',    'Y1 Axis Default Label'],
     -xTickLabel   => ['PASSIVE', 'xticklabel',    'Xticklabel',     undef],
     -yTickLabel   => ['PASSIVE', 'yticklabel',    'Yticklabel',     undef],
     -y1TickLabel  => ['PASSIVE', 'y1ticklabel',   'Y1ticklabel',    undef],
     -xType        => ['PASSIVE', 'xtype',         'Xtype',       'linear'],  # could be time, but not yet
     -yType        => ['PASSIVE', 'ytype',         'Ytype',       'linear'],  # could be log
     -y1Type       => ['PASSIVE', 'y1type',        'Y1type',      'linear'],  # could be log
     -fonts        => ['PASSIVE', 'fonts',         'Fonts',       ['Times 10','Times 15','Times 18','Times 18'] ],
     -autoScaleY   => ['PASSIVE', 'autoscaley',    'AutoScaleY',      'On'],
     -autoScaleX   => ['PASSIVE', 'autoscalex',    'AutoScaleX',      'On'],
     -autoScaleY1  => ['PASSIVE', 'autoscaley1',   'AutoScaleY1',     'On'],
     -logMin       => ['PASSIVE', 'logMin',        'LogMin',         0.001],

    );
  #helvetica Bookman Schumacher
  # The four fonts are axis ticks[0], axis lables[1], plot title[2], and legend[3]
  $self->{-logCheck} = 0; # false, don't need to check on range of log data  
  # OK, setup the dataSets list
  $self->{-datasets}  = []; # empty array, will be added to 
  $self->{-zoomStack} = []; # empty array which will get the zoom stack
  #Some bindings here
  # use button 1 for zoom
  $self->Tk::bind("<Button-1>" ,        [  \&zoom, 0 ]   );
  $self->Tk::bind("<ButtonRelease-1>" , [  \&zoom, 1 ]   );
  $self->Tk::bind("<B1-Motion>" ,       [  \&zoom, 2 ]   );
  # button 2 to see coordinates, in the World system, of the mouse.
  $self->Tk::bind("<Button-2>" ,        [ \&printXY, "down" ] );
  $self->Tk::bind("<ButtonRelease-2>" , [ \&printXY, "up"   ] );
    
  # menu bar 
  my $mw = $Tk::LineGraph::MW;
  my $menubar = $mw->Menu;
  $mw->configure(-menu => $menubar);
  my $plotSetup = $menubar->cascade(-label => 'PlotSetup',-tearoff=>0);
  $plotSetup->command(-label=>'Plot Title',-command=>     [ \&plotTitleMenu, $self, 1]);
  $plotSetup->command(-label=>'Boarders',-command=>       [ \&boadersMenu, $self, 1]);
  $plotSetup->command(-label=>'Fonts',-command=>          [ \&fontsMenu, $self, 1]);

  my $options = $menubar->cascade(-label => 'Options',-tearoff=>0);
  $options->command(-label=>'Hide/Show',-command=>     [ \&hideShowLb, $self, 1]);
  $options->command(-label=>'Zoom Out(2)', -command=>  [ \&zoomInOut, $self, 1]);
  $options->command(-label=>'Zoom In(1/2)',-command=>  [ \&zoomInOut, $self, 2]);
  $options->command(-label=>'Rescale All',-command=>   [ \&rescale, $self, 'all']);
  $options->command(-label=>'Rescale Active',-command=>[ \&rescale, $self, 'Active']);
  $options->command(-label=>'Datasets',      -command=>[ \&datasetsMenu, $self, 1]);

  my $axis    = $menubar->cascade(-label => 'Axis',-tearoff=>0);
  $axis->command(-label=>'X Axis', -command=> [\&configAxisMenu, $self, 'X'] );
  $axis->command(-label=>'Y Axis' ,-command=> [\&configAxisMenu, $self, 'Y'] );
  $axis->command(-label=>'Y1 Axis',-command=> [\&configAxisMenu, $self, 'Y1'] );

  $mw->bind('<Configure>' => [\&resize, $self] );

  my $help = $menubar->cascade(-label => 'Help');

 } # end Populate
    
sub fontsMenu {
  # The four fonts are axis ticks[0], axis lables[1], plot title[2], and legend[3]
  use strict;
  require Tk::LabEntry;
  my $mw = $Tk::LineGraph::MW;
  my $self = shift;
  my $f = $self->cget('-fonts');
  my($f0,$f1,$f2,$f3) = @{$f};
  my $db = $mw->DialogBox
    (-title=> 'Fonts',
     -buttons=>['Apply', 'Cancel'],
     -default_button => 'Apply');
  $db->add
    ('LabEntry',
     -textvariable => \$f0 ,
     -label => "Axis Ticks Font",
     -labelPack => [-side => 'left']) ->pack;
   $db->add
    ('LabEntry',
     -textvariable => \$f1,
     -label => "Axis Label Font",
     -labelPack => [-side => 'left']) ->pack;
   $db->add
    ('LabEntry',
     -textvariable => \$f2,
     -label => "Plot Title Font",
     -labelPack => [-side => 'left']) ->pack;
   $db->add
    ('LabEntry',
     -textvariable => \$f3,
     -label => "Legend Font",
     -labelPack => [-side => 'left']) ->pack;

  my $answer = $db->Show();
    return if($answer ne 'Apply');
  @{$f} = ($f0,$f1,$f2,$f3);
  $self->configure('-fonts' => $f);
  $self->rescale();
}
# Verdana, Tahoma, Times New Roman, Arial, Trebuchet, Comic Sans, Impact 
sub boadersMenu {
  use strict;
  require Tk::LabEntry;
  my $mw = $Tk::LineGraph::MW;
  my $self = shift;
  my $b = $self->cget('-boarder');
  my($top,$right,$bottom,$left) = @{$b};
  my $background = $self->cget('-background');
  my $db = $mw->DialogBox
    (-title=> 'Boarders',
     -buttons=>['Apply', 'Cancel'],
     -default_button => 'Apply');
  $db->add
    ('LabEntry',
     -textvariable => \$top,
     -label => "Top boarder in Pixels",
     -labelPack => [-side => 'left']) ->pack;
   $db->add
    ('LabEntry',
     -textvariable => \$right,
     -label => "Right boarder in Pixels",
     -labelPack => [-side => 'left']) ->pack;
   $db->add
    ('LabEntry',
     -textvariable => \$bottom,
     -label => "Bottom boarder in Pixels",
     -labelPack => [-side => 'left']) ->pack;
   $db->add
    ('LabEntry',
     -textvariable => \$left,
     -label => "Left boarder in Pixels",
     -labelPack => [-side => 'left']) ->pack;
   $db->add
    ('LabEntry',
     -textvariable => \$background,
     -label => "Background Color",
     -labelPack => [-side => 'left']) ->pack;

  my $answer = $db->Show();
    return if($answer ne 'Apply');
  $self->configure('-background' => $background);
  @{$b} = ($top,$right,$bottom,$left);
  $self->configure('-boarder' => $b);
  $self->rescale();
}

sub plotTitleMenu {
  use strict;
  require Tk::LabEntry;
  my $mw = $Tk::LineGraph::MW;
  my $self = shift;
  my $p = $self->cget('-plotTitle');
  my $plotTitle = $p->[0];
  my $fromTop = $p->[1];
  my $db = $mw->DialogBox
    (-title=> 'Plot Title',
     -buttons=>['Apply', 'Cancel'],
     -default_button => 'Apply');
  $db->add
    ('LabEntry',
     -textvariable => \$plotTitle,
     -label => "Plot Title",
     -labelPack => [-side => 'left']) ->pack;
   $db->add
    ('LabEntry',
     -textvariable => \$fromTop,
     -label => "Pixles from top",
     -labelPack => [-side => 'left']) ->pack;

  my $answer = $db->Show();

  #	$self->configure(-scale=>[$xMinP, $xMaxP, $xIntervals,$yMinP, $yMaxP, $yIntervals]);
  return if($answer ne 'Apply');
  $p->[0] = $plotTitle;
  $p->[1] = $fromTop;
  $self->configure('-plotTitle' => $p);
  $self->rescale();
}
sub resize { # called when the window changes size (configured)
    use strict;
    my $self = shift;   # can be either main window or canvas (Plot)
    my $c = shift;  # canvas
    # Comes in here for both the main window and the canvas
    my $what = ref($self);
    # get the current size;
    if($what =~ /MainWindow/) {
      # get the current size of the main window 
      my $g = $self->geometry();  # <902x902+177+0> page 239 
      my ($w,$h,$a,$b) = split(/[x+]/,$g);
      # print "resize  h,w ($h,$w),offset  ($a,$b) \n";
      # now make the canvas bigger
      # but first look to see if it is already that size, then nothing to do
      my $ch = $c->cget('-height');
      my $cw = $c->cget('-width');
      # print "resize mw size is ($h,$w)  current canvas size is ($ch,$cw)\n";
      if((abs($ch-$h) > 10 ) or (abs($cw-$w) > 10 ) ) {
        $c->configure('-height'=> $h);
        $c->configure('-width'=> $w);
        # print "resize change the canvas size.\n";
        $c->rescale();
      }
      return;
    }
    return;
    my $h = $self->cget('-height');
    my $w = $self->cget('-width');
    # print "resize The new canvas (h,w) ($h,$w)\n";
    my $g = $self->geometry();
    # print "resize geometry for canvas <$g>\n\n";
}

sub rescale { # all, active, not 
  # rescale the plot and redraw. Scale to  all or just active as per argument
  use strict;
  my($self, $how, %args)  = @_;
  $self->delete('all');      # empty the canvas, erase
  $self->scalePlot($how) if($how ne "not");    # Get max and min for scalling
  $self->drawAxis();     # both x and y for now
  $self->titles();
  $self->drawDatasets(%args);
  $self->legends(%args);
}

sub configAxisMenu {  # which axis, X,Y,Y1
    use strict;
    require Tk::LabEntry;
    my $mw = $Tk::LineGraph::MW;
    my $self = shift;
    my $which = shift;
    # print "configAxisMenu for axis <$which> \n";
    my $t = "Configuer $which Axis";
    my($min, $max, $int, $s, $color, $label, $db, $type, $autoScale);
    my $scale = $self->cget('-scale');
    #[$xMinP, $xMaxP, $xIntervals,$yMinP, $yMaxP, $yIntervals]);
    if($which eq 'X') {
      ($min, $max, $int)  = ($scale->[0], $scale->[1], $scale->[2]);
      $label = $self->cget('-xlabel');
      $type = $self->cget('-xType');
      $autoScale = $self->cget('-autoScaleX');
    } elsif($which eq 'Y') {
      ($min, $max, $int)  = ($scale->[3], $scale->[4], $scale->[5]);
      $label = $self->cget('-ylabel'); 
      $type = $self->cget('-yType'); 
      $autoScale = $self->cget('-autoScaleY');
    } else { # Y1
      ($min, $max, $int)  = ($scale->[6], $scale->[7], $scale->[8]);
      $label = $self->cget('-y1label');
      $type = $self->cget('-y1Type');
      $autoScale = $self->cget('-autoScaleY1');
    }

    $db = $mw->DialogBox
	(-title=> $t,
	 -buttons=>['Apply', 'Cancel'],
	 -default_button => 'Apply');
    $db->add
	('LabEntry',
	 -textvariable => \$min,
	 -label => "$which Min",
	 -labelPack => [-side => 'left']) ->pack;
    
    $db->add
	('LabEntry',
	 -textvariable => \$max,
	 -label => "$which Max",
	 -labelPack => [-side => 'left']) ->pack;
    
    $db->add
	('LabEntry',
	 -textvariable => \$int,
	 -label => 'Intervals',
	 -labelPack => [-side => 'left']) ->pack;
    
    $db->add
	('LabEntry',
	 -textvariable => \$label,
	 -label => "$which Label",
	 -labelPack => [-side => 'left']) ->pack;
# axis type
    if($which =~ /Y/) {
	my $f0 = $db->add('Frame')->pack;
	$db->add
	    ('Radiobutton',
	     -text=>'Linear Scale',
	     -value => 'linear',
	     -variable=>\$type)->pack(-in=>$f0, -side => 'left');
	
	$db->add
	    ('Radiobutton',
	     -text=>'Log Scale',
	     -value => 'log',
	     -variable=>\$type)->pack( -in=>$f0, -side => 'left');
    }
# auto scaling	
    my $f1 =  $db->add('Frame')->pack;
    $db->add
	('Radiobutton',
	 -text=>'Auto Scale On',
	 -value => 'On',
	 -variable=>\$autoScale)->pack(   -in=>$f1, -side => 'left'          );
    
    $db->add
	('Radiobutton',
	 -text=>'Auto Scale Off',
	 -value => 'Off',
	 -variable=>\$autoScale)->pack(      -in=>$f1, -side => 'left'     );
   
    my $answer = $db->Show();
    # print "configAxis answer <$answer>\n";
    #	$self->configure(-scale=>[$xMinP, $xMaxP, $xIntervals,$yMinP, $yMaxP, $yIntervals]);
    return if($answer ne 'Apply');
    # print "configAxis for <$which>\n";
    if($which eq 'X') {
	$self->configure(-scale=>[$min, $max, $int, $scale->[3], $scale->[4], $scale->[5],$scale->[6], $scale->[7], $scale->[8]  ] );
	$self->configure('-xlabel'=>$label);
	$self->configure(-autoScaleX=>$autoScale);
    } elsif($which eq 'Y')  {
	$self->configure(-scale=>[ $scale->[0], $scale->[1], $scale->[2], $min, $max, $int,$scale->[6], $scale->[7], $scale->[8]   ] );
	$self->configure('-ylabel'=>$label);
	$self->configure('-yType'=>$type);
	$self->configure(-autoScaleY=>$autoScale);
    } else { 
	$self->configure(-scale=>[ $scale->[0], $scale->[1], $scale->[2], $scale->[3], $scale->[4], $scale->[5], $min, $max, $int ] );
	$self->configure('-y1label'=>$label);
	$self->configure('-y1Type'=>$type);
	$self->configure(-autoScaleY1=>$autoScale);
    }
    #draw again
    $s = $self->cget(-scale);
    # print "configAxis  $s->[0], $s->[1], $s->[2],  $s->[3], $s->[4], $s->[5] \n";
    $self->delete("all");
    $self->rescale('all');  # this all means active and non active 


}

sub zoom { 
  # start to do the zoom
  use strict;
  my $self = shift;
  my $which = shift;
  my $z;
  print "zoom which is <$which> self <$self> \n"if($which == 1  or $which == 3);
  if($which == 0) { # button 1 down 
    my $e = $self->XEvent;
    my ($a,$b) = ($e->x, $e->y);
    $z = $self->cget('-zoom');
    $z->[0] = $a; $z->[1] = $b;
    $self->configure('-zoom' => $z);
  } elsif($which == 1) {  # button 1 release, that is do zoom
    my $e = $self->XEvent;
    my ($a,$b) = ($e->x, $e->y);
    $z = $self->cget('-zoom');
    $z->[2] = $a; $z->[3] = $b;
    $self->configure('-zoom' => $z);
    # OK, we can now do the zoom
    # print "zoom $z->[0],$z->[1] $z->[2],$z->[3] \n";

    # If the box is small we undo one level of zoom
    if( (abs($z->[0]-$z->[2]) < 3)  and (abs($z->[1]-$z->[3]) < 3) ) {
	# try to undo one level of zoom
	return if(@{$self->{'-zoomStack'}} == 0);  # no zooms to undo
	my $s = pop(@{$self->{'-zoomStack'}} );
	# print "zoom off stack $s->[3], $s->[4] \n";
	$self->configure(-scale=>$s);
	# if we have a time axis then we must generate the labels again, also log axis?
	if($self->cget('-xType') eq 'time') {
	  my($xMinP, $xMaxP, $xIntervals, $tickLabels) = timeRange($s->[0], $s->[1]);
	  $self->configure(-xTickLabel=> $tickLabels);
	}
	if($self->cget('-yType') eq 'log') {
	  my ($aa,$bb) = (10**$s->[3],10**$s->[4]);
	  # print "zoom a $aa b $bb \n";
	  my($yMinP, $yMaxP, $yIntervals, $tickLabels) = $self->logRange($aa,$bb);
	  # print "zoom $tickLabels \n";
	  $self->configure(-yTickLabel=> $tickLabels);
	} 
	if($self->cget('-y1Type') eq 'log') {
	  my ($aa,$bb) = (10**$s->[6],10**$s->[7]);
	  # print "zoom for y1 log  $aa b $bb \n";
	  my($yMinP, $yMaxP, $yIntervals, $tickLabels) = $self->logRange($aa,$bb);
	  # print "zoom y1 $tickLabels \n";
	  $self->configure(-y1tickLabel=> $tickLabels);
	} 
    } else {        # box not small, time to zoom 
	my ($x1W,$y1W,$y11W) = $self->toWorldPoints($z->[0],$z->[1]);
	my ($x2W,$y2W,$y12W) = $self->toWorldPoints($z->[2],$z->[3]);
	my $z; #holdem
	if($x1W  > $x2W)  { $z = $x1W;  $x1W =  $x2W;  $x2W  = $z;}
	if($y1W  > $y2W)  { $z = $y1W;  $y1W =  $y2W;  $y2W  = $z;}
	if($y11W > $y12W) { $z = $y11W; $y11W = $y12W; $y12W = $z;}

	# push the old scale values on the zoom stack
	push(@{$self->{'-zoomStack'}}, $self->cget(-scale) );
	# now rescale 
	# print "zoom Rescale ($y1W, $y2W)  ($x1W, $x2W)  \n";  
	my($yMinP, $yMaxP, $yIntervals)    = niceRange($y1W, $y2W);
	my($y1MinP, $y1MaxP, $y1Intervals) = niceRange($y11W, $y12W);
	my($xMinP, $xMaxP, $xIntervals)    = niceRange($x1W, $x2W);
	my ($xTickLabels,$yTickLabels,$y1TickLabels);
	($xMinP, $xMaxP, $xIntervals, $xTickLabels) = timeRange($x1W, $x2W)if($self->cget('-xType') eq 'time');
	($yMinP, $yMaxP, $yIntervals, $yTickLabels) = $self->logRange ($y1W, $y2W)if($self->cget('-yType') eq 'log');
	($y1MinP, $y1MaxP, $y1Intervals, $y1TickLabels) = $self->logRange ($y11W, $y12W)if($self->cget('-y1Type') eq 'log');
	# print "zoom 	($xMinP, $xMaxP, $xIntervals)  xTickLabels <$xTickLabels> \n";
	$self->configure(-xTickLabel=> $xTickLabels);
	$self->configure(-yTickLabel=> $yTickLabels);
	print "($xMinP, $xMaxP,$xIntervals), ($yMinP, $yMaxP, $yIntervals),  ($y1MinP, $y1MaxP, $y1Intervals)\n";
	$self->configure(-scale=>[$xMinP, $xMaxP, $xIntervals,$yMinP, $yMaxP, $yIntervals, $y1MinP, $y1MaxP, $y1Intervals]);
    }
    
    $self->delete('all');
    # draw again
    $self->drawAxis();     # both x and y for now
    $self->titles();
    $self->drawDatasets();
    $self->legends();

  } elsif($which == 2) { # motion, draw box
    my $e = $self->XEvent;
    my ($a,$b) = ($e->x, $e->y);
    $z = $self->cget('-zoom');
    $self->delete($z->[4])if($z->[4] != 0);
    $z->[4] = $self->createRectangle($z->[0],$z->[1],$a,$b,'-outline'=>'gray');
    $self->configure('-zoom' => $z);
  }

}
# below not used Dec 2005
sub pointZoom {  # for now only going in
    #  zoom mode where zoom is by 2 centered on where the cursor is 
    use strict;
    my $self = shift;
    my $e = $self->XEvent;
    my ($a,$b) = ($e->x, $e->y);
    # this is where the mouse is
    

    
}

sub zoomInOut { # arg is which 1 is zoom out 2 is zoom in
    # zoom out by two in both x and y.
    use strict;
  my $self = shift;
  my $which = shift;
  my $div = ($which == 1) ? 1 :4 ;
  my $i = ($which == 1) ? 2 :0.5 ; 
  my $s =  $self->cget(-scale);
  # just change the scale and redraw.
  my $delta = ($s->[1]-$s->[0])/$div;
  my $mid = ($s->[1]+$s->[0])/2;
  $s->[0] = $mid - $delta; #new min
  $s->[1] = $mid + $delta;  #new max
  $s->[2] =   $s->[2]*$i;
  my $delta = ($s->[4]-$s->[3])/$div;
  my $mid = ($s->[4]+$s->[3])/2;
  $s->[3] = $mid - $delta; #new min
  $s->[4] = $mid + $delta;  #new max
  $s->[5] =   $s->[5]*$i;
  my $delta = ($s->[7]-$s->[6])/$div;
  my $mid = ($s->[7]+$s->[6])/2;
  $s->[6] = $mid - $delta; #new min
  $s->[7] = $mid + $delta;  #new max
  $s->[8] =   $s->[8]*$i;

  $self->delete('all');
  # draw again
  $self->drawAxis();     # both x and y for now
  $self->titles();
  $self->drawDatasets();
  $self->legends(); 
}

sub printXY {  # up or down argument 
  use strict;
  my $self = shift;
  my $which = shift;  # up or down
  my($xS,$yS, $xC,$yC);
  if($which eq 'down') {
    my $e = $self->XEvent;
    # ($xS,$yS) = ($e->x, $e->y);
    ($xC,$yC) = ($e->x, $e->y);  # comes in in the canvas system
    #print "printXY pixels as they come in from e  ($xC,$yC)  canvas \n";
    ($xS, $yS) = $self->canvasToScreen($xC, $yC);
    # get World 
    my($xW, $yW, $y1W) = $self->toWorldPoints($xC, $yC);
    # might have to log them 
    # $yW = 10**$yW   if($self->cget('-yType')  eq 'log');
    # $y1W = 10**$y1W if($self->cget('-y1Type') eq 'log');
    # print "World (x,y) $xW, $yW  (x,y1) $xW, $y1W\n";
    #printf ("World (x,y) %7.3f,%7.3f  (x,y1) %7.3f,%7.3f\n",  $xW, $yW ,  $xW, $y1W);
    my $t= sprintf("World (x,y ) %7.3f,%7.3f\nWorld (x,y1) %7.3f,%7.3f\n",  $xW, $yW ,  $xW, $y1W);
    # put up a window to show these values
    # Going to put up a mian window with a label and delete it after the button is up.
    my $mw = MainWindow->new();
    $mw->overrideredirect(1);
    $mw->geometry("200x40+$xS+$yS");
    # $mw->deiconify();
    # $mw->raise;


    my $l = $mw->Label(-text => $t, -relief=>'flat',-anchor => 'n')->pack();
    $self->{-infoWin} = $mw;  # save the window so I can delete it on the up button
    return;
  }

  my $mw = $self->{-infoWin};
  $mw->destroy;
  #  warn "button release I hope";

}

sub hideShowLb {  # no arguments ? 
  # make the hideShow list box 
    use strict;
    my $self = shift;
    my $mw = $Tk::LineGraph::MW;
    my ($cx,$cy) = $mw->pointerxy;
    # print "put the new tl here $cx,$cy\n";
    my $tl = $mw->Toplevel(-title=>'View Datasets');
    $tl->geometry("+$cx+$cy");
    my $lb = $tl->Listbox(-selectmode=>'multiple');
    my @list;
    foreach my $ds (@{$self->{-datasets}}) {
	my $name = $ds->get('-name');
	push @list,$name;
    } 
    $lb->insert('end',@list);
    $lb->pack();
    my $c = 0;
    # find the active ones and set the listbox accordingly
    foreach my $ds (@{$self->{-datasets}}) {
	$lb->selectionSet($c )if($ds->{'-active'} == 1);
	$c++;
    } 
    $lb->bind("<Button-1>"=>[\&hideShowAction, $self, 99]);
}

sub  datasetsMenu   { # no arguments 
  use strict;
  my $self = shift;
  # find out where the cursor is so that the top level can be put there
  my $mw = $Tk::LineGraph::MW;
  my ($cx,$cy) = $mw->pointerxy;
  # print "put the new tl here $cx,$cy\n";
  my $tl = $mw->Toplevel(-title=>'View Datasets 3');
     $tl->geometry("+$cx+$cy");
  # get a list of the dataset names
  my (@dsNames, $ds);
  foreach $ds (@{$self->{-datasets}}) {
    push @dsNames,$ds->get('-name');
  }
  $ds = $self->{-datasets}->[0];
  my $dsName = $dsNames[0];
  my $yAxis;
  $yAxis = $ds->get(-yAxis);
  my $color = $ds->get(-color);
  my ($tw, $show);   # tw is text wiget
  my ($DS);
  $tl->BrowseEntry(-choices=> \@dsNames, 
		   -browsecmd=>sub {
		       $DS = $self->dsName2Obj($dsName);
		       $color = $DS->get(-color);
		       $yAxis = $DS->get(-yAxis);
		       # print "choice made yAxis <$yAxis> \n";
		       $self->datasetMenuAction3($tw, $show, $dsName, $yAxis, $color);},
		   -variable=>\$dsName)->pack();

  my $f0 = $tl->Frame()->pack(); 
  my $f1 = $tl->Frame()->pack();
  my $fa = $tl->Frame()->pack();
  my $f2 = $tl->Frame()->pack();
  my $f3 = $tl->Frame(-width=>25, -height=>12) ->pack();
  $tw = $f3->Text(-width=>25, -height=>12)->pack();

  $f1->Radiobutton
    (-text => "Y1",
     -value => "Y1",
     -variable => \$yAxis,
     -command => sub {$self->datasetMenuAction3($tw, $show, $dsName, $yAxis, $color)}
    )->pack(-anchor => 'w',-side=>'right'); 
  $f1->Radiobutton
    (-text => "Y",
     -value => "Y",
     -variable => \$yAxis,
     -command => sub {$self->datasetMenuAction3($tw, $show, $dsName, $yAxis, $color)}
    )->pack(-anchor => 'w',-side=>'right'); 

  my $le = $fa->LabEntry
    (-textvariable => \$color,
     -label => "color",
     -foreground=>"black",
     -validate => 'key',
     -validatecommand => sub { $self->datasetMenuAction3($tw, $show, $dsName, $yAxis, $color)if($color =~ /z/); return(1)  },

     -labelPack => [-side => 'left']) ->pack;

  $f2->Checkbutton
    (-text => "Show Dataset Points",
     -variable => \$show,
     -command => sub {$self->datasetMenuAction3($tw, $show, $dsName, $yAxis, $color)}
    )->pack(-anchor => 'w',-side=>'right');



 
}

sub dsName2Obj { # dataset name
    # return the ds obj given the name
    # return undef if not a right name
    use strict;
    my $self = shift;
    my $name = shift;
    my ($ds,$dss);
    foreach $ds (@{$self->{-datasets}}) {
	$dss = $ds;
	last if($ds->get('-name') eq $name);
    }
    return(undef) if($dss->get('-name') ne $name);
    return($dss);
}

sub datasetMenuAction3 { # Get the "state" of the dataset menu and make the menu and plot right.
  # comes in here with a brows entry object
  # and the value of whichDS
  use strict;
  # print "datasetMenuAction3 @_ \n";
  # now want to list the points in the selected dataset
  my $self = shift;
  my $tw = shift;          # text window
  my $show = shift;        # show points in the window
  my $whichDS = shift;     # the current, selected dataset
  my $yAxis = shift;
  my $color = shift;
  my ($ds,$DS,$n,$t);
  # find the selected dataset
  $ds = $self->dsName2Obj($whichDS);
  # print "datasetManuAction3  ds obj <$ds>\n";
  if($show) {
    $tw->delete("1.0", 'end');
    $tw->pack();
    $t = "";
    my $yData = $ds->get('-yData');
    my $xData = $ds->get('-xData');
    $xData = [0..scalar(@$yData)]if($xData eq undef);
    for (my $i=0;$i< @{$yData} ;$i++) {
      $t = $t . sprintf("%f, %f\n", $xData->[$i], $yData->[$i]);
    }
    $tw->insert("end",$t);
  } else { # don't show the data
    $tw->delete("1.0", 'end');
    $tw->pack('forget');
  }
  # take care of the Y, Y1 axis option
  my $y1 = $ds->get(-yAxis);
  # print "actionMenu3 <$y1>   <$yAxis> \n";
  if($y1 ne $yAxis) {
      # print "actionMenu have to change and replot\n";
      $ds->{-yAxis} = $yAxis;
      $self->rescale("all");
  }
  # maybe we have a new color 
  my $currentColor = $ds->get(-color);
  # print "datasetMenuAction <$currentColor> <$color>\n";
  if($currentColor ne $color) { # something to do
      $ds->{-color} = $color;
      $self->rescale("all");
  }
}

sub popIt {  # currently not used Nov 18 2005
    use strict;
    my $self = shift;
    my $e = $self->XEvent;
    my ($x,$y) = ($e->x, $e->y);
    # print "popIt (x,y) ($x,$y)\n";
    my $m1 = $self->{'-menu'};
    # want to add all datasets to the menu
    $m1->insert('end','separator');
    my $c = 0;
    foreach my $ds (@{$self->{-datasets}}) {
	my $name = $ds->get('-name');
	# print "popIt $name \n";
	$m1->insert('last','command',-label => $name, -command =>[ \&hideShow, $self, (2+$c++)] );
    }  
    #$m1 -> post($x,$y);
    # Listbox setup here
    my $mw = MainWindow->new(-title=>'Show/Hide');
    my $lb = $mw->Listbox(-selectmode=>'multiple');
    my @list;
    foreach my $ds (@{$self->{-datasets}}) {
	my $name = $ds->get('-name');
	push @list,$name;
    } 
    $lb->insert('end',@list);
    $lb->pack();
    my $c = 0;
    foreach my $ds (@{$self->{-datasets}}) {
	$lb->selectionSet($c )if($ds->{'-active'} == 1);
	$c++;
    } 
    $lb->bind("<Button-1>"=>[\&hideShow1, $self, 99]);
    
}

sub hideShowAction { 
  # called after a button 1 event on the Hide/Show menu
  use strict;
  my $lb = shift;
  my $pw = shift;   # plot widget 
  my $a = shift;
  # print("hideShow1 listbox <$lb>  window <$pw>   <$a>\n");
  my $dataSets =  $pw->{-datasets};
  my $index = 0;
  foreach my $ds (@$dataSets) {
      if($lb->selectionIncludes($index)) {
	  # should be drawn
	  if($ds->{'-active'} == 0) { # not active, draw it
	      $ds->set('-active'=>1);
	      $pw->drawOneDataset($ds);
	  }
      } else { # not selected, should  not be not drawn	  
	  if($ds->{'-active'} == 1) { # active
	      my $tag = $ds->{-name};
	      $pw->delete($tag);
	      $ds->set('-active'=>0);
	      # print "hideShowAction did an erase of <$tag> index <$index>\n";
	  }
      }
    $index++;
  } # done with all the data sets 
}

sub createLinePlot {
  use strict;
  my($self, %args) = @_;
  my $data = delete $args{-data};
  croak "createLinePlot:  No -data option." unless defined $data;
  $self->createLine(@$data, %args);;
} # end createLinePlot

sub createPiePlot {

    my($self, $x1, $y1, $x2, $y2, %args) = @_;

    my $data = delete $args{-data};
    croak "createPiePlot:  No -data option." unless defined $data;

    my(@ids) = ();

    my $total;
    for(my $i = 0; $i < $#{@$data}; $i += 2) {
	$total += $data->[$i+1];
    }

    my $colors = $self->cget(-colors);
    my $color;
    my $dp_unit = 360.0 / $total;

    my $degrees = 0;
    for(my $i = 0; $i < $#{@$data}; $i += 2) {
	my $d = $data->[$i+1];
	my $arc = $d * $dp_unit;
	$color = $$colors[ $i / 2 % @$colors ];
	push @ids, $self->createArc(
            $x1, $y1, $x2, $y2,
            %args,				    
            -start  => $degrees,
	    -extent => $arc,
	    -style  => 'pieslice',
	    -fill   => $color,
        );
	$degrees += $d * $dp_unit;
	my $label = sprintf("%-15s %5d", $data->[$i], $data->[$i+1]);
	push @ids, $self->createText(
            $x2 + 25, $y1 + ($i * 10),
            %args,
	    -text   => $label,
	    -fill   => $color,
	    -font   => $self->cget(-font),
	    -anchor => 'w',
        );
    } # forend

    --$id;
    $ids{$id} = [@ids];
    $id;

} # end createPiePlot

sub delete {
    my($self, @ids) = @_;
    foreach my $id (@ids) {
	if ($id >= 0) {
	    $self->SUPER::delete($id);
	} else {
	    $self->SUPER::delete(@{$ids{$id}});
	    delete $ids{$id};
	}
    }
}

sub createPlotAxis { # start and end point of the axis, other args a=>b
  # Optional args  -tick
  # Optional args  -label 
  # end points are in Canvas pixels
  use strict;
  my($self, $x1, $y1, $x2, $y2, %args) = @_;
  my $y_axis = 0;
  if ($x1 == $x2) {
    $y_axis = 1;
  } elsif ($y1 != $y2) {
    die "Cannot determine if X or Y axis desired."
  }
  
  my $tick = delete $args{-tick};
  my $label = delete $args{-label};
  my($do_tick, $do_label) = map {ref $_ eq 'ARRAY'} ($tick, $label);
  
  $self->createLine($x1, $y1, $x2, $y2, %args);
  
  if ($do_tick) {
    my($tcolor, $tfont, $side, $start, $stop, $incr, $delta, $type) = @$tick;
    # start, stop are in the world system
    # $incr is space between ticks in world coordinates   $delta is the number of pixels between ticks
    # If type is log then a log axis maybe not 
    my($lcolor, $lfont, @labels) = @$label if $do_label;
    # print "t font <$tfont> l font <$lfont> \n";
    my $l;
    my $z = 0;  # will get $delta added to it, not x direction! 
    my $tl;
    my $an;  
    if ($y_axis) {
      $tl = $side eq 'w' ? 5 : -6; # tick length
      $an = $side eq 'w' ? 'e' : 'w' if $y_axis;  #anchor 
    } else {
      $tl = $side eq 's' ? 5 : -6; # tick length
      $an = $side eq 's' ? 'n' : 's' if not $y_axis;
	}
    # do the ticks
    for(my $l = $start; $l <= $stop; $l += $incr) {
      if ($y_axis) {
	$self->createLine(
			  $x1-$tl,  $y2-$z, $x1, $y2-$z,
			  %args, -fill => $tcolor,
			 );
      } else {
	$self->createLine(
			  $z+$x1,  $y1+$tl, $z+$x1, $y2,
			  %args, -fill => $tcolor,
			 );
      }
      if ($do_label) {
	my $lbl = shift(@labels);
	if ($y_axis) {
	  $self->createText
	    ($x1-$tl, $y2-$z, -text => $lbl,
	     %args, -fill => $lcolor,
	     -font => $lfont, -anchor => $an,
	    ) if $lbl;
	} else {
	  $self->createText
	    ($z+$x1, $y1+$tl, -text => $lbl,
	     %args, -fill => $lcolor,
	      -font => $lfont, -anchor => $an,
	    ) if $lbl;
	}
      } else {       # default label uses tfont 
	if ($y_axis) {
	  $self->createText(
			    $x1-$tl, $y2-$z, -text => $l,
			    %args, -fill => $tcolor,
			    -font => $tfont, -anchor => $an,
			   );
	} else {
	  $self->createText(
			    $z+$x1, $y1+$tl, -text => $l,
			    %args, -fill => $tcolor,
			    -font => $tfont, -anchor => $an,
			   );
	}
      }
      $z += $delta;  # only use of delta 
    }
  } # ifend label this axis

} # end createPlotAxis

sub titles {
  # put axis titles and plot title on the plot 
  # x, y, y1, plot all at once for now
  use strict;
  my $self = shift;
  my $boarders = $self->cget(-boarder);
  my $fonts = $self->cget('-fonts');
  my $w = $self->cget('-width');
  my $h = $self->cget('-height');
  my $yp = $boarders->[2]*0.6;
  # y axis
  my $yStart = $self->centerTextV($boarders->[0], $h-$boarders->[2],$fonts->[1], $self->cget('-ylabel') );
  $self->createTextV
    ($self->toCanvasPixels('canvas',10,$h-$yStart),
     -text=>$self->cget('-ylabel'), -anchor => 'sw', -font=>$fonts->[1], '-tag'=>"aaaaa",
    );
  
  # Is y1 axis used for active datasets?

  # y1 axis
  my $yStart = $self->centerTextV($boarders->[0], $h-$boarders->[2],$fonts->[1], $self->cget('-y1label') );
  $self->createTextV
    ($self->toCanvasPixels('canvas',$w-5,$h-$yStart),
     -text=>$self->cget('-y1label'), -anchor => 'sw', -font=>$fonts->[1],'-tag'=>"y1y1y1y1",
     )if($self->countY1());

  #   x axis
  my $xStart = $self->centerText($boarders->[3],$w-$boarders->[2], $fonts->[1],$self->cget('-xlabel') );
  $self->createText
    ($self->toCanvasPixels('canvas',$xStart, $yp), 
     -text=>$self->cget('-xlabel'), -anchor => 'sw',  -font=>$fonts->[1],
    );

  # add a plot title
  my $p = $self->cget('-plotTitle');
  $xStart = $self->centerText($boarders->[3],$w-$boarders->[1], $fonts->[1],$p->[0]);
  $self->createText
      ($self->toCanvasPixels('canvas',$xStart, $h-$p->[1]),
	text=>$p->[0], -anchor => 'nw', -font=>$fonts->[2],
       );
}

sub createTextV { # canvas widget, x,y, then all the text arguments plus -scale=>number
  # Writes text from top to bottom.
  # For now argument -anchor is removed
  # scale is set to 0.75.  It the fraction of the previous letter's height that the
  # current letter is lowered.
  #
  use strict;
  my $self = shift;
  my($x,$y) = (shift,shift);
  my %args = @_;
  my $text =    delete($args{-text});
  my $anchor =  delete($args{-anchor});
  my $scale =   delete($args{-scale});
  my $tag   =  delete($args{-tag});
  my @letters = split(//,$text);
  # print "args",  %args, "\n";;
  # OK we know that we have some short and some long letters
  # a,c,e,g,m,m,o,p,r,s,t,u,v,w,x,y,z are all short.  They could be moved up a tad
  # also g,j,q, and y hang down, the next letter has to be lower
  my $th = 0;
  my $lc = 0;
  # sorry to say, the height of all the letters as returned by bbox is the same for a given font.
  # same is true for the text widget.  Nov 2005!  
  my $letter = shift(@letters);
  $self->createText($x,$y+$th, -text=>$letter,'-tags'=>$tag, %args, -anchor=> 'c');  # first letter
  my($l, $t, $r, $b) = $self->bbox($tag);
  my $h = $b - $t;
  my $w = $r - $l;
  my $step = 0.80;
  $th = $step*$h + $th;
  foreach my $letter (@letters) {
    # print "createTestV letter <$letter>\n";
    # If the letter is short, move it up a bit.
    $th = $th - 0.10*$h if($letter =~ /[acegmnoprstuvwxyz.;,:]/);  # move up a little
    $th = $th - 0.40*$h if($letter =~ /[ ]/);                    # move up a lot 
    # now write the letter
    $self->createText($x,$y+$th, -text=>$letter, '-tags'=>$tag, %args, -anchor=> 'c');
    # space for the next letter 
    $th = $step*$h + $th;
    $th = $th + 0.10*$h if($letter =~ /[gjpqy.]/);  # move down a bit if the letter hangs down 
    $lc++;
    
  }
}

sub legends { 
  # For all the (active) plots, put a legend
  my ($self, %args) = @_;
  my $count = 0;
  # count the (active) data sets
  foreach my $ds (@{$self->{-datasets}}) {
    my $name = $ds->get('-name');
    # print "legends $name \n";
    $count ++if($ds->get('-active') == 1);
  }
  # print "legends have $count legends to do\n";
  my $fonts = $self->cget('-fonts');
  my $xs = 20;
  my $tag;
  foreach my $ds (@{$self->{-datasets}}) {
    if($ds->get('-active') != 99) {  # do them all, not just active 
      my($x,$y) = $self->toCanvasPixels('canvas',$xs, 5);
      my $lineTag = $ds->get('-name');
      $tag = $lineTag.'legend';
      my $fill = $ds->get('-color');
      my $t = $ds->get('-name');
      $t = ($ds->get('-yAxis') eq "Y1") ? $t."(Y1) " : $t." ";
      $self->createText
	($x,$y, -text=>$t, -anchor => 'sw', -fill => $ds->get('-color'),
	 -font=>$fonts->[3],-tag=>$tag);
      # want the plot  to turn red when we enter the legend
    $self->bind($tag,"<Enter>"=> sub{ $self->itemconfigure($lineTag,-fill=>'red')} );
    $self->bind($tag,"<Leave>"=> sub{ $self->itemconfigure($lineTag,-fill=>$fill); } );
      my($x1,$y1,$x2,$y2) = $self->bbox($tag);
      $xs = $x2;
      # print "legend location of last character p1($x1,$y1), p2($x2,$y2)\n";
    }
  }
}

sub addDatasets {
    # add data sets to the plot object 
  my($self, %args) = @_;
  # If a Dataset was an argument, push  it onto the DataSets list
  # Do this till no more DataSets in the arguments
  my $dataSet;
  while (1 == 1) {
      $dataSet = delete $args{-dataset};
      push @{$self->{-datasets}}, $dataSet   if($dataSet ne undef);
      last if($dataSet eq undef);
  }
}

sub countY1 {
    # count how many datasets are using y1
    use strict;
    my $self = shift;
    my $count = 0;
    foreach my $ds (@{$self->{-datasets}}) {
	$count++ if($ds->get('-yAxis') eq "Y1");
    }
    # print "countY1 <$count>\n";
    return($count); 
}

sub dataSetsMinMax { # one argument, all or active 
    # Get the min and max of the datasets
    # could be done for all datasets or just the active datasets
    # return xmin,xmax, ymin, ymax, y1min, y1max
    use strict;
    my $self = shift;
    my $all = (shift eq 'all') ? 1 : 0;  # $all true if doing for all datasets
    my ($first, $first1) = (0, 0);
    my $e; # element
    my($yMax, $yMin, $xMax, $xMin, $yMax1, $yMin1);
    my($xData, $yData);
    # Do x then y and y1
    foreach my $ds (@{$self->{-datasets}}) {
	if(($all) or ($ds->get('-active') == 1) ) {
	    $yData = $ds->get('-yData');
	    $xData = $ds->get('-xData');
	    $xData = [0..scalar(@$yData)]if($xData eq undef);
	    if($first == 0) {
		$xMax = $xMin = $xData->[0];
		$first = 1;
	    }
	    foreach $e (@{$xData}) {
		$xMax = $e if($e > $xMax );
		$xMin = $e if($e < $xMin );
	    }
	}
    }
    $first = $first1 = 0;
    foreach my $ds (@{$self->{-datasets}}) {
	if(($all) or ($ds->get('-active') == 1) ) {
	    $yData = $ds->get('-yData');
	    if($ds->get('-yAxis') eq "Y1")   {
		if($first1 == 0) {
		    $yMax1 = $yMin1 = $yData->[0];
		    $first1 = 1;
		}
		foreach $e (@{$yData}) {
		    $yMax1 = $e if($e > $yMax1);
		    $yMin1 = $e if($e < $yMin1);
		}
	    } else {  # for y axis 
		if($first == 0) {
		    $yMax = $yMin = $yData->[0];
		    $first = 1;
		}
		foreach $e (@{$yData}) {
		    $yMax = $e if($e > $yMax);
		    $yMin = $e if($e < $yMin);
		}
	    }
	}
    }
    # print "datasetMinMax X($xMin,$xMax), Y($yMin, $yMax), Y1($yMin1, $yMax1)\n";
    return($xMin,	$xMax, $yMin, $yMax, $yMin1, $yMax1);
}

sub scalePlot { # 'all'  or 'active'
  # scale either all the data sets or just the active ones
  use strict;
  my $self = shift;
  my $how = shift;
  my($xMin, $xMax, $yMin, $yMax, $y1Min, $y1Max) =  $self->dataSetsMinMax($how);
  print "scalePlot  min and max  ($xMin, $xMax), ($yMin, $yMax),  ($y1Min, $y1Max)\n";
  my($xtickLabels, $ytickLabels, $y1tickLabels);
  my($yMinP,  $yMaxP,  $yIntervals);
  my $scale = $self->cget(-scale);
  if($self->cget(-autoScaleY) eq 'On') {
      ($yMinP,  $yMaxP,  $yIntervals)                 = niceRange($yMin,  $yMax);
      ($yMinP,  $yMaxP,  $yIntervals, $ytickLabels)   = $self->logRange ($yMin, $yMax)   if($self->cget('-yType') eq 'log');
  } else {
      ($yMinP,  $yMaxP,  $yIntervals)  = ($scale->[3], $scale->[4],$scale->[5]);
  }
  my($y1MinP, $y1MaxP, $y1Intervals);
  if($self->cget(-autoScaleY1) eq 'On') {
      ($y1MinP, $y1MaxP, $y1Intervals) = niceRange($y1Min, $y1Max);
      ($y1MinP, $y1MaxP, $y1Intervals, $y1tickLabels) = $self->logRange ($y1Min, $y1Max ) if($self->cget('-y1Type') eq 'log');
  } else {
      ($y1MinP, $y1MaxP, $y1Intervals) = ($scale->[6], $scale->[7],$scale->[8]);
  }
  my($xMinP,  $xMaxP,  $xIntervals);
  if($self->cget(-autoScaleX) eq 'On') {
      ($xMinP,  $xMaxP,  $xIntervals)  = niceRange($xMin,  $xMax);
      ($xMinP, $xMaxP, $xIntervals, $xtickLabels) = timeRange($xMin, $xMax)   if($self->cget('-xType') eq 'time');
  } else {
      ($xMinP, $xMaxP, $xIntervals) = ($scale->[0], $scale->[1],$scale->[2]);   
  }
  # print "scalePlot $yMinP,  $yMaxP,  $yIntervals, @$ytickLabels\n";
  # print "($xMinP, $xMaxP, $xIntervals)  tickLabels <$tickLabels> \n";
  $self->configure(-xTickLabel=>  $xtickLabels);
  $self->configure(-yTickLabel=>  $ytickLabels);
  $self->configure(-y1TickLabel=> $y1tickLabels);
  # print "scale Y $yMinP, $yMaxP, $yIntervals  X  $xMinP, $xMaxP, $xIntervals \n";
  # put these scale values into the plot widget
  $self->configure(-scale=>[$xMinP, $xMaxP, $xIntervals,  $yMinP, $yMaxP, $yIntervals,  $y1MinP, $y1MaxP, $y1Intervals]);
  # print "in scale  $yMinP, $yMaxP, $yIntervals \n";
  # reset the zoom stack!
  $self->{-zoomStack} = []; 
}

sub plot {
# plot all the active data sets
  use strict;
  my($self, %args) = @_;
  foreach my $key (keys(%args) ) {
  #  print "plot args hash <$key> <$args{$key}> \n";
  }

  # If a DataSet was an argument, push  it onto the DataSet list
  # Do this till no more DataSets in the arguments
  # Then plot all the active DataSets
  my $dataSet;
  while (1 == 1) {
      $dataSet = delete $args{-dataset};
      push @{$self->{-datasets}}, $dataSet   if($dataSet ne undef);
      last if($dataSet eq undef);
  }

  $self->rescale('all');

}

sub drawAxis { 
  # do both of the axis 
  my $self = shift;
  my $s = $self->cget(-scale);  # get the scale factors
  my ($nb, $eb, $sb, $wb) = @{$self->cget(-boarder)};
  # for now, figure this will fit
  my $h = $self->cget('-height');
  my $w = $self->cget('-width');
  my $tl = $self->cget('-xTickLabel');
  my $fonts = $self->cget('-fonts');
  # print "drawAxis xTickLabel <$tl>\n";
  my $lab = [];
  if($tl) {
    # print "draw axis making tick labels\n";
    push @{$lab},'red', $fonts->[0] ;
    foreach my $a (@{$tl} ) {
      push  @{$lab},$a;
      # print "drawAxis @{$lab} \n";
	
    }
  } else {
    $lab = undef;
  }

  #xAxis first
  # tick stuff
  my ($tStart, $tStop, $interval) =  ($s->[0], $s->[1], $s->[2]);
  my $ticks = ($tStop-$tStart)/$interval;
  my $aLength = $w-$wb-$eb;
  my  $d = $aLength/$ticks;
  my($xStart, $ystart, $xEnd, $yEnd) = ($wb, $h-$sb, $w-$eb, $h-$sb);
  my $result = $self->createPlotAxis
  ($xStart, $ystart, $xEnd, $yEnd,
   -fill => "black",
   # $tcolor, $tfont,  $side, $start, $stop, $incr, $delta)
   # incr step size - used in lable in PIXELS, delta is the PIXELS  between ticks 
   # have to start at the start of the "axis".  Not good!
   -tick => ['black',$fonts->[0],'s',$tStart,$tStop,$interval,$d],
   -label =>$lab,
  );
 
  # box x axis
  ($xStart, $ystart, $xEnd, $yEnd) = ($wb, $nb, $w-$eb, $nb);
  $result = $self->createPlotAxis
  ($xStart, $ystart, $xEnd, $yEnd,
   -fill => "black");

  # setup the tick labels if they have been set 
  my $tl  = $self->cget('-yTickLabel');
  if($tl) { 
      # print "draw axis making tick labels for y\n";
      push @{$lab},'black', $fonts->[0] ;
      foreach my $a (@{$tl} ) {
	  push  @{$lab},$a;
	  # print "drawAxis @{$lab} \n";	  
      }
  } else {
      $lab = undef;
  }
  # print "y axis label <$lab> \n";
  #YAxis now
  ($xStart, $ystart, $xEnd, $yEnd) = ($wb, $nb, $wb, $h-$sb);
  ($tStart, $tStop, $interval) =  ($s->[3], $s->[4], $s->[5]);
  $interval = 10 if($interval <= 0);
  $ticks = ($tStop-$tStart)/$interval;
  $aLength = $h-$nb-$sb;
  $d = $aLength/$ticks;
  $result = $self->createPlotAxis
    ($xStart, $ystart, $xEnd, $yEnd,
     -fill => "black",
     # $tcolor, $tfont,  $side, $start, $stop, $incr, $delta)
     # incr step size - used in lable in PIXELS, delta is the PIXELS  between ticks 
     # have to start at the start of the "axis".  Not good!
     -tick => ['black',$fonts->[0],'w',$tStart,$tStop,$interval,$d],
     -label => $lab,
    );

  #Y1Axis now if needed
  if($self->countY1()) {
  # setup the tick labels if they have been set 
  my $tl  = $self->cget('-y1TickLabel');
  if($tl) { 
      # print "draw axis making tick labels for y\n";
      push @{$lab},'black', $fonts->[0] ;
      foreach my $a (@{$tl} ) {
	  push  @{$lab},$a;
	  # print "drawAxis @{$lab} \n";	  
      }
  } else {
      $lab = undef;
  }
     ($xStart, $ystart, $xEnd, $yEnd) = ($w-$eb, $nb, $w-$eb, $h-$sb);
     ($tStart, $tStop, $interval) =  ($s->[6], $s->[7], $s->[8]);
     $interval = 10 if($interval <= 0);
     $ticks = ($tStop-$tStart)/$interval;
     $aLength = $h-$nb-$sb;
     $d = ($ticks != 0) ? $aLength/$ticks : 1;
     $result = $self->createPlotAxis
     ($xStart, $ystart, $xEnd, $yEnd,
      -fill => "black",
      # $tcolor, $tfont,  $side, $start, $stop, $incr, $delta)
      # incr step size - used in lable in PIXELS, delta is the PIXELS  between ticks 
      # have to start at the start of the "axis".  Not good!
      -tick => ['black',$fonts->[0],'e',$tStart,$tStop,$interval,$d],
      -label => $lab,
      );
 }
# box    y axis 
  ($xStart, $ystart, $xEnd, $yEnd) = ($w-$eb, $nb, $w-$eb, $h-$sb);
  $result = $self->createPlotAxis
  ($xStart, $ystart, $xEnd, $yEnd,
   -fill => "black",
  );
  $self->logTicks();
}

sub logTicks {
  # put the 2,3,4,...,9 ticks on a log axis
  use strict;
  my $self = shift;
  my $s = $self->cget('-scale');
  # do y axis
  return if($self->cget('-yType') ne 'log');
  my ($minP, $maxP, $deltaP) = ($s->[3], $s->[4],$s->[5]);
  my $dec = ($maxP-$minP);
  return if($dec > 5);  # only if there are less than four decades
  my $b =  $self->cget('-boarder');
  my ($h,$w) = ( $self->cget('-height'),  $self->cget('-width'));
  my $axisLength = $h-$b->[0]-$b->[2];
  my $dLength = $axisLength/($maxP-$minP);
  my $delta;
  foreach my $ii (1..$dec) {
    foreach my $i (2..9) {
      my $delta = (log10 $i) * $dLength;
      my $y = $h - ($b->[2]) - $delta - $dLength*($ii-1);;
      # print "logTicks $ii $i delta $delta  y $y \n";
      $self->createLine($b->[3], $y, $b->[3]+6, $y, -fill=>'black');
    }
  } # end each decade 
}

sub drawDatasets { 
  # draw the line(s) for all active datasets
  use strict;
  my ($self, @args) = @_;
  foreach my $ds (@{$self->{-datasets}}) {
    if($ds->get('-active') == 1) {
      $self->drawOneDataset($ds);
    }
  }
} # end plotDatasets  

sub drawOneDataset { # index of the dataset to draw, widget args 
  # draw even if not active ?
  my ($self, $ds, @args) = @_;
  my ($nb, $eb, $sb, $wb) = @{$self->cget(-boarder)};
  my $fill;
  my $index = $ds->get('-index');
  if($ds->get('-color') eq "none") {
    $fill = $self->cget('-colors')->[$index % 10];
    $ds->set('-color'=>$fill);
  } else {
    $fill = $ds->get('-color');
  }
  my $tag = $ds->get('-name');
  my $yax  = $ds->get('-yAxis');  # does this dataset use y or y1 axis
  # print "drawOneDataSet index <$index> color  <$fill> y axis <$yax>\n";
  my $yData = $ds->get('-yData');
  my $xData = $ds->get('-xData');
  $xData = [0..scalar(@$yData)]if($xData eq undef);
  my $y = []; 
  my $logMin = $self->cget(-logMin);
  # just maybe we have a log plot to do.  In that case must take the log of each point
  if( ( ($yax eq "Y1") and  ($self->cget('-y1Type') eq 'log') ) or ( ($yax eq "Y") and ($self->cget('-yType') eq 'log') ) ){
      foreach my $e (@{$yData}) {
	  $e = $logMin if($e <= 0);
	  push @{$y}, log10($e);
      } # end foreach
  } else {  # not log at all 
      $y = $yData;
  }

  # need to make one array out of two
  my @xyPoints; 
  # right here we need to go from data set cooridents to plot PIXEL cooridents

  my($xReady, $yReady) =  $self->ds2PlotPixels($xData, $y, $yax);
  @xyPoints =  $self->arraysToCanvasPixels('axis', $xReady, $yReady);
  # got to take care of the case where the data set is empty or just one point.
  return  if(@xyPoints == 0);
  if(@xyPoints == 2){ 
      print "one point, draw a dot!\n";
      my($xa,$ya) = ($xyPoints[0],$xyPoints[1]);
      $self->createOval($xa-6,$ya-6, $xa+6,$ya+6, -fill=>$fill, -tags=>$tag);
  } else {   
      $self->drawOneDatasetB(-data => \@xyPoints, -fill=>$fill, -tags=>$tag);
  }
  # turn line red when we enter it with the mouse to make it easy to see
  $self->bind($tag,"<Enter>"=> sub{ $self->itemconfigure($tag,-fill=>'red')} );
  $self->bind($tag,"<Leave>"=> sub{ $self->itemconfigure($tag,-fill=>$fill)} );

  $self->bind($tag,"<B3-Motion>" =>       sub {$self->moveLine($tag)} );
  $self->bind($tag,"<ButtonRelease-3>" => sub {$self->placeLine($tag)} );
  # print "drawOneDataset tag is <$tag> did binds! \n";
} # end plotDatasets  

# not used Jan 2006  Might us it if we remove bad points rather than setting to m in, more work!
sub filterLogData { # ydata and x data array is input
    # return new xData and yData array
    # come in here for log plots
    # if needed filter the dataset to get rid of numbers <= 0
    # for now replace them with the min, do not change the xArray
    my $self = shift;
    my $check = $self->{-logCheck};
    my($xArray,$yArray) = (shift,shift);
    my($xNew,$yNew);([],[]);
    my $e; # element
    if($check) {
	my $min = $self->cget(-logMin);
	foreach my $e (@{$yArray}) {
	    $e = $min if($e < $min);
	    push @{$yNew}, log10($e);
	}
	return($xArray,$yNew);
    }

    foreach my $e (@{$yArray}) {
	push @{$yNew}, log10($e);
    }
    return($xArray,$yNew);
    
}
	
sub centerTextV { # given y1,y2, a font and a string
  # return a y value for the start of the text
  # The system is in canvas, that is 0,0 is top right.
  # return -1 if the text will just not fit
  use strict;
  my $self = shift;
  my($y1, $y2, $f, $s) = @_;
  return(-1) if($y1 > $y2);
  my $g = "gowawyVVV";
  $self->createTextV
    (0, 10000,  -text=>$s, -anchor => 'sw',
     -font=>$f,-tag=>$g);
  my($l,$t,$r,$b) = $self->bbox($g);
  # print "centerTextV ($l,$t,$r,$b)\n";
  $self->delete($g);  
  my $space = $y2-$y1;
  my $strLen = $b - $t;
  return(-1) if($strLen > $space);
  # print "centerTextV $y1,$y2, space $space, strLen $strLen\n";
  return( ($y1+$y2-$strLen)/2);
}

sub centerText { # x1,x2 a font and a string
  # return the x value fo where to start the text to center it
  # forget about leading and trailing blanks!!!!
  # Return -1 if the text will not fit
  use strict;
  my $self = shift;
  my($x1, $x2, $f, $s) = @_;
  return(-1) if($x1 > $x2);
  my $g = "gowawy";
  $self->createText
    (0, 10000,  -text=>$s, -anchor => 'sw',
     -font=>$f,-tag=>$g);
  my($l,$t,$r,$b) = $self->bbox($g);
  $self->delete($g);
  my $space = $x2-$x1;
  my $strLen = $r - $l;
  return(-1) if($strLen > $space);
  return(($x1+$x2 - $strLen)/2);
}

sub moveLine { # move a line 
  my $self = shift;
  my  $tag = shift;
  # print "moveLine self <$self> tag <$tag> \n";
  my $e = $self->XEvent;
  my ($x,$y) = ($e->x, $e->y);
  # the first time we go to move a line, we get a starting point.
  # then we move from that starting point
  my $index = $self->tag2Index($tag);
  my $ds = $self->{'-datasets'}->[$index];
  # print "moveLine self <$self> tag <$tag> index <$index> \n";
  if($ds->{'-lastPoint'} eq undef) {
    $ds->{'-lastPoint'} = [$x,$y];
    return;
  }
  my ($dx,$dy) = (-$ds->{'-lastPoint'}->[0]+$x, -$ds->{'-lastPoint'}->[1]+$y);
  $self ->move($tag,$dx,$dy); 
  $ds->{'-lastPoint'} = [$x,$y];
}


sub tag2Index { # input is a tag, return the dataset index
  use strict;
  my $self = shift;
  my $tag = shift;
  my $dataSets = $self->{'-datasets'};
  my $index = 0;
  foreach my $ds (@{$dataSets}) {
    return($index)if($ds->{'-tag'} eq $tag);
    $index++;
  }
  return(-1);
}

sub placeLine { # after a line has moved, clean up a bit

  my $self = shift;
  # print "placeLine self <$self>\n";
  my  $tag = shift;
  my $index = $self->tag2Index($tag);
  my $ds = $self->{'-datasets'}->[$index];
  $ds->{'-lastPoint'} = undef;
}

sub drawOneDatasetB { # takes same arguments as createLinePlot confused
  # do clipping if needed
  # do plot with dots if needed
  use strict;
  my ($self, %args) = @_;
  my $xyPoints = delete($args{'-data'});
  # $self->createLinePlot(-data => $xyPoints, %args);
  $self->clipPlot(-data => $xyPoints, %args);
  my $h = $self->cget('-height');
  my $w = $self->cget('-width');
  my $b = $self->cget(-boarder);
  # How many points are inside of the plot window.
  # mark the points if there are less that 20 points
  my $points = @{$xyPoints}/2;
  my $inPoints = $self->countInPoints($xyPoints);
  if($inPoints < 20) {
    for(my $i=0; $i< $points; $i++) {
      my ($x,$y) = ($xyPoints->[$i*2], $xyPoints->[$i*2+1]);
      $self->createOval($x-3, $y-3, $x+3, $y+3, %args) if(($x >= $b->[3])  and ($x <= ($w-$b->[1]))  and ($y >= $b->[0]) and ($y <= ($h-$b->[2])) );
    }
  }
}

sub countInPoints { # array of x,y points
  # count the points inside the plot box.
  my ($self) = shift;
  my $xyPoints = shift;
  my $points = @{$xyPoints}/2;
  my($x,$y, $count);
  my $h = $self->cget('-height');
  my $w = $self->cget('-width');
  my $b = $self->cget(-boarder);
  
  for(my $i=0;$i<$points;$i++) {
    ($x,$y) = ($xyPoints->[$i*2], $xyPoints->[$i*2+1]);
    $count ++ if(($x >= $b->[3])  and ($x <= ($w-$b->[1]))  and ($y >= $b->[0]) and ($y <= ($h-$b->[2])) );
  }
  return($count);
}

sub clipPlot { # -data => array ref which contains x,y points in Canvas pixels
  # draw a multi point line but cliped at the boarders
  my ($self, %args) = @_;
  my $xyPoints = delete($args{'-data'});
  my $pointCount  = (@{$xyPoints})/2;
  my $h = $self->cget('-height');
  my $w = $self->cget('-width');
  my $lastPoint = 1; # last pointed plotted is flaged as being out of the plot box
  my $b = $self->cget(-boarder);
  my @p;  # a new array with points for line segment to be plotted
  my ($x,$y);
  my ($xp,$yp) = ($xyPoints->[0], $xyPoints->[1]); # get the first point 
  if(($xp >= $b->[3])  and ($xp <= ($w-$b->[1]))  and ($yp >= $b->[0]) and ($yp <= ($h-$b->[2])) ) {
    # first point is in, put points in the new array
    push @p, ($xp,$yp);  # push the x,y pair
    $lastPoint = 0; # flag the last point as in 
  }
  for(my $i=1; $i< $pointCount; $i++) {
      ($x,$y) = ($xyPoints->[$i*2], $xyPoints->[$i*2+1]);
      # print "clipPlot $i ($x $b->[3])  and ($x  $w $b->[1])   ($y  $b->[0])  ($y  ($h-$b->[2])) lastPoint  $lastPoint\n";
      if(($x >= $b->[3])  and ($x <= ($w-$b->[1]))  and ($y >= $b->[0]) and ($y <= ($h-$b->[2])) ) {
	  # OK, this point is in, if the last one was out then we have work to do
	  if( $lastPoint == 1) { #out
	      $lastPoint = 0;   # in
	      my($xn,$yn) = $self->clipLineInOut($x ,$y ,$xp,$yp, $b->[3], $b->[0], $w-$b->[1], $h-$b->[2]);
	      push (@p, ($xn,$yn));
	      push (@p, ($x, $y ));
	      ($xp,$yp) =  ($x, $y );
	  } else { # last point was in, this  in  so we just add a point to the line and carry on
	      push (@p, ($x, $y ));
	      ($xp,$yp) =  ($x, $y );
	  } # end else 
      } else {  # this point out 
	  if($lastPoint == 0) { # in
	      # this point is out, last one was in, need to draw a line 
	      my ($xEdge,$yEdge) = $self->clipLineInOut($xp ,$yp ,$x,$y, $b->[3], $b->[0], $w-$b->[1], $h-$b->[2]);
	      push @p, $xEdge,$yEdge;
	      $self->createLine(\@p,%args);
	      splice(@p,0);  # empty the array?
	      $lastPoint = 1;   # out
	      ($xp,$yp) =  ($x, $y );
	  } else { # two points in a row out but maybe the lies goes thru the active area
	      # print "clip two points in a row out of box.\n";
	      my $p = $self->clipLineOutOut($xp ,$yp ,$x,$y, $b->[3], $b->[0], $w-$b->[1], $h-$b->[2]);
	      $self->createLine($p,%args)if(@$p >= 4);
	      $lastPoint = 1; # out!
	      ($xp,$yp) = ($x, $y );
	      
	  } # end else
      }
  } # end loop
  # now when we get out of the loop if there are any points in the @p array, make a line
  $self->createLine(\@p,%args) if(@p >= 4);
  
}

sub clipLineOutOut { # x,y  ,  x,y  and x,y corners of the box
  # see if the line goes thru the box
  # If so, draw the line
  # else do nothing
  my ($self,$x1,$y1,$x2,$y2,$xb1,$yb1,$xb2,$yb2) = @_;  # wow!
  my (@p,$x,$y);
  # print "clipLine ($x1,$y1) , ($x2,$y2),($xb1,$yb1) ,($xb2,$yb2)\n"; 
  return(\@p)if( ($x1 < $xb1) and ($x2 < $xb1));  # line not in the box 
  return(\@p)if( ($x1 > $xb2) and ($x2 > $xb2));
  return(\@p)if( ($y1 > $yb2) and ($y2 > $yb2));
  return(\@p)if( ($y1 < $yb1) and ($y2 < $yb1));
  # get here the line might pass thru the plot box
  # print "clipLineOutOut p1($x1,$y1), p2($x2,$y2), box1($xb1,$yb1), box2($xb2,$yb2)\n"; 
  my $m = ($y1-$y2)/($x1-$x2);    # as in y = mx + b
  my $b = $y1 - $m*$x1;
  # print "clipLineOutOut line m $m b $b\n";
  $x = ($m != 0) ? ($yb1-$b)/$m : $x1 ; #   print "$x $yb1\n";
  push @p, ($x,$yb1) if( ($x >= $xb1) and ($x <= $xb2) );
  $x = ($m != 0) ? ($yb2-$b)/$m : $x1 ;
  push @p, ($x,$yb2) if( ($x >= $xb1) and ($x <= $xb2) );
  $y = $m*$xb1 + $b;
  push @p, ($xb1,$y) if( ($y >= $yb1) and ($y <= $yb2) );
  $y = $m*$xb2 + $b;
  push @p, ($xb2,$y) if( ($y >= $yb1) and ($y <= $yb2) );
  # print "clifLineOutOut @p", "\n";
  return(\@p)

}

sub clipLineInOut { # x,y (1 in), x,y (2 out)   and x,y corners of the box
  # We have two points, one in the box, one outside of the box
  # Find where the line between the two points intersects the edges of the box
  # returns that point
  # Notebook page 106 
  my ($self,$x1,$y1,$x2,$y2,$xb1,$yb1,$xb2,$yb2) = @_;  # wow!
  # print "clipLine ($x1,$y1) , ($x2,$y2),($xb1,$yb1) ,($xb2,$yb2)\n"; 
  my ($xi,$yi);
  if($x1 == $x2) { # line par to y axis
    # print "clipLine line parallel to y axis\n";  
    $xi = $x1;
    $yi = ($y2 < $yb1) ? $yb1  : $yb2;
    return($xi,$yi);
  }
  if($y1 == $y2) { # line par to x axis 
   # print "clipLine line parallel to y axis\n";  
    $yi = $y1;
    $xi = ($x2 < $xb1) ? $xb1 : $xb2;
    return($xi,$yi);
  }
  # y = mx + b;   m = dy/dx   b = y1 - m*x1  x = (y-b)/m
  if(($x1-$x2) != 0) {
    my $m = ($y1-$y2)/($x1-$x2);
    my $b = $y1 - $m*$x1;
    if($y2 <= $y1) { # north boarder 
      $xi = ($yb1-$b)/$m;
      return($xi,$yb1) if( ($xi >= $xb1)  and ($xi <= $xb2) );
    } else { # south boarder
      $xi = ($yb2-$b)/$m;
      return($xi,$yb2) if( ($xi >= $xb1)  and ($xi <= $xb2) );
    }
    if($x2 <= $x1) { # west boarder
      $yi = $m*$xb1 + $b;
      return($xb1,$yi) if( ($yi >= $yb1)  and ($yi <= $yb2) );
    }
    # only one remaining is east boarder
    $yi = $m*$xb2 + $b;
    return($xb2,$yi) if( ($yi >= $yb1)  and ($yi <= $yb2) );
  } else { # dx == 0, vertical line, north or south boarder
    return($x1,$yb1)if($y2 <= $yb1);
    return($x1,$yb2)if($y2 >= $yb2);
    }
  warn "clip Line cannot get to here!";
  return(0,0);
}

# There are five  coordinate systems in use.  Comments came late in the code.
# some name usage might be wrong - Dec 2005, needs to be taken care of
# 1. World  - Units are the physical system being plotted.  Amps, DJ Average, dollers, etc
# 2. Axis   - Units are pixels. The (0,0) point is where the axis cross 
# 3. Plot   - Units are pixels. The (0,0) point is the lower left corner of the canvas
# 4. Canvas - Units are pixels. The (0,0) point is the upper left corner of the canvas.
# 5. Screen - Units are pixels. The (0,0) point is the upper left corner of the screen. (What about multi screens?)
#             For the  Perl/Tk low level canvas routines x,y values are in the canvas system.
#             I see I sometimes call Canvas  Screen in the code, should fix that.

sub screenToCanvas { # x,y in screen system
  # return x,y in canvas system
  use strict;
  my ($self, $x, $y) = @_;
  my $g = $Tk::LineGraph::MW->geometry();
  # print "geometry is $g \n";
  my ($w,$h,$xs,$ys) = split(/[x+]/,$g);
  # print "screenToCanvas in ($x,$y), offset ($xs, $ys)\n";
  return($x+$xs,$y+$ys);
  }

sub canvasToScreen { # x,y in canvas  system
  # return x,y in screen system
  use strict;
  my ($self, $x, $y) = @_;
  my $g = $Tk::LineGraph::MW->geometry();
  # print "geometry is $g \n";
  my ($w,$h,$xs,$ys) = split(/[x+]/,$g);
  # print "canvasToScreen  in ($x,$y), offset ($xs, $ys)\n";
  return($x+$xs,$y+$ys);
  }

sub toWorldPoints { # x,y in the Canvas system
  # convert to World points
  # get points on canvas from system in pixels, need to change them into units in the plot
  my ($self,$xp,$yp)  = @_;
  my $b = $self->cget(-boarder);   # north, east, south, west
  my $s = $self->cget(-scale);     # min X, max X, interval, min y, max y, 
  my $h = $self->cget(-height);
  my $w = $self->cget(-width);
  my $x = ($xp        - $b->[3])*($s->[1]-$s->[0])/($w-$b->[1]-$b->[3]) + $s->[0];
  my $y  = ( ($h-$yp) - $b->[2])*($s->[4]-$s->[3])/($h-$b->[0]-$b->[2]) + $s->[3];
 # but if the y axis are log some more work to do.
  my $y1 = ( ($h-$yp) - $b->[2])*($s->[7]-$s->[6])/($h-$b->[0]-$b->[2]) + $s->[6];
  $y = 10**$y   if($self->cget('-yType')  eq 'log');
  $y1 = 10**$y1 if($self->cget('-y1Type') eq 'log');
  # print "toWorldPoints ($xp,$yp) to ($x,$y,$y1\n";
  return($x,$y,$y1);
}

sub toCanvasPixels {   # which, x,y
  # given an x,y value in axis or canvas system return x,y in Canvas pixels.
  # axis => x,y are pixels relative to where the boarder is
  # canvas => x,y are pixels in the canvas system.
  # more to follow ?
  my($self, $which, $x, $y) = @_;
  my ($xOut, $yOut);
  if($which eq 'axis') {
    my $b = $self->cget(-boarder);
    return($x+$b->[3],$self->cget('-height')-($y+$b->[2]));
  }
  if($which eq 'canvas') {
    return($x, $self->cget('-height')-$y);
  }

} # end to canvas pixels

sub arraysToCanvasPixels { # which, x array ref, y array ref
  # given x array ref and y aray ref generate the one array, xy in canvas pixels
  my($self, $which, $xa, $ya) = @_;
  my @xyOut;
  my $h = $self->cget('-height');
  my $b = $self->cget(-boarder);
  if($which eq 'axis') {
    for (my $i=0;$i<@$ya; $i++) {
      $xyOut[$i*2]   = $xa->[$i]+$b->[3];
      $xyOut[$i*2+1] = $h-($ya->[$i]+$b->[2]);
    }
    return (@xyOut);
  }
}

sub ds2PlotPixels { # ref to xArray and yArray with ds values, which y axis 
  # ds is dataSet.  They are in world system
  # convert to Plot pixels, return ref to converted x array and y array
  my($self,$xa, $ya, $yAxis) = @_;
  my $s = $self->cget(-scale);
  my($xMin,$xMax,$yMin,$yMax);
  ($xMin,$xMax,$yMin,$yMax) = ($s->[0], $s->[1], $s->[3],$s->[4]);
  ($xMin,$xMax,$yMin,$yMax) = ($s->[0], $s->[1], $s->[6],$s->[7])if($yAxis eq "Y1");
  # print "ds2PlotPixels X($xMin,$xMax),Y($yMin,$yMax)\n";
  my $b = $self->cget(-boarder);
  my ($nb, $eb, $sb, $wb) = ($b->[0], $b->[1], $b->[2], $b->[3]);
  my $h = $self->cget('-height');
  my $w = $self->cget('-width');
  my(@xR,@yR);  # converted values to be returned
  my $sfX = ($w-$eb-$wb)/($xMax-$xMin);
  my $sfY = ($h-$nb-$sb)/($yMax-$yMin);
  my ($x,$y);
  for(my $i; $i<@{$xa}; $i++) {
    $x = ($xa->[$i]-$xMin)*$sfX;
    $y = ($ya->[$i]-$yMin)*$sfY;
    push @xR,$x;
    push @yR,$y;
  }
  return(\@xR, \@yR);
}

sub niceRange { # input is min,max, 
  # return is a new min, max and an interval for the tick marks
  # interval is not the number of intervals but the size of the interval
  # find a good min, max and interval for the axis
  # if min > max return min 0, max 100, interval of 10.  
  use strict;
  my $min = shift;
  my $max = shift;
  my $delta = $max - $min;
  return(0,100,10)if($delta <= 0);
  my $r = ($max != 0) ? $delta/$max : $delta;
  $r = -$delta/$min if($max < 0);
  my $spaces = 10; # number 
  # don't want a lot of ticks if the size of the space is very small compaired to values
  $spaces = 2 if($r < 1E-02);

  while(1 == 1) { # do this until a  return
      # print "ratio <$r> \n";
      # $spaces = 2 if($r < 1E-08);
      my $interval = $delta/$spaces;
      my $power = floor(log10($delta));
      # print "min,max $min,$max  delta $delta  power $power interval $interval $spaces\n";
      # find a good interval for the ticks
      $interval = $interval*(10**-$power)*10;
      # print "min,max $min,$max  delta $delta  power $power interval $interval\n";
      # now round this up the next whole number but not 3 or 6, 7 or 9.
      # leaves 1,2,4,5,8 
      $interval = ceil($interval);
      $interval = 8  if( ($interval == 7) or ($interval == 6) );
      $interval = 10 if(  $interval == 9);
      $interval = 4  if(  $interval == 3);
      #print "min,max $min,$max  delta $delta  power $power interval $interval\n";
      $interval = $interval*(10**(+$power-1));
      #print "min,max $min,$max  delta $delta  power $power interval $interval\n";
      # find the new min
      my ($newMax, $newMin);
      my $newDelta = $interval*$spaces;
      if($newDelta == $delta) {
	$newMax = $max;
	$newMin = $min;
      } else {
	my $n = $min/$interval;
	my $nFloor = floor($n);
	# print "n $n floor of n is $nFloor \n";
	$newMin = $nFloor * $interval;
	$newMax = $newMin + $spaces*$interval;
      }
      # print "niceRange min,max $min,$max  delta $delta  power $power interval $interval newMin $newMin newMax $newMax \n";
      
      # now see how much of the space has been used.  If there is a lot empty, increase the number of spaces (tickes)
      return($newMin, $newMax, $interval) if($spaces <= 3);
      return($newMin, $newMax, $interval) if( (($newDelta/$delta) < 1.4) and ($newMax >= $max) );
      $spaces++;
  }
}

# Time.  If total time is between 6 months and 20 months, mark months 
# If total time is more than 20 months, mark years and year fractions.
# If time from 5 weeks to 6 months (180 days) (24 weeks), mark in weeks or two weeks
# if time from 5 days to 35 days, days 
# If time from 5 hours to 120 hours (5 days) do dd:hh
# If from 5 min to 300 min (5 hours) do hh:mm
# If less than 5 min do sec. (300 sec max).





sub timeTicks { # input is min uni time and ma uni time
# setup the names on the tick marks
# what about the interval, the number of them
# Put the first time (date/time) of the first point some where (top right of the plot).
    my($max,$min) = (shift,shift);
    my $delta = $max-$min;
    my $first;
    if($delta <= 300) { # 300 seconds, 5 min  do seconds
	# just call nicescale with min 0 and ma $delta

    } elsif($delta <= 3600) { #  between 5 min and 60 min, do min 
	$first = floor($min/60)*60;
#	call nice
    } elsif($delta <= 300*60) { #  60  min, 5 hous, do hh:mm 5 min to 5 hours.
	$first = floor($min/3600)*3600;
	
    } elsif($delta <= 120*3600) { # between 5 hours and 120 hours (5 days) do days dd:hh


    } elsif($delta <= 150*24*3600) { # bwetween 5 days and 150 days do  mm:dd:hh

    } else { # do mm:dd 


    }

}

sub logRange { # min, max 
  # for scaling a log axis
  #returns a max and min, intervals  and an array ref that contains labels for the ticks
  use strict;
  my $self = shift;
  my($min,$max) = (shift,shift);

  if( ($min eq undef)  or ($max eq undef) ) {
      $min = 0.1;
      $max = 1000;
  }
  if($min <= 0) {
      my $t =  $self->cget(-logMin);
      print "Can't log plot data that contains numbers less than or equal to zero.\n";
      print "Data min is: <$min>.  Changed to $t\n";
      $min = $self->cget(-logMin);
      # set a flag to indicate the log data must be checked for min! 
      $self->{-logCheck} = 1; # true
  }
  my $delta = $max-$min;
  my $first;
  my @tLabel;

  my $maxP =  ceil(log10($max));
  $maxP = $maxP+1 if($maxP>0);
  my $minP =  floor(log10($min));
  my $f;
  # print "logRange max $max,min $min,  $maxP,$minP)\n";
  foreach my $t ($minP..$maxP) {
    my $n = 10.0**$t;
    # print "logRange <$n> <$t>\n";
    $f = sprintf("1E%3.2d",$t)if($t<0);
    $f = sprintf("1E+%2.2d",$t)if($t>=0);
    # print "logRange $f \n";
    push @tLabel, $f;
  }
  return($minP,$maxP,1,\@tLabel);
  # look returning min Power and the max Power.  Note the power step is always 1 this might not be good
  # used  1E-10, 1E-11 and so on.  Looks good to me!
}

sub timeRange {  # min, max
  # for scaling a time axis when the input is unix time, that is seconds
  # returns a new max and min and an array ref that contains labels for the ticks
  
  my($min,$max) = (shift,shift);
  $min = floor($min);
  $max = ceil($max);
  my $delta = $max-$min;
  my $first;
  my @tLabel;
  # print "timeRange min <$min> max <$max>  delta <$delta>\n";
  if($delta <= 300) { # 5 min
    $min = 10*floor($min/10)if($delta > 30);
    my $delta = $max-$min;
    my $i = 60;
    $i = 30 if($delta <= 120);
    $i = 10 if($delta <= 60);
    $i = 5 if($delta <= 20);
    $i = 1  if($delta <= 10);
    $first = localtime($min);   # show this as the first time
    # print "timeRange first time <$first>\n";
    # Sun Sept 21 15:33;22 1977 
    # now get the ticks out in ddd hh:mm:ss
    # print "timeRange min <$min> max <$max> delta <$delta> inc <$i> \n";
    my $tickTime = $min;
    while($tickTime <= $max) {
      my $s = localtime($tickTime);
      my @e = split(/\s/,$s);
      my $l = $e[0]." ".$e[3];
      push @tLabel,$l;
      # print "timeRange <$l>\n";
      $tickTime = $tickTime + $i;
    }
    $max = $tickTime-$i;
    return($min, $max, $i, \@tLabel);
  } elsif($delta <= 3600) { #  between 5 min and 60 min, do min 
    $first = floor($min/60)*60;
    #	call nice
  } elsif($delta <= 300*60) { #  60  min, 5 hous, do hh:mm 5 min to 5 hours.
    $first = floor($min/3600)*3600;
    
  } elsif($delta <= 120*3600) { # between 5 hours and 120 hours (5 days) do days dd:hh
    
    
  } elsif($delta <= 150*24*3600) { # bwetween 5 days and 150 days do  mm:dd:hh
      
  } else { # do mm:dd 
      
      
  }
  
}

1;

__END__


=head1 NAME

  Tk::LineGraph - A 2D Plot widget written entirely in Perl/Tk.

=head1 DESCRIPTION

The LineGraph widget is an extension of the Canvas widget that will plot Dataset objects in a 2D graph.
It is written entirely in Perl/Tk.
Scaled labeled X, Y and Y1 axis are displayed.  Many Datasets can be displayed in one LineGraph widget.  
The widget is interactive allowing the plot to be zoomed and individual data sets to be shown or hidden.
Axis scales and labels can be set in the code and interactively. 
Indeed almost all the LineGraph options can be changed from the widget itself.
LineGraph is a quick easy way to build an interactive Plot widget into a 
Perl application.

The following additional (in addition to the Canvas options) option/value pairs are supported:

=over 4

=item B<-dataset>

A data set to be given to the LineGraph widget to be plotted.  No default.

=item B<-colors>

An array of colors to use for the display of the data sets.  If there are more data sets than colors in the 
array then the colors will cycle. 

=item B<-boarders>

An array of four numbers which are the boarder size in pixels of the plot in the canvas.  
The order is North (top), East (right), South (bottom) and West (right).  These values 
can be changed from the PlotSetup Menu.

=item B<-scale>

A nine element array of the scale factors for the x,y, and y1 axis.  The  nine values are xMin, Xmax, 
xStep, yMin, yMax, yStep,
y1Min, y1Max, and y1Step.  The plot can be rescaled by changing these values.  This can be done in code 
using the configure method or using the Axis Menu.
The default values for all the axis are 0 to 100 with a step size of 10.

=item B<-plotTitle>

A two element array.  The first element is the plot title, the second element is the y offset of the title below the
top edge of the window.  The title is centered in the x direction.  These values can be changed from the PlotSetup Menu
or the configure method. 

=item B<-xlabel>

The label for the X axis.  The text is centered on the X axis. This value can be changed from the Axis Menu or
the configure method.
 
=item B<-ylabel>

The label for the Y axis.   The text is centered on the Y axis. This value can be changed from the Axis Menu.
or the configure method.
 
=item B<-y1label>

The label for the Y1 axis which is the optional axis to the right of the plot.   
The text is centered on the Y1 axis.  This value can be changed from the Axis Menu. the configure method. 

=item B<-xType>

The type of the X axis.  Currently only linear is supported for the X axis.

=item B<-yType>

The type of the Y axis.  Allowed values are linear and log.  This value can be changed from the Axis Menu or
the configure method.  
The default type is linear.

=item B<-y1Type>

The type of the y1 axis.  Allowed values are   linear and log..  This value can be changed from the Axis Menu
or the configure method.

=item B<-fonts>

A four element array with the font names for the various labels in the plot.  Element 0 is the font of the numbers 
at the axis ticks. Element 1 is the font for the axis labels (all of them), Element 2 is the plot title font and 
element 3 is the font for the legend.  These values can be changed from the PlotSetup Menu or the configure method.

=item B<-autoScaleX>

When set to "On" the X axis will be scaled to the values to be plotted.  Default is "On".
"Off" is the other possible value.

=item B<-autoScaleY> 

When set to "On" the Y axis will be scaled to the values to be plotted.  Default is "On".
"Off" is the other possible value.


=item B<-autoScaleY1> 

When set to "On" the Y1 axis will be scaled to the values to be plotted.  Default is "On".
"Off" is the other possible value.

=back

=head1 WIDGET BEHAVIOR

When the cursor is on a plotted line the line turns red to help identify 
that line in the plot.  Likewise when the cursor is over a Dataset name
in the legend the corresponding dataset line plot will turn red.  Individual 
points are not shown when there are more than  20 points in the plot.

The left button (button-1) is used to zoom a graph. Move the cursor to one of
the corners of the box into which you want the graph to zoom.  Hold down the 
left button and move to the opposite corner.  Release the left button and
the graph will zoom into the box. To undo one level of zoom click the
left button without moving the mouse.

The center button can be used to see the coordinates of a point on the plot.
With the cursor in the graph body click the center button and a pop up will
show the coordinates of the cursor position scaled to the axis.  The popup
goes away when the center button is released.

The right button can be used to move a line on the plot.  This can be useful 
in trying to line up date or move clutter.

The options menu provides tools to help look at the data.  The Hide/Show option allows
datasets to be removed from the plot,  made "inactive".  
The same menu can make the dataset active.  The Rescale Active option is used 
to rescale the graph to the currently active datasets.  Again this can be useful
in looking at selected datasets.  

The Datasets option allows the color of a dataset to be changed.
The vertical axis used to scale the dataset can be set from the Datasets
menu.  Finally the values in a Dataset can be displayed in the Datasets menu. 

=head1 EXAMPLE

     use Tk;
     use LineGraph;
     use DataSet;

     my $mw = MainWindow->new;

     my $cp = $mw->LineGraph(-width=>500, -height=>500, -background => snow)->grid;

     my @yArray = (1..5,11..18,22..23,99..300,333..555,0,0,0,0,600,600,600,600,599,599,599);
     my $ds = LineGraphDataset->new(-yData=>\@yArray,-name=>"setOne");
     $cp->plot(-dataset=>$ds);

     MainLoop;


=head1 METHODS

=item B<addDatasets(-dataset=>$ds1, -dataset=>$ds2, option=>value, )>

=item B<plot(-dataset=>$ds4, option=>value, )>



=head1 AUTHOR

Tom Clifford (Still_Aimless@yahoo.com)

Copyright (C) Tom Clifford.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 BUGS

Case where the number of points in x and y are different is not handled.
Log plot with zero or negative numbers is not graceful. 


=head1 KEYWORDS

Plot 2D Axis

=cut


__END__

# Nov 2005log - axis
# Dec 2005 - grid
# button-2, more info on print out.  Then in a window - done Dec 12, 2005
# center x axis label   -  done  Dec 2005
# center y axis label   -  done  Dec 2005
# center y1 axis label   - 
# center legend         - done  Dec 2005
# A no scale mode, user does own scaling
# Dec 12 2005 - button-2 - popup can be off screen
# Dec 12,2005 - Better format for numbers on axis.
# Dec 12,2005 -label on y1 axis is wrong - Done Dec 12, 2005
# Dec 2005 - legend needs y1 - Done Dec 12, 2005 
# Dec 2005 - What if legends are longer than plot?  Put them in their own window? 
# Dec 2005 - Dataset "editor" where axis can be assigned, points seen, changed, added
# Dec 2005 - finish log axis
# Dec 2005 - finish time axis
# Dec 2005 - Thinking of making boarder % of the window size.  No, not good idea.
# Dec 2005 - Make the dataset menu like the hide/show.  Hangs around.  - Done Jan 2006
# Dec 2005 - log axis needs to check that all numbers to plot are > 0 .
# Dec 2005 - Need to support some way for the plot to not self scale. - Done Jan 2006
# Jan 2006 - Legend box
# Jan 2006 - Could have the Y or Y1 axis go red when a line of legden is selected.
# Jan 2006 - When "on" a Y or Y1 axis, color al the graphs that go with the axis. 
