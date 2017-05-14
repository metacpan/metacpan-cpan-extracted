#!/usr/local/bin/perl

my $path;
my $perl;

=head1 NAME

 vptk - Perl/Tk Visual resource editor (canvas edition)

=head1 SYNOPSIS

 vptk [-help]

   -h[elp]  - show this help

=head1 DESCRIPTION

  1. General considerations
  =========================

  * The project supply toolkit for Perl/Tk canvas design
  * End-user may be not familiar with Perl/Tk

  2. User interface
  =================

  * All data stored in Perl/Tk include-file form
  * Most functions accessible both from pull-down menu,
    toolbar panel and by keyboard shortcuts

  3. Restrictions
  ===============

  * No infinite scaling for graphic objects
  * One-level undo only (maybe increased?)

  4. Main features
  ================

  * Widgets stored in Perl/Tk include-file format
  * All basic canvas objects supported: 
    line, poly, curves, oval, arc, chord, rectangle
  * Object editing by using selection bars
  * Objects order supported
  * Toolbar ballons and status string
  * File setup: description, background color, output precision
  * Constraint support for uniform figures
  * Arc/Pie support
  * Cursor changes on selection/object
  * Undo for all artwork modifications (incl. drag/resize)
  * Group select (for move/duplicate/erase only) - with massive undo
  * Help & HTML documentation
  * Unlimited undo/redo
  * Post-script print
 
  5. To be implemented
  ====================

  * Point remove (in polygons)
  * Figures type conversion (oval-circle,square-rect,line-polyline,
  line-curve,polyline-polygon,polygon-splash)
  * Cursor position display (on/off)
  * Strict checks of 'points' list (pairs, minimal number, constraints)
  * Add/remove objects to/from group selection with shift+click
  * NumEntry for numeric values

  6. Known bugs
  =============

  * transformations produce wrong results when scale is not 1:1 - blocked
  * dragging uniform figures sometime produce 'non-uniform' results

=cut

BEGIN
{
  $path=$0;
  $path=~s#[^/\\]+$##;
  $path='.' unless $path;
  unshift @INC,$path;
  foreach($^X, '/usr/local/bin/perl', '/usr/bin/perl')
  {
    if(-f $_)
    {
      $perl = $_;
      last;
    }
  }
  die "$0 installation error: directory ${path}/toolbar not found!\n"
    unless -d "${path}/toolbar";
}

use strict;
use Tk 800;

use Tk::DialogBox;
use Tk::Dialog;
use Tk::TList;
use Tk::Photo;
use Tk::Checkbutton;
use Tk::Canvas;
use Tk::Balloon;
use Tk::ROText;

if (grep /^--?h/,@ARGV)
{
  # for real perl script only!
  # does not work on M$ Win EXE-file
  system "perldoc $0";
  exit 1;
}

my $ver=q$Revision: 1.2 $;

my $bg_color='gray';
my $changes;          # Modifications flag
my $precision=2;      # Output file floating point precision
my %canv_obj=();      # internal structure for objects storing
my @canv_obj=();      # objects order array
my $cnv_bg=$bg_color; # canvas background
my $cnv_t='';         # canvas title (descriptions)
my $cnv_fullcode=0;   # generate full executable code
my $lastfile='';      # last file used in Open/Save
my $selected_id='';   # ID for selected object
my @undo=();          # Undo buffer
my @redo=();          # Redo buffer
my $obj_count=0;      # Uniq object ID counter
my $scale=1;          # Visualisation scale
my $scale_h='1:1';    # Visualisation scale (human-friendly form)
my ($sx,$sy);         # saved initial mouse x,y for dragging procedure
my $mouse_drag='';    # mouse gragging function
my $selection_type=1; # 1 - regular; 2 - fine edit
my $selection=0;      # 'selection painted' flag
# The following table describes geometric objects translation to Tk canvas:
my (%obj2canvas)=(
  Oval=>'oval',Circle=>'oval',Line=>'line',PolyLine=>'line',Splash=>'polygon',
  Polygon=>'polygon',Curve=>'line',Rectangle=>'rectangle',Square=>'rectangle',
  Pie=>'arc',Chord=>'arc');
# and here is the table of all objects' properties
my (%attr) = (
'Line'=>[-arrow=>'arrowside',-width=>'linewidth',-fill=>'color','points'=>2,
  -capstyle=>'menu(butt|projecting|round)'],
'PolyLine'=>[-arrow=>'arrowside',-width=>'linewidth',-fill=>'color','points'=>3,
  -capstyle=>'menu(butt|projecting|round)',-joinstyle=>'menu(bevel|miter|round)'],
'Curve'=>[-arrow=>'arrowside',-width=>'linewidth',-fill=>'color',-splinesteps=>'linewidth',
  'points'=>3,-capstyle=>'menu(butt|projecting|round)',-joinstyle=>'menu(bevel|miter|round)'],
'Polygon'=>[-width=>'linewidth',-fill=>'color',-outline=>'color','points'=>3],
'Splash'=>[-width=>'linewidth',-fill=>'color',-outline=>'color',-splinesteps=>'linewidth',
  'points'=>3],
'Oval'=>[-width=>'linewidth',-fill=>'color',-outline=>'color','points'=>2],
'Circle'=>[-width=>'linewidth',-fill=>'color',-outline=>'color','points'=>2],
'Rectangle'=>[-width=>'linewidth',-fill=>'color',-outline=>'color','points'=>2],
'Square'=>[-width=>'linewidth',-fill=>'color',-outline=>'color','points'=>2],
'Pie'=>[-extent=>'linewidth',-fill=>'color',-outline=>'color',-start=>'linewidth',-width=>'linewidth','points'=>2],
'Chord'=>[-extent=>'linewidth',-fill=>'color',-outline=>'color',-start=>'linewidth',-width=>'linewidth','points'=>2]
);

#
# ======================== Geometry management for Main window ================
# 
my $mw = MainWindow->new(-title=>"Visual Perl Tk $ver (canvas edition)",
  -background=>$bg_color);
$mw->bind("<Escape>", \&abandon);
$mw->geometry('+120+1'); # initial window position

# create bold font:
$mw->fontCreate('C_bold',-family => 'courier', -weight => 'bold');
# Prepare help from HTML file:
# 1. read HTML file
my (@html_help)=(&read_html("$path/toolbar/canvas_help.html"));
@html_help = 'text Sorry, help file not available!' unless $html_help[0];
# 2. get gif-files list
my @html_gifs=grep(/^gif/,@html_help);
map s/^\S+\s+//,@html_gifs;
# 3. get array of text descriptors in following format:
# {gif/text/bold} <text>
# read all pictures:
my %pic;
foreach (qw/open save new undo redo repaint properties delete exit duplicate/,
qw/canv_chord canv_line canv_polygon canv_splash canv_circle canv_oval canv_polyline canv_square canv_curve canv_pie canv_rectangle/,
  @html_gifs)
{
  my $pic_file="$path/toolbar/$_.gif";
  $pic_file = "$path/toolbar/$_.xpm" unless -e $pic_file;
  $pic{$_} = $mw->Photo(-file=>$pic_file)
    unless defined $pic{$_};
}

# +-------------------------------+
# | menu ...                      |
# +-------------------------------+
# | tool bar                      |
# +-------------------------------+
# |                               |  
# |                               |  
# |             canvas            |
# |             area              |
# |                               |  
# |                               |  
# |_______________________________|
# | status bar                    |
# +-------------------------------+
#

my $menubar = $mw->Frame(-relief => 'raised', -borderwidth => 2)
->form(-top=>'%0',-left=>'%0',-right=>'%100');

$menubar->Menubutton(qw/-text File -underline 0 -tearoff 0 -menuitems/ =>
  [
    [Button => 'Open ...',    -command => \&file_open, -underline => 0 , -accelerator => 'Control+o'],
    [Button => 'New',         -command => \&file_new, -underline => 0 ,  -accelerator => 'Control+n'],
    [Button => 'Save',        -command => \&file_save, -underline => 0 , -accelerator => 'Control+s'],
    [Button => 'Save As ...', -command => [\&file_save, 'Save As'], -underline => 5 ],
    [Separator => ''],
    [Button => 'Setup ...',   -command => \&file_setup, -underline => 1 ],
    [Separator => ''],
    [Button => 'Print ...',   -command => \&file_print, -underline => 0 ],
    [Separator => ''],
    [Button => 'Quit',        -command => \&abandon, -underline => 0 ,   -accelerator => 'ESC'],
  ])->pack(-side=>'left');

$menubar->Menubutton(qw/-text Edit -underline 0 -tearoff 0 -menuitems/ =>
  [
    [Button => 'Undo',         -command => \&undo, -underline => 0 , -accelerator => 'Control+z'],
    [Button => 'Redo',         -command => \&redo, -underline => 0 , -accelerator => 'Control+r'],
    [Button => 'Properties',   -command => \&edit_properties, -underline => 0 ],
    [Button => 'Delete',       -command => \&edit_delete, -underline => 1 ],
    [Button => 'Duplicate',    -command => \&edit_duplicate, -underline => 0 ],
  ])->pack(-side=>'left');

$menubar->Menubutton(qw/-text Transform -underline 0 -tearoff 0 -menuitems/ =>
  [
    [Button => 'Re-size',      -command => \&menus_resize, -underline => 3 ],
    [Button => 'X-mirror',     -command => \&menus_x_mirror, -underline => 0 ],
    [Button => 'Y-mirror',     -command => \&menus_y_mirror, -underline => 0 ],
    [Button => 'Free rotate',  -command => \&free_rotate, -underline => 0 ],
    [Button => 'Point edit',   -command => \&menus_point_edit, -underline => 0 ],
  ])->pack(-side=>'left');

$menubar->Menubutton(qw/-text Order -underline 0 -tearoff 0 -menuitems/ =>
  [
    [Button => 'Move up',        -command => [\&menus_order,'1+'], -underline => 5 ],
    [Button => 'Move down',      -command => [\&menus_order,'1-'], -underline => 5 ],
    [Button => 'Bring to front', -command => [\&menus_order,'+'], -underline => 0 ],
    [Button => 'Send to back',   -command => [\&menus_order,'-'], -underline => 0 ],
  ])->pack(-side=>'left');

$menubar->Menubutton(qw/-text View -underline 0 -tearoff 0 -menuitems/ =>
  [
     [Button => 'Repaint',        -command => \&menus_repaint, -underline => 0 ],
     [Separator => ''],
     [Button => 'Code',           -command => \&menus_codeview, -underline => 0 ],
     [Separator => ''],
     [Button => 'Scale 1:1',      -command => [\&menus_scale, '1:1'], -underline => 8 ],
     [Button => 'Scale 1:2',      -command => [\&menus_scale, '1:2'], -underline => 8 ],
     [Button => 'Scale 1:3',      -command => [\&menus_scale, '1:3'], -underline => 8 ],
     [Button => 'Scale 1:4',      -command => [\&menus_scale, '1:4'], -underline => 8 ],
     [Button => 'Scale 2:1',      -command => [\&menus_scale, '2:1']],
     [Button => 'Scale 3:1',      -command => [\&menus_scale, '3:1']],
     [Button => 'Scale 4:1',      -command => [\&menus_scale, '4:1']],
  ])->pack(-side=>'left');

my $createmenub=$menubar->Menubutton(qw/-text Create -underline 0/)
  ->pack(-side=>'left');
my $createmenu = $createmenub->Menu(-tearoff => 0);
foreach (qw/Line PolyLine Curve Polygon Splash Circle Oval Pie Chord Square Rectangle/)
{
  $createmenu->command(-label => $_, 
    -image=>$pic{lc("canv_$_")},-command => [\&menus_create, $_]);
}
$createmenub->configure(-menu =>$createmenu);

$menubar->Menubutton(qw/-text Help -underline 0 -tearoff 0 -menuitems/ =>
  [
     [Button => 'Help',      -command => \&help, -underline => 0 ],
     [Button => 'About',     -command => \&menu_about, -underline => 0 ],
  ])->pack(-side=>'right');

my $bf=$mw->Frame()->
form(-top=>$menubar,-left=>'%0',-right=>'%100',-bottom=>'%100');
my $ctrl_frame=$bf->Frame()->pack(-side=>'top',-anchor=>'nw');
my $main_frame=$bf->Frame()->
  pack(-side=>'top',-anchor=>'ne',-fill=>'both',-expand=>1);
my $status_frame=$bf->Frame(-relief=>'groove')->
  pack(-side=>'top',-anchor=>'nw',-fill=>'x');
my $sel_status_f=$status_frame->Frame(-relief=>'sunken',-borderwidth=>2)->
  pack(-side=>'left');
my $status=$sel_status_f->Label(-text=>'No selection')->pack(-side=>'left');
my $changes_f=$status_frame->Frame(-relief=>'sunken',-borderwidth=>2)->
  pack(-side=>'right');
my $changes_l=$changes_f->Label(-text=>' ')->pack(-side=>'right');
&changes(0);

my $tf=$main_frame->Scrolled('TList',-browsecmd=>\&tlist_select,
  -selectmode=>'extended',-orient => 'horizontal',-itemtype =>'imagetext')->
  pack(-side=>'left',-fill=>'y');
$tf->bind('<Control-Button-1>',\&tlist_select);
$tf->packAdjust(-side=>'left');
my $c=$main_frame->Scrolled('Canvas',-background=>$bg_color,-cursor=>'crosshair',
  -relief=>'sunken',-borderwidth=>2,
  -scrollbars=>'se',-scrollregion=>['-10c','-10c','50c','20c'])
   ->pack(-fill=>'both',-expand=>1);
# ==========
# ctrl_frame
# ==========
  $b=$mw->Balloon(-background=>'lightyellow',-initwait=>550);
  $b->attach($ctrl_frame->Button(-image=>$pic{'new'},-command=>\&file_new)->pack(-side=>'left',-expand=>1),-balloonmsg=>'New picture');
  $b->attach($ctrl_frame->Button(-image=>$pic{'open'},-command=>\&file_open) ->pack(-side=>'left',-expand=>1),-balloonmsg=>'Open file');
  $b->attach($ctrl_frame->Button(-image=>$pic{'save'},-command=>\&file_save) ->pack(-side=>'left',-expand=>1),-balloonmsg=>'Save current file');
  $ctrl_frame->Label(-text=>' ')->pack(-side=>'left',-expand=>1);
  $b->attach($ctrl_frame->Button(-image=>$pic{'undo'},-command=>\&undo) ->pack(-side=>'left',-expand=>1),-balloonmsg=>'Undo last change (limited)');
  $b->attach($ctrl_frame->Button(-image=>$pic{'redo'},-command=>\&redo) ->pack(-side=>'left',-expand=>1),-balloonmsg=>'Redo last change (limited)');
  $b->attach($ctrl_frame->Button(-image=>$pic{'delete'},-command=>\&edit_delete) ->pack(-side=>'left',-expand=>1),-balloonmsg=>'Erase selected');
  $b->attach($ctrl_frame->Button(-image=>$pic{'duplicate'},-command=>\&edit_duplicate) ->pack(-side=>'left',-expand=>1),-balloonmsg=>'Duplicate selected');
  $b->attach($ctrl_frame->Button(-image=>$pic{'properties'},-command=>\&edit_properties) ->pack(-side=>'left',-expand=>1),-balloonmsg=>'View/modify properties');
  $ctrl_frame->Label(-text=>' ')->pack(-side=>'left',-expand=>1);
  $b->attach($ctrl_frame->Button(-image=>$pic{'repaint'},-command=>\&menus_repaint) ->pack(-side=>'left',-expand=>1),-balloonmsg=>'Repaint all picture');
  my $sc_b=$ctrl_frame->Menubutton(qw/-text Scale -relief raised/)->pack(-side=>'left');
  $b->attach($sc_b,-balloonmsg=>'Zoom/unzoom picture view');
  {
    my $m = $sc_b->Menu(-tearoff => 0);
    foreach (qw/1:1 1:2 1:3 1:4 2:1 3:1 4:1/)
    {
      $m->command(-label => $_, -command=>[\&menus_scale, $_]);
    }
    $sc_b->configure(-menu => $m);
  }
  $ctrl_frame->Label(-text=>' ')->pack(-side=>'left',-expand=>1);
  $b->attach($ctrl_frame->Button(-image=>$pic{'exit'},-command=>\&abandon) ->pack(-side=>'left',-expand=>1),-balloonmsg=>'Exit program');

#
# =============================== Events/Keys binding ===============================
#
$c->bind('move','<Enter>' => sub{ $c->configure(-cursor=>'fleur') });
$c->bind('erase','<Enter>' => sub{ $c->configure(-cursor=>'pirate') });
$c->bind('resize','<Enter>' => sub{ $c->configure(-cursor=>'dotbox') });
$c->bind('configure','<Enter>' => sub{ $c->configure(-cursor=>'hand2') });
$c->bind('sel_type_resize','<Enter>' => sub{ $c->configure(-cursor=>'sizing') });
$c->bind('sel_type_cut','<Enter>' => sub{ $c->configure(-cursor=>'cross_reverse') });
$c->bind('selection','<Leave>' => sub{ $c->configure(-cursor=>'crosshair')});
$c->bind('cnv_obj','<Enter>' => sub{ $c->configure(-cursor=>'top_left_arrow')});
$c->bind('cnv_obj','<Leave>' => sub{ $c->configure(-cursor=>'crosshair')});

# massive selection area information
my %iinfo = (qw/areaX1 0 areaY1 0 areaX2 0 areaY2 0/);

$c->CanvasBind('<Button-3>',sub{&mark_start($Tk::event->x,$Tk::event->y)});
$c->CanvasBind('<B3-Motion>',sub{&mark_stroke($Tk::event->x,$Tk::event->y)});
$c->CanvasBind('<B3-ButtonRelease>',sub{&mark_end});
$c->CanvasBind('<Button-1>',\&mouse_click);
$c->CanvasBind('<B1-Motion>',sub{&mouse_drag($Tk::event->x,$Tk::event->y)});
$mw->bind('<Delete>',\&edit_delete);
$mw->bind('<Control-o>',\&file_open);
$mw->bind('<Control-s>',\&file_save);
$mw->bind('<Control-z>',\&undo);
$mw->bind('<Control-r>',\&redo);
$mw->bind('<F1>',\&help);
$mw->bind('<d>',\&edit_duplicate);

$mw->protocol('WM_DELETE_WINDOW',\&wm_abandon);

&file_read(@ARGV) if scalar(@ARGV);

MainLoop;

######################################################
#     SUBROUTINES section
######################################################

sub menu_about
{
  my $d = $mw->DialogBox(-title=>'About',-buttons=>['Ok']);
  $d->Label(-text=>"Visual Perl Tk (canvas edition)\n$ver")->pack();
  $d->Label(-text=>"Copyright (c) 2002 Felix Liberman\n\n".
    "e-mail: FelixL\@Rambler.RU\n\n".
    "IDE: GVIM 6.0")->pack();
  $d->resizable(0,0);
  $d->Show();
}

sub changes
{
  $changes=shift;
  $changes_l->configure(-text=> ($changes)?'*':' ');
}

sub redraw_preview
{
  my ($canv,$opt)=(@_);
  $canv->delete('preview');
  my @coords=(10,10,50,65);
  @coords=(10,10,65,50)
    if ($opt->{'rotate'});
  my @colors=('red','green','blue');
  @colors=('black','lightgray','darkgray')
    if ($opt->{'colormode'} eq 'gray');
  @colors=('black','white','black')
    if ($opt->{'colormode'} eq 'mono');

  $canv->create('rectangle',@coords,-fill=>'white',-outline=>'black',-tags=>['preview']);
  foreach my $color(@colors)
  {
    foreach my $i(0..3){$coords[$i]+=($i<2)?4:-4}
    my @fc=(@coords)[0,1,0,3,2,3,2,1];
    $canv->create('polygon',@fc,-fill=>$color,-smooth=>1,-tags=>['preview']);
  }

  @coords=(10,70,45,100);
  $canv->create('rectangle',@coords,-fill=>'white',-outline=>'black',-tags=>['preview']);
  $canv->create('line',25,86,53,82,11,99,30,65,25,89,-smooth=>1,-tags=>['preview']);
  $canv->create('rectangle',15,79,32,96,-tags=>['preview'])
   if $opt->{'capture'};
}

sub file_print
{
  my %opt=(
    'rotate'=>0,
    'colormode'=>'color',
    'name'=>'picture.ps',
    'capture'=>0);
  my $db=$mw->DialogBox(-title=>'Print PostScript',-buttons=>['Start','Dismiss']);
  my $Preview = $db -> Canvas(-borderwidth=>2,-relief=>'sunken',
    -width=>100,-height=>100)-> pack(-anchor=>'nw',-side=>'left',-fill=>'y');
  my $Options = $db -> Frame ( -relief=>'raised' ) -> 
    pack(-anchor=>'nw',-padx=>10,-side=>'left',-pady=>10,-fill=>'y');

  &redraw_preview($Preview,\%opt);
  my $or_fr = $Options -> LabFrame ( -labelside=>'acrosstop',-relief=>'ridge',
    -label=>'Orientation:') -> pack(-anchor=>'nw',-padx=>10);
  $or_fr -> Radiobutton ( -text=>'Portrait', -variable=>\$opt{'rotate'}, 
    -value=>0, -command=> [\&redraw_preview,$Preview,\%opt] ) ->  pack(-anchor=>'nw',-side=>'left');
  $or_fr -> Radiobutton ( -text=>'Landscape', -variable=>\$opt{'rotate'}, 
    -value=>1, -command=> [\&redraw_preview,$Preview,\%opt] ) ->  pack(-anchor=>'nw',-side=>'left');

  my $mode_fr = $Options -> LabFrame ( -labelside=>'acrosstop',-relief=>'ridge',
    -label=>'Print mode:' ) -> pack(-anchor=>'nw',-padx=>10);
  $mode_fr -> Radiobutton ( -text=>'Color', -value=>'color',
    -variable=>\$opt{'colormode'}, -command=> [\&redraw_preview,$Preview,\%opt]) -> pack(-side=>'left');
  $mode_fr -> Radiobutton ( -text=>'Greyscale', -value=>'gray',
    -variable=>\$opt{'colormode'}, -command=> [\&redraw_preview,$Preview,\%opt]) -> pack(-side=>'left');
  $mode_fr -> Radiobutton ( -text=>'Mono', -value=>'mono',
    -variable=>\$opt{'colormode'}, -command=> [\&redraw_preview,$Preview,\%opt]) -> pack(-side=>'left');

  my $cap_fr = $Options -> LabFrame ( -labelside=>'acrosstop',-relief=>'ridge',
    -label=>'Capture:') -> pack(-anchor=>'nw',-padx=>10);
  $cap_fr -> Radiobutton ( -text=>'All', -variable=>\$opt{'capture'}, 
    -value=>0, -command=> [\&redraw_preview,$Preview,\%opt] ) ->  pack(-anchor=>'nw',-side=>'left');
  $cap_fr -> Radiobutton ( -text=>'Window', -variable=>\$opt{'capture'}, 
    -value=>1, -command=> [\&redraw_preview,$Preview,\%opt] ) ->  pack(-anchor=>'nw',-side=>'left');

  my $File_fr = $Options -> Frame ( -relief=>'raised' ) -> pack(-anchor=>'nw',-pady=>10);
  my $File = $File_fr -> LabEntry ( -justify=>'left',-relief=>'sunken',-label=>'File',
    -labelPack=>[-anchor=>'n',-side=>'left'],-textvariable=>\$opt{'name'}
     ) -> pack(-side,'left');
  my $Open = $File_fr -> Button ( -text=>'Open...',
    -command=>sub{
      $mw->Busy;
      # open file save dialog box
      my @types = ( ["PostScript files",'.pl'], ["All files", '*'] );
      my $file = $opt{'name'};
      $file=~s#.*[/\\]([^/\\]+)$#$1#;
      if($^O=~/(^win)|(^$)/i)
      {
        $file = $mw->getSaveFile(-filetypes => \@types,
                          -initialfile => $file,
                          -defaultextension => '.ps',
                          -title=>'print to file');
      }
      else
      {
        $file = $mw->FileSelect(-directory => '.',
                          -initialfile => $file,
                          -title=>'print to file')->Show;
      }
      $mw->Unbusy;
      # if file selected
      $opt{'name'}=$file if($file);
    
    } ) -> pack(-side=>'left',-padx=>5);
  $db->resizable(0,0);
  return if($db->Show() eq 'Dismiss');
  my @capture=();
  my ($x0,$y0,$x1,$y1)=$c->bbox('all');
  @capture=('-x'=>$x0,'-y'=>$y0,-height=>$y1-$y0,-width=>$x1-$x0)
    unless $opt{'capture'};
  $c -> postscript(-colormode=>$opt{'colormode'},
    -file=>$opt{'name'},-rotate=>$opt{'rotate'},@capture);
}

sub file_setup
{
  my $new_bg=$cnv_bg;
  my $new_t=$cnv_t;
  my $new_p=$precision;
  my $new_fullcode = $cnv_fullcode;
  my $db=$mw->DialogBox(-title=>'Setup',-buttons=>['Accept','Cancel']);
  my $f1=$db->Frame()->pack(-side=>'top',-fill=>'x',-padx=>15,-pady=>15);
  $f1->Label(-text=>'Background ')->pack(-side=>'left',-padx=>5);
  my $menubutton = $f1->Menubutton(-relief=>'raised',-text=>'color',-background=>$new_bg)
    ->pack(-side=>'left');
  my $menu = $menubutton->menu(-tearoff=>0);
  $menubutton->configure(-menu => $menu);
  foreach (qw/white gray black red orange yellow green lightblue blue violet/)
  {
    $menubutton->command(-label => $_,-background=>$_,-foreground=>'cyan',
      -command=>[sub{$new_bg=shift;$menubutton->configure(-background=>$new_bg)},$_]);
  }
  my $f2=$db->Frame()->pack(-side=>'top',-fill=>'x',-padx=>15,-pady=>15);
  $f2->Label(-text=>'Title')->pack(-side=>'left',-padx=>5);
  $f2->Entry(-textvariable=>\$new_t)->pack(-side=>'left');
  my $f3=$db->Frame()->pack(-side=>'top',-fill=>'x',-padx=>15,-pady=>15);
  $f3->Label(-text=>'Output precision')->pack(-side=>'left',-padx=>5);
  &NumEntry($f3,-textvariable=>\$new_p,
          -width=>2,-minvalue=>0)->pack(-side=>'left');
  my $f4=$db->Frame()->pack(-side=>'top',-fill=>'x',-padx=>15,-pady=>15);
  $f4->Checkbutton(-text=>'Generate full executable program',
    -variable=>\$new_fullcode)->pack(-side=>'left',-padx=>5);


  $db->resizable(1,0);
  return if($db->Show() eq 'Cancel');
  # save current state for undo
  &undo_save();
  $c->configure(-background=>$new_bg);
  $precision=$new_p;
  $cnv_bg=$new_bg;
  $cnv_t=$new_t;
  $cnv_fullcode=$new_fullcode;
  &changes(1);
}

sub code_print
{
  my (@outext);
  my ($x0,$x1,$y0,$y1)=(1000,0,1000,0);
  my $id;
  if($cnv_fullcode)
  {
    foreach $id (@canv_obj)
    {
      my ($par)=$canv_obj{$id}->{par};
      my @p;
      foreach (@$par)
      {
        push (@p,$_) unless (/^-\D/);
      }
      my %p=(@p);
      my ($x,$y);
      while(($x,$y)=each(%p))
      {
        $x0 = $x if $x<$x0; $x1 = $x if $x>$x1;
        $y0 = $y if $y<$y0; $y1 = $y if $y>$y1;
      }
    }
    push(@outext,"#!$perl\n\nuse strict;\nuse Tk;\nuse Tk::Canvas;\nmy \$mw=MainWindow->new();\n");
    push(@outext,"\nmy \$c=\$mw->Canvas(-width=>$x1,-height=>$y1)->pack;\n\n");
  }
  foreach (split("\n",$cnv_t))
  {
    push(@outext,"# $_");
  }
  push(@outext,"\$c->configure(-background=>'$cnv_bg');");
  foreach $id (@canv_obj)
  {
    my ($par)=$canv_obj{$id}->{par};
    my @p;
    foreach (@$par)
    {
      if(/^-\D/ || /^[^\.\d]/)
      {
        $_ = "'$_'" unless /^[-']/;
        push(@p,$_);
      }
      else
      {
        push(@p,sprintf("%.${precision}f",$_));
      }
    }
    push( @outext, sprintf("my \$$id = \$c->create('%s',%s,-tags=>['$id','cnv_obj']);",
        $obj2canvas{$canv_obj{$id}->{name}}, join(',',@p) ) );
  }
  if($cnv_fullcode)
  {
    push( @outext, "\nMainLoop;\n");
  }
  return (@outext);
}

sub menus_codeview
{
  my $db=$mw->DialogBox(-title => "Code preview",-buttons=>['Dismiss']);
  my $t = $db->Scrolled(qw/ROText -setgrid true -wrap none
  -scrollbars osoe -background white/);
  $t->pack(qw/-expand yes -fill both/);
  $t->tag(qw/configure variable -foreground darkgreen/);
  $t->tag(qw/configure keyword -foreground brown -font C_bold/);
  $t->tag(qw/configure constant -foreground violet/);
  $t->tag(qw/configure comment -foreground blue/);
  foreach my $line(&code_print)
  {
    last unless length $line;
    if($line=~/^\s*my\s+/)
    {
      $t->insert('end','my ','keyword');
      $line=~s/^\s*my\s+//;
    }
    while(length($line))
    {
      if($line=~/^\s*\$\w+/)
      {
        my ($var)=($line=~/^(\s*\$\w+)/);
        $t->insert('end',$var,'variable');
        $line=~s/^\s*\$\w+//;
      }
      elsif($line=~/^\s*#/)
      {
        my ($comment) = ($line=~/^\s*#(.*)/);
        $t->insert('end',"#$comment",'comment');
        $line="";
      }
      elsif($line=~/^\s*(-\w+|'[^']*')/)
      {
        my ($const)=($line=~/^(\s*(?:-\w+|'[^']*'))/);
        $t->insert('end',$const,'constant');
        $line=~s/^\s*(-\w+|'[^']*')//;
      }
      else
      {
        my ($txt)=($line=~/^(\s*(?:->)?[^-\$']+)/);
	    $txt=~s/->\s*/->\n  /;
        $t->insert('end',$txt);
        $line=~s/^\s*(->)?[^-\$']+//;
      }
    }
    $t->insert('end', "\n");
  }
  $t->mark(qw/set insert 0.0/);
  $db->resizable(1,0);
  $db->Show();
}

sub menus_repaint
{
  # erase selection
  &selection_remove($selected_id) if $selected_id;
  &menus_scale('1:1');
  $c->configure(-cursor=>'crosshair');
  # erase all canvas
  $c->delete('cnv_obj');
  # clean canvas list:
  $tf->delete('0','end');
  # re-paint them using internal objects
  foreach my $id (@canv_obj)
  {
    my ($par)=$canv_obj{$id}->{par};
    map(s/'//g,@$par);
    $c->create($obj2canvas{$canv_obj{$id}->{name}},@$par,-tags=>[$id,'cnv_obj']);
    $tf->insert(0,-data=>$id,-image=>$pic{lc("canv_$canv_obj{$id}->{name}")},-text=>$id);
  }
  &selection_create($selected_id) if $selected_id;
}

sub menus_order
{
  my ($op)=shift;

  return unless $selected_id;
  return unless grep(/$selected_id/,@canv_obj);
  my $i;
  my $j=0;
  if($op =~ /1/)
  {
    foreach (@canv_obj) {last if $_ eq $selected_id; $j++}
    # now $j is the index of element to be moved
    $i=($j+1) if $op eq '1+';
    $i=($j-1) if $op eq '1-';
    $i=$#canv_obj if $i>$#canv_obj;
    $i=0 if $i<0;
    return if $i == $j;
  }
  # save current state for undo
  &undo_save();
  if($op =~ /1/)
  {
    @canv_obj[$i,$j] = @canv_obj[$j,$i];
  }
  else
  {
    @canv_obj=grep(!/^$selected_id$/,@canv_obj);
    if($op eq '-'){unshift(@canv_obj,$selected_id)}
    else {push(@canv_obj,$selected_id)}
  }
  # Set modification flag on
  &changes(1);
  # repaint here:
  &menus_repaint();
}

sub edit_duplicate
{
  return unless $selected_id=~/^cnv_/;
  my $scale_save=$scale_h;
  &selection_remove;
  &menus_scale('1:1');
  $c->configure(-cursor=>'crosshair');
  # save current state for undo
  &undo_save();

  foreach my $id(split(' ',$selected_id))
  {
     my ($par)=$canv_obj{$id}->{par};
     map(s/'//g,@$par);
     &obj_create(1,$canv_obj{$id}->{name},@$par);
  }
  # Set modification flag on
  &changes(1);
  &menus_scale($scale_save);
  $selected_id=$canv_obj[$#canv_obj] unless $selected_id=~/ /;
  &selection_create($selected_id);
}

sub mouse_drag
{
  my ($x,$y) = (@_);
  my ($tag,$subtag)=$c->itemcget('current','-tags');
  if($mouse_drag eq 'move' || $mouse_drag=~/^sel_ref_/)
  {
    my ($sel_ref)=($mouse_drag=~/^sel_ref_(.*)/);
    &selection_remove($selected_id);
    if($mouse_drag eq 'move')
    {
      foreach my $id(split(' ',$selected_id))
      {
        $c->move($id,$x-$sx,$y-$sy);
      }
    }
    else
    {
      # move point only ?
    }
    # move internal structure too
    if($selected_id=~/ / && $mouse_drag eq 'move')
    {
      foreach my $id(split(' ',$selected_id))
      {
        my $obj=$canv_obj{$id};
	my $par=$obj->{par};
	my $toggle=0;
        foreach (@$par)
        {
          last if /^-\D/;
          if($toggle) { $_+=($y-$sy)/$scale; }
          else        { $_+=($x-$sx)/$scale; }
          $toggle=1-$toggle;
        }
        $canv_obj{$id}=$obj;
      }
    }
    else
    {
      my $obj=$canv_obj{$selected_id};
      my $par=$obj->{par};
      if($mouse_drag eq 'move')
      {
        my $toggle=0;
        foreach (@$par)
        {
          last if /^-\D/;
          if($toggle) { $_+=($y-$sy)/$scale; }
          else        { $_+=($x-$sx)/$scale; }
          $toggle=1-$toggle;
        }
      }
      else
      {
        # move point + internal object
        if($sel_ref=~/\d/)
        {
          if($obj->{name} =~ /Circle|Square/)
          {
            $$par[$sel_ref]+=($y-$sy)/$scale;
          }
          else
          {
            $$par[$sel_ref]+=($x-$sx)/$scale;
          }
          $$par[$sel_ref+1]+=($y-$sy)/$scale;
          &apply_properties($selected_id,$obj,0,@$par);
        }
        else
        {
          # change degree (start/extent)
          my %h=Drawing::hash(@$par);
          my $val=$h{"-$sel_ref"};
          $val+=($y-$sy+$x-$sx)/$scale;
          $val %= 360;
          &apply_properties($selected_id,$obj,1,Drawing::array(@$par),"-$sel_ref",$val);
        }
      }
      $canv_obj{$selected_id}=$obj;
    }
    # Set modification flag on
    &changes(1);
    &selection_create($selected_id);
    ($sx,$sy)=($x,$y);
  }
}

sub menus_scale
{
  my ($factor)=shift;
  
  return if $scale_h eq $factor;
  my ($n1,$n2)=split(':',$factor);
  my ($o1,$o2)=split(':',$scale_h);
  $scale_h=$factor;
  $sc_b->configure(-text=>"Scale $scale_h");
  $factor=$n1/$n2;
  $scale=$o1/$o2;
  
  my ($x0,$y0,$x1,$y1)=$c->bbox('all');
  &selection_remove($selected_id) if($selected_id);
  $c->scale("all", ($x0+$x1)/2, ($y0+$y1)/2, $factor/$scale, $factor/$scale);
  &selection_create($selected_id) if($selected_id);
  $scale=$factor;
}

sub file_new
{
  return unless &check_changes;
  &canv_new;
  &changes(0);
}

sub canv_new
{
  %canv_obj=();
  @canv_obj=();
  $cnv_t='';
  $cnv_fullcode = 0;
  $cnv_bg = $bg_color;
  $c->configure(-background=>$cnv_bg);
  $c->delete('cnv_obj');
  &selection_remove($selected_id); $selected_id='';
  &menus_scale('1:1');
}

sub index_of
{
  my $tag=shift || return undef;

  my $index=0;
  while($canv_obj[$index] ne $tag)
  {
    $index++;
    return undef if $index > $#canv_obj;
  }
  return $#canv_obj-$index;
}

sub tlist_select
{
  my @tags;
  foreach my $i(split(' ',$tf->info('selection')))
  {
    next unless length $i;
    push(@tags,$canv_obj[$#canv_obj-$i]);
  }
  &selection_remove($selected_id);
  $selected_id=join(' ',@tags);
  &selection_create($selected_id) if $selected_id;
}

sub selection_create
{
  my ($tag)=shift;
  # repaint canvas selection list
  $tf->selectionClear('0','end');
  if ($tag =~ / /)
  {
    $status->configure(-text=>"Selected: $tag");
    # draw multiple selection
    foreach my $t(split(' ',$tag))
    {
      my ($x0,$y0,$x1,$y1)=$c->bbox($t);
      foreach my $x($x0,$x1)
      {
        foreach my $y($y0,$y1)
        {
          $c->create('rectangle',$x-3,$y-3,$x+3,$y+3, -fill=>'black',-tags=>['selection','move']);
        }
      }
      $tf->selectionSet(&index_of($t));
    }
    return;
  }
  my ($x0,$y0,$x1,$y1)=$c->bbox($tag);
  my ($x,$y);
  my (@actions)=(qw/move configure erase resize/);

  return if $selection;
  $selection=1;

  # calculate layer:
  $x=0;
  foreach (@canv_obj) {last if $_ eq $tag;$x++}
  $x=$#canv_obj-$x;
  $status->configure(-text=>"Selected: $tag (layer $x)");
  
  if ($selection_type == 1)
  {
    foreach $x($x0,$x1)
    {
      foreach $y($y0,$y1)
      {
        $c->create('rectangle',$x-3,$y-3,$x+3,$y+3,
           -fill=>'black',-tags=>['selection',shift(@actions)]);
      }
    }
    $c->create('line',$x0-6,$y0-6,$x0+6,$y0+6,-arrow=>'both',-tags=>['selection','move']);
    $c->create('line',$x0-6,$y0+6,$x0+6,$y0-6,-arrow=>'both',-tags=>['selection','move']);
    $c->create('line',$x1,$y1,$x1+8,$y1,-arrow=>'last',-tags=>['selection','resize']);
    $c->create('line',$x1,$y1,$x1,$y1+8,-arrow=>'last',-tags=>['selection','resize']);
    $c->create('line',$x1-5,$y0-5,$x1+5,$y0+5,-width=>1.8,-tags=>['selection','erase']);
    $c->create('line',$x1-5,$y0+5,$x1+5,$y0-5,-width=>1.8,-tags=>['selection','erase']);
    $c->create('rectangle',$x0-7,$y1-1,$x0-1,$y1+7,-fill=>'white',-tags=>['selection','configure']);
  }
  else
  {
    my (@p)=$c->coords($tag);
    my $obj_type=$canv_obj{$tag}->{name};
    if($obj_type =~ /Oval|Circle|Rectangle|Square|Pie|Chord/)
    {
      # 2 resizing points
      # normalize points order ?
      foreach my $i(0, 2)
      {
        my $x=$p[$i];
        my $y=$p[$i+1];
        $c->create('rectangle',$x-3,$y-3,$x+3,$y+3,
           -fill=>'black',-tags=>['selection','sel_type_resize',"sel_ref_$i"]);
      }
      if($obj_type =~ /Pie|Chord/)
      {
	my $ptr=$canv_obj{$tag}->{par};
	my %ptr=(@$ptr);
        my ($extent)=$ptr{-extent};
        my ($start)=$ptr{-start} || 0;
	$extent=90 if $extent eq '';
        # degree-resizing points:
	# 1. calculate max radius (R)
	# R=max(x2-x1,y2-y1)/2
	my $R=$p[2]-$p[0];
	$R=$p[3]-$p[1] if ($p[3]-$p[1]) > $R;
	$R/=2;
	# 2. calculate center point (xc,yc)
	# xc=(x1+x2)/2; yc=(y1+y2)/2;
	my $xc=($p[2]+$p[0])/2;
	my $yc=($p[3]+$p[1])/2;
	# 3. for each degree calculate projection to circle (xc,yc,R)
	# x=xc+cos(alfa)*R
	my (%p)=(start=>$start*3.1415926/180,extent=>($start+$extent)*3.1415926/180);
	foreach (keys %p)
	{
	  my $x=$xc+cos($p{$_})*$R;
	  my $y=$yc-sin($p{$_})*$R;
	  $c->create('line',$xc,$yc,$x,$y,-tags=>['selection','sel_type_resize',"sel_ref_$_"]);
          $c->create('oval',$x-5,$y-5,$x+5,$y+5,-outline=>'black',
           -fill=>'white',-tags=>['selection','sel_type_resize',"sel_ref_$_"]);
	}
      }
    }
    elsif ($obj_type =~ /Line|PolyLine|Curve|Polygon|Splash/)
    {
      for (my $i=0;$i<$#p;$i+=2)
      {
        my $x=$p[$i];
        my $y=$p[$i+1];
        $c->create('rectangle',$x-3,$y-3,$x+3,$y+3,
           -fill=>'black',-tags=>['selection','sel_type_resize',"sel_ref_$i"]);
	next if $obj_type =~ /^Line/;
	if($i+2<=$#p || $obj_type =~ /Polygon|Splash/ )
	{
	  # scissor-point on each segment
	  my ($x2,$y2)=($p[$i+2],$p[$i+3]);
	  ($x2,$y2)=($p[0],$p[1]) if($i+2>$#p && $obj_type =~ /Polygon|Splash/);
	  $x=($p[$i]+$x2)/2;
	  $y=($p[$i+1]+$y2)/2;
          $c->create('oval',$x-7,$y-3,$x+7,$y+7,-fill=>'white',-outline=>'white',-tags=>['selection','sel_type_cut',"sel_ref_$i"]);
	  $c->create('line',$x-4,$y-4,$x+4,$y+4,-tags=>['selection','sel_type_cut',"sel_ref_$i"]);
	  $c->create('line',$x-4,$y+4,$x+4,$y-4,-tags=>['selection','sel_type_cut',"sel_ref_$i"]);
	  $c->create('oval',$x-7,$y+3,$x-3,$y+7,-tags=>['selection','sel_type_cut',"sel_ref_$i"]);
	  $c->create('oval',$x+3,$y+3,$x+7,$y+7,-tags=>['selection','sel_type_cut',"sel_ref_$i"]);
	}
      }
    }
  }
  # repaint canvas list:
  $tf->delete('0','end');
  map($tf->insert(0,-data=>$_,-image=>$pic{lc("canv_$canv_obj{$_}->{name}")},-text=>$_),@canv_obj);
  $tf->selectionSet(&index_of($tag)) if $tag;
}

sub selection_remove
{
  my ($tag)=shift;
  $c->delete('selection');
  $tf->selectionClear('0','end');
  $selection=0;
  $status->configure(-text=>'No selection');
}

# Interface for point-level editing:
#  Figure:      Resizing points   Conversion point    Scissors
#  * square           1                  1
#  * circle           1                  1               1
#  * line             1                                  1
#  * oval             2                  1               1
#  * rectangle        2                  1
#  * polyline         n                  1(end)          n-1
#  * curve            n                  1(end)          n-1
#  * polygon          n                  n               n
#  * freeform         n                  n               n
#  * sector           4                  1
#  * pie ?

sub menus_point_edit
{
  # get object id or return;
  my ($obj_id)=shift || $selected_id;
  return unless $obj_id;
  # create selection 'type 2'
  &selection_remove($selected_id);
  $selection_type=2;
  $c->configure(-cursor=>'crosshair');
  &selection_create($obj_id);
  # tags:
  # selection, sel_type_<resize/convert/cut>, sel_ref_<index>
}

sub mouse_click
{
  my ($tag)=$c->itemcget('current','-tags');
  if($tag=~/^cnv_/)
  {
    if($selected_id ne $tag)
    {
      # remove selection
      &selection_remove($selected_id);
      # select new object
      $selected_id=$tag;
      $selection_type=1;
      &selection_create($tag);
    }
    else # switch selection type
    {
      &selection_remove($selected_id);
      $selection_type=(2-$selection_type)+1; # toggle 2<->1
      &selection_create($selected_id);
    }
  }
  else
  {
    my (@tags)=$c->gettags('current');
    $mouse_drag='';
    if (grep(/selection/,@tags))
    {
      ($sx,$sy) = ($Tk::event->x,$Tk::event->y);
      if(grep(/erase/,@tags))
      {
        &edit_delete( $selected_id );
      }
      elsif(grep(/move/,@tags))
      {
        # save current state for undo
        &undo_save();
	$mouse_drag='move';
      }
      elsif(grep(/^resize/,@tags))
      {
        &menus_point_edit();
      }
      elsif(grep(/configure/,@tags))
      {
	&edit_properties($selected_id);
      }
      elsif(grep(/sel_type_resize/,@tags))
      {
        # save current state for undo
        &undo_save();
        ($mouse_drag)=grep(/sel_ref_/,@tags);
      }
      elsif(grep(/sel_type_cut/,@tags))
      {
        # immidiate cut:
        my ($sel_ref)=grep(/sel_ref/,@tags);
	$sel_ref=~s/.*_//;
	my $obj=$canv_obj{$selected_id};
	my $par=$obj->{par};
	my (@p)=@$par;
	map (s/'//g,@p);
	my ($x2,$y2)=($p[0],$p[1]);
	($x2,$y2)=($p[$sel_ref+2],$p[$sel_ref+3]) if $sel_ref+3<=$#p;
	my $x=($p[$sel_ref]  +$x2)/2;
	my $y=($p[$sel_ref+1]+$y2)/2;
	splice(@p,$sel_ref+2,0,$x,$y);
        # save current state for undo
        &undo_save();
        &apply_properties($selected_id,$obj,0,@p);
      }
      return;
    }
    &selection_remove($selected_id) if($selected_id);
    $selected_id='';
  }
}

sub mark_start
{
  my($x,$y) = @_;

  $iinfo{areaX1} = $iinfo{areaX2} = $c->canvasx($x);
  $iinfo{areaY1} = $iinfo{areaY2} = $c->canvasy($y);
  &selection_remove($selected_id) if($selected_id);
  $selected_id='';
  $c->delete('sel_area');
  $c->delete('selection');
  $c->configure(-cursor=>'top_left_arrow');
}

sub mark_stroke
{
  my($x,$y) = @_;

  $x = $c->canvasx($x);
  $y = $c->canvasy($y);
  if (($iinfo{areaX1} != $x) and ($iinfo{areaY1} != $y)) 
  {
    $c->delete('sel_area');
    $c->addtag('sel_area', 'withtag', $c->create('rectangle',
        $iinfo{areaX1}, $iinfo{areaY1}, $x, $y, -outline => 'black'));
    $iinfo{areaX2} = $x;
    $iinfo{areaY2} = $y;
    $c->configure(-cursor=>'top_left_arrow');
  }
}

sub mark_end
{
  $c->delete('sel_area');
  my @objects = ();
  $c->dtag('all','mark_selection');
  $c->addtag('mark_selection','enclosed', $iinfo{areaX1},
            $iinfo{areaY1}, $iinfo{areaX2}, $iinfo{areaY2});
  foreach my $item ($c->find('withtag', 'mark_selection'))
  {
    my ($tag) = grep(/^cnv_[^o][^b][^j]/,$c->gettags($item));
    if ($tag) 
    {
      push @objects, grep(!/^cnv_obj/,$tag);
    }
  }
  $selected_id=join(' ',@objects) if @objects;
  $selection_type=1;
  &selection_create($selected_id) if $selected_id;
}

sub canv_create
{
  my($figure,$obj_id,@canv_par)=(@_);
  return unless $obj2canvas{$figure};
  # add to canvas $c
  $c->create($obj2canvas{$figure},@canv_par,-tags=>[$obj_id,'cnv_obj']);
  # - store in internal structures
  map(s/'//g,@canv_par);
  my $new_obj=Drawing->new($figure,$obj_id,@canv_par);
  $canv_obj{$obj_id}=$new_obj;
  push(@canv_obj,$obj_id);
}

sub rand_int
{
  my ($from,$to)=(@_);
  return int(rand($to-$from)+$from)*$scale;
}

sub menus_create
{
  my $scale_save=$scale_h;
  &menus_scale('1:1');
  $c->configure(-cursor=>'crosshair');
  # save current state for undo
  &undo_save();
  &obj_create(0,@_);
  &menus_scale($scale_save);
  # Set modification flag on
  &changes(1);
  # repaint canvas list:
  $tf->delete('0','end');
  map($tf->insert(0,-data=>$_,-image=>$pic{lc("canv_$canv_obj{$_}->{name}")},-text=>$_),@canv_obj);
}

sub obj_create
{
  my $duplicate=shift;
  my $figure=shift;

  # 1. Create new object with initial values:
  # - open dialog box for object naming/config
  $obj_count++;
  my $obj_id="cnv_${figure}_$obj_count";
  my (@canv_par);
  if(@_)
  {
    (@canv_par)=(@_);
    foreach (@canv_par)
    {
      last if /^-\D/;
      $_+=4 if $duplicate;
    }
  }
  else
  {
    (@canv_par)=
      (rand_int(10,40),rand_int(10,40),rand_int(50,110),rand_int(50,110));
    $canv_par[2]=$canv_par[0]+($canv_par[3]-$canv_par[1])
       if $figure =~ /Circle|Square/;
    push(@canv_par,rand_int(10,40),rand_int(50,110)) if $figure =~ /Curve|Poly|Splash/;
    push(@canv_par,-smooth=>1) if $figure =~ /Curve|Splash/;
    push(@canv_par,-style=>'chord') if $figure =~ /Chord/;
    # or dialog box here?
    # - if Ok:
    return unless scalar(@canv_par);
  }
  &canv_create($figure,$obj_id,@canv_par);
}

sub middle_point
{
  my ($c,$id)=(@_);
  my ($x0,$y0,$x1,$y1)=$c->bbox($id);

  return (($x1+$x0)/2,($y1+$y0)/2);
}

sub menus_resize
{
  my $obj_id=shift || $selected_id;
  my ($obj)=$canv_obj{$obj_id};
  return unless $obj;
  if($scale_h ne '1:1'){ &menus_error("resize with scale $scale_h"); return; }
  # Open re-size dialog box
  my ($xs,$ys)=(100,100);
  my $db=$mw->DialogBox(-title=>"Object $obj_id resizing",
    -buttons=>['Accept','Cancel']);#,'Preview']);
  my $xf=$db->Frame()->pack(-side=>'top',-fill=>'x');
  $xf->Label(-text=>'X scale (%)')->pack(-side=>'left');
  &NumEntry($xf,-textvariable=>\$xs,-width=>4)->pack(-side=>'left');
  my $yf=$db->Frame()->pack(-side=>'top',-fill=>'x');
  $yf->Label(-text=>'Y scale (%)')->pack(-side=>'left');
  &NumEntry($yf,-textvariable=>($obj->{name}=~/Circle|Square/)?\$xs : \$ys,-width=>4)->pack(-side=>'left');
  my $reply=$db->Show();
  # if user says 'Ok':
  return if $reply eq 'Cancel';
  $ys=$xs if $obj->{name}=~/Circle|Square/;
  $xs/=100; $ys/=100; $xs=1 if $xs<=0; $ys=1 if $ys<=0;
  # find object middle-point
  my $par=$obj->{par};
  my @p=Drawing::array(@$par);
  my ($mpx,$mpy)=&middle_point($c,$obj_id);
  # re-calculate all points
  for (my $i=0;$i<$#p;$i+=2)
  {
    $p[$i]  =$mpx+($p[$i]  -$mpx)*$xs;
    $p[$i+1]=$mpy+($p[$i+1]-$mpy)*$ys;
  }
  # save current state for undo
  &undo_save();
  # configure and re-paint object
  &apply_properties($obj_id,$obj,0,@p);
}

sub menus_x_mirror 
{
  my $obj_id=shift || $selected_id;
  my ($obj)=$canv_obj{$obj_id};
  return unless $obj;
  return if $obj->{name} =~ /Oval|Circle|Square|Rectangle|Pie|Chord/;
  if($scale_h ne '1:1'){ &menus_error("x_mirror with scale $scale_h"); return; }
  # find object middle-point
  my $par=$obj->{par};
  my @p=Drawing::array(@$par);
  my ($mpx,$mpy)=&middle_point($c,$obj_id);
  # re-calculate all points
  for (my $i=0;$i<$#p;$i+=2)
  {
    $p[$i]  =$mpx-($p[$i]  -$mpx);
  }
  # save current state for undo
  &undo_save();
  # configure and re-paint object
  &apply_properties($obj_id,$obj,0,@p);
}

sub menus_y_mirror
{
  my $obj_id=shift || $selected_id;
  my ($obj)=$canv_obj{$obj_id};
  return unless $obj;
  return if $obj->{name} =~ /Oval|Circle|Square|Rectangle|Pie|Chord/;
  if($scale_h ne '1:1'){ &menus_error("y_mirror with scale $scale_h"); return; }
  # find object middle-point
  my $par=$obj->{par};
  my @p=Drawing::array(@$par);
  my ($mpx,$mpy)=&middle_point($c,$obj_id);
  # re-calculate all points
  for (my $i=0;$i<$#p;$i+=2)
  {
    $p[$i+1] =$mpy-($p[$i+1]-$mpy);
  }
  # save current state for undo
  &undo_save();
  # configure and re-paint object
  &apply_properties($obj_id,$obj,0,@p);
}

sub free_rotate
{
  my $obj_id=shift || $selected_id;
  my ($obj)=$canv_obj{$obj_id};
  return unless $obj;
  # can't rotate: circle/oval/rectangle/square/pie/chord
  return if $obj->{name} =~ /Oval|Circle|Square|Rectangle|Pie|Chord/;
  if($scale_h ne '1:1'){ &menus_error("free_rotate with scale $scale_h"); return; }
  
#  my $par=$obj->{par};
  my @p=Drawing::array(@{$obj->{par}});

  # Show dialog and get angle:
  my $db=$mw->DialogBox(-title=>"Free rotate $obj_id",
    -buttons=>['Accept','Cancel']);#,'Preview']);
  my $alfa=0;
  #$db->LabEntry ( -labelPack=>[-side=>'left'=>-anchor=>'n'],
  #  -label=>'Angle:',-textvariable=>\$alfa,-width=>4 )->pack();
  $db->Label(-text=>'Angle:')->pack(-side=>'left',-padx=>5,-pady=>15);
  &NumEntry($db,-textvariable=>\$alfa,
      -width=>4)->pack(-side=>'left',-padx=>5,-pady=>15);
  my $reply=$db->Show();
  return if $reply eq 'Cancel';
  # save current state for undo
  &undo_save();
  # find object middle-point
  my ($Cx,$Cy)=&middle_point($c,$obj_id);
  my $cosA=cos($alfa*3.1415926/180);
  my $sinA=sin($alfa*3.1415926/180);
  for(my $i=0;$i<$#p;$i+=2)
  {
    my $Xr=$p[$i]  -$Cx;
    my $Yr=$p[$i+1]-$Cy;
    $p[$i]   = $Xr*$cosA-$Yr*$sinA+$Cx;
    $p[$i+1] = $Yr*$cosA+$Xr*$sinA+$Cy;
  }
  # configure and re-paint object
  &apply_properties($obj_id,$obj,0,@p);
}

sub edit_properties
{
  my ($obj_id)=shift;
  $obj_id=$selected_id unless $obj_id=~/^cnv_/;
  # find object in internal array by ID
  my ($obj)=$canv_obj{$obj_id};
  return unless $obj;
  
  # get properties via dialog box
  my $par=$obj->{par};
  map (s/'//g,@$par);
  my ($result,@par)=&get_properties($obj_id,$obj->{type},@$par);
  return unless $result;
  # save current state for undo
  &undo_save();
  &apply_properties($obj_id,$obj,1,@par);
}

sub apply_properties
{
  my ($obj_id,$obj,$appl_type,@par)=(@_);
  my $scale_save=$scale_h;
  &menus_scale('1:1');
  &selection_remove($selected_id);
  # re-configure object and canvas picture
  # for simmetric objects - re-order points
  my $obj_type=$canv_obj{$obj_id}->{name};
  if($obj_type=~/Oval|Circle|Square|Rectangle|Pie|Chord/)
  {
    my ($x0,$y0,$x1,$y1)=@par;
    ($x0,$x1)=($x1,$x0) if($x0>$x1);
    ($y0,$y1)=($y1,$y0) if($y0>$y1);
    $par[0,1,2,3]=($x0,$y0,$x1,$y1);
  }
  $obj->config($appl_type,@par);
  $canv_obj{$obj_id}=$obj;
  # Set modification flag on
  &changes(1);
  &menus_repaint();
  &menus_scale($scale_save);
  &selection_create($selected_id);
}

sub get_properties
{
  my($obj_id,$obj_type,@obj_par)=(@_);
  return 0 unless $obj_id;
  my (@new_par)=@obj_par;
  # 1. create dialog box according to obj. type
  my $db=$mw->DialogBox(-title=>"Object $obj_id properties",
    -buttons=>['Accept','Cancel']);#,'Preview']);
  my (@pack)=qw/-side top -padx 10 -pady 5 -fill x/;
  # ======================= configurable dialog here ============
  $obj_type=$canv_obj{$obj_id}->{name} unless $obj_type;
  my $p=$attr{$obj_type};
  map (s/'//g,@$p);
  my (%pr)=(@$p);
  my (%val)=Drawing::hash(@obj_par);
  # check for array legal length
  $val{'points'}=join(', ',Drawing::array(@obj_par));
  foreach my $k(sort keys %pr)
  {
    my $f=$db->Frame()->pack(@pack);
    $f->Label(-text=>$k)->pack(-side=>'left');
    if($k eq 'points')
    {
      $f->Entry(-textvariable=>\$val{'points'})->pack(-side=>'right');
    }
    elsif($pr{$k} eq 'color')
    {
      my $cl=$f->Menubutton(qw/-text Color -relief raised/)->pack(-side=>'right');
      my $m = $cl->Menu(-tearoff => 0);
      my $var=($val{$k})?1:0;
      my $i=1;
      foreach (qw/Brown Red pink wheat2 orange
        Yellow DarkKhaki LightSeaGreen Green DarkSeaGreen
        green4 DarkGreen Cyan LightSkyBlue Blue
        NavyBlue plum magenta1 Magenta3 purple3
        White gray90 gray75 gray50 Black/)
 	{ 
 	  $m->command(-label => $_, -columnbreak=>(($i-1) % 5)?0:1,
	    -command=>
	    [sub{$val{$k}=shift;$var=1;$cl->configure(-background=>$val{$k})},$_]);
 	  my $i1 = $m->Photo(qw/-height 16 -width 16/);
          $i1->put('gray50', qw/-to 0 0 16 1/);
          $i1->put('gray50', qw/-to 0 1 1 16/);
          $i1->put('gray75', qw/-to 0 15 16 16/);
          $i1->put('gray75', qw/-to 15 1 16 15/);
          $i1->put($_, qw/-to 1 1 15 15/);
 	  $m->entryconfigure($i, -image => $i1);
 	  $i++;
 	}
      $cl->configure(-menu => $m);
      $cl->configure(-background=>$val{$k}) if $val{$k};
      my $cb=$f->Checkbutton(-text => 'enabled',-relief => 'flat',
        -variable=>\$var,
        -command => sub{ $val{$k}='' unless $var; }
	)->pack(-side=>'right');
    }
    elsif($pr{$k} eq 'arrowside')
    {
      my (@as)=qw/none first last both/;
      my (%as)=(none=>'----',first=>'<---',last=>'--->',both=>'<-->');
      $val{$k}='none' unless $val{$k};

      my $am=$f->Menubutton(-text=>$as{$val{$k}},-relief=>'raised')->pack(-side=>'right');
      my $rc=$am->Menu(-tearoff => 0);
      foreach (@as)
      {
	$rc->radiobutton(-label=>$as{$_},-variable=>\$val{$k},-value=>$_,
	  -command=>sub{$am->configure(-text=>$as{$val{$k}})});
      }
      $am->configure( -menu => $rc);
    }
    elsif($pr{$k} eq 'linewidth')
    {
      &NumEntry($f,-textvariable=>\$val{$k},
          -width=>4,-minvalue=>0)->pack(-side=>'right');
    }
    elsif($pr{$k} =~ /^menu\(/)
    {
      my $menu=$pr{$k};
      $menu=~s/.*\(//;$menu=~s/\)//;
      if(split('\|',$menu)>2)
      {
        $f->Optionmenu(-options=>[split('\|',$menu)],-textvariable=>\$val{$k})
          ->pack(-side=>'right');
      }
      else
      {
        my ($on,$off)=split('\|',$menu);
        $val{$k}=$on unless $val{$k};
        $f->Button(-textvariable=>\$val{$k},-relief=>'flat',
          -command=>sub{$val{$k}=($val{$k} eq $on)?$off:$on;})->pack(-side=>'right');
      }
    }
  }

  # 2. run it and get reply status
  my $reply = # dialog box ...
    $db->Show();
  @new_par=split(/,\s*/,$val{'points'});
  # correct according to scale
  delete $val{'points'};
  push(@new_par,%val);
  # 3. if accept - return parameters
  return (0,@obj_par) if $reply eq 'Cancel';
  return (1,@new_par);
}

sub undo_save
{
  @redo=(); push(@undo,join("\n",&code_print()));
}

sub redo
{
  return unless @redo;
  my $scale_save=$scale_h;
  &menus_scale('1:1');
  $c->configure(-cursor=>'crosshair');
  push(@undo,join("\n",&code_print())); # undo <= current
  &canv_new;
  &code_read(split("\n",pop(@redo)));
  &menus_scale($scale_save);
  # repaint canvas list:
  $tf->delete('0','end');
  map($tf->insert(0,-data=>$_,-image=>$pic{lc("canv_$canv_obj{$_}->{name}")},-text=>$_),@canv_obj);
}

sub undo
{
  return unless @undo;
  my $scale_save=$scale_h;
  &menus_scale('1:1');
  $c->configure(-cursor=>'crosshair');
  # clear current design and restore from backup:
  push(@redo,join("\n",&code_print())); # redo <= current
  &canv_new;
  &code_read(split("\n",pop(@undo)));
  &menus_scale($scale_save);
  # repaint canvas list:
  $tf->delete('0','end');
  map($tf->insert(0,-data=>$_,-image=>$pic{lc("canv_$canv_obj{$_}->{name}")},-text=>$_),@canv_obj);
}

sub edit_delete
{
  my $obj_id=shift;
  $obj_id=$selected_id unless $obj_id=~/^cnv_/; # say warning?
  return unless $obj_id=~/^cnv_/;
  $c->configure(-cursor=>'crosshair');
  # save current state for undo
  &undo_save();
  foreach my $id(split(' ',$obj_id))
  {
    # 1. delete from data structures
    delete $canv_obj{$id};
    # 2. erase from canvas
    $c->delete($id);
    @canv_obj = grep (!/^$id$/,@canv_obj);
  }
  &selection_remove($selected_id); $selected_id='';
  &changes(1);
  # repaint canvas list:
  $tf->delete('0','end');
  map($tf->insert(0,-data=>$_,-image=>$pic{lc("canv_$canv_obj{$_}->{name}")},-text=>$_),@canv_obj);
}

sub menus_error
{
  $mw->Dialog(-bitmap=>'error',-text=> "@{_}? Still not implemented!\n")->Show();
}

# limited HTML format read
# 1. Text is pre-formatted
# 2. Each line associated with bold_text/regular_text/picture
sub read_html
{
  my $file_name=shift;
  my @result=();

  open (HTML,$file_name) || return 0;
  my @file=<HTML>;
  close HTML;
  my $body=0;
  my ($line,$type);
  foreach (@file)
  {
    $body=1 if/<body/i;
    $body=0 if/<\/body>/i;
    s/.*<body[^>]+>//i;
    s/<\/body>.*//i;
    if ($body)
    {
      next if /<.?pre>/;
      $type='text';
      if(/<b>.*<\/b>/i)
      {
        $line=$_;
	$line=~s/<.?b>//ig;
        $type ='bold';
      }
      elsif(/<img src=/i)
      {
        ($line) = (/<img src=["']([^'"]+)\.gif['"]/i);	
        $type ='gif';
      }
      else
      {
        $line=$_;
	$line=~s/<[^>]+>//g;
      }
      push(@result,"$type $line");
    }
  }
  return (@result);
}

sub help
{
  my $hd=$mw->DialogBox(-title=>'Help');
  my $t=$hd->Scrolled(qw/Text -scrollbars e -wrap word/)->pack(-fill=>'both');
  $t->tag(qw/configure bold -font C_bold/);
  $t->insert('0.0',"");
  foreach (@html_help)
  {
    my ($type,$line)=(/(\S+)\s(.*)/);
    if($type eq 'bold')
    {
      $t->insert('end',"$line\n",'bold');
    }
    elsif($type eq 'gif')
    {
      $t->imageCreate('end',-image=>$pic{$line});
      $t->insert('end',"\n");
    }
    else
    {
      $t->insert('end',"$line\n");
    }
  }
  $t->configure(-state=>'disabled');
  $hd->resizable(1,0);
  $hd->Show;
}

sub check_changes
{
  if($changes)
  {
    # ask for save
    
    my $reply=$mw->Dialog(-bitmap=>'question',
     -text=>"File not saved!\nDo you want to save the changes?",
        -title => "You have some changes", 
        -buttons => ['Save','Don\'t save', 'Cancel'])->Show;
    if($reply eq 'Save')
    {
      $reply=&file_save('Save As');
    }
    return 0 if($reply eq 'Cancel');
  }
  return 1; # Ok
}

sub file_open
{
  &file_new();
  $c->configure(-cursor=>'crosshair');

  $mw->Busy;
  # open file save dialog box
  my @types = ( ["Perl files",'.pl'], ["All files", '*'] );
  my $file = $lastfile;
  $file=~s#.*[/\\]([^/\\]+)$#$1#;
  if($ENV{OS}=~/(^win)|(^$)/i)
  {
    $file = $mw->getOpenFile(-filetypes => \@types,
                          -initialfile => $file,
                          -defaultextension => '.pl',
                          -title=>'file to read');
  }
  else
  {
    $file = $mw->FileSelect(-directory => '.',
                          -initialfile => $file,
                          -title=>'file to read')->Show;
  }
  $mw->Unbusy;
  # return 'Cancel' if file not selected
  return 'Cancel' unless($file);
  &file_read($file);
}

sub file_read
{
  my ($file)=shift;
  $lastfile=$file;
 
  unless(open (DATA,$file))
  {
    # report error
    $mw->Dialog(-text=>"File $file read - $!\n",-buttons=>['Continue'])->Show();
    return 'Cancel';
  }
  else
  {
    &code_read(<DATA>);
    @redo=(); @undo=(); # nothing to undo
    &changes(0);
    # repaint canvas list:
    $tf->delete('0','end');
    map($tf->insert(0,-data=>$_,-image=>$pic{lc("canv_$canv_obj{$_}->{name}")},-text=>$_),@canv_obj);
    close DATA;
  }
}

sub code_read
{
  $obj_count=0;
  $cnv_t = '';
  $cnv_bg = $bg_color;
  $cnv_fullcode = 0;
  foreach (@_)
  {
    chomp;
    if(/^\s*#!/) { $cnv_fullcode = 1; next; }
    if(/^\s*#/) { s/^\s*#\s*//; $cnv_t .= "$_ "; next; }
    if(/^\s*\$c->configure/) { ($cnv_bg) = m/-background=>'([^']+)'/; next; }
    s/^my \$//;
    s/\s+=.*create\([^,]+,/,/;
    s/,-tags=>.*//;
    s/'//g;
    my ($id,@pars)=split(/\s*,\s*/);
    my $type=(split('_',$id))[1];
    # map(s/'//g,@pars);
    &obj_create(0,$type,@pars);
  }
  $c->configure(-background=>$cnv_bg);
}

sub file_save
{
  my ($type)=shift;
  unless($type)
  {
    return unless $changes;
  }
  $c->configure(-cursor=>'crosshair');
  $mw->Busy;
  # open file save dialog box
  my @types = ( ["Perl files",'.pl'], ["All files", '*'] );
  my $file = $lastfile;
  $file=~s#.*[/\\]([^/\\]+)$#$1#;
  if(! -f $lastfile || $type)
  {
    $file='newfile.pl';
    if($ENV{OS}=~/(^win)|(^$)/i)
    {
      $file = $mw->getSaveFile(-filetypes => \@types,
                          -initialfile => $file,
                          -defaultextension => '.pl',
                          -title=>'file to save');
    }
    else
    {
      $file = $mw->FileSelect(-directory => '.',
                          -initialfile => $file,
                          -title=>'file to save')->Show;
    }
  }
  $mw->Unbusy;
  # return 'Cancel' if file not selected
  return 'Cancel' unless($file);
  $lastfile=$file;

  # save data structure to file
  unless(open (DATA,">$file"))
  {
    # report error
    $mw->Dialog(-text=>"File $file write - $!\n",-buttons=>['Continue'])->Show();
    return 'Cancel';
  }
  else
  {
    print DATA join("\n",&code_print());
    close DATA;
  }
  # reset changes flag
  &changes(0);
  return 0;
}

sub wm_abandon
{
  return unless &check_changes;
  $mw->destroy;
}

sub abandon
{
  return unless &check_changes;
  exit;
}

# This code is partially copied from original NumEntry
# Reason: the original widget does not support -textvariable (sic!)
# Problems: No strict syntax control, No FireButton functionality
my $def_bitmaps = 0;

sub NumEntry
{
  my ($parent,%par)=@_;
  my $numentry;
  my $minvalue=delete $par{'-minvalue'};
  unless($def_bitmaps) 
  {
    my $bits = pack("b8"x5,
      "........",
      "...11...",
      "..1111..",
      ".111111.",
      "........"
    );

    $mw->DefineBitmap('INCBITMAP' => 8,5, $bits);

    # And of course, decrement is the reverse of increment :-)
    $mw->DefineBitmap('DECBITMAP' => 8,5, scalar reverse $bits);
    $def_bitmaps=1;
  }
  my $result=$parent->Frame();
  $numentry=$result->Entry(%par)->pack(-anchor=>'w', -side=>'left');
  $numentry->bind('<Up>',[\&inc_num_controlled,$par{'-textvariable'},1,$minvalue]);
  $numentry->bind('<Down>',[\&inc_num_controlled,$par{'-textvariable'},-1,$minvalue]);
  $result->Button(-bitmap=>'INCBITMAP',-cursor=>'left_ptr',-command=>
    [\&inc_num_controlled,$par{'-textvariable'},1,$minvalue])
    ->pack(-anchor=>'nw', -side=>'top');
  $result->Button(-bitmap=>'DECBITMAP',-cursor=>'left_ptr',-command=>
    [\&inc_num_controlled,$par{'-textvariable'},-1,$minvalue])
    ->pack(-anchor=>'nw', -side=>'top');
  return $result;
}

sub inc_num_controlled
{
  shift if ref($_[0]) ne 'SCALAR';
  my ($ptr,$inc,$minvalue,$maxvalue)=@_;

  my $value=$$ptr+$inc;
  return if length $minvalue && $value<$minvalue;
  return if length $maxvalue && $value>$maxvalue;
  $$ptr=$value;
}

# Data storing/decoding:
# - All objects stored in array
# - File stored as perl include-file using $c as base canvas

package Drawing;

sub hash
{
  my (@p);  my $s=0;
  foreach (@_)
  {
    $s=1 if /^-\D/;
    push (@p,$_) if $s;
  }
  return @p;
}

sub array
{
  my (@p);
  foreach (@_){ last if /^-\D/; push (@p,$_)}
  return @p;
}

sub data_merge
{
  my ($merge_type,$p_new,$p_old)=(@_);
  my (@a_new)=array(@$p_new);
  my (%h_old)=hash(@$p_old);
  return (@a_new,%h_old) if $merge_type == 0;
  my (@a_old)=array(@$p_old);
  map(s/'//g,@$p_new);
  my (%h_new)=hash(@$p_new);
  @a_new=@a_old unless scalar(@a_new);
  foreach (keys %h_old)
  {
    $h_new{$_}=$h_old{$_} unless defined $h_new{$_};
  }
  map {delete $h_new{$_} unless $h_new{$_}} (qw/-width -fill -outline -splinesteps -start -extent/);
  return (@a_new,%h_new);
}

# Example:
# my $x = Drawing->new(qw/Line canv_line_000/);
sub new
{
  my $class=shift;
  my $self={};
  bless ($self,$class);
  $self->{'name'} = shift;
  $self->{'id'} = shift;
  map (s/'//g,@_);
  $self->{'par'} = [@_];
  return $self;
}

# Example:
# $x->config(-posx=>2,-posy=>15,-arrow=>'both',-width=>'3');
# note! we are changing internal structure, not a real drawing!
sub config
{
  my ($self,$merge_type,@par)=(@_);
  unless (@par)
  {
    return;
  }
  my $oldpar=$self->{'par'};
  $self->{'par'} = [&data_merge($merge_type,\@par,$oldpar)];
}

__END__

