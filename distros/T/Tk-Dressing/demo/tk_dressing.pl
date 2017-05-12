#!/usr/bin/perl
#==================================================================
# $Author    : Djibril Ousmanou                                   $
# $Copyright : 2011                                               $
# $Update    : 01/01/2011 00:00:00                                $
# $AIM       : Test Tk::Dressing with standard widget             $
#==================================================================
use warnings;
use Carp;
use strict;
use English qw( -no_match_vars );

use vars qw($VERSION);
$VERSION = '1.04';

BEGIN {
  my $error;
  foreach my $module (qw/ Tk::ColoredButton Tk::Canvas::GradientColor /) {
    eval "use $module;";
    if ( $EVAL_ERROR !~ /^\s*$/ ) { $error .= "\t- $module\n"; }
  }
  if ( defined $error ) {
    carp("[ERROR] To use this test script you need to install theses modules :\n$error");
    exit;
  }
}

use Tk;
use Tk::BrowseEntry;
use Tk::Canvas::GradientColor;
use Tk::ColoredButton;
use Tk::Dialog;
use Tk::DialogBox;
use Tk::DirTree;
use Tk::HList;
use Tk::LabFrame;
use Tk::MsgBox;
use Tk::NoteBook;
use Tk::Tree;
use Tk::Pane;
use Tk::ProgressBar;
use Tk::Table;
use Tk::TList;

use Tk::Dressing;

my $tk_dressing = Tk::Dressing->new();

my $mw = MainWindow->new( -title => 'Using Tk::Dressing' );
$mw->minsize( 400, 400 );

# menubar
my $menu_bar = $mw->Menu( -type => 'menubar', );
$mw->configure( -menu => $menu_bar, );

my $file_menu = $menu_bar->cascade( -label => 'Files', -tearoff => 0, );
$file_menu->command( -label => 'File 1', );
$file_menu->command( -label => 'File 2', -compound => 'left' );
$file_menu->command( -label => 'File 3', );
my $exit_menu = $menu_bar->cascade( -label => 'exit', -tearoff => 0, );
$exit_menu->command( -label => 'Close', -command => sub { exit; } );

my $label = $mw->Label( -text => 'List of different standard widget' );
my $browse_entry_theme = $mw->BrowseEntry(
  -label   => 'Theme : ',
  -state   => 'readonly',
  -choices => [ 'clear dressing', sort $tk_dressing->get_all_theme ],
);
$browse_entry_theme->configure(
  -browse2cmd => sub {
    my $theme = $browse_entry_theme->Subwidget('entry')->get;
    if ( $theme eq 'clear dressing' ) { $tk_dressing->clear($mw); return; }
    $tk_dressing->design_widget(
      -widget => $mw,
      -theme  => $theme,
    );
  },
);

my $labframe = $mw->LabFrame( -label => 'My LabFrame' );

my $labelentry    = $labframe->Label( -text => 'Entry' );
my $entry         = $labframe->Entry();
my $entrydisabled = $labframe->Entry( -text => 'Entry disabled', -state => 'disabled' );
my $but1          = $labframe->Button( -text => 'Test button' );
my $but2          = $labframe->Button( -text => 'Test button disabled', -state => 'disabled' );
my $coloredbutton1
  = $labframe->ColoredButton( -text => 'ColoredButton1', -tooltip => 'load file', -autofit => 1 );

my $checkbutton1 = $labframe->Checkbutton( -text => 'Example checkbutton', );
my $coloredbutton2 = $labframe->ColoredButton(
  -text    => 'CLEAR THEME',
  -tooltip => 'Button5',
  -font    => '{arial} 12 bold',
  ,
  -autofit  => 1,
  -gradient => { -start_color => '#FFCC33', -end_color => '#9999FF', },
  -command => sub { $tk_dressing->clear($mw); return; },
);
my $coloredbutton3 = $labframe->ColoredButton(
  -text           => 'ColoredButton 3',
  -tooltip        => 'Button8',
  -gradient       => { -start_color => '#666666', -end_color => '#00B0D0' },
  -activegradient => { -start_color => '#60C000', -end_color => '#7000D0' },
);

# Radiobutton
my $radiobutton1 = $labframe->Radiobutton( -text => 'Radiobutton1', );
my $radiobutton2 = $labframe->Radiobutton( -text => 'Radiobutton2', -value => 0 );
my $radiobutton3 = $labframe->Radiobutton( -text => 'Radiobutton3', -state => 'disabled' );

# messageBox, MsgBox, DialogBox and Dialog
my $button_messagebox = $labframe->Button(
  -text    => 'messageBox',
  -command => sub {
    my $reponse_messagebox = $labframe->messageBox(
      -icon    => 'info',
      -title   => 'Message',
      -type    => 'OK',
      -message => 'Tk::Dressing not work in messageBox',
    );
  }
);
my $button_msgbox = $labframe->Button(
  -text    => 'MsgBox',
  -command => sub {
    my $msgbox = $labframe->MsgBox(
      -title   => 'MsgBox',
      -type    => 'okcancel',
      -message => 'Tk::Dressing not work in MsgBox',
    );

    my $button = $msgbox->Show;
  }
);
my $button_dialogbox = $labframe->Button(
  -text    => 'DialogBox',
  -command => sub {
    my $dialogbox = $labframe->DialogBox(
      -title   => 'DialogBox',
      -buttons => [ 'OK', 'Cancel' ]
    );
    $dialogbox->Label( -text => 'Test DialogBox', )->pack();
    $tk_dressing->design_widget(
      -widget => $dialogbox,
      -theme  => $browse_entry_theme->Subwidget('entry')->get,
    );

    $dialogbox->Show;
  }
);
my $button_dialog = $labframe->Button(
  -text    => 'Dialog',
  -command => sub {
    my $dialog = $mw->Dialog(
      -text           => 'Save File?',
      -bitmap         => 'question',
      -title          => 'Save File Dialog',
      -default_button => 'Yes',
      -buttons        => [qw/Yes No Cancel/],
    );
    $tk_dressing->design_widget(
      -widget => $dialog,
      -theme  => $browse_entry_theme->Subwidget('entry')->get,
    );
    $dialog->Show;
  }
);

# Scale
my $scale = $labframe->Scale(
  -label     => 'Scale example',
  -from      => 0,
  -to        => 100,
  -orient    => 'horizontal',
  -takefocus => 1
);

# Spinbox
my $spinbox = $labframe->Spinbox( qw/-from 1 -to 10 -width 10 -validate key/, );

# Listbox
my $liste = $labframe->Listbox();
$liste->insert( 'end', qw/perl java R C++/ );

my $hlist = $labframe->HList(
  -itemtype   => 'text',
  -separator  => '/',
  -selectmode => 'single',
  -browsecmd  => sub {
    my $file = shift;
    $label->configure( -text => $file );
  }
);
foreach (qw(/ /home /home/ioi /home/foo /usr /usr/lib)) {
  $hlist->add( $_, -text => $_ );
}

my $tree = $labframe->Scrolled('Tree');
foreach (
  qw/orange orange.red orange.yellow green green.blue
  green.yellow purple purple.red purple.blue/
  )
{
  $tree->add( $_, -text => $_ );
}

my $labframeonglet = $mw->LabFrame( -label => 'LabFrame onglets' );

# NoteBook
my $notebook = $labframeonglet->NoteBook();
my $onglet1  = $notebook->add( 'onglet 1', -label => 'Tk::Text', );
my $onglet2  = $notebook->add( 'onglet 2', -label => 'Canvas', );
my $onglet3  = $notebook->add( 'onglet 3', -label => 'Menu', );
my $onglet4  = $notebook->add( 'onglet 4', -label => 'disabled', -state => 'disabled' );
my $onglet5  = $notebook->add( 'onglet 5', -label => 'Tk::Table' );
my $onglet6  = $notebook->add( 'onglet 6', -label => 'Tk::TList' );
my $onglet7  = $notebook->add( 'onglet 7', -label => 'Tk::ProgressBar' );

my $widget_text = $onglet1->Scrolled( 'Text', -scrollbars => 'osoe', );
$widget_text->insert( 'end', "1 : data example\n" );
$widget_text->insert( 'end', "2 : data example\n" );

# Canvas GradientColor
my $canvas = $onglet2->GradientColor();
my $but_canvas = $canvas->Button( -text => 'Test button' );
$canvas->createOval( 10, 10, 50, 50, -fill => 'green' );
$canvas->createWindow( 75, 75, -window => $but_canvas );

my $menu_button = $onglet3->Menubutton(
  -text      => 'Menubutton',
  -menuitems => [
    [ 'command', => 'one' ],
    [ 'command', => 'two' ],
    '-',
    [ 'command', => 'three' ],
    [ 'command', => 'four' ],
  ],
);
my $languagemenu = $menu_button->cascade(
  -label   => 'Your language please ?',
  -tearoff => 0,
);
$languagemenu->checkbutton( -label => 'Perl', );
$languagemenu->checkbutton( -label => 'JAVA', );

my $menu_option = $onglet3->Optionmenu(
  -options => [
    [ 'January'   => 1 ],
    [ 'February'  => 2 ],
    [ 'March'     => 3 ],
    [ 'April'     => 4 ],
    [ 'May'       => 5 ],
    [ 'June'      => 6 ],
    [ 'July'      => 7 ],
    [ 'August'    => 8 ],
    [ 'September' => 9 ],
    [ 'October'   => 10 ],
  ],
);

# Tk::Table
my ( @cell_vars, $row, $col );
foreach $row ( 0 .. 9 ) {
  my @row_vars;
  foreach $col ( 0 .. 9 ) {
    push @row_vars, $row * $col;
  }
  push @cell_vars, \@row_vars;
}

my $table = $onglet5->Table(
  -rows         => 6,
  -columns      => 9,
  -scrollbars   => 'os',
  -fixedrows    => 1,
  -fixedcolumns => 1,
)->pack;

foreach $col ( 1 .. 9 ) {
  my $col_header = $onglet5->Button( -text => 'Column' . $col );
  $table->put( 0, $col, $col_header );
}

foreach $row ( 1 .. 5 ) {
  my $row_header = $onglet5->Button( -text => 'Row' . $row );
  $table->put( $row, 0, $row_header );
  foreach $col ( 1 .. 9 ) {
    my $cell = $onglet5->Entry( -width => 10, -textvariable => \$cell_vars[$row][$col] );
    $table->put( $row, $col, $cell );
  }
}

# TList
my $tlist = $onglet6->Scrolled( 'TList', -scrollbars => 'osoe', -width => 30, -height => 20, )->pack();
for ( my $i = 0; $i < 50; $i++ ) {
  $tlist->insert( $i, -itemtype => 'text', -text => "This is item $i" );
}

# ProgressBar
my $progress = $onglet7->ProgressBar(
  -from   => 0,
  -to     => 100,
  -length => 200,
  -colors => [ 0, 'red' ],
  -width  => 20,
)->pack(qw / -pady 10 /);
$onglet7->Button( -text => 'start progressbar', -command => \&progressbar )->pack(qw / -pady 10 /);

# Display widget
$label->grid( $browse_entry_theme, qw/ -padx 10 -pady 10 / );
$labframe->grid( $labframeonglet, qw/ -padx 10 -pady 10 / );

$labelentry->grid( $entry, $entrydisabled, qw/ -padx 10 -pady 10 / );
$but1->grid( $but2, $coloredbutton1, qw/ -padx 10 -pady 10 / );

$notebook->pack(qw/ -expand 1 -fill both -padx 10 -pady 10 /);
$widget_text->grid(qw/ -padx 10 -pady 10 /);
$canvas->grid(qw/ -padx 10 -pady 10 /);
$menu_button->grid( $menu_option, qw/ -padx 10 -pady 10 / );

$checkbutton1->grid( $coloredbutton2, $coloredbutton3, qw/ -padx 10 -pady 10 / );
$radiobutton1->grid( $radiobutton2,   $radiobutton3,   qw/ -padx 10 -pady 10 / );
$button_messagebox->grid( $button_msgbox, $button_dialogbox, qw/ -padx 10 -pady 10 / );
$button_dialog->grid( $spinbox, $scale, qw/ -padx 10 -pady 10 / );
$liste->grid( $hlist, $tree, qw/ -padx 5 -pady 5 / );

MainLoop;

sub progressbar {
  for ( my $i = 0; $i <= 100; $i = $i + 10 ) {
    $progress->value($i);
    $progress->update;
    sleep 1;
  }
}
