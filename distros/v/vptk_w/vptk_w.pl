#!/usr/local/bin/perl

my $path;    # where current application installed
my $toolbar; # where application resources could be found
my $os;      # what kind of OS we have: win/unix

=head1 NAME

 vptk_w - Perl/Tk Visual resource editor (widget edition)

=head1 SYNOPSIS

 vptk_w [-help]

   -h[elp]  - show this help

=head1 DEVELOPER NOTES

  1. General considerations
  =========================

  * VPTK is a tool for Perl/Tk widget-level scripts development
  * It can be used for user interface sketching
  * Code is instantly generated and could be re-used in standalone app

  2. User interface
  =================

  * All generated code stored as Perl/Tk ready-to-run program
  * Project displayed both visually and as widgets tree
  * Most functions accessible both from pull-down menu,
    toolbar panel and by keyboard shortcuts

  3. Restrictions
  ===============
  * Commas and brackets prohibited inside of text fields
  * Due to known bugs in Tk some balloons not dispayed
  * No undo/redo for file properties changes

  4. Implemented features
  ================
  * Undo for all artwork modifications
  * Unlimited undo/redo
  * Object editing using selection bars
  File: Open, New, Save, Save as, Setup, Quit
  Edit: Undo, Redo, Delete, Rename, Properties
  Create: Before, After, Subwidget
  View: Repaint, Code, Options
  * Object selection by click on view window
  * Right-button context menu on tree and view window
  * Full-functional program generation
  (use ...; mw=...; {body} MainLoop;)
  * Help & HTML documentation
  * Full menus support
  * Code generation with 'strict syntax'
  * Conflicts in geometry managers resolved automatically
  * Balloon diaplaying code for each widget
  * X/Y mouse pointer coordinates displayed
  * Default values for most widgets apon creation
  * Default entries for lists and other arrays (display only)
  * View options: Balloons on/off, blink on/off, coord on/off
  * User-defined widget names on creation + rename option
  * Callback functions support
  * User-defined code support
  * Widget state variables
  * Automatic declaration of widget-dependent variables
  * Code portions cut-n-paste
  * Syntax highlight in code preview window
  * NumEntry used for numeric data input
  * Debugging mode for generated app
  * Syntax check for generated code (perl -c)
  * All edited widgets defined as abstract objects
  * New widgets could be plugged-in without main routine modification
  * User code before main loop - full support
  * Balloon assigned from 'edit menu' (one-to-one)
  * Bindings list in File->Setup (one-to-many)
  * Clipboard paste after/under selection
  
  5. To be implemented
  ====================
  * Cursor changes on selection/object
  * Full widgets set
  * Portions save/retrieve
  * External templates for most basic windows:
  Dialog, Configuration, Editor
  * Subroutines/variables/pictures management windows
  * Tiler as geometry manager
  * Tix->form as geometry manager (?)

  6. Known bugs
  =============
  * Double-click on HList works diffently in Unix and M$ Win
  * Bug in LabFrame and BrowseEntry not fixed - detour ;-)
  * No syntax control for callbacks, user code and variables

  7. Data structures
  ==================

  All data represented as following objects:
  - Array of all widgets descriptors
  - Widgets hierarchy tree (array):
  w_Frame_001
  w_Frame_001.w_Frame_002
  w_Frame_001.w_Frame_002.w_Button_001
  w_Frame_001.w_Frame_002.w_Label_001
  w_Frame_001.w_Frame_003
  w_Frame_001.w_Frame_004
  w_Frame_005
  w_Frame_006
  - Hash (Widget id) -> descriptor

  Default widget identificator: w_<WidgetType>_<0padNumber>
  Widget descriptor:
  * ID
  * Type
  * Parameters
  * Geometry info (pack/grid/place) + parameters
  * Final output ID
  * Display widget (?)

  External data representation:
  $<widget ID> = $<Parent ID> -> <Type> ( <Parameters> ) -> <Geometry>;
  Menu items (and others that don't require placement):
  $<widget ID> = $<Parent ID> -> <Type> ( <Parameters> );

  8. Geometry conflicts and bugs in generated code
  ================================================

  What is geometry conflict? First of all it's mix of different
  geometry managers under same parent widget. Additional restriction
  (possible deviated from first one) Tk geometry manager gets
  mad if user tryes to use 'grid' geometry under frame with label.

  Solution is to detect and fix such cases in 3 potential situations:
  - widget creation
  - widget editing
  - widget move
  1st case is most trivial - newly created widget simply inherits
  geometry manager from it's 'brothers'
  In two rest cases we can detect conflict by comparison with any
  of 'brothers'. Possible solutions (we'll let user to decide):
  - Propagate conflicting geometry manager to 'brothers'
  - Adopt conflicting geometry manager according to environment
  - Cancel operation

  Yet another geometry conflict source: when some widget use
  packAdjust 'sub-widget' while 'brothers' use non-pack
  geometry managers. No solution till now (simply avoid such
  situations - otherwise your application became stuck).

  Generated program can fail on following known bugs:
  - Missed menu for Menubutton/cascade (simply don't forget it!)
  - Empty menu & -tearoff=>0 (nothing to dispay - avoid such cases!)
  - Balloon assigned to BrowseEntry/LabFrame cause error messagess 
    on double-click (in older PerlTk versions)

  ...and now documented bugs can be referred as 'feature' ;-)

  9. Menus handling
  =================

  We have two types of Menu: Menu and Menubutton
  Menubutton is the root of one Menu
  Under Menu user can create following objects:
  - Command
  - Checkbutton
  - Radiobutton
  - Separator
  - Cascade
  Under Cascade can be created any of listed objects too.

=cut

BEGIN
{
  $path=$0;
  $path=~s#[^/\\]+$##;
  $path='.' unless $path;
  unshift (@INC,$path);
  $toolbar = "$path/toolbar";
  die "$0 installation error: directory $toolbar not found!\n"
    unless -d $toolbar;
  $os = 'win' unless $^O;
  $os = 'win' if $^O =~ /win/i;
  $os = 'unix' if $^O =~ /linux|unix|aix|sun|solaris|cygwin/i;
  # we treat cygwin-X environment as "Unix-like"
}

use strict;
use Tk 800;

use Tk::DialogBox;
use Tk::Photo;
use Tk::Checkbutton;
use Tk::Balloon;
use Tk::Adjuster;
use Tk::LabFrame;
use Tk::LabEntry;
use Tk::BrowseEntry;
use Tk::NoteBook;
use Tk::HList;
use Tk::FileSelect;
use Tk::Tiler;
use Tk::ROText;
use Tk::Dialog;
use Tk::Pane;

use IPC::Open3;
use Data::Dumper;

# editor-related modules:
use vptk_w::ConfigRead;
use vptk_w::EditorServices;
use vptk_w::VPTK_Widget;
use vptk_w::Project;
use vptk_w::Project::Options;
use vptk_w::Project::Widgets;
use vptk_w::Project::Code;

if (grep /^--?h/,@ARGV)
{
  # this works for real perl script only!
  # does not work on M$ Win EXE-file
  system "perldoc $0";
  exit 1;
}

my $VERSION;
$VERSION = q$Revision: 2.42 $;

my $selected;         # Currently selected widget path
my %widgets=();       # Displayed Tk visual objects (widgets)
my $changes;          # Modifications flag
my $view_repaint = 0; # 'Just repainted' flag
my $lastfile='';      # last file used in Open/Save
my %descriptor=();    # Mapping id->descriptor
my @tree=('mw');      # design tree list ('.' separated entry)
my $obj_count=0;      # counter for unique object id
my @undo=();          # Undo buffer
my @redo=();          # Redo buffer
my %cnf_dlg_balloon;   # Help messages for all widget configuration options
my $Project = vptk_w::Project->new();
my $pOpt = vptk_w::Project::Options->new();
my @main_clipboard=();
my @user_auto_vars;
my @callbacks;
my @user_subs;
my @project_bindings;
# Structure of project_bindings:
# ['widget_id'=>'event name'=>'callback'], ...
my $wProjOptionsHintMsg;
my %IDE_settings;
my %Project_defaults;
my $balloon_bg_color;
my $balloon_delay;

my @AllWidgetsNames = AllWidgetsNames();

# Legal parameters per geometry:
my (%w_geom) = (
  'pack'  => [qw/-side -fill -expand -anchor -ipadx -ipady -padx -pady/],
  'grid'  => [qw/-row -column -rowspan -columnspan -sticky -ipadx -ipady -padx -pady/],
  'place' => [qw/-anchor -height -width -x -y -relheight -relwidth -relx -rely/]
);

my @OrdinaryWidgets = (grep(HaveGeometry($_),sort @AllWidgetsNames),'packAdjust'); 
# (excluded widgets without geometry)
my @wrapped_icons = map(WidgetIconName($_),@AllWidgetsNames);
#
# ======================== Geometry management for Main window ================
# 
my $mw = MainWindow->new(-title=>"Visual Perl Tk $VERSION (widget edition)");
&ResetIDE_SettingsToDefaults();

# Prepare help from HTML file:
# 1. read HTML file
my (@html_help)=(&ReadHTML("$toolbar/widget_help.html"));
@html_help = 'Sorry, help file is not available!' unless $html_help[0];
my (@html_tutorial)=(&ReadHTML("$toolbar/tutorial.html"));
@html_tutorial = 'Sorry, tutorial file is not available!' unless $html_tutorial[0];
# 2. get gif-files list
my @html_gifs=grep(/^gif/,@html_help,@html_tutorial);
map s/^\S+\s+//,@html_gifs;
# 3. create bold font:
$mw->fontCreate('C_bold',qw/-family courier -weight bold/);

# read in all pictures:
foreach (sort(qw/open save new before after subwidget balloon run
  undo redo viewcode properties delete exit cut copy paste bind callback
  justify_right justify_left justify_center
  undef fill_both fill_x fill_y
  rel_flat rel_groove rel_raised rel_ridge rel_solid rel_sunken
  anchor_center anchor_e anchor_n anchor_ne anchor_nw anchor_s anchor_se anchor_sw anchor_w
  side_bottom side_left side_right side_top/,
  @html_gifs,@wrapped_icons))
{
  my $pic_file="$toolbar/$_.gif";
  $pic_file = "$toolbar/$_.xpm" unless -e $pic_file;
  unless (-e $pic_file) { 
    warn "no file $pic_file"; next;
  }
  $pic{$_} = $mw->Photo(-file=>$pic_file)
    unless defined $pic{$_};
}

# Read balloon messages:
%cnf_dlg_balloon = &ReadCnfDlgBalloon("$toolbar/balloon_cnf_dlg.txt");

my $xy; # X=nnn Y=nnn indicator

# +-------------------------------+
# | menu ...                      |
# +-------------------------------+
# | tool bar                      |
# +------+------------------------+
# |      |                        |  
# | tree |                        |  
# | area |      drawing           |
# |      |      area              |
# |      |                        |  
# |      |                        |  
# |______|________________________|
# | status bar             x= y= *|
# +-------------------------------+
#

my $menubar = $mw->Frame(-relief => 'raised', -borderwidth => 2)
  ->form(-top=>'%0',-left=>'%0',-right=>'%100');

$menubar->Menubutton(qw/-text File -underline 0 -tearoff 0 -menuitems/ =>
  [
    [Button => '~Open ...',    -command => \&file_open, -accelerator => 'Control+o'],
    [Button => '~New',         -command => \&file_new,  -accelerator => 'Control+n'],
    [Button => '~Save',        -command => \&file_save, -accelerator => 'Control+s'],
    [Button => 'Save ~As ...', -command => [\&file_save, 'Save As']],
    [Separator => ''],
    [Button => '~Project properties ...',   -command => \&file_properties],
    [Button => '~Editor properties ...',    -command => [\&file_properties,'IDE']],
    [Separator => ''],
    [Button => '~Quit',        -command => \&abandon,   -accelerator => 'ESC'],
  ])->pack(-side=>'left');

$menubar->Menubutton(qw/-text Insert -underline 0 -tearoff 0 -menuitems/ =>
  [
    [Button => '~Before',     -command => [\&insert,'before']],
    [Button => '~After',      -command => [\&insert,'after']],
    [Button => '~Sub-widget', -command => [\&insert,'subwidget']],
  ])->pack(-side=>'left');

$menubar->Menubutton(qw/-text Edit -underline 0 -tearoff 0 -menuitems/ =>
  [
    [Button => '~Properties', -command => \&edit_properties],
    [Separator=>''],
    [Button => '~Undo',       -command => \&undo, -accelerator => 'Control+z'],
    [Button => '~Redo',       -command => \&redo, -accelerator => 'Control+r'],
    [Separator=>''],
    [Button => '~Cut',        -command => \&edit_cut, -accelerator => 'Control+x'],
    [Button => 'C~opy',       -command => \&edit_copy, -accelerator => 'Control+c'],
    [Button => 'P~aste before sel', -command => \&edit_paste, -accelerator => 'Control+v'],
    [Button => 'Pa~ste after sel', -command => [\&edit_paste,'after']],
    [Button => 'Paste ~under sel', -command => [\&edit_paste,'under']],
    [Separator=>''],
    [Button => 'R~ename',     -command => \&rename],
    [Button => '~Delete',     -command => \&edit_delete, -accelerator => 'Delete'],
  ])->pack(-side=>'left');

$menubar->Menubutton(qw/-text View -underline 0 -tearoff 0 -menuitems/ =>
  [
    [Button => '~Repaint',    -command => \&view_repaint],
    [Button => '~Code',       -command => sub{&CodePreview(&code_print)}],
    [Cascade => '~Options', -tearoff=>0, -menuitems =>
      [
        [Checkbutton=>'~Show code preview over widget',
          -variable=>\$IDE_settings{'view_balloons'},-command=>\&view_repaint],
        [Checkbutton=>'~Blink widget on selection',-variable=>\$IDE_settings{'view_blink'}],
        [Checkbutton=>'Show ~mouse pointer X,Y coordinates',
          -variable=>\$IDE_settings{'view_pointerxy'},-command=>\&view_repaint],
        [Button => '~Re-color myself',   -command=> \&ColoringScheme ]
      ]
    ],
  ])->pack(-side=>'left');

$menubar->Menubutton(qw/-text Debug -underline 0 -tearoff 0 -menuitems/ =>
  [
    [Button => '~Edit code',    -command => \&debug_edit],
    [Button => '~Check syntax', -command => \&debug_syntax],
    [Button => '~Run code',     -command => \&debug_run],
  ])->pack(-side=>'left');

$menubar->Menubutton(qw/-text Help -underline 0 -tearoff 0 -menuitems/ =>
  [
     [Button => 'VPTk ~help',       -command => [\&ShowHelp,@html_help]],
     [Button => 'VPTk ~tutorial',   -command => [\&ShowHelp,@html_tutorial]],
     [Button => '~Context help',    -command => \&tkpod],
     [Cascade => '~PerlTk manuals', -tearoff=>0, -menuitems =>
       [
         [Button => '~Overview',          -command => [\&tkpod,'overview']],
         [Button => '~Standard options',  -command => [\&tkpod,'options']],
         [Button => 'Option ~handling',   -command => [\&tkpod,'option']],
         [Button => 'Tk ~variables',      -command => [\&tkpod,'tkvars']],
         [Button => '~Grab manipulation', -command => [\&tkpod,'grab']],
         [Button => '~Binding',           -command => [\&tkpod,'bind']],
         [Button => 'Bind ~tags',         -command => [\&tkpod,'bindtags']],
         [Button => '~Callbacks',         -command => [\&tkpod,'callbacks']],
         [Button => '~Events',            -command => [\&tkpod,'event']],
       ]
     ],
     [Button => 'Perl/Tk ~status',  -command => [\&ShowStatusMessage]],
     [Button => '~About',           -command => [\&ShowAboutMessage,$VERSION]],
  ])->pack(-side=>'right');

# pop-up menu on right button

my $popup=$mw->Menu(-tearoff=>0);
my $popup_insert=$popup->Menu(-tearoff=>0);
$popup_insert->add('command',-label=>'Before',-underline=>0,-command=>[\&insert,'before']);
$popup_insert->add('command',-label=>'After',-underline=>0,-command=>[\&insert,'after']);
$popup_insert->add('command',-label=>'Subwidget',-underline=>0,-command=>[\&insert,'subwidget']);
$popup->add('cascade',-label=>'Insert',-underline=>0,-menu=>$popup_insert);
$popup->add('command',-label=>'Properties',-underline=>0,-command=>\&edit_properties);
$popup->add('command',-label=>'Balloons',-underline=>0,-command=>\&edit_balloon);
$popup->add('command',-label=>'Context help',-underline=>8,-command=>\&tkpod);
$popup->add('command',-label=>'Cut',-underline=>0,-command=>\&edit_cut,-accelerator => 'Control+x');
$popup->add('command',-label=>'Copy',-underline=>1,-command=>\&edit_copy,-accelerator => 'Control+c');
$popup->add('command',-label=>'Paste before sel',-underline=>1,-command=>\&edit_paste,-accelerator => 'Control+v');
$popup->add('command',-label=>'Paste after sel',-underline=>3,-command=>[\&edit_paste,'after']);
$popup->add('command',-label=>'Paste under sel',-underline=>6,-command=>[\&edit_paste,'under']);
$popup->add('command',-label=>'Rename',-underline=>0,-command=>\&rename);
$popup->add('command',-label=>'Delete',-underline=>0,-command=>\&edit_delete,-accelerator => 'Delete');

my $bf=$mw->Frame()->
  form(-top=>$menubar,-left=>'%0',-right=>'%100',-bottom=>'%100');
# ===============
# 'buttons' frame
# ===============
my $ctrl_frame=$bf->Frame()->pack(-side=>'top',-anchor=>'nw');
my $main_frame=$bf->Frame()
  ->pack(-side=>'top',-anchor=>'ne',-fill=>'both',-expand=>1);
my $status_frame=$bf->Frame(-relief=>'groove')
  ->pack(-side=>'top',-anchor=>'nw',-fill=>'x');
my $status=$status_frame->Label(-text=>'No selection',-relief=>'sunken',-borderwidth=>2)
  ->pack(-side=>'left');
my $changes_l=$status_frame->Label(-text=>' ',-relief=>'sunken',-borderwidth=>2)
  ->pack(-side=>'right');
$status_frame->Label(-textvariable=>\$xy,-relief=>'sunken',-borderwidth=>2,-width=>11)
  ->pack(-side=>'right',-padx=>10);
&changes(0);
# ==========
# ctrl_frame
# ==========
$b=$mw->Balloon();

my @buttons = 
(
  ['new',      \&file_new,            'New project'],
  ['open',     \&file_open,           'Open file'],
  ['save',     \&file_save,           'Save current file'],
  [],
  ['before',   [\&insert,'before'],   'Insert new widget before'],
  ['after',    [\&insert,'after'],    'Insert new widget after'],
  ['subwidget',[\&insert,'subwidget'],'Insert new subwidget'],
  [],
  ['undo',     \&undo,                'Undo last change'],
  ['redo',     \&redo,                'Redo last change'],
  [],
  ['delete',   \&edit_delete,         'Erase selected'],
  ['cut',      \&edit_cut,            'Cut selected tree to clipboard'],
  ['copy',     \&edit_copy,           'Copy selected tree to clipboard'],
  ['paste',    \&edit_paste,          'Paste from clipboard before selected'],
  ['properties',\&edit_properties,    'View & edit properties'],
  [],
  ['balloon',  \&edit_balloon,        'Edit widget\'s balloon'],
  ['bind',     \&edit_bindings,       'Edit widget\'s binding(s)'],
  ['callback',  [\&file_properties,'callbacks'],  'Edit callbacks'],
  [],
  ['viewcode', sub{&CodePreview(&code_print)}, 'Preview generated code'],
  ['run',      \&debug_run,           'Run generated program'],
  [],
  ['exit',     \&abandon,             'Exit program'],
);
foreach my $button(@buttons)
{
  if(@$button)
  {
    $b->attach(
      $ctrl_frame->Button(-image=>$pic{$button->[0]}, -command=>$button->[1])->pack(-side=>'left',-expand=>1),
      -balloonmsg=>$button->[2]);
  }
  else
  {
    $ctrl_frame->Label(-text=>' ')->pack(-side=>'left',-expand=>1);
  }
}

my $tf=$main_frame->Scrolled('HList', -scrollbars=>'se',-itemtype=>'imagetext')
  ->pack(-side=>'left',-fill=>'y');
$tf->bind('<Button-1>', 
  sub{ my $s=$tf->infoSelection; &set_selected($tf->info('data',$s))if $s; } );
$tf->configure(
  -command  => sub{&set_selected($tf->info('data',$tf->infoSelection));&edit_properties},
  -browsecmd=> sub{&set_selected($tf->info('data',$tf->infoSelection));} );
$tf->add('mw',-text=>'mw',-data=>'mw',-image=>WidgetIcon('Frame'));

my $w;
$tf->packAdjust(-side=>'left');

$tf->bind('<Button-3>',
  sub{ &set_selected($tf->nearest($tf->pointery-$tf->rooty)); $popup->Post($mw->pointerxy)});
my %EditorBindings = 
(
  '<Control-o>' => \&file_open,
  '<Control-s>' => \&file_save,
  '<Control-n>' => \&file_new,
  '<Control-z>' => \&undo,
  '<Control-r>' => \&redo,
  '<Delete>'    => \&edit_delete,
  '<Control-x>' => \&edit_cut,
  '<Control-c>' => \&edit_copy,
  '<Control-v>' => \&edit_paste,
  '<F1>'        => [\&ShowHelp,@html_help],
  '<Escape>'    => \&abandon,
);
map( $mw->bind($_ => $EditorBindings{$_}), keys %EditorBindings );
$mw->geometry('=600x500+120+1'); # initial window position

$mw->protocol('WM_DELETE_WINDOW',\&abandon);

$mw->SelectionOwn(-selection=>'CLIPBOARD');
&ReadIDE_Settings();

if (@ARGV) {
  &file_clean;
  &file_read(@ARGV);
}
else {
  &file_new;
}
&set_selected('mw');

MainLoop;

print "We are not supposed to be here...\n";

######################################################
#     SUBROUTINES section
######################################################
# we call this routine only when creating new project!!!
sub InitProject
{
  my $project = shift;
  my $perl = $pOpt->get('perl executable');
  @project_bindings=();
  $pOpt->init( {description=>'',title=>'',%Project_defaults,'perl executable'=>$perl,bindings=>\@project_bindings,'balloon_color'=>'lightyellow','balloon_delay'=>550} );
  $project->push('Options'=>$pOpt);

  my $pW = vptk_w::Project::Widgets->new();
  $project->push('Widgets'=>$pW);

  my $pCode = vptk_w::Project::Code->new();
  $project->push('Code'=>$pCode);
  $project->get('Code')->push('code before tk'=>[]);
  $project->get('Code')->push('code before widgets'=>[]);
  $project->get('Code')->push('code before main'=>[]);
  $project->get('Code')->push('user code'=>[]);
  &PopulateProject($project);
}

# fill project with data: - to be removed TBD
sub PopulateProject{
  my $project = shift;

  foreach my $widgetPath( @tree ) {
    my $wid = &path_to_id($widgetPath);
    $project->get('Widgets')->add($widgetPath,$wid,$descriptor{$wid});
  }
}

# Display dialog box for application coloring configuration
sub ColoringScheme
{
  my ($bg_color,$fg_color)=&GetMainPalette();
  
  my $db=$mw->DialogBox(-title=>'Choose color scheme:',-buttons=>[qw/Ok Default Dismiss/]);
  my $f;
  $f=$db->Frame->pack(-padx=>6,-pady=>6,-anchor=>'w',-fill=>'x');
  $f->Label(-text=>'Background:')->pack(-side=>'left',-fill=>'x');
  &ColorPicker($f,'Background',\$bg_color,0,-fill=>'x',-expand=>1);
  $f=$db->Frame->pack(-padx=>6,-pady=>6,-anchor=>'w',-fill=>'x');
  $f->Label(-text=>'Foreground:')->pack(-side=>'left',-fill=>'x');
  &ColorPicker($f,'Foreground',\$fg_color,0,-fill=>'x',-expand=>1);
  my $reply = $db->Show;
  return if $reply eq 'Dismiss';
  ($bg_color,$fg_color)=(qw/gray90 black/) if $reply eq 'Default';
  if(uc($bg_color) eq uc($fg_color))
  {
    $reply = $mw->Dialog(
      -title=>"Error",
      -text=>"You can't use same color for background and foreground",
      -buttons=>["Retry","Dismiss"]
      )->Show();
    return if $reply eq "Dismiss";
    return ColoringScheme();
  }
  &SetMainPalette($mw,$bg_color,$fg_color);
  # Re-paint preview window:
  &view_repaint; # force repaint!
}

# define combo widget that used for color selection
# arguments: 
# $f     - frame (container widget)
# $text  - prompt displayed on menubutton
# $p     - pointer to "color value" variable
# $checkbutton - boolean flag: display "enabled" checkbutton or not
sub ColorPicker
{
  my($f,$text,$p,$checkbutton,@extra_opt)=@_;
  my $cl=$f->Menubutton(-text=>$text,-relief=>'raised')
    ->pack(-side=>'right', -padx=>7, @extra_opt);
  my $m = $cl->Menu(qw/-tearoff 0/);
  my $var=($$p)?1:0;
  my $i=1;
  foreach (qw/Brown Red sienna2 pink DarkOliveGreen1 khaki4
  DarkOrange2 DarkGoldenrod1 Yellow Green green4 DarkGreen
	DarkSeaGreen LightSkyBlue Cyan LightSeaGreen RoyalBlue4 Blue
	NavyBlue SlateBlue1 plum magenta1 Magenta3 purple3
        White gray80 gray70 gray50 gray13 Black/)
  {
    $m->command(-label => $_, -columnbreak=>(($i-1) % 6)?0:1,
      -command=>
      [sub{$$p=shift;$var=1;$cl->configure(-background=>$$p)},$_]);
    my $i1 = $m->Photo(qw/-height 16 -width 16/);
    $i1->put(qw/gray50 -to 0 0 16 1/);
    $i1->put(qw/gray50 -to 0 1 1 16/);
    $i1->put(qw/gray75 -to 0 15 16 16/);
    $i1->put(qw/gray75 -to 15 1 16 15/);
    $i1->put($_, qw/-to 1 1 15 15/);
    $m->entryconfigure($i, -image => $i1);
    $i++;
  }
  $cl->configure(-menu => $m);
  $cl->configure(-background=>$$p,-activebackground=>$$p,
    -highlightbackground=>$$p,-state=>'active') 
    if $$p;
  if($checkbutton)
  {
    my $cb=$f->Checkbutton(-text => 'enabled',
      -relief => 'solid',-variable=>\$var,-borderwidth=>0,
      -command => sub{ $$p='' unless $var; }
     )->pack(-side=>'right', -padx=>7);

  }
}

# Perform one of debug actions using system-dependent terminal
# Arguments:
# $str   - command-line to be executed
# $title - explanation to be displayed as window title
sub debug_do
{
  return &ShowDialog(-title=>'Debug',-bitmap=>'error',-text=> "File not saved!\n")
    if $changes;
  return &ShowDialog(-title=>'Debug',-bitmap=>'error',-text=> "Your design is empty!\n")
    if scalar(@tree) <= 1;
  my ($str,$title)=@_;
  my $filepath=$lastfile;
  
  if($os eq 'unix')
  {
    $filepath="$ENV{PWD}/$filepath" unless $filepath=~/^\//;
  }

  $str=~s/\$filepath/$filepath/g;
  if($os eq 'unix')
  {
    $title="-T '$title' " if $title;
    system("xterm $title -e $str");
  }
  else
  {
    my @log = ();
    open3(\*WTRFH, \*RDRFH, \*ERRFH, $str);
    push(@log,map("text $_",<RDRFH>));
    push(@log,map("bold $_",<ERRFH>));
    close WTRFH; close RDRFH; close ERRFH;
    chomp @log;
    # show results if log generated
    &ShowHelp(@log) if @log;
  }
}

# one of debug actions - file editing
sub debug_edit
{
  my $editor=$IDE_settings{'text_editor'};
  my $run_str = ($os eq 'unix')?
    "$editor \$filepath &" : "$editor \$filepath";
  &debug_do($run_str,'Editing');
  # if file is empty - exit immediately
  return
    if scalar(@tree) <= 1;
  # if file not saved - exit immediately
  return
    if $changes;
  return unless &ShowDialog(-title=>'Editing finished',
    -text=>"Reload file after editing?\n(click when really finish editing)",
    -buttons=>[qw/Yes No/]);
  # reload data from file (read_file)
  my $filepath=$lastfile;
  
  if($os eq 'unix')
  {
    $filepath="$ENV{PWD}/$filepath" unless $filepath=~/^\//;
  }
  &file_clean;
  &file_read($filepath);
}

# debug action - run perl in "compile only" mode
sub debug_syntax
{
  my $perl = $pOpt->get('perl executable');
  my $run_str = ($os eq 'unix')?
    "csh -c '$perl -c \$filepath | less'" : "$perl -c \$filepath";
  &debug_do($run_str,'Syntax check');
}

# debug action - just run generated code
sub debug_run
{
  return &ShowDialog(-title=>'Debug',-bitmap=>'error',-text=> "The code is not fully executable! You can change it in 'File'->'Properties'\n")
    unless $pOpt->data->{'fullcode'};
  my $perl = $pOpt->get('perl executable');
  my $run_str = ($os eq 'unix')?
    "csh -c '$perl -w \$filepath | less'" : "$perl -w \$filepath";
  &debug_do($run_str);
}

# mapping of icon according to widget type
sub WidgetIcon {
  return $pic{WidgetIconName($_[0])}
}

# intercepting Tk internal errors and storing in log-file
sub Tk::Error
{
  my ($widget,$error,@locations) = @_;
  print "DEBUG: widget <$widget> error <$error> from <@locations>\n";
}

# This routine will clear visual part of our design
sub clear_preview
{
  eval{map($b->detach($_),values %widgets)};
  # we use "eval" here in order to skip irrelevant error messages from "detach"
  if (Exists($w))
  {
    # unbind here?
    $w->destroy();
  }
  %widgets=();
  $xy='';
  $w=$main_frame->Scrolled('Frame',-relief=>'sunken',-borderwidth=>2) 
    ->pack(-fill=>'both',-expand=>1);
  &bind_xy_move($w);
}

# Bind X and Y coordinates display for given widget
sub bind_xy_move
{
  shift->bind('<Motion>',
    sub{my($x,$y)=$w->pointerxy;$x-=$w->rootx;$y-=$w->rooty;$xy="x=$x y=$y"})
    if $IDE_settings{'view_pointerxy'};
}

# Repaint visual part of project - preview window
sub view_repaint
{
  &clear_preview();
  my %tmp_vars=('mw'=>$w); # those variables exist only for 'redraw' window
  # widgets connectivity
  foreach my $path(@tree)
  {
    my $id=&path_to_id($path);
    next unless defined $descriptor{$id};
    next if $id eq 'mw';
    my $d=$descriptor{$id};
    my $x=$tmp_vars{$d->{'parent'}};
    my @arg=&split_opt($d->{'opt'});
    my $callback_assigned = 0;
    if(grep(/-\w*(command|cmd)/,@arg))
    {
      my (%arg)=@arg;
      foreach my $par(qw/command createcmd raisecmd/)
      {
        if ($arg{"-$par"})
        {
          $arg{"-$par"}=[\&callback,$arg{"-$par"},$path,$par,$id];
          $callback_assigned = 1;
        }
      }
      foreach my $par (keys %arg)
      {
        delete $arg{$par} if (ref $arg{$par} eq 'CODE' || ref $arg{$par} eq 'SCALAR' || $arg{$par} =~ /^\\/);
      }
      (@arg)=(%arg);
    }
    if(grep($_ eq $d->{'type'}, @AllWidgetsNames) ) {
      my $obj = vptk_w::VPTK_Widget->new($d->{'type'},-id=>$id);
      my ($geom,$geom_opt)=(split '[)(]',$d->{'geom'});
      $obj->InstanceData(
        -widget_data=>{@arg},
        -geometry_data=>{geometry=>$geom,&split_opt($geom_opt)}
      );
      $tmp_vars{$id} = $obj->Draw($x);
    }
    if(&HaveGeometry($d->{'type'}))
    {
      my $balloonmsg=&code_line_print($path);
      $balloonmsg =~ s/ -> / ->\n/g;
      $balloonmsg =~ s/,/,  \n/g;

      $b->attach($tmp_vars{$id},-balloonmsg=>$balloonmsg)
       if $IDE_settings{'view_balloons'} && 
         $d->{'type'} !~ /^(BrowseEntry|LabFrame)$/; # bug in BrowseEntry/LabFrame?
      $tmp_vars{$id}->bind('<Button-3>',
        sub{&set_selected($tf->info('data',$path));$popup->Post($mw->pointerxy)});
      $tmp_vars{$id}->bind('<Button-1>',
        sub{&set_selected($tf->info('data',$path))});
      unless($callback_assigned)
      {
        $tmp_vars{$id}->bind('<Double-1>',
            sub{&set_selected($tf->info('data',$path));&edit_properties});
      }
      &bind_xy_move($tmp_vars{$id});
    }
    $widgets{$path}=$tmp_vars{$id};
  }
  $widgets{'mw'}=$w;
  $view_repaint = 1;
}

sub SetProjOptHint
{
  my ($text) = @_;
  $wProjOptionsHintMsg -> configure ( -text => $text );
}

sub GetResourceFileName
{
  my ($read) = @_;
  my $name = 'vptk_w.rc';
  foreach my $p('.',$ENV{'HOME'},$path)
  {
    if($read)
    {
      return "$p/$name" if -r "$p/$name";
    }
    else
    {
      return "$p/$name" if -w "$p/$name";
    }
  }
  return undef if $read;
  return $name;
}

sub ReadIDE_Settings
{
  # 1. Get file name
  # 2. Read IDE settings
  # 3. Read project defaults
  my $filename = &GetResourceFileName(1);
  unless($filename)
  {
    &ShowDialog(-title=>'Warning:',-text=>"Failed to find configuration file - reset to defaults",-buttons=>['Continue']);
    &ResetIDE_SettingsToDefaults;
    &WriteIDE_Settings(%{$pOpt->data});
    return;
  }
  unless(open(FILE,$filename))
  {
    &ShowDialog(-title=>'Error:',-text=>"Failed to read configuration file $filename",-buttons=>['Continue']);
    return;
  }
  my $section;
  my %config;
  while(<FILE>)
  {
    chomp;
    s/[\n\r]$//g;
    next if /^[#;]/;
    if(/^\[\S+\]/)
    {
      ($section) = /^\[(\S+)\]/;
      $config{$section}={};
      next;
    }
    if(/=/)
    {
      my ($key,$val) = /([^=]+)=(.*)/;
      $config{$section}->{$key} = $val if $key;
    }
  }
  close FILE; 
  map($IDE_settings{$_}=$config{'IDE_settings'}->{$_},keys %{$config{'IDE_settings'}});
  &SetMainPalette($mw,$IDE_settings{'bg_color'},$IDE_settings{'fg_color'});
  $b->configure(-background=>'lightyellow',-initwait=>550);
  $Project_defaults{'fullcode'} = $config{'project_settings'}->{'fullcode'};
  $Project_defaults{'strict'} = $config{'project_settings'}->{'strict'};
}

sub WriteIDE_Settings
{
  my (%proj_opt) = @_;
  # 1. Get file name
  # 2. Write IDE settings
  # 3. Write project defaults
  my $filename = &GetResourceFileName(0);
  unless(open(FILE,">$filename"))
  {
    &ShowDialog(-title=>'Error:',-text=>"Failed to write configuration file $filename",-buttons=>['Continue']);
    return;
  }
  my ($bg_color,$fg_color)=&GetMainPalette();
  print FILE "[IDE_settings]\n";
  foreach my $key(keys %IDE_settings)
  {
    next if $key eq 'bg_color' || $key eq 'fg_color';
    print FILE "$key=$IDE_settings{$key}\n" if $key;
  }
  print FILE "bg_color=$bg_color\n";
  print FILE "fg_color=$fg_color\n";
  print FILE "[project_settings]\n";
  print FILE "fullcode=$proj_opt{'fullcode'}\n";
  print FILE "strict=$proj_opt{'strict'}\n";

  close FILE;
}

sub ResetIDE_SettingsToDefaults
{
  # 1. Reset IDE settings
  # (we use dirty trick with hash deep copy to preserve some hash pointers)
  my %defaultIDE_settings = (
    'view_balloons'=>1,'view_blink'=>0,'view_pointerxy'=>0,
    'auto_options'=>1,'hint_msg'=>1,
    'bg_color'=>'gray90',
    'fg_color'=>'black',
    'text_editor'=>($ENV{'EDITOR'} || 'vi'));
  map($IDE_settings{$_}=$defaultIDE_settings{$_},keys %defaultIDE_settings);
  $IDE_settings{'perldoc'} = ($os eq 'win')?
    'start cmd /c perldoc' :
    'xterm -e perldoc';
  &SetMainPalette($mw,$IDE_settings{'bg_color'},$IDE_settings{'fg_color'});
  # 2. Reset project defaults
  %Project_defaults = ('fullcode'=>1,'strict'=>1);
}

# show dialog box and enter project-related parameters
sub file_properties
{
  my ($open_tab,$sub_select) = (@_); # open dialog in Balloon notebook
  my $db = $mw->DialogBox(-title=>'Project setup',-buttons=>['Ok','Cancel']);
  my (@p)=(qw/-side top -fill x -padx 10 -pady 5/);
  my %NB_NameToRaise = (
    'balloon'   => 'wBalloonsNF',
    'callbacks' => 'wUserCodeAfterMFrame',
    'bind'      => 'wBindingsNF',
    'IDE'       => 'wIDE_OptionsNF'
    );
  my $TabToRaise = $NB_NameToRaise{$open_tab};
  @user_subs = grep(!/^sub\W/,@callbacks); 
  my ($selSub)=$sub_select?($sub_select):(@user_subs);

  # copy options
  my (%new_opt)=%{$pOpt->data};
  my (%saved_IDE_settings)=%IDE_settings;
  my $p_user_subroutines = $Project->get('Code')->get('user code');
  my $p_code_before_main = $Project->get('Code')->get('code before main');
  my $p_code_before_tk = $Project->get('Code')->get('code before tk');
  my $p_code_before_widgets = $Project->get('Code')->get('code before widgets');

  my $wProjOptionsNB = $db -> NoteBook (  ) -> pack(-fill=>'both',-expand=>1,-padx=>10,-pady=>10);
  $wProjOptionsHintMsg = $db -> Message ( -aspect=>750 ) -> pack();
  $wProjOptionsHintMsg->packForget() unless $IDE_settings{'hint_msg'};
  my ($txtBeforeMain,$txtUserCode,$wProjDescrEntr,$txtBeforeTk,$txtBeforeWidgets);
  my $wProjGeneralFrame = $wProjOptionsNB -> add ( 'wProjGeneralFrame', -wraplength=>50, -label=>'Project options', -justify=>'left', -raisecmd=>sub{
    $wProjDescrEntr->focus();
    &SetProjOptHint( "Hint: if you don't want to see this window when creating new project - enter 'Editor options' tab and un-check respective setting");
    } );
  my $wIDE_OptionsNF = $wProjOptionsNB -> add ( 'wIDE_OptionsNF', -wraplength=>50, -label=>'Editor options', -justify=>'left', -raisecmd=>sub{
      &SetProjOptHint( "Here you can manage Editor-related options. To hide this message in all dialog boxes un-check respective setting above.");
  });
  $wIDE_OptionsNF->Checkbutton(-text=>"Automatically open project options window (recommended for beginner)",-anchor=>'w',-variable=>\$IDE_settings{'auto_options'})->pack(@p);
  $wIDE_OptionsNF->Checkbutton(-text=>"Show hint message in dialog boxes (recommended for beginner)",-anchor=>'w',-variable=>\$IDE_settings{'hint_msg'})->pack(@p);
  $wIDE_OptionsNF->LabEntry(-label=>'Text editor:',
    -labelPack=>[-side=>'left',-anchor=>'n'],
    -textvariable=>\$IDE_settings{'text_editor'})->pack(@p);
  $wIDE_OptionsNF->LabEntry(-label=>'Perldoc utility:',
    -labelPack=>[-side=>'left',-anchor=>'n'],
    -textvariable=>\$IDE_settings{'perldoc'})->pack(@p);
  $wIDE_OptionsNF->Checkbutton(-text=>"Show code preview over widgets",-anchor=>'w',-variable=>\$IDE_settings{'view_balloons'})->pack(@p);
  $wIDE_OptionsNF->Checkbutton(-text=>"Blink selected widget",-anchor=>'w',-variable=>\$IDE_settings{'view_blink'})->pack(@p);
  $wIDE_OptionsNF->Checkbutton(-text=>"Show cursor coordinates",-anchor=>'w',-variable=>\$IDE_settings{'view_pointerxy'})->pack(@p);
  $wIDE_OptionsNF->Button(-text=>'Coloring scheme...',-anchor=>'w',-command=>\&ColoringScheme)->pack(@p);
  my $wButtonsFrm=$wIDE_OptionsNF->Frame()->pack(@p);
  $wButtonsFrm->Button(-text=>'Save this setting as default',-command=>
    sub{ &WriteIDE_Settings(%new_opt);}
    )->pack(-side=>'left');
  $wButtonsFrm->Button(-text=>'Restore from saved settings',-command=>
    sub { &ReadIDE_Settings; }
    )->pack(-side=>'left',-padx=>10);
  $wButtonsFrm->Button(-text=>'Reset to factory settings',-command=>
    sub { &ResetIDE_SettingsToDefaults; }
    )->pack(-side=>'left');
  $wProjDescrEntr=$wProjGeneralFrame->LabEntry(-label=>'Program description (inserted to code as a comment):',-width=>45,
    -textvariable=>\$new_opt{'description'})->pack(@p);
  $wProjGeneralFrame->LabEntry(-label=>'Window title:',-width=>45,
    -textvariable=>\$new_opt{'title'})->pack(@p);
  my $fullExeCheckbtn = $wProjGeneralFrame->Checkbutton(
    -text=>'Generate full executable program (only widgets definition when unchecked)',-anchor=>'w',
    -variable=>\$new_opt{'fullcode'})->pack(@p);
  $wProjGeneralFrame->Checkbutton(-text=>'Use strict output syntax (see "perldoc strict" for details)',-justify=>'left',-anchor=>'w',
    -variable=>\$new_opt{'strict'})->pack(@p);

  my $wUserCodeBeforeTk = $wProjOptionsNB -> add ( 'wUserCodeBeforeTk', -wraplength=>80, -label=>'User code before Tk part', -justify=>'left', -state=>'normal', -raisecmd=>sub{
      &SetProjOptHint( "This code will run before Tk part of your project.\n".
    "Note that widgets are still undefined at this stage; it could be a\n".
    "good idea to put here variables definition and ARGV parsing.");
      } );
  $txtBeforeTk=$wUserCodeBeforeTk->Scrolled(qw/Text -scrollbars oe -height 15 -background white/,
    -foreground=>'black'
    )->pack(-fill=>'both',-expand=>1);
  map($txtBeforeTk->insert('end',"$_\n"),@$p_code_before_tk)
    if @$p_code_before_tk;
  my $wUserCodeBeforeWidgets = $wProjOptionsNB -> add ( 'wUserCodeBeforeWidgets', -wraplength=>100, -label=>'User code before widgets definition', -justify=>'left', -state=>'normal', -raisecmd=>sub{
      &SetProjOptHint( "This code will run before widgets definition.\n".
    "Note that mw already defined at this stage; this section could be\n".
    "useful for Tk-related configuration and initialization.");
      } );
  $txtBeforeWidgets=$wUserCodeBeforeWidgets->Scrolled(qw/Text -scrollbars oe -height 15 -background white/,
    -foreground=>'black'
    )->pack(-fill=>'both',-expand=>1);
  map($txtBeforeWidgets->insert('end',"$_\n"),@$p_code_before_widgets)
    if @$p_code_before_widgets;
  my $wUserCodeBeforeMFrame = $wProjOptionsNB -> add ( 'wUserCodeBeforeMFrame', -wraplength=>90, -label=>'User code before main loop', -justify=>'left', -state=>'normal', -raisecmd=>sub{
      $txtBeforeMain->focus();
      &SetProjOptHint( "This code will run before GUI part of your project.\n".
    "Note that \$mw and all widgets will be already\n".
    "defined at this stage, but not visible.");
      } );
  $txtBeforeMain=$wUserCodeBeforeMFrame->Scrolled(qw/Text -scrollbars oe -height 15 -background white/,
    -foreground=>'black'
    )->pack(-fill=>'both',-expand=>1);
  map($txtBeforeMain->insert('end',"$_\n"),@$p_code_before_main)
    if @$p_code_before_main;
  my $wUserCodeAfterMFrame = $wProjOptionsNB -> add ( 'wUserCodeAfterMFrame', -wraplength=>80, -label=>'User code after main loop', -justify=>'left', -state=>'normal', -raisecmd=>sub{
      $txtUserCode->focus();
      &SetProjOptHint("Here you can define your callbacks for GUI events.\n".
    "All subroutines defined here will be automatically\n".
    "inserted into callback selection listbox.");} );

  my $wBalloonsNF = $wProjOptionsNB -> add ( 'wBalloonsNF', -label=>'Balloons', -justify=>'left', -state=>'normal' );
  $balloon_bg_color = $Project->get('Options')->get('balloon_color');
  $balloon_delay    = $Project->get('Options')->get('balloon_delay');
  my $wBlnEntry=&PopulateBalloonDialog($wBalloonsNF);

  $wProjOptionsNB->pageconfigure('wBalloonsNF',-raisecmd=>
     sub{
       $wBlnEntry->focus() if ref $wBlnEntry;
       &SetProjOptHint("Balloon is a text that appear in ".
    "a popping 'cloud' next to the widget when ".
    "user stops a cursor on it. ".
    "Newlines are Ok (as \\n digraph).\n".
    "To erase balloon just clear all text in editing box.");
       }
     );
  my $wBindingsNF = $wProjOptionsNB -> add ( 'wBindingsNF', -label=>'Bindings', -justify=>'left', -state=>'normal', -raisecmd=>sub{&SetProjOptHint("The bind method associates callbacks with X events\n".
  "You can assign more than one bind to same widget")} );

  my ($selBind)=@project_bindings; # we take 1st as default
  my $wBindLB = $wBindingsNF->Listbox(-selectmode=>'single')->
    pack(-anchor=>'nw',-side=>'left',-fill=>'both',-expand=>1);
  $wBindLB->insert('end'=>@project_bindings);
  $wBindLB->bind('<<ListboxSelect>>'=>sub{$selBind=$wBindLB->get('anchor')});
  my $wBindFrm = $wBindingsNF->Frame()->pack(-anchor=>'nw',-side=>'left',-fill=>'y');
  $wBindFrm->LabEntry(-label=>'Bind:',-state=>'readonly',-textvariable=>\$selBind,
    -labelPack=>[-side=>'left',-anchor=>'n'],-justify=>'left')->
    pack(-pady=>10,-padx=>10,-fill=>'x');
  $wBindFrm->Button(-text=>'Create ...',-command=>[\&BindCreate,\$wBindLB,\$selBind])->
    pack(-pady=>10,-padx=>10,-fill=>'x');
  $wBindFrm->Button(-text=>'Delete!',-command=>[\&BindDelete,\$wBindLB,\$selBind])->
    pack(-pady=>10,-padx=>10,-fill=>'x');
  $wBindFrm->Button(-text=>'Read more about Binding ...',-command=>[\&tkpod,'bind'])->
    pack(-pady=>10,-padx=>10,-fill=>'x');
  my $wUserCodeTopFrm=$wUserCodeAfterMFrame->Frame()->pack(-fill=>'x');
  my $wSubNameEntry = $wUserCodeTopFrm->BrowseEntry(-width=>14,
          -variable=>\$selSub,-choices=>\@user_subs)->pack(-side=>'left',-pady=>5,-fill=>'x',-expand=>1);
  my $wButtonsFrame = $wUserCodeTopFrm->Frame()->pack(-side=>'left',-anchor=>'nw');
  $wButtonsFrame->Button(-text=>'create',-command=>[\&UserCodeCreate,\$selSub,\$txtUserCode,$wSubNameEntry])->pack(-side=>'left',-padx=>5);
  $wButtonsFrame->Button(-text=>'change',-command=>[\&UserCodeChange,\$selSub,\$txtUserCode])
    ->pack(-side=>'left',-padx=>5);
  $wButtonsFrame->Button(-text=>'delete',-command=>[\&UserCodeDelete,\$selSub,\$txtUserCode,$wSubNameEntry])->pack(-side=>'left',-padx=>5);
  $wButtonsFrame->Button(-text=>'help...',-command=>[\&tkpod,'callbacks'])->pack(-side=>'left',-padx=>5);
  $txtUserCode=$wUserCodeAfterMFrame->Scrolled(qw/Text -scrollbars oe -height 15 -background white -state normal/,
    -foreground=>'black'#$palette{'-foreground'}
    )->pack(-fill=>'both',-expand=>1);
  my $signature=(@$p_user_subroutines) ?
    shift(@$p_user_subroutines) : '#===vptk end===< DO NOT CODE ABOVE THIS LINE >===';
  map($txtUserCode->insert('end',"$_\n"),@$p_user_subroutines);
  $db->bind('<Key-Return>',undef);
  $wProjOptionsNB->raise($TabToRaise) if $TabToRaise;
  if($sub_select)
  {
    &UserCodeChange(\$selSub,\$txtUserCode);
  }
  $db->resizable(1,0);
  &Coloring($db);
  # show dialog
  my $reply=$db->Show();
  (@$p_user_subroutines)=($signature,@$p_user_subroutines);
  if ($reply eq 'Cancel')
  {
    &undo;
    %IDE_settings = %saved_IDE_settings;
    &SetMainPalette($mw,$IDE_settings{'bg_color'},$IDE_settings{'fg_color'});
    $b->configure(-background=>'lightyellow',-initwait=>550);
    return;
  }

  # apply new options
  %{$pOpt->data} = %new_opt;
  $Project->get('Options')->set('balloon_color',$balloon_bg_color);
  $Project->get('Options')->set('balloon_delay',$balloon_delay);

  if($pOpt->get('fullcode')) {
    (@$p_user_subroutines)=($signature,split("\n",$txtUserCode->get('0.0','end')));
    (@$p_code_before_main)=(split("\n",$txtBeforeMain->get('0.0','end')));
    (@$p_code_before_widgets)=(split("\n",$txtBeforeWidgets->get('0.0','end')));
    (@$p_code_before_tk)=(split("\n",$txtBeforeTk->get('0.0','end')));
  }
  else {
    (@$p_user_subroutines)=();
    (@$p_code_before_main)=();
  }
  
  map(&PushCallback(/sub\s+([^\s\{]+)/),@$p_user_subroutines);

  &changes(1); # can't store undo info so far!
}

sub UserCodeDelete
{
  my ($selSub,$txtUserCode,$wSubNameEntry)=@_;

  my $id = $$selSub;
  $id =~ s/^\\&//;

  unless ($id)
  {
    &ShowDialog(-title=>'Error:',-text=>"Subroutine name empty or illegal!\n",-buttons=>['Continue']);
    return;
  }
  my $arg = $id;
  $arg="\\\&$arg" if $arg=~/^\w/ && $arg!~/^(sub[\s\{]|\[)/;
  unless (grep($arg eq $_, @user_subs))
  {
    &ShowDialog(-title=>'Error:',-text=>"Subroutine '$id' not found!\n",-buttons=>['Continue']);
    return;
  }
  # find definition in text
  $$txtUserCode->SetCursor("0.0");
  $$txtUserCode->FindNext(-forward,-regexp,-nocase,"^sub $id(\$|\\W)");
  if($$txtUserCode->GetTextTaggedWith("sel"))
  {
    # remove it in text
    $$txtUserCode->delete("sel.first","sel.last+1 chars");
    # remove it's name from callbacks
    @callbacks = grep($arg ne $_, @callbacks);
    @user_subs = grep(!/^sub\W/,@callbacks); 
    # update listbox
    $wSubNameEntry->configure(-choices=>\@user_subs);
    $wSubNameEntry->focus();
  }
  else
  {
    &ShowDialog(-title=>'Error:',-text=>"Subroutine '$id' definition not found!\n",-buttons=>['Continue']);
  }
}

sub BindDelete
{
  my ($pLB,$pLE) = @_;
  my $selected = ${$pLB}->get('active');
  # remove from array selected element
  @project_bindings = grep($_ ne $selected, @project_bindings);
  # update listbox
  ${$pLB}->delete(0,'end');
  ${$pLB}->insert('end'=>@project_bindings);
  # update lab-entry
  (${$pLE})=@project_bindings; # we take 1st as default
}

sub PopulateBindDialog
{
  my ($db,$bindSelWidget,$bindSelEvent,$bindSelCallb) = @_;
  my @modifiers = qw/Control Shift Lock Button1 1 Button2 2 Button3 3 Button4 4 Button5 5
    Mod1 M1 Mod2 M2 Mod3 M3 Mod4 M4 Mod5 M5 Alt Double Triple Quadruple/;
  my @event_types = qw/ Activate Destroy Map ButtonPress Button Enter MapRequest
    ButtonRelease Expose Motion Circulate FocusIn MouseWheel CirculateRequest FocusOut Property
    Colormap Gravity Reparent Configure KeyPress Key ResizeRequest
    ConfigureRequest KeyRelease Unmap Create Leave Visibility Deactivate/;
  unshift(@modifiers,'');
  unshift(@event_types,'');
  my ($bindM1, $bindM2, $bindT);
  my ($event_detail);

  my $wBindTopFr = $db -> Frame ( -relief=>'flat' ) -> pack(-anchor=>'nw', -pady=>10, -fill=>'x', -padx=>10);
  my $wBindWidgL = $wBindTopFr -> Label ( -justify=>'left', -textvariable=>$bindSelWidget ) -> pack(-anchor=>'nw', -side=>'left');
  $wBindTopFr -> Label ( -justify=>'left', -text=>"-> bind('" ) -> pack(-anchor=>'nw', -side=>'left');
  my $wBindEvntL = $wBindTopFr -> Label ( -justify=>'left', -textvariable=>\$bindSelEvent ) -> pack(-anchor=>'nw', -side=>'left');
  $wBindTopFr -> Label ( -justify=>'left', -text=>"' =>" ) -> pack(-anchor=>'nw', -side=>'left');
  my $wBindCallbL = $wBindTopFr -> Label ( -justify=>'left', -relief=>'flat', -textvariable=>$bindSelCallb ) -> pack(-anchor=>'nw', -side=>'left');
  $wBindTopFr -> Label ( -justify=>'left', -text=>");" ) -> pack(-anchor=>'nw', -side=>'left');
  my $wBindDlgNB = $db -> NoteBook (  ) -> pack(-fill=>'both',-expand=>1);
  my $wBindW_NBF = $wBindDlgNB -> add ( 'wBindW_NBF', -label=>'Widget', -justify=>'left', -state=>'normal' );
  my $wBindW_LB = $wBindW_NBF -> Scrolled ( 'HList', -scrollbars=>'osoe' ) -> pack(-pady=>8, -fill=>'both', -padx=>8);
  $wBindW_LB->bind('<Button-1>'=>sub{$$bindSelWidget=$wBindW_LB->info('data',$wBindW_LB->infoSelection)});
  map($wBindW_LB->add($_,-text=>(/([^\.]+)$/),-data=>(/([^\.]+)$/))=>@tree);
  my $browsecmd = [\&update_event_var,$bindSelEvent,\$event_detail,\$bindM1,\$bindM2,\$bindT];
  my $wBindE_NBF = $wBindDlgNB -> add ( 'wBindE_NBF', -label=>'Event', -justify=>'left', -state=>'normal' );
  my $wBindEv1_BE = $wBindE_NBF -> BrowseEntry ( -variable=>\$bindM1, -state=>'readonly', -label=>'Modifier1:', -justify=>'left', -labelPack=>[-side=>'left',-anchor=>'n'], -choices=>\@modifiers, -browsecmd=>$browsecmd ) -> pack(-anchor=>'nw', -fill=>'x', -padx=>8);
  my $wBindEv2_BE = $wBindE_NBF -> BrowseEntry ( -variable=>\$bindM2, -state=>'readonly', -label=>'Modifier2:', -justify=>'left', -labelPack=>[-side=>'left',-anchor=>'n'], -choices=>\@modifiers, -browsecmd=>$browsecmd ) -> pack(-anchor=>'nw', -fill=>'x', -padx=>8);
  my $wBindEv3_BE = $wBindE_NBF -> BrowseEntry ( -variable=>\$bindT, -state=>'readonly', -label=>'Type:', -justify=>'left', -labelPack=>[-side=>'left',-anchor=>'n'], -choices=>\@event_types, -browsecmd=>$browsecmd ) -> pack(-anchor=>'nw', -fill=>'x', -padx=>8);
  my $wBindEv4_BE = $wBindE_NBF -> LabEntry ( -label=>'Detail:', -justify=>'left', -labelPack=>[-side=>'left',-anchor=>'n'], -textvariable=>\$event_detail, -validatecommand=>$browsecmd, -validate=>'all' ) -> pack(-anchor=>'nw', -fill=>'x', -padx=>8, -pady=>18 );
  my $wBindC_NBF = $wBindDlgNB -> add ( 'wBindC_NBF', -label=>'Callback', -justify=>'left', -state=>'normal' );
  my $wBindCallb_BE = $wBindC_NBF -> BrowseEntry ( -label=>'Function:', -justify=>'left', -labelPack=>[-side=>'left',-anchor=>'n'], -relief=>'sunken', -variable=>$bindSelCallb, -state=>'normal' ) -> pack(-fill=>'x',-expand=>0);
  # update listbox content respectively
  $wBindCallb_BE->configure(-choices=>\@callbacks);
  return ($wBindW_LB);

}

sub update_event_var
{
  my ($bindSelEvent,$event_detail,$bindM1,$bindM2,$bindT,$ev_d)=@_;
  $ev_d = $$event_detail if scalar(@_)<=7 || ref $ev_d;
  $$bindSelEvent = '<'.join('-', $$bindM1, $$bindM2, $$bindT, $ev_d).'>';
  $$bindSelEvent =~ s/-+/-/g;
  $$bindSelEvent =~ s/^<-/</;
  $$bindSelEvent =~ s/->$/>/;
  1;
}

sub BindCreate
{
  my ($pLB,$pLE) = @_;
  my $new_bind = "'test'=>'<123>'=>\\&kuku";
  # open dialog box and ask for 3 bind components
  my $db = $mw->DialogBox(-title=>'Bind setup',-buttons=>['Ok','Cancel']);
  my ($bindSelCallb,$bindSelEvent,$bindSelWidget);

  &PopulateBindDialog($db,\$bindSelWidget,\$bindSelEvent,\$bindSelCallb);
  $db->resizable(1,0);
  &Coloring($db);
  # show dialog
  my $reply=$db->Show();
  return if $reply eq 'Cancel';
  # on 'Ok' - check that the same is not exist
  # insert new bind into array
  $bindSelWidget =~ s/^.*\.//;
  $new_bind = $bindSelWidget."->bind('$bindSelEvent',$bindSelCallb);";
  &PushCallback($bindSelCallb);
  push(@project_bindings,$new_bind);
  # update listbox
  ${$pLB}->delete(0,'end');
  ${$pLB}->insert('end'=>@project_bindings);
  # update lab-entry
  (${$pLE})=@project_bindings; # we take 1st as default
}

sub UserCodeCreate
{
  my ($selSub,$txtUserCode,$wSubNameEntry)=@_;

  my $id = $$selSub;
  $id =~ s/^\\&//;

  unless ($id)
  {
    &ShowDialog(-title=>'Error:',-text=>"Subroutine name empty or illegal!\n",-buttons=>['Continue']);
    return;
  }
  # check, do we have such sub id?
  # if not - create template in txt-widget
  if(&PushCallback($id))
  {
    $$txtUserCode->insert('end',"\nsub $id\n{\n\n}\n");
    &UserCodeChange($selSub,$txtUserCode);
    @user_subs = grep(!/^sub\W/,@callbacks); 
    # update listbox content respectively
    $wSubNameEntry->configure(-choices=>\@user_subs);
  }
  else
  {
    # say that such sub already defined
    &ShowDialog(-title=>'Error:',-text=>"Subroutine '$id' already defined!\n",-buttons=>['Continue']);
  }
}

# User code routine focus for changes
sub UserCodeChange
{
  my ($selSub,$txtUserCode)=@_;
  my $id = $$selSub;
  $id =~ s/^\\&//;

  unless ($id)
  {
    &ShowDialog(-title=>'Error:',-text=>"Subroutine name empty or illegal!\n",-buttons=>['Continue']);
    return;
  }
  # find routine index in code and place cursor there
  $$txtUserCode->SetCursor("0.0");
  $$txtUserCode->FindNext(-forward,-regexp,-nocase,"^sub $id(\$|\\W)");
  if($$txtUserCode->GetTextTaggedWith("sel"))
  {
    $$txtUserCode->SetCursor("sel.last");
    $$txtUserCode->focus();
  }
  else
  {
    &ShowDialog(-title=>'Error:',-text=>"Subroutine '$id' not found!\n",-buttons=>['Continue']);
  }
}

## clean all project structures
sub file_clean
{
  &struct_new;
  @callbacks=();
  &changes(0);
  @redo=(); @undo=(); # clear undo/redo stacks
  $selected='mw';
  &InitProject($Project);
  &view_repaint; # force repaint!
}

## Create a new project.
sub file_new
{
  # check for save status here!

  return unless &check_changes;

  &file_clean;
  $lastfile='';
  &file_properties if $IDE_settings{'auto_options'};
}

# Create internal project structures defining widgets set
sub struct_new
{
  #________________________________
  # widget section:
  &clear_preview();
  # clean tree widget:
  $tf->delete('all');
  $tf->add('mw',-text=>'mw',-data=>'mw',-image=>WidgetIcon('Frame'));
  #________________________________
  # data section:
  @tree=('mw');
  foreach my $id (keys %descriptor)
  {
    undef %{$descriptor{$id}} if(ref $descriptor{$id});
    delete $descriptor{$id};
  }
  %widgets=();
  @user_auto_vars=();
}

# make widget passed as argument "selected"
sub set_selected
{
  $selected = shift;
  my $display_selected = $selected;
  if(length($display_selected)>40)
  {
    $display_selected = substr($selected,0,20) . '...' . substr($selected,-20)
  }
  $status->configure(-text=>"Selected: $display_selected");
  # highlight respective object:
  return unless defined $widgets{$selected};
  $tf->anchorClear(); $tf->selectionClear();
  $tf->anchorSet($selected); $tf->selectionSet($selected);
  return unless $IDE_settings{'view_blink'}; # return here if no blink
  return if $selected eq 'mw';
  return unless exists $descriptor{&path_to_id($selected)};
  return unless &HaveGeometry($descriptor{&path_to_id($selected)}->{'type'});
  my $sw=$widgets{$selected};
  my $saved=$sw->cget(-background);
  foreach my $color(qw/white black yellow blue/)
  {
    Tk::DoOneEvent(0);$mw->after(20);
    last unless $sw->Exists();
    $sw->configure(-background=>$color);
    Tk::DoOneEvent(0);$mw->after(20);
    last unless $sw->Exists();
    $sw->configure(-background=>$saved);
  }
}

# Mark changes flag and perform respective actions:
# - update visual changes indicator
# - resolve conflicts (if any)
sub changes
{
  $changes=shift;
  $changes_l->configure(-text=> ($changes)?'*':' ');
  if ($changes)
  {
    # @par resolve conflicts:
    # -----------------
    # conflict No 1 - remove Label from Frame with grid sub-widgets
    # (since geometry manager gets mad in such situation)
    #   for each frame widget
    #   get all children id's
    #   get those geometry
    #   remove -label if at least one match 'grid'
    foreach my $elm(@tree)
    {
      my ($id) = ($elm=~/\.([^\.]+)$/);
      next unless $descriptor{$id}->{'type'} eq 'Frame';
      my (@children)=grep(/\.$id\.([^\.]+)$/,@tree);
      next unless @children;
      map {s/.*\.//} @children;
      map {$_=$descriptor{$_}->{'geom'}} @children;
      if ( grep (/grid/,@children) )
      {
        my (%opt)=&split_opt($descriptor{$id}->{'opt'});
        if ($opt{'-label'})
        {
          delete $opt{'-label'};
          $descriptor{$id}->{'opt'} = join(', ',%opt);
        }
      }
    }
    # @par conflict No 2 - for grid-based widgets calculate position 
    # and move interlaced element downward
    #  for each widget:
    #  - get list of children
    #  - if 1st child have 'grid' geometry
    #    - prepare matrix of placement
    #    - foreach child: 
    #      - re-calculate (xmax,ymax) 
    #      - try to store in matrix
    #      - if this cell already "in use" - push it into "conflicts" list
    #    - foreach element in "conflicts" list:
    #      - place it into free space under ymax row
    foreach my $elm(@tree)
    {
      my ($id) = ($elm=~/\.([^\.]+)$/);
      my (@children)=grep(/\.$id\.([^\.]+)$/,@tree);
      if($elm eq 'mw') {
        @children = grep(/^mw.([^\.]+)$/,@tree);
      }
      next if scalar(@children) < 2; # need at least 2 for conflict!
      map {s/.*\.//} @children;
      next unless grep ($descriptor{$_}->{'geom'}=~/grid/,@children);
      # here we've list of widgets with 'grid' geometry
      # 1. For each element:
      # 1.1. calculate (xmax,ymax) using current element (x,y)
      # 1.2. check, does this cell free or not
      # 1.3. if conflict - store it's id in '@conflicts' list
      # 2. For each element in '@conflicts' list
      # 2.1. correct element's (x,y) using 'safe' space after (xmax/ymax)
      my ($x,$y,$xmax,$ymax);
      my @conflicts;
      my @matrix;

      $xmax = $ymax = -1;
      foreach (@children) {
        ($x) = $descriptor{$_}->{'geom'} =~ /-column\W+(\d+)/; # prevented matching -columnspan
        $x = '0' unless $x;
        $xmax = $x if $x > $xmax;
        ($y) = $descriptor{$_}->{'geom'} =~ /-row\W+(\d+)/; # prevented matching -rowspan
        $y = '0' unless $y;
        $ymax = $y if $y > $ymax;
        if($matrix[$y][$x]) { push(@conflicts,$_); }
        else                { $matrix[$y][$x]=$_;  }
      }
      $x = 0; $ymax++;
      foreach (@conflicts) {
        $descriptor{$_}->{'geom'} =~ s/(-column)\D+\d+/$1=>$x/; $x++;
        $descriptor{$_}->{'geom'} =~ s/(-row)\D+\d+/$1=>$ymax/;
        if($x > $xmax) {
          $x = 0; $ymax++;
        }
      }
      if(@conflicts) {
        # inform user about fix:
        &ShowDialog(-title=>"Geometry conflicts!",-bitmap=>'info',-buttons=>['Continue'],
          -text=>join("\n",'Grid cell conflicts resolved for following widgets:',@conflicts));
      }
    }

    &view_repaint;
  }
}

# "Application close" callback
sub abandon
{
  return unless &check_changes;
  exit;
}

# Make sure that changes of current project are saved
# Return result indicating success of save procedure
sub check_changes
{
  if($changes)
  {
    # ask for save
    
    my $reply=&ShowDialog(-bitmap=>'question',
     -text=>"File not saved!\nDo you want to save the changes?",
        -title => "You have some changes", 
        -buttons => ['Save','Don\'t save', 'Cancel']);
    if($reply eq 'Save')
    {
      $reply=&file_save('Save As');
    }
    return 0 if($reply eq 'Cancel');
  }
  return 1; # Ok
}

# Open "file save" dialog box (when needed) and perform save operation.
# return 0 on success and error code otherwise.
# bug: 'Save' does not always save. But 'Save As' works.
sub file_save
{
  my ($type)=shift;
  unless($type eq 'Save As')
  {
    return unless $changes;
  }
  $mw->Busy;
  # open file save dialog box
  my $file = $lastfile;
  $file=~s%.*[/\\]([^/\\]+)$%$1%;
  if(! (-f $lastfile) || ($type eq 'Save As'))
  {
    $file='newfile.pl';
    if($os eq 'win')
    {
      my @types = ( ["Perl files",'.pl'], ["All files", '*'] );
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
    &ShowDialog(-title=>'Error:',-text=>"File $file write - $!\n",-buttons=>['Continue']);
    return 'Cancel';
  }
  else
  {
    &PopulateProject($Project);
    print DATA map ("$_\n",$Project->print);
    close DATA;
  }
  # reset changes flag
  &changes(0);
  return 0;
}

# Open file dialog box and load file if success
sub file_open
{
  return unless &check_changes;

  $mw->Busy;
  # open file save dialog box
  my $file = $lastfile;
  $file=~s%.*[/\\]([^/\\]+)$%$1%;
  if($os eq 'win')
  {
    my @types = ( ["Perl files",'.pl'], ["All files", '*'] );
    $file = $mw->getOpenFile(-filetypes => \@types,
      -initialfile => $file, -defaultextension => '.pl',
      -title=>'file to read');
  }
  else
  {
    $file = $mw->FileSelect(-directory => '.',
      -initialfile => $file, -title=>'file to read')->Show;
  }
  $mw->Unbusy;
  # return 'Cancel' if file not selected
  return 'Cancel' unless($file);
  &file_clean;
  &file_read($file);
}

# read file and convert to internal data
sub file_read 
{
  my ($file)=(@_);
  $lastfile=$file;

  my (@file);

  unless(open (DATA,$file))
  {
    # report error
    &ShowDialog(-title=>'Error:',-text=>"File $file read - $!\n",-buttons=>['Continue']);
    return 'Cancel';
  }
  &struct_read(<DATA>);
  close DATA;
  &view_repaint;
}

## Clipboard operations implementation
#
# 1. Clibpoard data consistency (check for signature line)
# 2. All clipboard operations can be performed on single
#    widget selection (and all it's sub-widgets)
# 3. When placing to clipboard the data must be 'transferred'
#    to root hierarhy level by substitution of 'parent' for
#    selected widget
# 4. While pasting data from clipboard 1st of all must be
#    checked selected (to be inserted) widget type. If it 
#    contradict to paste context - operation cancelled with
#    error box.
# 5. Next check is for possible geometry management conflicts 
#    between widget to be inserted and context. User can
#    choose one of following: 'propagate' | 'adopt' | 'cancel'
# 6. Last check must be done per widget to be inserted:
#    does it's ID conflicting with existing widgets?
#    In case of conflict operation must be cancelled
#    (no ugly automatic names!)

## Copy then delete selected widgets (and its subs). @see edit_copy, edit_delete
sub edit_cut 
{
  return if $selected eq 'mw';
  # store selected:
  &edit_copy;
  # delete selected:
  &edit_delete;
}

## Copy selected widget and its subs.
sub edit_copy
{
  return if $selected eq 'mw';
  my $id=&path_to_id($selected);
  #$mw->clipboardClear();
  #$mw->SelectionClear(-selection => 'CLIPBOARD');
  @main_clipboard=();
  push (@main_clipboard,join('|','#VPTK_W',$descriptor{$id}->{'parent'},$id,
    $descriptor{$id}->{'type'},$descriptor{$id}->{'geom'}));
  # get all IDs of copied widgets:
  my @copy_id=grep(/(^|\.)$id(\.|$)/,@tree);
  map (s#^.*\.##,@copy_id);
  push (@main_clipboard,'#'.join('|',@copy_id));
  grep (push(@main_clipboard,&code_line_print($_)),@copy_id);
  #$mw->clipboardAppend(join("\n",@clipboard));
}

## Paste before/after selected widget.
sub edit_paste
{
  return if $selected eq 'mw';
  my $where = shift || 'before';
  my $id=&path_to_id($selected);
  my @clipboard=@main_clipboard;
  #@clipboard = split(/\n/,$mw->SelectionGet(-selection => 'CLIPBOARD'));
  # check for signature:
  unless ($clipboard[0]=~/^#VPTK_W\|/)
  {
    &ShowDialog(-bitmap=>'error',-text=> "Clipboard is empty or corrupt!");
    return;
  }
  # check type conflict:
  my $parent=$descriptor{$id}->{'parent'};
  $parent = $id if $where eq 'under';
  my $parent_type=$descriptor{$parent}->{'type'};
  $clipboard[0]=~s/^#VPTK_W\|//;
  my ($clp_parent,$clp_id,$clp_type,$clp_geom)=split(/\|/,shift(@clipboard));
  if(
    ($clp_type eq 'NoteBookFrame' && $parent_type ne 'NoteBook') ||
    ($clp_type eq 'Menu' && $parent_type !~ /^(Menubutton|cascade)$/) ||
    ($parent_type ne 'Menu' && $clp_type =~ 
      /^(cascade|command|checkbutton|radiobutton|separator)$/))
  {
    &ShowDialog(-bitmap=>'error',-text=> 
      "Clipboard <-> destination type conflict ($clp_type,$parent_type)!");
    return;
  }
  # check name conflict:
  $clipboard[0]=~s/^#//;
  foreach (split(/\|/,$clipboard[0]))
  {
    if(defined $descriptor{$_})
    {
      &ShowDialog(-bitmap=>'error',
        -text=> "Can't paste $_ from clipboard - this ID already used!");
      return;
    }
  }
  my $reply='';
  # check geometry conflict:
  if($clp_geom)
  {
    my $clp_geom_patt=$clp_geom;
    $clp_geom_patt=~s/\(.*$//;
    # Get brothers, but only those with geometry
    my (@brothers)=grep($descriptor{$_}->{'type'} !~ /packAdjust|Menu/,&tree_get_sons($parent));

    # get their geometry
    map ( $_=$descriptor{$_}->{'geom'} , @brothers );
    if (grep(!/^$clp_geom_patt/,@brothers))
    {
      # if any of brothers does not match:
      # Ask user about possible conflict solution
      # 'Propagate' | 'Adopt' | 'Cancel'
      # return on 'Cancel'
      my $eb = $mw->DialogBox(-title=>'Geometry conflict!',
        -buttons=>[qw/Propagate Adopt Cancel/]);
      $eb->Label(-justify=>'left',-text=>"Geometry <$clp_geom> of clipboard widget conflicts with\n".
      "other sub-widgets of $parent :\n".
      join(' ',grep(!/^$clp_geom_patt/,@brothers)).
      "\n\n   Now you can:\n".
      " Propagate this geometry to neighbor widgets\n".
      " Adopt current widget geometry to it's neighbors\n".
      " or Cancel paste operation")->pack();
      $eb->resizable(1,0);
      &Coloring($eb);
      $reply = $eb->Show();
      return if $reply eq 'Cancel';
    }
  }
  shift(@clipboard);
  $clipboard[0] =~ s/\$($clp_parent)(\W)/\$$parent$2/g; # rename parent for inserted root
  # Save undo information:
  &undo_save();
  # insert here:
  # 1st, calculate insert position
  my $insert_pos = &calc_insert_position($where);
  # then, divide tree into two parts
  my (@save_tree)=splice(@tree,$insert_pos);
  # and put the new contents after 1st part
  &struct_read(@clipboard);
  # and finally - put 2nd part
  push (@tree,@save_tree);
  if ($reply eq 'Propagate')
  {
    foreach (&tree_get_brothers($clp_id)) { $descriptor{$_}->{'geom'}=$descriptor{$clp_id}->{'geom'} }
  }
  if ($reply eq 'Adopt')
  {
    $descriptor{$clp_id}->{'geom'} = $descriptor{(&tree_get_brothers($clp_id))[0]}->{'geom'}
  }
  # repaint tree:
  $tf->delete('all');
  $descriptor{'mw'}->{'type'}='Frame';
  map ( $tf->add($_,-text=>&path_to_id($_),-data=>$_,
    -image=>WidgetIcon($descriptor{&path_to_id($_)}->{'type'})), @tree );
  delete $descriptor{'mw'};
  &changes(1);
  &set_selected($selected);
}

## check are any of erased widgets listed in 'bind array'
# if any - warn and update array
sub check_bind_before_delete
{
  my @widgets_todelete = grep(/$selected/,@tree);
  map(s/.*\.//,@widgets_todelete);
  my @bind_todelete;
  foreach my $w (@widgets_todelete)
  {
    push(@bind_todelete,grep(/^$w.>bind\(/,@project_bindings));
  }
  if(@bind_todelete)
  {
     my $reply = ShowDialog(-title=>'Error',
       -text=>"There are some bindings connected to selected widget(s)",
       -buttons=>['Ok','Dismiss']);
     if($reply eq 'Ok')
     {
       foreach my $b(@bind_todelete)
       {
         @project_bindings = grep($_ ne $b,@project_bindings);
       }
     }
     else
     {
        return 0;
     }
  }
  return 1;
}

## Delete selected widget and its subs.
sub edit_delete
{
  return unless &check_bind_before_delete();
  if ($selected eq 'mw') # say something to user here:
  {
#    &ShowDialog(-title=>'Error',-text=>'Use File->New in order to clear all');
    &file_new;
    return;
  }

  # save current state for undo
  &undo_save();
  # 1. remove internal structures (including sub-widgets)
  foreach my $d (grep(/$selected/,@tree))
  {
    my $id=$d; $id=~s/.*\.//;
    undef %{$descriptor{$id}} if(ref $descriptor{$id});
    delete $descriptor{$id};
  }
  @tree = grep(!/$selected/,@tree);
  # 2. remove from tree
  $tf->delete('entry',$selected);
  &set_selected('mw');
  $tf->selectionSet($selected);
  &changes(1);
}

## Insert new widget.
sub insert
{
  my ($where)=shift; #< 'before' | 'after' | 'subwidget'

  if($selected eq 'mw' && $where ne 'subwidget')
  {
      $mw->Dialog(-title => 'Warning', -buttons => [ 'Ok' ],
                  -text => 'The main window can only have sub widgets. Please use Insert Subwidget.'
                  ) -> Show();
      return;
  }
  # 1. ask for widget type
  my $db=$mw->DialogBox(-title => "Create $where $selected",-buttons=>['Ok','Cancel','New class ...']);
  my @LegalW=@OrdinaryWidgets;
  # determine where insertion point is
  # if it's menu/menubutton/cascade - change LegalW to respective array
  # Menubutton -> Menu
  # Menu,cascade -> cascade,command,checkbutton,radiobutton,separator
  {
    my $parent=&path_to_id($selected);
    $parent = $descriptor{$parent}->{'parent'}
      if($where ne 'subwidget');  # go up one level
    @LegalW=('Menu') 
      if($descriptor{$parent}->{'type'} =~ /^(Menubutton|cascade)$/);
    @LegalW=(qw/cascade command checkbutton radiobutton separator/) 
      if($descriptor{$parent}->{'type'} eq 'Menu');
    if($descriptor{$parent}->{'type'} eq 'NoteBook')
    {
      &do_insert($where,'NoteBookFrame');
      return;
    }
    return 
      if $descriptor{$parent}->{'type'} =~ /^(command|checkbutton|radiobutton|separator)$/;
    return
      if $LegalW[0] eq 'Menu' && &tree_get_sons($parent);
  }
  my $type=$LegalW[0];
  my $f=$db->Frame()->pack(-fill=>'both',-padx=>8,-pady=>18);
  my $reply;
  my $i=0;
  foreach my $lw (@LegalW)
  {
    $f->Radiobutton(-variable=>\$type,-value=>$lw,-text=>$lw)->
      grid(-row=>$i,-column=>0,-sticky=>'w',-padx=>18);
    $f->Label(-image=>WidgetIcon($lw))->
      grid(-row=>$i,-column=>1,-sticky=>'w',-padx=>18);
    $i++;
  }
  my $bindUpSaved = $db->bind('all', '<Key-Up>');
  my $bindDnSaved = $db->bind('all', '<Key-Down>');
  $db->bind('all', '<Key-Up>'   => 'focusPrev');
  $db->bind('all', '<Key-Down>' => 'focusNext');
  $db->resizable(1,0);
  &Coloring($db);
  $reply=$db->Show();
  # un-bind here:
  $db->bind('all', '<Key-Up>'   => $bindUpSaved);
  $db->bind('all', '<Key-Down>' => $bindDnSaved);

  system("$path/wizard_vptk_w.pl") if $reply eq 'New class ...';
  return if $reply ne 'Ok';
  &do_insert($where,$type);
}

## return position of widget in hierarchy tree (according to ID)
sub index_of
{
  my $id=shift;
  my $i=0;

  while ($tree[$i] !~ /(^|\.)$id$/) { $i++ };
  return $i;
}

sub calc_insert_position
{
  my ($where) = @_;

  my $i=&index_of($selected);
  my $j=$i+1;
  $j=$i if $where eq 'before';
  if($where eq 'subwidget' || $where eq 'under') # insert after last sub-entry
  {
    while($tree[$j] =~ /(^|\.)$selected(\.|$)/) { $j++ }
  }
  return $j;
}

# insert widget into current project
sub do_insert
{
  my ($where,$type)=@_;
  # save current state for undo
  &undo_save();
  # 2. Find selected element index in @tree
  my $j = &calc_insert_position($where);
  my $id=&generate_unique_id($type);
  # Ask user for human-readable name here:
  return unless ($id=&ask_new_id($id,$type));
  my $parent=&path_to_id($selected);
  $parent = $descriptor{$parent}->{'parent'}
    if($where ne 'subwidget');  # go up one level
  # 3. Create descriptor
  my ($insert_path)=grep(/(^|\.)$parent$/,@tree);
  $insert_path='mw' unless $insert_path;
  my @w_opt=(); 
  
  # default values:
  my $widget_attr = EditorProperties($type);
  foreach my $k(keys %$widget_attr)
  {
    # text fields
    next if $k =~ 
      /^-(bitmap|accelerator|show|command|createcmd|raisecmd|textvariable|variable|onvalue|offvalue)$/;
    push(@w_opt,"$k, $id") if($widget_attr->{$k}=~/text/);
  }
  # Set default attributes for known widgets:
  my $default_params = DefaultParams($type);
  push(@w_opt, @$default_params);

  my $geom='';
  if (&HaveGeometry($type))
  {
    # resolving geometry conflicts:
    # get geometry from 'brothers'
    my (@brothers)=&tree_get_sons($parent);
    ($geom)=$descriptor{$brothers[0]}->{'geom'};
    $geom='pack()' unless $geom; # default geometry if no 'brothers'
  }
  # Add data to internal structures according to gathered parameters:
  $descriptor{$id}=&descriptor_create($id,$parent,$type,join(', ',@w_opt),$geom);
    
  splice(@tree,$j,0,"${insert_path}.$id");

  # 4. Update display tree
  my $image =  WidgetIcon($type);
  if($where eq 'subwidget')
  {
    $tf->add("${insert_path}.$id",-text=>$id,
      -data=>"${insert_path}.$id",-image=>$image);
  }
  else
  {
    $tf->add("${insert_path}.$id",-text=>$id,-data=>"${insert_path}.$id",
      -image=>$image,"-$where"=>$selected)
  }
  
  # For menu-related elements automatically create 'Menu':
  if($type =~ /^(Menubutton|cascade)$/)
  {
    $parent=$id;
    $type='Menu';
    $id=&generate_unique_id($type);
    my $default_params = DefaultParams($type);
    $descriptor{$id}=&descriptor_create($id,$parent,$type,join(', ',@$default_params),'');
    splice(@tree,$j+1,0,"${insert_path}.$parent.$id");
    $tf->add("${insert_path}.$parent.$id",-text=>$id,
      -data=>"${insert_path}.$parent.$id",-image=>WidgetIcon($type));
  }
  &changes(1);
}

# rename widget
sub rename
{
  my $old_id=&path_to_id($selected);
  my $id=$old_id;
  return if $id eq 'mw';
  $id=&ask_new_id($id,$descriptor{$id}->{'type'});
  return unless $id;
  
  # save current state for undo
  &undo_save();
  # Read generated program and globally substitute $old_id with new one
  my (@program)=&code_print();
  map (s/\$($old_id)(\W)/\$$id$2/g,@program);
  &struct_new();
  &struct_read(@program);
  &view_repaint;
  &changes(1);
  $selected=$id;
}

sub ask_new_id
{
  my ($id,$type)=(@_);
  do
  {
    my $db=$mw->DialogBox(-title=>"Name for $type widget",-buttons=>['Proceed','Cancel']);
    $db->LabEntry(-textvariable=>\$id,-labelPack=>[-side=>'left',-anchor=>'w'],
      -label=>'Type UNIQUE and CORRECT name ')->pack(-pady=>20,-padx=>30);
    $db->Label(-text=>"The field 'widget name' is\n".
      "a name of variable that associated\n".
      "with this widget in your project.",-justify=>'left')->pack(-pady=>10);
    $db->resizable(1,0);
    &Coloring($db);
    return 0 if($db->Show() eq 'Cancel');
  }
  while(defined $descriptor{$id} || $id=~/\W/);
  return $id;
}

sub generate_unique_id
{
  my $type=shift;
  my $id;
  do
  {
    $obj_count++; $id = sprintf("w_${type}_%03.3d",$obj_count);
  }
  while(defined $descriptor{$id});

  return $id;
}

sub PopulateBalloonDialog
{
  my ($wBlDialog) = @_;
  my $tPromptMessage;
  my $wBlnEntry; # we return a pointer to main entry in this tab, allowing main frame to focus on it
  my @list = grep($_ ne 'mw',@tree);
  # replace with exact "can have balloon" flag - TBD
  @list = grep( &HaveGeometry($descriptor{&path_to_id($_)}->{'type'}),@list );
  my $selected_widget_for_balloon = $selected;
  $selected_widget_for_balloon = $list[0] if $selected eq 'mw'; 
  my $id=$selected_widget_for_balloon; $id=~s/.*\.//;
  $selected_widget_for_balloon = $list[0] if !$id ||
    ($id && !&HaveGeometry($descriptor{$id}->{'type'}));
  $id=$selected_widget_for_balloon; $id=~s/.*\.//;
  if ( $id eq 'mw' || !$selected_widget_for_balloon || 
  # replace with exact "can have balloon" flag - TBD
      !&HaveGeometry($descriptor{$id}->{'type'}) )
  {
    $wBlDialog->Label(-text=>"No balloons to edit")->pack(-pady=>10);
    return;
  }
  my $d=$descriptor{$id};
#  return unless &HaveGeometry($d->{'type'}); 
  my $lf;
  $tPromptMessage="Balloon for widget $id:";
  $lf=$wBlDialog->Scrolled('Listbox',-scrollbars=>'osoe')->pack(-side=>'left',-fill=>'both',-expand=>1);
  $lf->insert('end'=>@list);
  my $sindex=0;
  for(my $i=0;$i<=$#list;$i++){if($list[$i] eq $selected_widget_for_balloon){$sindex=$i;last;}};
  $lf->selectionSet($sindex);
  $lf->bind('<<ListboxSelect>>'=>
      sub
      {
        $selected_widget_for_balloon=$lf->get($lf->curselection);
        $id = $selected_widget_for_balloon; $id=~s/.*\.//;
        $tPromptMessage="Balloon for widget $id:";
        $d=$descriptor{$id};
	$wBlnEntry->configure(-textvariable=>\$d->{'wballoon'});
      });
# Save undo information:
  &undo_save();
  my $rf=$wBlDialog->Frame()->pack(-side=>'left',-padx=>5,-pady=>5,-anchor=>'nw');
  $rf->Label(-textvariable=>\$tPromptMessage,-justify=>'left')->pack(-pady=>10);
  $wBlnEntry=$rf->Entry(-textvariable=>\$d->{'wballoon'})->pack(-pady=>5,-fill=>'x');
  $rf->Button(-text=>'Read more about Balloons ...',-command=>[\&tkpod,'Balloon'])->pack(-pady=>7);
  my $wBalloonGeneralFrm = $rf->Frame()->pack(-fill=>'x',-pady=>7);
  $wBalloonGeneralFrm->Label(-text=>'Delay: ')->pack(-side=>'left');
  &NumEntry($wBalloonGeneralFrm,-textvariable=>\$balloon_delay,
      -width=>4,-minvalue=>0)->pack(-side=>'left');
  &ColorPicker($wBalloonGeneralFrm,'Balloon background',\$balloon_bg_color);
  return $wBlnEntry;
}

# Edit selected widget's balloon
sub edit_balloon { &file_properties('balloon'); }

sub edit_bindings { &file_properties('bind'); }

## open dialog for widget's properties editing
sub edit_properties
{
  return unless $selected;
re_enter:
  my $id=$selected; $id=~s/.*\.//;
  if ($id eq 'mw') {
    &file_properties();
    return;
  }
  return unless defined $descriptor{$id};
  my $d=$descriptor{$id};
  
  return if $d->{'type'} eq 'separator';
  my $pr = EditorProperties($d->{'type'});
  return unless keys %$pr;
  
  my @frm_pak=qw/-side left -fill both -expand 1 -padx 5 -pady 5/;
  my @pl=qw/-side left -padx 5 -pady 5/;
  
  my $db=$mw->DialogBox(-title=>"Properties of $id",-buttons=>['Accept','Cancel']);
  my $fbl=$db->LabFrame(-labelside=>'acrosstop',-label=>'Help')
    ->pack(-side=>'bottom',-anchor=>'s',-pady=>5);
  my $bl=$fbl->Label(-height=>6,-width=>80,-justify=>'left')->pack();
  $fbl->packForget unless $IDE_settings{'hint_msg'};

  my %val;
  my (%lpack)=();
  my @user_vars_for_edit = map("\\\$$_",@user_auto_vars);
  if (keys %$pr)
  {
    my $db_lf=$db->LabFrame(-labelside=>'acrosstop',-label=>"Widget ".$d->{'type'}." options:")
      ->pack(@frm_pak);
    my $db_lft = $db_lf->Scrolled('Tiler', -columns => 1, -scrollbars=>'oe')
      ->pack;
    (%val)=&split_opt($d->{'opt'});
    my @right_pack=(qw/-side right -padx 7/);
    foreach my $k(sort keys %$pr)
    {
      my $f = $db_lft->Frame(); $db_lft->Manage( $f );
      $f->Label(-text=>$k)->pack(-padx=>7,-pady=>10,-side=>'left');
      &cnf_dlg_balloon($bl,$f,$k);
      if($pr->{$k} eq 'color')
      {
        &ColorPicker($f,'Color',\$val{$k},1);
      }
      elsif($pr->{$k} eq 'float')
      {
        $f->Button(-text=>'+',-command=>sub{($val{$k})++})
          ->pack(@right_pack);
        $f->Entry(-textvariable=>\$val{$k},-width=>4)
          ->pack(-side=>'right');
        $f->Button(-text=>'-',-command=>sub{($val{$k})--;})
          ->pack(@right_pack);
      }
      elsif($pr->{$k} eq 'int+')
      {
	&NumEntry($f,-textvariable=>\$val{$k},
          -width=>4,-minvalue=>0)->pack(@right_pack);
      }
      elsif($pr->{$k} eq 'variable')
      {
        # add list of choises
        $f->BrowseEntry(-variable=>\$val{$k},-choices=>\@user_vars_for_edit)->pack(@right_pack);
      }
      elsif($pr->{$k} eq 'text')
      {
        if($d->{'type'} !~ /^(Frame|command|radiobutton|checkbutton|cascade)$/)
        {
          $val{$k}=$id if ! $val{$k} && $k !~
            /^-(accelerator|show|command|textvariable|bitmap|variable|onvalue|offvalue)$/;
        }
        $f->Entry(-textvariable=>\$val{$k})->pack(@right_pack);
      }
      elsif($pr->{$k} eq 'callback')
      {
        $f->Button(-text=>'Code...',-command=>
          sub {
            $db->{'SubWidget'}->{'B_Accept'}->invoke();
            $mw->after(10=>[\&file_properties,'callbacks'=>$val{$k}]);
            }
          )->pack(-padx=>7,-pady=>10,-side=>'right');
        $f->BrowseEntry(-variable=>\$val{$k},-width=>14,
          -choices=>\@callbacks)->pack(@right_pack);
      }
      elsif($pr->{$k} eq 'justify')
      {
        $val{$k}='left' unless $val{$k};
        my $mnb = $f->Menubutton(-underline=>0,-relief=>'raised',
          -textvariable=>\$val{$k}, -direction =>'below')->pack(@right_pack);
        my $mnu = $mnb->menu(qw/-tearoff 0/); $mnb->configure(-menu => $mnu);
        foreach my $r(qw/left center right/)
        {
          $mnu->command(-label=>$r,-image=>$pic{"justify_$r"},
            -command=>sub{$val{$k}=$r;});
        }
      }
      elsif($pr->{$k} eq 'relief')
      {
        $val{$k}='raised' unless $val{$k};
        my $mnb = $f->Menubutton(-underline=>0,-relief=>$val{$k},-borderwidth=>4,
          -textvariable=>\$val{$k}, -direction =>'below')->pack(@right_pack);
        my $mnu = $mnb->menu(qw/-tearoff 0/); $mnb->configure(-menu => $mnu);
        foreach my $r(qw/raised sunken flat ridge solid groove/)
        {
          $mnu->command(-label=>$r,-image=>$pic{"rel_$r"},
            -command=>sub{$val{$k}=$r;$mnb->configure(-relief=>$r)});
        }
      }
      elsif($pr->{$k} eq 'anchor')
      {
        &AnchorMenu($f,\$val{$k},'')->pack(@right_pack);
      }
      elsif($pr->{$k} eq 'side')
      {
        &SideMenu($f,\$val{$k},'')->pack(@right_pack);
      }
      elsif($pr->{$k} =~ /^bitmap/)
      {
        $val{$k}='' unless $val{$k};
        my $menu='|gray12|gray25|gray50|gray75|hourglass|info|error|warning|questhead|question|Tk';
        # show bitmaps in menubutton
        my $mnb = $f->Menubutton(-underline=>0,-relief=>'raised',-bitmap=>$val{$k},
          -textvariable=>\$val{$k}, -direction =>'below')->pack(@right_pack,-ipadx=>5);
        my $mnu = $mnb->menu(qw/-tearoff 0/); $mnb->configure(-menu => $mnu);
        my $i=0;
        foreach my $r(split(/\|/,$menu))
        {
          $mnu->command(-label=>$r,-bitmap=>$r,-columnbreak=>(($i) % 5)?0:1,
            -command=>sub{$val{$k}=$r;$mnb->configure(-bitmap=>$r)});
          $i++;
        }
      }
      elsif($pr->{$k} =~ /^menu\(/)
      {
        my $menu=$pr->{$k};
        $menu=~s/.*\(//;$menu=~s/\)//;
        if(split('\|',$menu)>2)
        {
          $f->Optionmenu(-options=>[split('\|',$menu)],-textvariable=>\$val{$k})
            ->pack(@right_pack);
        }
        else
        {
          my ($on,$off)=split('\|',$menu);
          $val{$k}=$on unless $val{$k};
          $f->Button(-textvariable=>\$val{$k},-relief=>'flat',
            -command=>sub{$val{$k}=($val{$k} eq $on)?$off:$on;})->pack(@right_pack);
        }
      }
      elsif($pr->{$k} eq 'lpack')
      {
        $val{$k}=~s/[\[\]']//g;
        (%lpack)=&split_opt($val{$k});
        $f->Optionmenu(-options=>[qw/n ne e se s sw w nw/],
          -textvariable=>\$lpack{'-anchor'})->pack(@right_pack);
        $f->Optionmenu(-options=>[qw/left top right bottom/],
          -textvariable=>\$lpack{'-side'})->pack(@right_pack);
      }
      elsif($pr->{$k} eq 'scrolled')
      {
        my ($scl_vert,$scl_hor);
        ($scl_vert) = ($val{$k}=~/(o?[ns])/); 
        ($scl_hor)  = ($val{$k}=~/(o?[we])/); $val{'-scrolled'}=$val{$k}ne'';
        $f->Optionmenu(-options=>['',qw(w e ow oe)],-textvariable=>\$scl_hor,
           -command=>sub{$val{$k} = $scl_vert . $scl_hor; $val{'-scrolled'}=$val{$k}ne'';})
            ->pack(@right_pack);
        $f->Optionmenu(-options=>['',qw(s n os on)],-textvariable=>\$scl_vert,
           -command=>sub{$val{$k} = $scl_vert . $scl_hor; $val{'-scrolled'}=$val{$k}ne'';})
            ->pack(@right_pack);
        $f->Checkbutton(-text => 'enabled',
            -relief => 'solid',-variable=>\$val{'-scrolled'},-borderwidth=>0,
            -command => sub{ 
                if($val{'-scrolled'}){$scl_vert='s';$scl_hor='e'}
                else        {$scl_vert=$scl_hor=''} 
                $val{$k} = $scl_vert . $scl_hor;
              }
            )->pack(@right_pack);
      }
      elsif($pr->{$k} eq 'sticky') 
      {
        my %st;
        foreach my $s (qw/n s e w/)
        {
          $st{$s}=grep(/$s/,$val{$k});
          $f->Checkbutton(-text=>$s,-variable=>\$st{$s},
              -command => sub{$val{$k}=~s/$s//g;$val{$k}.=$s if $st{$s}})
            ->pack(@right_pack);
        }
      }
    }
    foreach (0 .. 9-scalar(keys %$pr))
    {
      $db_lft->Manage( $db_lft->Frame() );
    }
  }
  my ($geom_type,$geom_opt,$n);
  my (%g_val);
  my (@brothers);
  # geometry part
  if ($d->{'geom'})
  {
    my $db_rf=$db->LabFrame(-labelside=>'acrosstop',-label=>'Widget geometry:')
      ->pack(@frm_pak); # define right frame
    ($geom_type,$geom_opt)=split('[)(]',$d->{'geom'}); # get type and options
    (%g_val)=&split_opt($geom_opt); # get geometry option values
    $n = $db_rf->NoteBook( -ipadx => 6, -ipady => 6 )
      ->pack(qw/-expand yes -fill both -padx 5 -pady 5 -side top/);

    my $g_pack = $n->add('pack', -label => 'pack', -underline => 0);
    my $g_grid = $n->add('grid', -label => 'grid', -underline => 0);
    my $g_place = $n->add('place', -label => 'place', -underline => 1);

    # pack options:
    {
      &cnf_dlg_balloon($bl,$g_pack->Label(-text=>'-side',-justify=>'left')->
        grid(-row=>0,-column=>0,-sticky=>'w',-padx=>8),'-side');
      &SideMenu($g_pack,\$g_val{'-side'},$bl)->grid(-row=>0,-column=>1,-pady=>4);
    }
    {
      &cnf_dlg_balloon($bl,$g_pack->Label(-text=>'-anchor',-justify=>'left')->
        grid(-row=>1,-column=>0,-sticky=>'w',-padx=>8),'-anchor');
      &AnchorMenu($g_pack,\$g_val{'-anchor'},$bl)->grid(-row=>1,-column=>1,-pady=>4);
    }
    {
      &cnf_dlg_balloon($bl,$g_pack->Label(-text=>'-fill',-justify=>'left')->
        grid(-row=>2,-column=>0,-sticky=>'w',-padx=>8),'-fill');
      my $mnb = $g_pack->Menubutton(-direction=>'below')->grid(-row=>2,-column=>1,-pady=>4);
      &cnf_dlg_balloon($bl,$mnb,'-fill');
      my $mnu = $mnb->menu(qw/-tearoff 0/); $mnb->configure(-menu => $mnu);
      foreach my $r('','x','y','both')
      {
        $mnu->command(-label=>$r,-image=>map_pic('fill',$r),-columnbreak=>($r eq 'x'),
          -command=>sub{$g_val{'-fill'}=$r;$mnb->configure(-image=>map_pic('fill',$r))});
        $mnb->configure(-image=>map_pic('fill',$r)) if($r eq $g_val{'-fill'});
      }
    }
    {
      &cnf_dlg_balloon($bl,$g_pack->Label(-text=>'-expand',-justify=>'left')->
        grid(-row=>3,-column=>0,-sticky=>'w',-padx=>8),'-expand');
      &cnf_dlg_balloon($bl,$g_pack->
        Button(-textvariable=>\$g_val{'-expand'},-relief=>'flat',-command=>
	 sub{$g_val{'-expand'}=1-$g_val{'-expand'}})->grid(-row=>3,-column=>1,-pady=>4),'-expand');
	
    }
    my $i=0;
    foreach my $k(qw/-ipadx -ipady -padx -pady/)
    {
      $i++;
      &cnf_dlg_balloon($bl,$g_pack->Label(-text=>$k,-justify=>'left')->
        grid(-row=>3+$i,-column=>0,-sticky=>'w',-padx=>8),$k);
      my $f=$g_pack->Frame()->grid(-row=>3+$i,-column=>1,-pady=>4);
      &cnf_dlg_balloon($bl,$f,$k);
      &NumEntry($f,-textvariable=>\$g_val{$k},-width=>4,
        -minvalue=>0)->pack(-side=>'right');
    }
  
    # geometry: grid
    {
      &cnf_dlg_balloon($bl,$g_grid->Label(-text=>'-sticky',-justify=>'left')->
        grid(-row=>0,-column=>0,-sticky=>'w',-padx=>8),'-sticky');
      my $f=$g_grid->Frame()->grid(-row=>0,-column=>1,-pady=>4);
      &cnf_dlg_balloon($bl,$f,'-sticky');
      my %st;
      foreach my $s (qw/n s e w/)
      {
        $st{$s}=grep(/$s/,$g_val{'-sticky'});
        $f->Checkbutton(-text=>$s,-variable=>\$st{$s},
          -command => sub{$g_val{'-sticky'}=~s/$s//g;$g_val{'-sticky'}.=$s if $st{$s}})
          ->pack(-side=>'left');
      }
    }
    my $i=1;
    foreach my $k(qw/-column -row -columnspan -rowspan -ipadx -ipady -padx -pady/)
    {
      &cnf_dlg_balloon($bl,$g_grid->Label(-text=>$k,-justify=>'left')->
        grid(-row=>$i,-column=>0,-sticky=>'w',-padx=>8),$k);
      my $f=$g_grid->Frame()->grid(-row=>$i,-column=>1,-pady=>4);
      &cnf_dlg_balloon($bl,$f,$k);
      &NumEntry($f,-textvariable=>\$g_val{$k},-width=>4,
        -minvalue=>($k=~/(-column|-row)$/)?0:1)->pack(-side=>'right');
      $i++;
    }

    # geometry: place
    my $i=0;
    foreach my $k(qw/-height -width -x -y -relheight -relwidth -relx -rely/)
    {
      &cnf_dlg_balloon($bl,$g_place->Label(-text=>$k,-justify=>'left')->
        grid(-row=>$i,-column=>0,-sticky=>'w',-padx=>8),$k);
      my $f=$g_place->Frame()->grid(-row=>$i,-column=>1,-pady=>4);
      &cnf_dlg_balloon($bl,$f,$k);
      &NumEntry($f,-textvariable=>\$g_val{$k},-width=>4,
        -minvalue=>0)->pack(-side=>'right');
      $i++;
    }
  
    $n->raise($geom_type);

  }
  # bind balloon message + help on click
  $bl->bind('<Enter>',
    sub{$bl->configure(-text=>"Click here to get help about current widget\n".
      "by perldoc utility.\n\n".
      ($n?"Right-click here for current geometry manager help":''))});
  $bl->bind('<Leave>',
    sub{$bl->configure(-text=>'')});
  $bl->bind('<1>',[\&tkpod,$id]);
  $bl->bind('<3>',sub{&tkpod($n->raised())}) if $n;
  $db->resizable(0,0);
  &Coloring($db);
  my $reply=$db->Show();
  return if($reply eq 'Cancel');
  if (keys %$pr)
  {
    $val{'-labelPack'}="[-side=>'$lpack{'-side'}',-anchor=>'$lpack{'-anchor'}']"
      if %lpack;
  }
  if ($d->{'geom'})
  {
    $geom_type=$n->raised();
    # check for geometry conflicts here:
    # find all 'brothers' for current widget
    (@brothers)=grep($descriptor{$_}->{'type'} !~ /packAdjust|Menu/,&tree_get_brothers($id));
    # get their geometry
    map ( $_=$descriptor{$_}->{'geom'} ,@brothers);
    # if any of brothers does not match:
    # Ask user about possible conflict solution
    # 'Propagate' | 'Adopt' | 'Back' | 'Cancel'
    # go to start on 'Back'
    # return on 'Cancel'
    # otherwise - fix geometry respectively after 'undo_save'
    if (grep(!/^$geom_type/,@brothers))
    {
      # we have conflict with one of the brothers
      my $eb = $mw->DialogBox(-title=>'Geometry conflict!',
        -buttons=>[qw/Propagate Adopt Back Cancel/]);
      $eb->Label(-justify=>'left',
        -text=>"Geometry <$geom_type> for widget $id conflicts with\n".
        "other sub-widgets of ".$descriptor{$id}->{'parent'}." :\n".
        join(' ',grep(!/^$geom_type/,@brothers)).
        "\n\n   Now you can:\n".
        " Propagate this geometry to neighbor widgets\n".
        " Adopt current widget geometry to it's neighbors\n".
        " return Back to properties window\n".
        " or Cancel your changes and exit properties window")->pack();
      $eb->resizable(1,0);
      &Coloring($eb);
      $reply = $eb->Show();
      return if $reply eq 'Cancel';
      goto re_enter if $reply eq 'Back';
    }
  } 
  # save current state for undo
  &undo_save();
  if (keys %$pr)
  {
    foreach my $k( keys %val)
    {
      delete $val{$k}
        if $pr->{$k} eq 'scrolled' && !$val{'-scrolled'};
      $val{$k} =~ tr/,/./ unless $k eq '-labelPack';
      if($k =~/^-(showvalue|tearoff|indicatoron|underline)$/)
      {
        delete $val{$k} if $val{$k}=~/^\s*$/;
      }
      else
      {
        delete $val{$k} unless $val{$k};
      }
      # if callback - try to store in @callbacks array
      if($pr->{$k} eq 'callback')
      {
        &PushCallback($val{$k});
      }
      if($pr->{$k}=~/variable/)
      {
        # store user-defined variable in array
        my $tval = $val{$k};
        my ($user_var)=($tval=~/\\\$(\w+)/);
        unless ($user_var)
        {
          $tval=~/\$(\w+)/; # alternate name extraction
          ($user_var)=$1;
        }
        push(@user_auto_vars,$user_var)
          if $user_var && ! grep($_ eq $user_var,@user_auto_vars);
      }
    }
    $d->{'opt'}=join(', ',%val);
  }
  if ($d->{'geom'})
  {
    foreach my $k(keys %g_val)
    {
      if($k =~/^(-row|-column)$/)
      {
        $g_val{$k}=0 if $g_val{$k}=~/^\s*$/;
      }
      else
      {
        delete $g_val{$k} unless $g_val{$k};
      }
      delete $g_val{$k} unless grep($k eq $_,@{$w_geom{$geom_type}})
    }
    $geom_opt=join(',',%g_val);
    $d->{'geom'}=$geom_type."($geom_opt)";
    if ($reply eq 'Propagate')
    {
      (@brothers)=&tree_get_brothers($id);
      foreach (@brothers) { $descriptor{$_}->{'geom'}=$d->{'geom'} }
    }
    if ($reply eq 'Adopt')
    {
      $d->{'geom'} = $descriptor{(&tree_get_brothers($id))[0]}->{'geom'}
    }
  }
  &changes(1);
}

# store callback name(s) in global array "@callbacks"
# (if not already exist)
sub PushCallback
{
  my (@arg)=@_;
  my $count = 0;
  foreach my $arg (@arg)
  {
    next unless $arg;
    $arg="\\\&$arg" if $arg=~/^\w/ && $arg!~/^(sub[\s\{]|\[)/;
    unless (grep($arg eq $_, @callbacks))
    {
      push(@callbacks,$arg);
      $count++;
    }
  }
  return $count;
}

# display POD help window (paltform-dependent)
sub tkpod
{
  my $id=shift;
  $id=shift if ref $id; # for callbacks with editor widget refs
  $id=$selected unless $id; # default if no argument
  $id=~s/.*\.//; # clean up when 'selected' used
  my $widget='';
  my $hid = TkClassName($descriptor{$id}->{'type'});
  $widget = $hid if $hid;
  $widget=$id if $id=~
    /^(grid|place|pack|overview|options|option|tkvars|grab|bind|bindtags|callbacks|event|Balloon)$/;
  $widget = 'MainWindow' if $id eq 'mw';
  $widget = "Tk::$widget" unless $widget =~ /^Tk::/;
  $mw->Busy;
  my $pod_util = $IDE_settings{'perldoc'};
  my $PATH = $ENV{'PATH'};
  my ($TkPATH) = $INC{'Tk.pm'} =~ m#^(.*)/#;
  my $perl = $pOpt->get('perl executable');
  my $path_delimiter = ($perl =~ /:/)?';':':';
  $perl =~ s#[/\\].*##;
  $ENV{'PATH'} .= $path_delimiter . $TkPATH;
  $ENV{'PATH'} .= $path_delimiter . $perl;
  system("$pod_util $widget &");
  $ENV{'PATH'} = $PATH;
  $mw->Unbusy;
}

# Create visual object for "side" property editing
sub SideMenu
{
  my ($where,$pvar,$balloon)=(@_);
  my $mnb = $where->Menubutton(-direction=>'below',-cursor=>'left_ptr');
  &cnf_dlg_balloon($balloon,$mnb,'-side')
   if $balloon;
  my $mnu = $mnb->menu(qw/-tearoff 0/); $mnb->configure(-menu => $mnu);
  foreach my $r('','left','bottom','top','right')
  {
    my $break=0;
    $break=1 if $r =~ /left|top/;
    $mnu->command(-label=>$r,-image=>map_pic('side',$r),-columnbreak=>$break,
      -command=>sub{$$pvar=$r;$mnb->configure(-image=>map_pic('side',$r))});
    $mnb->configure(-image=>&map_pic('side',$r)) if($r eq $$pvar);
  }
  return $mnb;
  # end SideMenu
}

# Create visual object for "anchor" property editing
sub AnchorMenu
{
  my ($where,$pvar,$balloon)=(@_);
  my $mnb = $where->Menubutton(-direction=>'below',-cursor=>'left_ptr');
  &cnf_dlg_balloon($balloon,$mnb,'-anchor') 
   if $balloon;
  my $mnu = $mnb->menu(qw/-tearoff 0/); $mnb->configure(-menu => $mnu);
  foreach my $r('','nw','w','sw','n','center','s','ne','e','se')
  {
    my $break=0;
    $break=1 if $r =~ /^n/; # break before North pole ;-)
    $mnu->command(-label=>$r,-image=>&map_pic('anchor',$r),-columnbreak=>$break,
      -command=>sub{$$pvar=$r;$mnb->configure(-image=>&map_pic('anchor',$r))});
    $mnb->configure(-image=>&map_pic('anchor',$r)) if($r eq $$pvar);
  }
  return $mnb;
}

# Structures hadling:
sub path_to_id
{
  return (split /\./,shift)[-1];
}

sub tree_get_sons
{
  my $parent=shift;
  my @sons;
  
  foreach my $widget(grep (/(^|\.)$parent\.[^\.]+$/,@tree))
  {
    my $wid=$widget;
    $wid =~ s/.*\.//;
    push(@sons,$wid);
  }
  return @sons;
}

sub tree_get_brothers
{
  my ($id)=(@_);
  my ($parent)=$descriptor{$id}->{'parent'};
  return grep(!/^$id$/,&tree_get_sons($parent));
}

sub cnf_dlg_balloon
{
  my ($bln,$w,$key)=(@_);
  return unless defined $cnf_dlg_balloon{$key};
  $w->bind("<Enter>",sub{$bln->configure(-text=>$cnf_dlg_balloon{$key})});
  $w->bind("<Leave>",sub{$bln->configure(-text=>'')});
}

sub map_pic
{
  my ($name,$x)=@_;
  my $p="${name}_$x"; 
  return $pic{'undef'} unless defined $pic{$p};
  return $pic{$p};
}

############################################################
#                   Undo/Redo section
############################################################
sub undo_save
{
  @redo=(); push(@undo,join("\n",&code_print()));
}

sub redo
{
  return unless @redo;
  my $sel_save=$selected;
  push(@undo,join("\n",&code_print())); # undo <= current
  &struct_new();
  &struct_read(split("\n",pop(@redo)));
  &view_repaint;
  $sel_save='mw' unless defined $widgets{$sel_save};
  &set_selected($sel_save);
}

sub undo
{
  return unless @undo;
  my $sel_save=$selected;
  # clear current design and restore from backup:
  push(@redo,join("\n",&code_print())); # redo <= current
  &struct_new();
  &struct_read(split("\n",pop(@undo)));
  &view_repaint;
  $sel_save='mw' unless defined $widgets{$sel_save};
  &set_selected($sel_save);
}

###############################################
#        Generated code handling section
###############################################

sub code_print
{
  my @code=();
  foreach my $element(@tree)
  {
    my $code=&code_line_print($element);
    next unless $code;
    push (@code,$code);
  }
  return @code;
}

## Generate code for specified element.
sub code_line_print
{
  my $code;
  my $id=&path_to_id(shift);
  
  return '' unless defined $descriptor{$id};
  return '' if $id eq 'mw';
  my $d=$descriptor{$id};
  my $my='';
  $my = 'my ' if $pOpt->data->{'strict'};
  my $postconfig='';
  $postconfig=' $'.$d->{'parent'}."->configure(-menu=>\$$id);"
    if $d->{'type'} eq 'Menu';
  my $geom='';
  $geom = ' -> '.&quotate($d->{'geom'})
    if &HaveGeometry($d->{'type'});
  my $parent=$d->{'parent'};
  $parent = $descriptor{$parent}->{'parent'}
    if $descriptor{$parent}->{'type'} eq 'cascade';
  my $type=$d->{'type'};
  my $opt=&quotate($d->{'opt'});
  if($opt =~ /-scrolled/) {
    $opt =~ s/^/'$type', /;
    $opt =~ s/-scrolled\s?=>\s?1//;
    $opt =~ s/,\s*,/,/;
    $opt =~ s/,\s*$//;
    $type = 'Scrolled';
  }
  if($descriptor{$parent}->{'type'} eq 'NoteBook')
  {
    $type='add';
    $opt="'$id', $opt";
  }
  my $wballoon = ($d->{'wballoon'}) ? 
    " \$vptk_balloon->attach(\$$id,-balloonmsg=>\"$d->{'wballoon'}\");"
    :'';
  $code =
    $my.'$'.$d->{'id'}.' = $'.$parent.' -> '.
    $type.' ( '.$opt.' )'.
    $geom.';'.$postconfig . $wballoon;
  return $code;
}

sub quotate
{
  my ($opt_list)=shift;
  my ($prefix,$suffix)=($opt_list=~/^\s*([^\(]*\().*(\)[^\)]*)/);
  $opt_list =~ s/^\s*([^\(]*\()//; $opt_list =~ s/(\)[^\)]*)//;
  my (%opt)=&split_opt($opt_list);
  foreach my $k(keys %opt)
  {
    $opt{$k} = "'$opt{$k}'" 
      unless $opt{$k} =~ /^(\d|\[)/ || $k =~ /(variable|command|cmd|image)$/;
    if($opt{$k} =~ /^\[/ && $opt{$k} !~ /'/)
    {
      $opt{$k} =~ s/[\[\]]//g;
      my (%labelPack)=&split_opt($opt{$k});
      foreach (keys %labelPack)
      {
        $labelPack{$_}="'$labelPack{$_}'" unless $labelPack{$_}=~/^[\@\$\\]/
      }
      $opt{$k} = '['.join(',',map{"$_=>$labelPack{$_}"} keys %labelPack).']'
    }
  }
  return $prefix. join(', ',map{"$_=>$opt{$_}"} keys %opt) . $suffix;
}

# Global structures used:
# -----------------------
# %descriptor (id->descriptor)
# @tree
# @user_auto_vars - user-defined variables to be pre-declared automatically
# use vars qw/$x/;
#
# Global widgets used:
# --------------------
# $tf - list of objects in tree form
#
# read string-represented data structure into internal data
sub struct_read 
{
  my (@lines)=@_;
  my @ERRORS;

  my $count=0; # just for diagnostics - input line number
  my $user_subroutines=0;
  my $user_code_before_main=0;
  my $user_code_before_tk=0;
  my $user_code_before_widgets=0;
  my $p_user_subroutines = $Project->get('Code')->get('user code');
  chomp @lines;
# for each widget description line:
# 1. get Id, Parent, Type, parameters, geometry
# 2. check for Parent existance
# 3. add line to tree descriptor
# 4. add element to widget descriptor
# 5. add element to id->descriptor hash
  foreach my $line( @lines )
  {
    $count++;
    if($line=~/^#===vptk end===/ ||
        $user_subroutines)
    {
      push(@$p_user_subroutines,$line);
      &PushCallback($line=~/sub\s+([^\s\{]+)/);
      $user_subroutines=1;
      next;
    }
    if($line=~/^use Tk;/)
    {
      $user_code_before_tk=0;
      next;
    }
    if($line=~/^#===vptk user code before tk===/ ||
        $user_code_before_tk)
    {
      push(@{$Project->get('Code')->get('code before tk')},$line) if $user_code_before_tk;
      $user_code_before_tk=1;
      next;
    }
    if($line=~/^MainLoop;/)
    {
      $user_code_before_main=0;
      next;
    }
    if($line=~/^#===vptk user code before main===/ ||
        $user_code_before_main)
    {
      push(@{$Project->get('Code')->get('code before main')},$line) if $user_code_before_main;
      $user_code_before_main=1;
      next;
    }
    if($line=~/mw->Balloon\(/)
    {
      my ($args) = $line =~ /\((.*)\)/;
      my (%settings) = split(/,|=>/,$args);
      $settings{'-background'} =~ s/"//g;
      $Project->get('Options')->set('balloon_color',$settings{'-background'});
      $Project->get('Options')->set('balloon_delay',$settings{'-initwait'});
      next;
    }
    if($line=~/->bind\(/)
    {
      my ($bindSelCallb) = ($line=~/'[^']+',(.*)\);$/);
      $line =~ s/^\$//;
      push(@project_bindings,$line);
      &PushCallback($bindSelCallb);
      next;
    }
    if($line=~/-> (pack|grid|place)\(/)
    {
      $user_code_before_widgets=0;
    }
    if($line=~/^(#===vptk widgets definition===|use Tk::Balloon)/)
    {
      $user_code_before_widgets=0;
      next;
    }
    if($user_code_before_widgets)
    {
      push(@{$Project->get('Code')->get('code before widgets')},$line) if $user_code_before_widgets;
      next;
    }
    if($line=~/^\s*#[^!]/)
    {
      $line =~ s/^\s*#\s*//;
      if($line)
      {
        $pOpt->data->{'description'} .= ' ' if $pOpt->data->{'description'};
        $pOpt->data->{'description'} .= $line;
        $pOpt->data->{'fullcode'}=1;
      }
      next;
    }
    if($line=~/^\s*my\s+/)
    {
      $line=~s/^\s*my\s+//;
      $pOpt->data->{'strict'}=1;
    }
    if($line=~/new.*-title\s*=>\s*['"]/)
    {
      ($pOpt->data->{'title'}) = $line=~/-title\s*=>\s*['"]([^"']*)['"]/;
      $pOpt->data->{'fullcode'}=1;
      $user_code_before_widgets=1;
      next;
    }
    next if $line=~/^\s*[^\$]/;
    next if $line=~/^\s*\$(mw|vptk_balloon)\s*=/;
    $line =~ s/'//g; # ignore self-generated quotes
      if($line =~ /^\s*\$/)
      {
        my ($id,$parent,$type,$opt,$geom,$w_balloon);
        # parse balloonmsg (if any)
        if($line =~ /\$vptk_balloon/)
        {
          ($w_balloon) = $line =~ /\$vptk_balloon.*"([^"]+)"/;
          $line =~ s/\$vptk_balloon.*//;
        }
        ($id,$parent,$type,$opt,$geom) =
          $line =~ /^\s*\$(\S+)\s+=\s+\$(\S+)\s+->\s+([^(]+)\(([^)]+)\)\s+->\s+([^;]+);/;
        unless($id)
        {
          my $virtual_parent;
          ($id,$virtual_parent,$type,$opt,$parent) =
            $line =~ /^\s*\$(\S+)\s+=\s+\$(\S+)\s+->\s+([^(]+)\(([^)]+)\); \$(\S+)->configure\(-menu=>.*\);/;
        }
        unless($id)
        {
          ($id,$parent,$type,$opt) =
            $line =~ /^\s*\$(\S+)\s+=\s+\$(\S+)\s+->\s+([^(]+)\(([^)]+)\);\s*$/;
        }
# 2.
        next unless $id;
        if($type =~ /^\s*Scrolled\s*$/) {
          my ($real_type,$real_opt) = $opt =~ /^\s*'?(\w+)'?,\s(.*)/;
          $type=$real_type; $opt=$real_opt.", -scrolled=>1";
        }
        if($parent ne 'mw' && ! defined $descriptor{$parent})
        {
# error - report in Tk style:
          push @ERRORS, "line ${count}: Wrong parent id <$parent> for widget <$id>";
          next;
        }
        if(defined $descriptor{$id})
        {
          push @ERRORS, "line ${count}: Duplicated widget <$id> definition\n";
          next;
        }
        $obj_count++;
        my ($parent_path)=grep(/$parent$/,@tree);
        $parent_path='mw' unless $parent_path;
        my ($insert_path)=(grep(/$parent\.[^.]+$/,@tree))[-1];
        push(@tree,"$parent_path.$id");
        $type=~s/\s//g;
        if ($type eq 'add')
        {
          $type='NoteBookFrame';
          $opt=~s/^\s*\S+\s*,\s*//;
        }
        my $image = WidgetIcon($type);
        if($insert_path)
        {
          $tf->add("$parent_path.$id",-text=>$id,-data=> "$parent_path.$id",
              -image=>$image,-after=>$insert_path);
        }
        else
        {
          $tf->add("$parent_path.$id",-text=>$id,-data=> "$parent_path.$id",-image=>$image);
        }
        $descriptor{$id}=&descriptor_create($id,$parent,$type,$opt,$geom,$w_balloon);
        if($opt=~/variable/)
        {
# store user-defined variable in array
          my ($user_var)=($opt=~/\\\$(\w+)/);
          push(@user_auto_vars,$user_var)
            if $user_var && ! grep($_ eq $user_var,@user_auto_vars);
        }
        &PushCallback($opt=~/(?:-command|-\wcmd)\s*=>\s*([^,]+), /g);
      }
  }
  if(@ERRORS)
  {
    if(@ERRORS > 10)
    {
      splice(@ERRORS,10);
      push @ERRORS, "Too many errors - skipped\n";
    }
    &ShowDialog(-title=>"Errors:",-text=>join("\n",@ERRORS));
  }
}

sub descriptor_create
{
  my @p=@_;
  map s/\s*$//,@p;
  map s/^\s*//,@p;
  my ($id,$parent,$type,$opt,$geom,$wballoon)=@p;

  my $descriptor={'id'=>$id,'parent'=>$parent,'type'=>$type,'opt'=>$opt,'geom'=>$geom,'wballoon'=>$wballoon};
  $descriptor{$id}=$descriptor;
  return $descriptor;
}

sub split_opt
{
  # input: options string
  # otput: array of pairs (-param=>value,-param2=>value2,...)
  my $opt=shift || return;
  my %result;
  my @virtual_arrays;

  # if options contain 'reference to anonimous array' it must be temporary 
  # replaced with real array reference
  while($opt =~ /\[[^\[\]]+\]/)
  {
    push(@virtual_arrays,($opt =~ /(\[[^\[\]]+\])/));
    $opt=~s/\[[^\[\]]+\]/ARRAY($#virtual_arrays)/;
  }

  (%result)=split(/\s*(?:,|=>)\s*/,$opt);
  foreach (keys %result)
  {
    $result{$_}=~s/ARRAY\((\d+)\)/$virtual_arrays[$1]/;
  }
  return (%result);
}

# reaction for click on objects that could have callbacks
sub callback
{
  my ($function,$self_path,$event,$id)=@_;
  if($view_repaint)
  {
    $view_repaint = 0;
    return;
  }
  set_selected($self_path);
  my $reply=&ShowDialog(-bitmap=>'info',-title=>"Callback triggered for $id",
    -text=> "Callback function <$function> is assigned to action <$event> for widget <$id>",
    -buttons=>['Close','Edit callbacks','Widget properties','Help']);
  &file_properties('callbacks',$function) if($reply eq 'Edit callbacks');
  &edit_properties if($reply eq 'Widget properties');
  &tkpod('callbacks') if($reply eq 'Help');
}

__END__
