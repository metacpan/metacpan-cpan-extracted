#!/usr/bin/perl
#====================================================================
# $Author    : Djibril Ousmanou                                    $
# $Copyright : 2011                                                $
# $Update    : 17/07/2011 12:47:33                                 $
# $AIM       : Test the module by creation of severals buttons     $
#====================================================================
use strict;
use warnings;

use Tk;
use Tk::ColoredButton;
use Tk::PNG;
use Time::HiRes qw ( sleep );

use vars qw($VERSION);
$VERSION = '1.05';

my $mw = MainWindow->new( -background => 'white', -title => 'Buttons' );
$mw->minsize( 300, 300 );

my $pixmap1 = <<'PIXMAP';
/* XPM */
static char * Icon_xpm[] = {
"32 32 4 1",
"     c none",
".    c #000000000000",
"X    c #9E6DF3",
"o    c #0000FFFF0000",
"                                ",
"       ..                ..     ",
"      ...               ...     ",
"      .X..             .....    ",
"     ..XX..            ......   ",
"     .X..X.           ...X...   ",
"    ..X.X.X. .......  .......   ",
"    .X.XXX....XXXXX...........  ",
"   ..X.X..XXXXXXXXXXXX........  ",
"   .XX...XXXXXXXXXXXXXXX......  ",
"   .X..XXXXXXXXXXXXXXXXXX.....  ",
"   ...XXXXXXXXXXXXXXXXXXXX....  ",
"   .XXXXXXXXXXXXXXXXXXXXXXX...  ",
"   .XXXXXXXXXXXXXXXXXXXXXXXXX.  ",
"  ..XXX.....XXXXXXX.....XXXXX.  ",
"  .XXX.ooooo.XXXXX.ooooo.XXXX.  ",
"  .XX.ooooo.o.XXX.o.ooooo.XXX.  ",
" ..XX.ooooooo.XXX.ooooooo.XXX.  ",
" .XXXX.ooooo.XXXXX.ooooo.XXXXX. ",
" .XXXXX.....XXXXXXX.....XXXXXX. ",
" .XXXXXXXXXXXXXXXXXXXXXXXXXXXX. ",
" .XXXXXXXXXXXXX.XXXXXXXXXXXXXX. ",
" .XXXXXXXXXXXXXXXXXXXXXXXXXXXX. ",
"..XXX..XXXXXXXXXXXXXXXXXXXXXXXX.",
".XXX.XX.XXXXXXXXXXXXXXXX...XXX..",
".XX.XX.XXXXXXXXXXXXXXXX..XX.XX..",
".XX.X.X.XXXXX.XXX.XXXXX.X.XXX...",
".XXXX.X.XXXXXX...XXXXXXX.X.XX.X.",
"..XXX.X.XXXXXXXXXXXXXXXX.X.XX.X.",
".X.XXXXXXXXXXXXXXXXXXXXX.XXX.XX.",
".XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.",
".XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX."};
PIXMAP

my $pixmap2 = <<'PIXMAP';
/* XPM */
static char * exemple_xpm[] = {
"24 20 3 1",
" 	c None",
".	c #3A32E4",
"+	c #E43232",
"                        ",
"    ..                  ",
"   ....                 ",
"  ......++++++++        ",
" .........+++++++       ",
" ..........+++++++      ",
" ............++++++     ",
" .............++++++    ",
"  ..............++++    ",
"   +.............+++    ",
"   ++.............++    ",
"   +++.............+    ",
"   +++++.............   ",
"   ++++++.............. ",
"   ++++++++............ ",
"   +++++++++........... ",
"    +++++++++.........  ",
"     ++++++++++.......  ",
"      ++++++++++.....   ",
"       +++++++++ ...    "};
PIXMAP

my $image = <<'DATA';
iVBORw0KGgoAAAANSUhEUgAAACQAAAAOCAMAAABw6U76AAAAB3RJTUUH1AsUERQYzfaDBAAAAAlw
SFlzAAALEgAACxIB0t1+/AAAAJlQTFRFn0EDPxoBIQ4B/5pX/2YAfTMC5V4EwlAE1VgE4V0E8GMF
/6tz////8dTA+bKC9+ng8GwU/7SC4KeC/49E8K6C/9Gy355y0HIz5YRD9GQF6KuC/3IV//bw9+DQ
57OR5nsz7cmx1GEU8MGhzWcj+pZT572h88Kh/3wk+vTv3W4k+NfB/+3hzlUE/+PR/4U0/8ik/9rB
/+bV5Hcu9l/TCwAAAK5JREFUeNqV0NsOgjAQBFDU6gIOYq2C2KJ4QfGK+v8f55YnJRh0kk26ycmk
WedRtubp9ERr+n+gIYwWClctgZsQJcDbvd50QqbPiC+M8kQDIIXAraFDgRQRJRIFjtI0I7EDAhoI
iRyZ2X9BCgjXgtFkA2ybkTYmxbJCK2TUjGaIYmBukZeQW6FwIaX6OAF/aIRwbBHvFbKZ+m9NA+Ju
j4jHIsEvn2y83y/udFrTfQGnKxbutFN/VQAAAABJRU5ErkJggg==
DATA

my $image_stop = <<'DATA';
R0lGODlhEAAQAPe9ANsAAOfa2tIAAP8AAP/o6PoAAMd+OPUAANUAAPcAANgAANkAAPsAAP7//9cA
AP0AAJ1eKZ5dKdUUFOcAAJ5GLZ5HL+OSkv9mZv+Skv8FBaRqL6ZrL6wAAP+Rkf/i4ufY2N/Kyt7J
yf9KSu0AANxzc/9SUoI4GaA0Ia1vMalsMH0rE9a7u6ZQRPRCQp9JKP5fX6taKMBTU8qDOsyEOv/I
yP8gIN0AAMuGO//x8Z5DKqFKJdJdXebf39IfH8lqaqVRJbcAAPlyctM9PaBmLf+xsbEPC6pYJ/8p
KfodHfcbG//Nzf9ZWcJgYNKVlekQENa3t/4yMv/Bwc6IPM6Njf+oqP+vr4s4Gf9XV+jd3c4KCp1h
K9ENDf9HR93CwukAAOhYWMVPT38rE/4AAOYAAOsAAMidnefZ2aVSJv9JSfAAALFtMKdWJ//JyZ5B
J4ZIIKdVJotKIaRTQ6RURM0AAODJyf5QUMg3N9J/f65fKv/z885ZWf97e5xHIubc3NlZWfs7O+EA
AJ4VCf/GxtUZGcVmZqpMRf8WFrVoLumvr/9lZciTk5JYJ/qYmMUAAM4AAPKDg/ZtbckAAJQFAtcT
E+8AAPwAAP/d3XsiD4ckEP8HB/t6ev82Nv/h4fGoqNCJPdIqKqteWPuxscJtbenh4cWKisZDQ9W6
upxDHYU+G8oAAN4AAKQAAP+zs4AdDf/U1IE3GP2IiMpKSpYEAvIAAOQAAOm+vv/Ly84wMNm/v80u
LsBXV68FAv///9GKPQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAL0ALAAAAAAQABAA
AAj/AHsJ7GXgTAU5cSj8MDCw4RpQtQjkwcEJUaE3DXvxaULAgyslbATZirLj1EAjUyzR6BSqChVG
jzB0sAOj1wwWrIhYKHMHliYfir6IQBJIBh4SeyCR4oVFD5g+vAglOBApgosgFxL5CcHrgxlepiRU
GgHASo4XV5aUEAKCFy9cWQYcmGAjTJs6XND8KRXAbYBPDCgBcqBCR4tNUGLx4PWkC69RucYASIXq
0K0jSUQ1WLFlEp0GTBY44KCl14kahpzEGDRATA9dAhQ4anWjl5oimTIUeJAgjRcACgTIGjIQwq4C
DGaRoaVqwRxJizKiwAQEAQAEjVZd2pBRoKcUcEy8BnKjQUrDgAA7
DATA

my $obj_image  = $mw->Photo( -data => $image );
my $obj_image2 = $mw->Photo( -data => $image_stop );
my $obj_pixmap1 = $mw->Pixmap( -data => $pixmap1 );
my $obj_pixmap2 = $mw->Pixmap( -data => $pixmap2 );

my %coloredbutton_conf = (
  -height  => 40,
  -width   => 160,
  -font    => '{arial} 12 bold',
  -command => sub { exit; },
);
my %button_conf = (
  -font             => '{arial} 12 bold',
  -command          => sub { print "test\n"; },
  -background       => '#F0D0FF',
  -activebackground => '#6BA8F2',
);

my %gradient1 = (
  -start_color  => '#FFFFFF',
  -end_color    => '#bfd4e8',
  -type         => 'mirror_vertical',
  -start        => 50,
  -end          => 100,
  -number_color => 30,
);
my %active_gradient1 = (
  -start_color  => '#bfd4e8',
  -end_color    => '#FFFFFF',
  -type         => 'mirror_vertical',
  -start        => 50,
  -end          => 100,
  -number_color => 30,
);

my %gradient2 = (
  -start_color  => 'red',
  -end_color    => 'white',
  -type         => 'linear_vertical',
  -number_color => 30,
);
my %gradient3 = (
  -start_color  => '#9933CC',
  -end_color    => 'white',
  -type         => 'corner_right',
  -number_color => 30,
);
my %active_gradient3 = (
  -start_color  => '#FFFFFF',
  -end_color    => '#bfd4e8',
  -type         => 'mirror_vertical',
  -start        => 50,
  -end          => 100,
  -number_color => 30,
);

# 6 boutons
my $button1
  = $mw->ColoredButton( -text => 'Button1', %coloredbutton_conf, -tooltip => 'Button1', -autofit => 1 );
my $button2 = $mw->ColoredButton(
  -text => 'Button2',
  %coloredbutton_conf,
  -tooltip        => 'Button2',
  -gradient       => \%gradient1,
  -activegradient => \%active_gradient1,
  -image          => $obj_pixmap2,
  -compound       => 'top',
);
my $button3 = $mw->ColoredButton(
  -text => 'Button3',
  %coloredbutton_conf,
  -tooltip  => 'Button3',
  -gradient => \%gradient2
);
my $button4 = $mw->ColoredButton(
  -text => 'Button4',
  %coloredbutton_conf,
  -tooltip        => 'Button4',
  -gradient       => \%gradient3,
  -activegradient => \%active_gradient3,
  -image          => $obj_pixmap1,
);
my $button5 = $mw->ColoredButton(
  -text => 'Button5',
  %coloredbutton_conf,
  -tooltip  => 'Button5',
  -gradient => { -start_color => '#FFCC33', -end_color => '#9999FF', },
);
my $button6 = $mw->ColoredButton(
  -text => 'Button6',
  %coloredbutton_conf,
  -tooltip        => 'Button6',
  -gradient       => { -start_color => 'brown', -end_color => 'yellow', -type => 'radial' },
  -activegradient => { -start_color => 'yellow', -end_color => 'brown', -type => 'losange' },
);
my $button7 = $mw->ColoredButton(
  -text => 'Button7',
  %coloredbutton_conf,
  -tooltip        => 'Button7',
  -gradient       => { -start_color => '#99CCCC', -end_color => '#999933', -type => 'corner_left' },
  -activegradient => { -start_color => 'white', -end_color => 'black', -type => 'corner_right' },
);
my $button8 = $mw->ColoredButton(
  -text => 'Button8',
  %coloredbutton_conf,
  -tooltip        => 'Button8',
  -gradient       => { -start_color => '#666666', -end_color => '#00B0D0' },
  -activegradient => { -start_color => '#60C000', -end_color => '#7000D0' },
);
my $button9 = $mw->ColoredButton(
  -text => 'Button9',
  %coloredbutton_conf,
  -tooltip        => 'Button9',
  -gradient       => { -start_color => '#F07FC0', -end_color => '#007FF0' },
  -activegradient => { -start_color => 'white', -end_color => '#FF7030' },
  -image          => $obj_image,
  -compound       => 'right',
  -background     => 'red',
);
my $button10 = $mw->ColoredButton(
  -text => 'Button10',
  %coloredbutton_conf,
  -tooltip        => 'Button10',
  -gradient       => { -start_color => '#7F8000', -end_color => 'white' },
  -activegradient => { -start_color => 'white', -end_color => '#7F8000' },
  -bitmap         => 'question',
  -compound       => 'left',
  -autofit        => 1
);
my $button11 = $mw->ColoredButton(
  -text => 'Button11',
  %coloredbutton_conf,
  -tooltip        => 'Button11',
  -gradient       => { -start_color => 'green', -end_color => 'black' },
  -activegradient => { -start_color => 'gray50', -end_color => '#7F8000' },
  -imagedisabled  => $obj_image2,
  -compound       => 'left',
);
my $button12 = $mw->ColoredButton(
  -text => 'Button12',
  %coloredbutton_conf,
  -tooltip  => 'Button12',
  -gradient => { -start_color => 'pink', -end_color => '#8945C3', -number_color => 5, -type => 'radial' },
  -activegradient =>
    { -start_color => 'white', -end_color => '#60FF50', -number_color => 3, -type => 'linear_vertical' },
  -image          => $obj_image,
  -compound       => 'left',
  -repeatdelay    => 5000,
  -repeatinterval => 1000,
  -state          => 'disabled',
  -imagedisabled  => $obj_image2,
  -command        => sub { print "boutton 12\n"; },
);

my $real_button1 = $mw->Button(
  -text => 'Real button 1 - enabled button 11',
  %button_conf,
  -command => sub { $button11->configure( -state => 'normal' ); $button11->redraw_button; },

);
my $real_button2 = $mw->Button(
  -text    => 'Disabled button 11',
  -font    => '{arial} 12 bold',
  -command => sub { $button11->configure( -state => 'disabled' ); $button11->redraw_button; },
);

$button1->grid( $button2,  $button3,  $button4,  qw/ -padx 10 -pady 10 / );
$button5->grid( $button6,  $button7,  $button8,  qw/ -padx 10 -pady 10 / );
$button9->grid( $button10, $button11, $button12, qw/ -padx 10 -pady 10 / );
$real_button1->grid( $real_button2, qw/ -padx 10 -pady 10 / );

$button9->flash();

foreach my $bouton (
  $button1, $button2, $button3,  $button4,  $button5,  $button6,      $button7,
  $button8, $button9, $button10, $button11, $button12, $real_button1, $real_button2,
  )
{

  foreach my $anchor (qw/ nw n ne e se s sw w center /) {
    $bouton->configure( -anchor => $anchor );
    if ( $bouton->class eq 'ColoredButton' ) {
      $bouton->redraw_button;
    }
    $bouton->update;
    sleep 0.5;
  }
}
MainLoop;

