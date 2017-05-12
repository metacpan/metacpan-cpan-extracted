package Tk::XPMs;

use vars qw(@EXPORT_OK $VERSION);
use warnings;
use strict;

our $VERSION = "1.11";

use Exporter;
our @ISA=qw(Exporter);

my @xpm_list = # {{{
qw(
  box_nonsel_xpm
  box_yellow_xpm
  box_sel_xpm
  tools_1_xpm
  tools_xpm
  exit_xpm
  stop_xpm
  diskette_xpm
  diskette2_xpm
  folder_xpm
  red_folder_xpm
  openfolder_xpm
  textfile_xpm
  srcfile_xpm
  file_xpm
  winfolder_xpm
  act_folder_xpm
  winact_folder_xpm
  wintext_xpm
  ColorEditor_xpm
  Camel_xpm
  Tk_xpm
  arrow_up_xpm
  arrow_down_xpm
  arrow_left_blue_xpm arrow_right_blue_xpm
  arrow_left_xpm arrow_right_xpm
  arrow_first_xpm
  arrow_prev_xpm
  arrow_ppage_xpm
  arrow_npage_xpm
  arrow_next_xpm
  arrow_last_xpm
  zoom_in_xpm zoom_out_xpm
  cut_disabled_xpm cut_normal_xpm
  paste_disabled_xpm paste_normal_xpm
  cross_xpm
  money_xpm
  mail_xpm
  search_xpm
  thumbs_xpm
  dias_xpm
  info_xpm
  rotate_left_xpm
  rotate_right_xpm
  eye_xpm
  noeye_xpm
  lock_xpm
  filter_xpm
  filter_switch_xpm
); # }}}

our %EXPORT_TAGS = ( # {{{
  'all' => [ @xpm_list,
              "list_xpms"
           ] ,
  'search' => [ qw(
                   filter_xpm
                   filter_switch_xpm
                   search_xpm
                 )
           ] ,
  'arrows' => [ qw(
                   arrow_up_xpm
                   arrow_down_xpm
                   arrow_first_xpm
                   arrow_prev_xpm
                   arrow_ppage_xpm
                   arrow_npage_xpm
                   arrow_next_xpm
                   arrow_last_xpm
                   arrow_left_blue_xpm
                   arrow_right_blue_xpm
                   arrow_left_xpm
                   arrow_right_xpm
                 )
           ] ,


); # }}}

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

sub list_xpms # used for test script ... {{{
{
  return @xpm_list;
} # }}}

# POD {{{1

=head1 NAME

Tk::XPMs - xpm images for icons

=head1 SYNOPSIS

 use Tk;
 use Tk::XPMs qw(:all);

 my $top = MainWindow->new;

 my $xpm = $top->Pixmap(-data => openfolder_xpm);

 my $b1 = $top->Button(
    -image     => $xpm,
    -command   => sub{ print "openfolder_xpm\n"; },
     );


=head1 DESCRIPTION

This module provides some xpm images for icons.  Each image is
implemented as a function which returns the xpm data as a string.

The following image methods are defined:

=cut

# }}}

sub tools_1_xpm { # {{{

=head2 tools_1_xpm()

Returns a tool box icon.

=cut

  return <<'EOT';
/* XPM */
static char * tools_1_xpm[] = {
/* width height num_colors chars_per_pixel */
"21 20 5 1",
/* colors */
" 	c none",
".	c black",
"X	c #f0ff80",
"W	c #f0dd70",
"g	c #444444",
/* pixels */
"               .     ",
"             ..     .",
"           ...     ..",
"          ...     ...",
"          ...    ... ",
"           ........  ",
"            .....    ",
"           ...g      ",
"          ...g       ",
"          ..g        ",
"        ...g         ",
"       ...g          ",
"      ...g           ",
"    ....g            ",
" ........            ",
"...    ...           ",
"..     ...           ",
"..    ...            ",
".    ..              ",
"    .                "};
EOT
} # tools_1_xpm }}}

sub tools_xpm { # {{{

=head2 tools_xpm()

Returns a tool box icon.

=cut

  return <<'EOT';
/* XPM */
static char * tools_xpm[] = {
/* width height num_colors chars_per_pixel */
"21 20 5 1",
/* colors */
" 	c none",
".	c #554477",
"X	c #f0ff80",
"W	c #333333",
"g	c #885588",
/* pixels */
"               .     ",
"             ..     .",
"           ...     ..",
"  XX      ...     ...",
"   XX     ...    ... ",
"    XX     ........  ",
"     XX     .....    ",
"      XX   ...g      ",
"       XX ...g       ",
"        XX..g        ",
"        ...g         ",
"       ...g          ",
"      ...g XX        ",
"    ....g   XWWW     ",
" ........  WWWWWW    ",
"...    ...  WWWWWW   ",
"..     ...   WWWWWW  ",
"..    ...     WWWWWW ",
".    ..        WWWWWW",
"    .           WWWW "};
EOT
} # tools_xpm }}}

sub Tk_xpm { # {{{

=head2 Tk_xpm()

Returns a 32 x 32 Tk symbol.

=cut

  return <<'EOT';
/* XPM */
static char *Tk[] = {
/* width height num_colors chars_per_pixel */
"    32    32        2            1",
/* colors */
"# c #008080",
"a c #ff0000",
/* pixels */
"################################",
"################################",
"################################",
"################################",
"################################",
"################################",
"##########aaaaaaaa##############",
"#######aaaaaaaaaaaa#######aa####",
"#####aaaaaaaaaaaaaa######aaa####",
"####aaaaaaaaaaaaaaaa####aaaa####",
"####aaaaaaa######aa####aaaa#####",
"###aaaa#########aaa###aaaa######",
"###aaaa#########aa###aaaa#######",
"######aa#######aa####aaa########",
"##############aaa###aaaa########",
"#############aaa###aaaa##aaa####",
"#############aa####aaa#aaaaa####",
"############aaa###aaa#aaaaaa####",
"###########aaa####aa#aa#aaa#####",
"###########aaa###aa#aa#aaa######",
"##########aaa####aaaaaaaa#aa####",
"##########aaa####aaaaaaa##aa####",
"#########aaaa####aaaaaaaaaa#####",
"#########aaa#####aa##aaaaa######",
"#########aaa##########aa########",
"################################",
"################################",
"################################",
"################################",
"################################",
"################################",
"################################"
};
EOT
} # Tk_xpm }}}

sub diskette_xpm { # {{{

=head2 diskette_xpm()

Returns a 14 x 15 floppy disc symbol.

=cut

  return <<'EOT';
/* XPM */
static char *diskette[] = {
/* width height num_colors chars_per_pixel */
"    14    15       17            1",
/* colors */
"  c none",
"# c #222222",
". c #808080",
"a c #800000",
"b c #808000",
"c c #008000",
"d c #008080",
"e c #000080",
"f c #800080",
"g c #ffffff",
"h c #c0c0c0",
"i c #ff0000",
"j c #ffff00",
"k c #00ff00",
"l c #00ffff",
"m c #0000ff",
"n c #ff00ff",
/* pixels */
"##############",
"#..gghhhhgg..#",
"#..gghhhhgg..#",
"#..gghhhhgg..#",
"#..gggggggg..#",
"#...gggggg...#",
"#............#",
"#............#",
"#............#",
"#............#",
"#............#",
"#..........gg#",
"#..........gg#",
"##...........#",
" #############",
};
EOT
} # diskette_xpm }}}

sub diskette2_xpm { # {{{

=head2 diskette2_xpm()

Returns another 14 x 15 floppy disc symbol.

=cut

  return <<'EOT';
/* XPM */
static char *diskette2[] = {
/* width height num_colors chars_per_pixel */
"    14    15       17            1",
/* colors */
"  c none",
"# c #222222",
". c #808080",
"a c #800000",
"b c #808000",
"c c #008000",
"d c #008080",
"e c #000080",
"f c #800080",
"g c #ffffff",
"h c #c0c0c0",
"i c #ff0000",
"j c #ffff00",
"k c #00ff00",
"l c #00ffff",
"m c #0000ff",
"n c #ff00ff",
/* pixels */
" #############",
"#bbbgggggggb##",
"#bbbgggggggb##",
"#bbbgggggggb##",
"#bbbgggggggb##",
"#bbbbbbbbbbb##",
"#bbbbbbbbbbb##",
"#bbbbbbbbbbb##",
"#bbb##########",
"#bbb##########",
"#bbb##########",
"#bbb#######bb#",
"#bbb#######bb#",
"##bb##########",
" #############",
};
EOT
} # diskette2_xpm }}}

sub folder_xpm { # {{{

=head2 folder_xpm( $color )

Returns a 16 x 12 symbol for a folder.
The $color parameter is optional.
Default color is "#f0ff80".

=cut

  my $color = shift || "#f0ff80";
  return <<"EOT";
/* XPM */
static char * folder_xpm[] = {
/* width height num_colors chars_per_pixel */
\"16 12 5 1\",
\/* colors */
\" 	s None	c None\",
\".	c black\",
\"X	c $color\",
\"v	c #f0dd70\",
\"g	c #eeeeee\",
/* pixels */
\"   ggg.         \",
\"  gXXXX.        \",
\" gXXXXXX.       \",
\"gggggggggggg.   \",
\"gXXXXXXXXXXX.   \",
\"gXXXXXXXXXXX.   \",
\"gXXXXXXXXXXX.   \",
\"gXXXXXXXXXXX.   \",
\"gXXXXXXXXXvv.   \",
\"gXXXXXXXvvvv.   \",
\"gXXXvvvvvvvv.   \",
\".............   \"};
EOT
} # folder_xpm }}}

sub red_folder_xpm { # {{{

=head2 red_folder_xpm()

Returns a 17 x 15 symbol for a folder. The color of the folder symbol is red.

=cut

  return <<'EOT';
/* XPM */
static char *red_folder[] = {
/* width height num_colors chars_per_pixel */
"    17    15       17            1",
/* colors */
"  c none",
". c #000000",
"# c #808080",
"a c #800000",
"b c #808000",
"c c #008000",
"d c #008080",
"e c #000080",
"f c #800080",
"g c #ffffff",
"h c #c0c0c0",
"i c #ff0000",
"j c #cc0000",
"k c #00ff00",
"l c #00ffff",
"m c #0000ff",
"n c #ff00ff",
/* pixels */
"                 ",
"   #####         ",
"  #hjhjh#        ",
" #hjhjhjh######  ",
" #gggggggggggg#. ",
" #gjhjhjhjhjhj#. ",
" #ghjhjhjhjhjh#. ",
" #gjhjhjhjhjhj#. ",
" #ghjhjhjhjhjh#. ",
" #gjhjhjhjhjhj#. ",
" #ghjhjhjhjhjh#. ",
" #gjhjhjhjhjhj#. ",
" ##############. ",
"  .............. ",
"                 ",
};
EOT
} # folder_xpm }}}

sub openfolder_xpm { # {{{

=head2 openfolder_xpm( $color )

Returns a 17 x 15 open folder symbol.
The $color parameter is optional.
Default color is "#f0ff80".

=cut

  my $color = shift || "#f0ff80";
  return <<"EOT";
/* XPM */
static char * openfolder_xpm[] = {
/* width height num_colors chars_per_pixel */
\"17 15 3 1\",
/* colors */
\" 	s None	c None\",
\".	c black\",
\"X	c $color\",
/* pixels */
\"                 \",
\"    ....         \",
\"   .XXXX.        \",
\"  .XXXXXX.       \",
\" .............   \",
\" .XXXXXXXXXXX.   \",
\" .XXX............\",
\" .XX.XXXXXXXXXXX.\",
\" .XX.XXXXXXXXXX. \",
\" .X.XXXXXXXXXXX. \",
\" .X.XXXXXXXXXXX. \",
\" ..XXXXXXXXXX..  \",
\" .............   \",
"                 ",
"                 ",
};
EOT
} # openfolder_xpm }}}

sub textfile_xpm { # {{{

=head2 textfile_xpm( $color )

Returns a 12 x 12 symbol for a windows text file.
The $color parameter is optional. Default color is "white".

=cut

#"X	c #E0E0FFFFE0E0",
  my $color = shift || "white";
  return <<"EOT";
/* XPM */
static char * textfile_xpm[] = {
\"12 12 3 1\",
\" 	s None	c None\",
\".	c #000000000000\",
\"X	c $color\",
\" ........   \",
\" .XXXXXX.   \",
\" .XXXXXX... \",
\" .X....XXX. \",
\" .XXXXXXXX. \",
\" .X...XXXX. \",
\" .XXXXXXXX. \",
\" .X.....XX. \",
\" .XXXXXXXX. \",
\" .X.....XX. \",
\" .XXXXXXXX. \",
\" .......... \"};
EOT
} # textfile_xpm }}}

sub srcfile_xpm { # {{{

=head2 srcfile_xpm( $color )

Returns a symbol for a source file.
The $color parameter is optional. Default color is "white".

=cut

  my $color = shift || "white";
  return <<"EOT";
/* XPM */
static char * srcfile_xpm[] = {
\"12 12 3 1\",
\" 	s None	c None\",
\".	c #000000000000\",
\"X	c $color\",
\" ........   \",
\" .XXXXXX.   \",
\" .XXXXXX... \",
\" .XXXXXXXX. \",
\" .XX...XXX. \",
\" .X.XXX.XX. \",
\" .X.XXXXXX. \",
\" .X.XXXXXX. \",
\" .XX....XX. \",
\" .XXXXXXXX. \",
\" .XXXXXXXX. \",
\" .......... \"};
EOT
} # srcfile_xpm }}}

sub file_xpm { # {{{

=head2 file_xpm( $color )

Returns a symbol for a file.
The $color parameter is optional. Default color is "white".

=cut

  my $color = shift || "white";
  return <<"EOT";
/* XPM */
static char * file_xpm[] = {
\"12 12 3 1\",
\" 	s None	c None\",
\".	c #000000000000\",
\"X	c $color\",
\" ........   \",
\" .XXXXXX.   \",
\" .XXXXXX... \",
\" .XXXXXXXX. \",
\" .XXXXXXXX. \",
\" .XXXXXXXX. \",
\" .XXXXXXXX. \",
\" .XXXXXXXX. \",
\" .XXXXXXXX. \",
\" .XXXXXXXX. \",
\" .XXXXXXXX. \",
\" .......... \"};
EOT
} # file_xpm }}}

sub winfolder_xpm { # {{{

=head2 winfolder_xpm( )

Returns a symbol for a windows folder.

=cut

  return <<'EOT';
/* XPM */
static char *winfolder[] = {
/* width height num_colors chars_per_pixel */
"    17    15       17            1",
/* colors */
"  c none",
". c #000000",
"# c #808080",
"a c #800000",
"b c #808000",
"c c #008000",
"d c #008080",
"e c #000080",
"f c #800080",
"g c #ffffff",
"h c #c0c0c0",
"i c #ff0000",
"j c #ffff00",
"k c #00ff00",
"l c #00ffff",
"m c #0000ff",
"n c #ff00ff",
/* pixels */
"                 ",
"   #####         ",
"  #hjhjh#        ",
" #hjhjhjh######  ",
" #gggggggggggg#. ",
" #gjhjhjhjhjhj#. ",
" #ghjhjhjhjhjh#. ",
" #gjhjhjhjhjhj#. ",
" #ghjhjhjhjhjh#. ",
" #gjhjhjhjhjhj#. ",
" #ghjhjhjhjhjh#. ",
" #gjhjhjhjhjhj#. ",
" ##############. ",
"  .............. ",
"                 ",
};
EOT
} # winfolder_xpm }}}

sub winact_folder_xpm { # {{{

=head2 winact_folder_xpm()

Returns a symbol for a opened windows folder.

=cut

  return <<'EOT';
/* XPM */
static char *winact_folder[] = {
/* width height num_colors chars_per_pixel */
"    17    15       17            1",
/* colors */
"  c none",
". c #000000",
"# c #808080",
"a c #800000",
"b c #808000",
"c c #008000",
"d c #008080",
"e c #000080",
"f c #800080",
"g c #ffffff",
"h c #c0c0c0",
"i c #ff0000",
"j c #ffff00",
"k c #00ff00",
"l c #00ffff",
"m c #0000ff",
"n c #666666",
/* pixels */
"                 ",
"    #####        ",
"   #hjhjh#       ",
"  #hjhjhjh###### ",
"  #gggggggggggg#.",
"  #gjhjhjhjhjhj#.",
"#############jh#.",
"#ghhjhjhjhjh#hj#.",
"#ghjhjhjhjhjh#h#.",
" #ghjhjhjhjhj#h#.",
" #gjhjhjhjhjhj##.",
" #ghjhjhjhjhjh##.",
"  #############..",
"   nnnnnnnnnnnnnn",
"                 ",
};
EOT
} # winact_folder_xpm }}}

sub act_folder_xpm { # {{{

=head2 act_folder_xpm( $color )

Returns a symbol for an opened windows folder.
The $color parameter is optional. Default color is "yellow".

=cut

  my $color = shift || "yellow";
  return <<"EOT";
/* XPM */
static char * act_folder_xpm[] = {
/* width height num_colors chars_per_pixel */
\"16 12 4 1\",
/* colors */
\" 	s None	c None\",
\".	c black\",
\"X	c $color\",
\"o	c #5B5B57574646\",
/* pixels */
\"   ....         \",
\"  .XXXX.        \",
\" .XXXXXX.       \",
\".............   \",
\".oXoXoXoXoXo.   \",
\".XoX............\",
\".oX.XXXXXXXXXXX.\",
\".Xo.XXXXXXXXXX. \",
\".o.XXXXXXXXXXX. \",
\".X.XXXXXXXXXXX. \",
\"..XXXXXXXXXX..  \",
\".............   \"};
EOT
} # act_folder_xpm }}}

sub wintext_xpm { # {{{

=head2 wintext_xpm( $color )

Returns a symbol for a text file.
The $color parameter is optional. Default color is "white".

=cut

  my $color = shift || "white";
  return <<"EOT";
/* XPM */
static char *wintext[] = {
/* width height num_colors chars_per_pixel */
"    15    18       17            1",
/* colors */
"  c None",
". c #000000",
"# c #808080",
"a c #800000",
"b c #808000",
"c c #008000",
"d c #008080",
"e c #000080",
"f c #800080",
"g c $color\",
"h c #c0c0c0",
"i c #ff0000",
"j c #ffff00",
"k c #00ff00",
"l c #00ffff",
"m c #0000ff",
"n c #ff00ff",
/* pixels */
"               ",
"   . . . . .   ",
"  .g#g#g#g#g.  ",
" #g.g.g.g.g.g. ",
" #ggggggggggh. ",
" #ggggggggggh. ",
" #gg...g..ggh. ",
" #ggggggggggh. ",
" #gg......ggh. ",
" #ggggggggggh. ",
" #gg......ggh. ",
" #ggggggggggh. ",
" #gg......ggh. ",
" #ggggggggggh. ",
" #ggggggggggh. ",
" #hhhhhhhhhhh. ",
"  ...........  ",
"               "
};
EOT
} # wintext_xpm }}}

sub ColorEditor_xpm { # {{{

=head2 ColorEditor_xpm()

Returns a symbol for a color editor.

=cut

  return <<'EOT';
/* XPM */
static char * ColorEditor_xpm[] = {
"48 48 6 1",
" 	c #0000FFFF0000",
".	c #FFFFFFFF0000",
"X	c #FFFF00000000",
"o	c #000000000000",
"O	c #0000FFFFFFFF",
"+	c #00000000FFFF",
"                   . . ......X..XXXXXXXXXXXXXXXX",
"                      . .X.X. X...XX.XXXXXXXXXXX",
"                   .  . .  ... ...XXXXXXXXXXXXXX",
"                .   .    .. .....XX.XXXXXXXXXXXX",
"                    .   .X.X...XXX..XXXXXXXXXXXX",
"                       .. .  ....X...X.XXXXXXXXX",
"                       ..  ..X.. . ..X..XXXXXXXX",
"                          ....  ..X.X..X.XXXXXXX",
"                         ...  .X. X...X...XX.XXX",
"                     .    .. ... XX...XXXX..XXXX",
"      ooo o         ooo.   .  .. .X...X..X.XXXXX",
"    oo   oo          oo.    . .  . .......X.X.XX",
"    oo    o          oo   . . .. ........XX.XXXX",
"   oo         ooo   oo   ooo Xooo.oo..... X XX.X",
"   oo        o  oo  oo  o  oo  ooo o.. . X...X X",
"   oo       oo  oo  oo oo  oo .oo  . X.X.....XX ",
"O  oo     o oo  oo oo  oo  oo oo.  ...  X..... .",
"O O oo   oo oo  o  oo ooo  o. oo     . ... .X..X",
"O OOOooooO   ooo   ooo  ooo   oo  ... ....... X ",
"  O OOO                         .  . ..  ...  ..",
"OOO OOOO OO O                    . .... . . .. .",
" +  O  O   O  O                        .. .. . .",
"   O  OOO  OO                    .    ..   .... ",
"OOOOO    O   OO                  .   ..  .  ... ",
"+OOOO OOOO  OO    O                  ...   .. ..",
" O+OO OO      O                            .    ",
"OOOOOOOOoooooooOOOO  ooo  oo               .... ",
"OO++ OOO ooO OoOO     oo  oo  oo           ..   ",
"+OOOOOOOOooOOOo O O   oo      oo               .",
"++OOO   +oo+oOO O oo oo ooo ooooo  ooo  ooo oo. ",
"+OO O OOoooooO O o  ooo  oo  oo   o  oo  ooo o  ",
"++++ O OooOOoO Ooo  Ooo  oo  oo  oo  oo  oo     ",
"+++OOOO ooOOOoOOooOOooO oo  oo   oo  oo oo      ",
"++++++ Ooo OOoOOooOooo ooo ooo o oo  o  oo      ",
"+++O+++oooooooOOOooOoooOooo ooo  Oooo   oo      ",
"++++++++O++OOOO   O OOOOOOO                     ",
"++O++++O+O+OOOOOOO O O OOOOOO  O                ",
"+++O+++OOO+OO OOOO O   OO  O O O                ",
"++++++++O++O OO OO OO  OOO OO O   O             ",
"+++++++++++++ OOOOOO OOOO OO OO                 ",
"+++++++++++++O+ +O OOOO OOO  OOO OOO            ",
"++++++++++++++ OOOOO O OOOOOOOOOO               ",
"+++++++++++++ ++  OO  +O OOOOO O  O   O         ",
"+++++++++++++++O+++O+O+O OOOOOOOOOO    O        ",
"+++++++++++++O++++O++  O OOO O OOO OO           ",
"++++++++++++++++O+++O+O+OOOO OOOO  O  OO        ",
"+++++++++++++++++++O+++ +++O OOOOOO OO   O      ",
"++++++++++++++++++++++ +++ O OOOOOOOOO          "};

EOT
} # ColorEditor_xpm }}}

sub Camel_xpm { # {{{

=head2 Camel_xpm( $color )

Returns a camel icon.
The $color parameter is optional. Default color is "#7f7f00".

=cut

  my $color = shift || "#7f7f00";
  return <<"EOT";
/* XPM */
static char *Camel[] = {
/* width height num_colors chars_per_pixel */
"    32    32        2            1",
/* colors */
". c #ffffff",
"# c $color",
/* pixels */
"................................",
"................................",
"...................###..........",
".......####......######.........",
"....####.##.....########........",
"....########....#########.......",
"......######..###########.......",
"......#####..#############......",
".....######.##############......",
".....######.###############.....",
".....######################.....",
".....#######################....",
".....#######################....",
"......#######################...",
".......####################.#...",
"........###################.#...",
"........###############.###.#...",
"............#######.###.###.#...",
"............###.###.##...##.....",
"............###.###..#...##.....",
"............##.####..#....#.....",
"............##.###...#....#.....",
"............##.##...#.....#.....",
"............#...#...#.....#.....",
"............#....#..#.....#.....",
"............#.....#.#.....#.....",
"............#.....###.....#.....",
"...........##....##.#....#......",
"...........#..............#.....",
".........###.............#......"
"................................",
"................................",
};
EOT
} # Camel_xpm }}}

sub arrow_up_xpm { # {{{

=head2 arrow_up_xpm( $color )

Returns a symbol for an up-arrow. 
The $color parameter is optional.
Default color is "white".

=cut

  my $color = shift || "white";
  return <<"EOT";
/* XPM */
static char * arrow_up_xpm[] = {
\"20 12 3 1\",
\" 	s None	c None\",
\".	c #000000000000\",
\"X	c $color\",
\"                    \",
\"         ..         \",
\"        .XX.        \",
\"       .XXXX.       \",
\"      .XXXXXX.      \",
\"     ....XX....     \",
\"        .XX.        \",
\"        .XX.        \",
\"        .XX.        \",
\"        .XX.        \",
\"        ....        \",
\"                    \"};
EOT
} # arrow_up_xpm }}}

sub arrow_down_xpm { # {{{

=head2 arrow_down_xpm( $color )

Returns a symbol for a down-arrow. The $color parameter is optional.
Default color is "white".

=cut

  my $color = shift || "white";
  return <<"EOT";
/* XPM */
static char * arrow_down_xpm[] = {
\"20 12 3 1\",
\" 	s None	c None\",
\".	c #000000000000",
\"X	c $color\",
\"                    \",
\"        ....        \",
\"        .XX.        \",
\"        .XX.        \",
\"        .XX.        \",
\"        .XX.        \",
\"     ....XX....     \",
\"      .XXXXXX.      \",
\"       .XXXX.       \",
\"        .XX.        \",
\"         ..         \",
\"                    \"};
EOT
} # arrow_down_xpm }}}

sub arrow_left_blue_xpm { # {{{

=head2 arrow_left_blue_xpm()

Returns a symbol for a blue left arrow.

=cut

  return arrow_left_xpm( "#0A246A");

} # arrow_left_blue_xpm }}}

sub arrow_right_blue_xpm { # {{{

=head2 arrow_right_blue_xpm()

Returns a symbol for a blue right arrow.

=cut

  return arrow_right_xpm( "#0A246A");

} # arrow_right_blue_xpm }}}

sub arrow_left_xpm { # {{{

=head2 arrow_left_xpm( $color )

Returns a symbol for a left arrow. The $color parameter is optional.
Default color is "#ffffff".

=cut

  my $color = shift ||"#ffffff";
  return <<"EOT";
/* XPM */
static char *arrow_left_blue[] = {
/* columns rows colors chars-per-pixel */
\"20 20 2 1\",
\".	s None	c None\",
\"  c $color\",
/* pixels */
\"....................\",
\"....................\",
\"....................\",
\"....................\",
\"....................\",
\"........ ...........\",
\".......  ...........\",
\"......   ...........\",
\".....            ...\",
\"....             ...\",
\"...              ...\",
\"....             ...\",
\".....            ...\",
\"......   ...........\",
\".......  ...........\",
\"........ ...........\",
\"....................\",
\"....................\",
\"....................\",
\"....................\"
};
EOT
} # arrow_left_xpm }}}

sub arrow_right_xpm { # {{{

=head2 arrow_right_xpm( $color )

Returns a symbol for a right arrow. The $color parameter is optional.
Default color is "#ffffff".

=cut

  my $color = shift ||"#ffffff";
  return <<"EOT";
/* XPM */
static char *arrow_right_blue[] = {
/* columns rows colors chars-per-pixel */
\"20 20 2 1\",
\".	s None	c None\",
\"  c $color\",
/* pixels */
\"....................\",
\"....................\",
\"....................\",
\"....................\",
\"....................\",
\"........... ........\",
\"...........  .......\",
\"...........   ......\",
\"...            .....\",
\"...             ....\",
\"...              ...\",
\"...             ....\",
\"...            .....\",
\"...........   ......\",
\"...........  .......\",
\"........... ........\",
\"....................\",
\"....................\",
\"....................\",
\"....................\"
};
EOT
} # arrow_right_xpm }}}

sub arrow_first_xpm { # {{{

=head2 arrow_first_xpm( $color )

Returns a symbol for a  |<  arrow. 
The $color parameter is optional. Default color is "#ffffff".

=cut

  my $color = shift || "#ffffff";
  return <<"EOT";
/* XPM */
static char * arrow_first_xpm[] = {
\"20 12 3 1\",
\" 	s None	c None\",
\".	c #000000000000\",
\"X	c $color\",
\"      .X     .      \",
\"      .X    ..      \",
\"      .X   .X.      \",
\"      .X  .XX.      \",
\"      .X .XXX.      \",
\"      .X.XXXX.      \",
\"      .X .XXX.      \",
\"      .X  .XX.      \",
\"      .X   .X.      \",
\"      .X    ..      \",
\"      .X     .      \",
\"                    \"};
EOT
} # arrow_first_xpm }}}

sub arrow_prev_xpm { # {{{

=head2 arrow_prev_xpm( $color )

Returns a symbol for a  <  arrow.
The $color parameter is optional. Default color is "#ffffff".

=cut

  my $color = shift || "#ffffff";
  return <<"EOT";
/* XPM */
static char * arrow_prev_xpm[] = {
\"20 12 3 1\",
\" 	s None	c None\",
\".	c #000000000000\",
\"X	c $color\",
\"            .       \",
\"           ..       \",
\"          .X.       \",
\"         .XX.       \",
\"        .XXX.       \",
\"       .XXXX.       \",
\"        .XXX.       \",
\"         .XX.       \",
\"          .X.       \",
\"           ..       \",
\"            .       \",
\"                    \"};
EOT
} # arrow_prev_xpm }}}

sub arrow_ppage_xpm { # {{{

=head2 arrow_ppage_xpm( $color )

Returns a symbol for a  <<  arrow.
The $color parameter is optional. Default color is "#ffffff".

=cut

  my $color = shift || "#ffffff";
  return <<"EOT";
/* XPM */
static char * arrow_ppage_xpm[] = {
\"20 12 3 1\",
\" 	s None	c None\",
\".	c #000000000000\",
\"X	c $color\",
\"         .     .    \",
\"        ..    ..    \",
\"       .X.   .X.    \",
\"      .XX.  .XX.    \",
\"     .XXX. .XXX.    \",
\"    .XXXX..XXXX.    \",
\"     .XXX. .XXX.    \",
\"      .XX.  .XX.    \",
\"       .X.   .X.    \",
\"        ..    ..    \",
\"         .     .    \",
\"                    \"};
EOT
} # arrow_ppage_xpm }}}

sub arrow_next_xpm { # {{{

=head2 arrow_next_xpm( $color )

Returns a symbol for a  >  arrow.
The $color parameter is optional. Default color is "#ffffff".

=cut

  my $color = shift || "#ffffff";
  return <<"EOT";
/* XPM */
static char * arrow_next_xpm[] = {
\"20 12 3 1\",
\" 	s None	c None\",
\".	c #000000000000\",
\"X	c $color\",
\"       .            \",
\"       ..           \",
\"       .X.          \",
\"       .XX.         \",
\"       .XXX.        \",
\"       .XXXX.       \",
\"       .XXX.        \",
\"       .XX.         \",
\"       .X.          \",
\"       ..           \",
\"       .            \",
\"                    \"};
EOT
} # arrow_next_xpm }}}

sub arrow_npage_xpm { # {{{

=head2 arrow_npage_xpm( $color )

Returns a symbol for a  >>  arrow.
The $color parameter is optional. Default color is "#ffffff".

=cut

  my $color = shift || "#ffffff";
  return <<"EOT";
/* XPM */
static char * arrow_npage_xpm[] = {
\"20 12 3 1\",
\" 	s None	c None\",
\".	c #000000000000\",
\"X	c $color\",
\"    .     .         \",
\"    ..    ..        \",
\"    .X.   .X.       \",
\"    .XX.  .XX.      \",
\"    .XXX. .XXX.     \",
\"    .XXXX..XXXX.    \",
\"    .XXX. .XXX.     \",
\"    .XX.  .XX.      \",
\"    .X.   .X.       \",
\"    ..    ..        \",
\"    .     .         \",
\"                    \"};
EOT
} # arrow_npage_xpm }}}

sub arrow_last_xpm { # {{{

=head2 arrow_last_xpm( $color )

Returns a symbol for a  >|  arrow.
The $color parameter is optional. Default color is "#ffffff".

=cut

  my $color = shift || "#ffffff";
  return <<"EOT";
/* XPM */
static char * arrow_last_xpm[] = {
\"20 12 3 1\",
\" 	s None	c None\",
\".	c #000000000000\",
\"X	c $color\",
\"      .     X.      \",
\"      ..    X.      \",
\"      .X.   X.      \",
\"      .XX.  X.      \",
\"      .XXX. X.      \",
\"      .XXXX.X.      \",
\"      .XXX. X.      \",
\"      .XX.  X.      \",
\"      .X.   X.      \",
\"      ..    X.      \",
\"      .     X.      \",
\"                    \"};
EOT
} # arrow_last_xpm }}}

sub mail_xpm { # {{{

=head2 mail_xpm()

Returns a symbol for an envelope.

=cut

  return <<'EOT';
/* XPM */
static char *mail[] = {
/* columns rows colors chars-per-pixel */
"20 20 123 2",
"a  c #A8977B",
"5  c #645A4E",
"@. c #F4E3C9",
"q  c #625B55",
"O  c #413527",
"9. c #FEEFD8",
"'. c #FFF9F1",
"-. c #FBE8CA",
"$  c #443C2F",
"n. c #F6EDE6",
"'  c #E4D8C8",
"4  c #645B4C",
"<  c #584630",
"C  c #D0BD9C",
"f  c #B09D7F",
"z  c #B9A58C",
"y  c #8E7A61",
"{  c #E6DBD5",
"0. c #FFF0D3",
" . c #EEE3DD",
"-  c #443B32",
"V  c #B9ADA1",
"j. c #ECF1F4",
"y. c #FDF2DC",
"1. c #F5E9D3",
"v  c #B5A79A",
"t  c #665953",
"J  c #D6C6B7",
"l  c #BAA58A",
"]  c #E4D8CC",
"4. c #F5E8D8",
"e. c #FFF1D8",
"<. c #F0E3DD",
"D  c #CBBAB0",
"S  c #C6BCB2",
"3  c #5F5B5A",
"2  c #584536",
"I  c #D8C8B1",
"K. c #FDF4EB",
"j  c #ACA298",
"K  c #D0C6BA",
"B  c #B7ADA3",
"7  c #625B53",
"&  c #4B3B22",
"/. c #F2F4F3",
"p  c #A69279",
"(. c #F0F4F5",
"w. c #FBF3DE",
"H. c #FAF6EA",
"x  c #B4A797",
"O. c #F3E3CA",
"R  c #E8D7BD",
"Z  c #CBB6A1",
"5. c #F7EEDF",
"V. c #FFF4E1",
"k  c #BAA588",
"m. c #F9ECE4",
"g. c #EDF1F2",
"U  c #DECDBB",
"). c #F1F5F4",
"G  c #DBC7AC",
"M  c #B7A69C",
"g  c #AF9C8B",
":. c #FFEFCE",
"L  c #D2CABD",
"t. c #FEF2DA",
"1  c #584632",
"6. c #F9E9D2",
"p. c #EDF2EE",
"M. c #F2F4EF",
"a. c #EFF1EE",
"#  c #453C2D",
"0  c #635957",
"$. c #F7E9CE",
"   c #3C2F26",
",  c #53463D",
"P. c #FEF6E9",
"9  c #605B57",
"P  c #D9C7B1",
"s  c #A8967E",
"8  c #635A53",
"|  c #E9DBD0",
"~. c #F0F4F3",
"d. c #EAF2F5",
"^. c #F2F4F1",
"m  c #B4A79E",
">. c #F1E4D4",
"@  c #453C2B",
"u. c #FFF5DD",
"o. c #F6E3C3",
"!  c #EAD9BF",
"q. c #FFF2D7",
"X  c #44321C",
"A  c #CEBCA6",
"=. c #FBE8C8",
"*  c #4C3A24",
"x. c #EFF4F7",
"{. c #FFFEFB",
"`  c #E2D8CE",
"W. c #FFFAEE",
"%. c #F7E9CF",
"X. c #EFE5DC",
"U. c #FFFAEA",
" X c #FEFFFF",
"c  c #B6A794",
"R. c #FFF8EF",
"(  c #E4D7C4",
"l. c none",
"o  c #413121",
"H  c #DCC7A8",
"d  c #B09B7C",
"J. c #FCF5EB",
"C. c #FFF4E3",
".  c #43321E",
"i  c #A79277",
"+. c #F2E3CC",
"3. c #F6E9D6",
"h. c #EFF1F0",
"+  c #473B2B",
"B. c #FAF3E3",
";. c #F8E8CF",
"W  c #EAD6BD",
";  c #453A34",
/* pixels */
"l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.",
"l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.",
"l.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.l.",
"l.x.(.(.~.).).).).).).^.g.^.M.M.M.^.g.l.",
"l.x.(.3 0 9 9 9 0 q 7 7 7 5 4 4 4 5 5 l.",
"l.x.(.0 <. .{ { { { ` ] ' ( R ! I U o l.",
"l.x.).7 ] R.W.'.'.W.P.P.B.V.t.0.0.P . l.",
"l.).).0 m B J.'.W.W.H.U.C.t.q.=.f p X l.",
"l.)./.q m.S j  .J.'.W.B.V.e.C i l P X l.",
"l.).g.0 W.W.K V m K.W.C.6.z i k ! W * l.",
"l.x.).9 n.W.W.U v m J A p y P o.=.@.& l.",
"l.x./.8 X.R.L B 5.4.c s G ! a C :.W < l.",
"l. X X8 | ' x n.C.C.y.9.%.%.=.d H W 1 l.",
"l. X{.8 D v C.C.C.w.V.u.e.t.0.-.f Z 1 l.",
"l. X Xt M >.4.4.4.3.1.;.+.$.O.O.W g 2 l.",
"l.j.p.0 ; - - - - $ # # @ @ @ + O ,   l.",
"l.d.d.p.p.p.p.p.p.p.p.a.a.a.a.~.a.(.h.l.",
"l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.",
"l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.",
"l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l.l."
};
EOT
} # mail_xpm }}}

sub cross_xpm { # {{{

=head2 cross_xpm( $color )

Returns a symbol for a x-shaped cross. The $color parameter is optional.
Default color is "red".

=cut

  my $color = shift || 'red';
  return <<"EOT";
/* XPM */
static char *cross[] = {
/* columns rows colors chars-per-pixel */
\"16 20 3 1\",
\"  c black\",
\". c $color\",
\"o c None\",
/* pixels */
\"oooooooooooooooo\",
\"oooooooooooooooo\",
\"oooooooooooooooo\",
\"oooooooooooooooo\",
\"oooooooooooo ooo\",
\"oo  ooooooo . oo\",
\"o .. ooooo ... o\",
\"o ... ooo .... o\",
\"oo ... o ...  oo\",
\"ooo  .. ... oooo\",
\"ooooo ...  ooooo\",
\"oooo .. .. ooooo\",
\"ooo .. o .. oooo\",
\"oo .. ooo .. ooo\",
\"o ... ooo ... oo\",
\"o .. ooooo .. oo\",
\"o .. oooooo  ooo\",
\"oo  oooooooooooo\",
\"oooooooooooooooo\",
\"oooooooooooooooo\"
};
EOT
} # cross_xpm }}}

sub info_xpm { # {{{

=head2 info_xpm()

Returns a symbol for a info symbol.

=cut

  return <<'EOT';
/* XPM */
static char *info[] = {
/* columns rows colors chars-per-pixel */
"24 20 3 1",
"X	s None	c None",
"  c #0A246A",
". c red",
/* pixels */
"XXXXXXXXXXXXXXXXXXXXXXXX",
"XXXXXXXXXXXXXXXXXXXXXXXX",
"XXXXXXXXX......XXXXXXXXX",
"XXXXXXX..XXXXXX..XXXXXXX",
"XXXXXX.XXXXXXXXXX.XXXXXX",
"XXXXX.XXXXX  XXXXX.XXXXX",
"XXXXX.XXXXX  XXXXX.XXXXX",
"XXXX.XXXXXXXXXXXXXX.XXXX",
"XXXX.XXXXX   XXXXXX.XXXX",
"XXXX.XXXXXX  XXXXXX.XXXX",
"XXXX.XXXXXX  XXXXXX.XXXX",
"XXXX.XXXXXX  XXXXXX.XXXX",
"XXXXX.XXXXX  XXXXX.XXXXX",
"XXXXX.XXXX    XXXX.XXXXX",
"XXXXXX.XXXXXXXXXX.XXXXXX",
"XXXXXXX..XXXXXX..XXXXXXX",
"XXXXXXXXX......XXXXXXXXX",
"XXXXXXXXXXXXXXXXXXXXXXXX",
"XXXXXXXXXXXXXXXXXXXXXXXX",
"XXXXXXXXXXXXXXXXXXXXXXXX"
};
EOT
} # info_xpm }}}

sub zoom_in_xpm { # {{{

=head2 arrow_zomm_in_xpm()

Returns a symbol for a zoom-in lense.

=cut

  return <<'EOT';
/* XPM */
static char *zoom_in[] = {
/* columns rows colors chars-per-pixel */
"20 20 4 1",
"o	s None	c None",
"  c black",
". c red",
"X c #808080",
/* pixels */
"oooooooooooooooooooo",
"oooooooooooooooooooo",
"oooooooooooooooooooo",
"ooooooX    Xoooooooo",
"ooooo  oooo  ooooooo",
"oooo XooooooX oooooo",
"oooX ooo..ooo Xooooo",
"ooo oooo..oooo ooooo",
"ooo oo......oo ooooo",
"ooo oo......oo ooooo",
"ooo oooo..oooo ooooo",
"oooX ooo..ooo Xooooo",
"oooo Xooooooo oooooo",
"ooooo  oooo    ooooo",
"ooooooX    Xo   oooo",
"oooooooooooooo   ooo",
"ooooooooooooooo   oo",
"oooooooooooooooo Xoo",
"oooooooooooooooooooo",
"oooooooooooooooooooo"
};
EOT
} # arrow_zoom_in_xpm }}}

sub zoom_out_xpm { # {{{

=head2 arrow_zomm_out_xpm()

Returns a symbol for a zoom-out lense.

=cut

  return <<'EOT';
/* XPM */
static char *zoom_out[] = {
/* columns rows colors chars-per-pixel */
"20 20 4 1",
"o	s None	c None",
"  c black",
". c red",
"X c #808080",
/* pixels */
"oooooooooooooooooooo",
"oooooooooooooooooooo",
"oooooooooooooooooooo",
"oooooX    Xooooooooo",
"oooo  oooo  oooooooo",
"ooo XooooooX ooooooo",
"ooX oooooooo Xoooooo",
"oo oooooooooo oooooo",
"oo oo......oo oooooo",
"oo oo......oo oooooo",
"oo oooooooooo oooooo",
"ooX oooooooo Xoooooo",
"ooo Xooooooo ooooooo",
"oooo  oooo    oooooo",
"oooooX    Xo   ooooo",
"ooooooooooooo   oooo",
"oooooooooooooo   ooo",
"ooooooooooooooo Xooo",
"oooooooooooooooooooo",
"oooooooooooooooooooo"
};
EOT
} # arrow_zoom_out_xpm }}}

sub cut_disabled_xpm { # {{{

=head2 cut_disabled_xpm()

Returns a symbol for a cut symbol (disabled).

=cut

  return <<'EOT';
/* XPM */
static char *cut_disabled[] = {
/* columns rows colors chars-per-pixel */
"20 20 3 1",
".	s None	c None",
"  c #808080",
"X c gray100",
/* pixels */
"....................",
"....................",
"....................",
"....... ... ........",
"....... X.. X.......",
"....... X.. X.......",
".......  .  X.......",
"........ X XX.......",
"........   X........",
"......... XX........",
"........   .........",
"........ X   .......",
"......   X XX ......",
"..... .X X X. X.....",
"..... X. X X. X.....",
"..... X. X.  .X.....",
"......  .X..XX......",
".......XX...........",
"....................",
"...................."
};
EOT
} # cut_disabled_xpm }}}

sub cut_normal_xpm { # {{{

=head2 cut_normal_xpm()

Returns a symbol for a cut symbol (normal).

=cut

  return <<'EOT';
/* XPM */
static char *cut_normal[] = {
/* columns rows colors chars-per-pixel */
"20 20 3 1",
".	s None	c None",
"  c #222222",
"X c #444444",
/* pixels */
"....................",
"....................",
"....................",
"....... ... ........",
"....... X.. X.......",
"....... X.. X.......",
".......  .  X.......",
"........ X XX.......",
"........   X........",
"......... XX........",
"........   .........",
"........ X   .......",
"......   X XX ......",
"..... .X X X. X.....",
"..... X. X X. X.....",
"..... X. X.  .X.....",
"......  .X..XX......",
".......XX...........",
"....................",
"...................."
};
EOT
} # cut_normal_xpm }}}

sub paste_disabled_xpm { # {{{

=head2 paste_disabled_xpm()

Returns a symbol for a paste symbol (disabled).

=cut

  return <<'EOT';
/* XPM */
static char *paste_disabled[] = {
/* columns rows colors chars-per-pixel */
"24 20 3 1",
".	s None	c None",
"  c #808080",
"X c gray100",
/* pixels */
"........................",
"........................",
".........    ...........",
".....            .......",
"....              ......",
"....    XXXXXX    X.....",
"....              X.....",
"....              X.....",
"....              X.....",
"....       XXXXX  X.....",
"....       X.... X .....",
"....       X   .   X....",
"....       X.XXX.X X....",
"....       X     . X....",
".....      X.XXXXX X....",
"......XXXX         X....",
"...........XXXXXXXXX....",
"........................",
"........................",
"........................"
};
EOT
} # paste_disabled_xpm }}}

sub paste_normal_xpm { # {{{

=head2 paste_normal_xpm()

Returns a symbol for a paste symbol (normal).

=cut

  return <<'EOT';
/* XPM */
static char *paste_normal[] = {
/* columns rows colors chars-per-pixel */
"24 20 3 1",
".	s None	c None",
"  c #333333",
"X c #ffffff",
/* pixels */
"........................",
"........................",
".........    ...........",
".....            .......",
"....              ......",
"....    XXXXXX    X.....",
"....              X.....",
"....              X.....",
"....              X.....",
"....       XXXXX  X.....",
"....       X.... X .....",
"....       X   .   X....",
"....       X.XXX.X X....",
"....       X     . X....",
".....      X.XXXXX X....",
"......XXXX         X....",
"...........XXXXXXXXX....",
"........................",
"........................",
"........................"
};
EOT
} # paste_normal_xpm }}}

sub search_xpm { # {{{

=head2 search_xpm()

Returns a symbol for a big lense.

=cut

  return <<'EOT';
/* XPM */
static char *search[] = {
/* columns rows colors chars-per-pixel */
"28 29 101 2",
"a  c #BFBDBA",
"5  c #9794AE",
"q  c #A08091",
"@. c #C7FBFF",
"O  c #857C7E",
"^  c #EABD85",
"e  c #B29F80",
"-. c #E9EEF4",
"$  c #CA8B59",
"'  c #C7C4C4",
"4  c #8A95B9",
"<  c #8087B7",
"f  c #9198C5",
"z  c #9FACCD",
"{  c #CDC9C6",
"y  c #ABA9BF",
":  c #8584A7",
" . c none",
"n  c #A2ACCA",
"N  c #A8AAC9",
"V  c #A8BEDB",
"v  c #A49EC3",
"l  c #9AA4CA",
"J  c #ACD5F2",
"t  c #A3A1B7",
"]  c #C4C2C9",
"D  c #98C0ED",
"S  c #A1BCE0",
"3  c #8291BD",
"2  c #8A8CB5",
"I  c #B1D6ED",
"B  c #A1B1D0",
"K  c #AADCFF",
"7  c #9295BC",
"&  c #FEBB55",
"p  c #BAB7BD",
"x  c #93A7D3",
"R  c #B3E5FF",
"O. c #CBECFF",
"b  c #A5A2C3",
"Z  c #BAB6C2",
"k  c #91A7CB",
"U  c #BADCEE",
"G  c #A2D5FF",
"F  c #A2C0E0",
"M  c #ACABC5",
"Q  c #BDE4FC",
"g  c #989EC1",
":. c #ECFFFF",
"L  c #B9CFE0",
"1  c #858DB9",
"u  c #B7B4AF",
"#  c #DE833C",
"%  c #FEAE49",
"T  c #B2DFFF",
"0  c #9F9FB9",
")  c #C7C0B4",
"$. c #CBFCFE",
"[  c #C7C9C9",
"   c #7A7CA5",
",  c #868AAA",
"9  c #9B9AB3",
"P  c #B6D0E0",
"|  c #D1CDC8",
"~  c #BEF2FF",
"E  c #B5E8FF",
",. c #FDFEFF",
"m  c #AAA3C3",
"=  c #958C87",
">. c #F5FEFF",
"@  c #AD6D5A",
"!  c #BBEBFE",
"o. c #CBEDF3",
"A  c #BCBAC3",
"=. c #E3EEF4",
"r  c #A4A19E",
"*  c #FDBE5B",
"`  c #EAC185",
"%. c #D7E0ED",
"X. c #C0E9F8",
"#. c #CAF6FD",
"*. c #DBFEFE",
"c  c #95BDEE",
"Y  c #B4DCF2",
"}  c #CDC9C9",
"(  c #C1BEC7",
"o  c #8E7660",
".. c #CFDEED",
"H  c #A6D9FF",
"d  c #8B9CCD",
"i  c #B3B2BC",
".  c #7C81AB",
"+. c #C3F3FE",
"6  c #9698A1",
"&. c #D4FEFE",
"+  c #AF6D54",
";. c #E3FFFF",
"w  c #A28F98",
"h  c #8EA9D3",
"W  c #BBE7F3",
";  c #9A9897",
/* pixels */
" . . . . . . . . . . . . . . . . . . . . . . . . . . . .",
" . . . . . . . . . . . . . . . . . . . . . . . . . . . .",
" . . . . . . . . . . . . . . . . . . .|  . . . . . . . .",
" . . . . . . . . . . . . . .{ t . . 1 f 7 y |  . . . . .",
" . . . . . . . . . . . . .Z 2 k I X.+.Q J x 2 A  . . . .",
" . . . . . . . . . . . .Z g %.,.:.#.+.+.$.! c < p  . . .",
" . . . . . . . . . .| ] g ..,.,.O.Q H G K +.+.D . {  . .",
" . . . . . . . . . . .M V :.,.>.Q R R R E R ~ +.h 5  . .",
" . . . . . . . . . .} l U *.O.T K ! ~ @.@.@.+.$.J   {  .",
" . . . . . . . . . .( l +.#.Q R E @.$.&.*.&.&.$.W < (  .",
" . . . . . . . . . .] l $.R G E @.$.&.*.*.*.*.&.&.4 ]  .",
" . . . . . . . . . .] l +.! H R @.&.;.:.:.:.:.&.#.4 ]  .",
" . . . . . . . . . .] l U +.K E $.&.;.:.>.>.:.*.o.. '  .",
" . . . . . . . . . .| N S @.E ! $.*.;.:.,.,.,.;.P : |  .",
" . . . . . . . . . . .A d J @.~ @.&.;.:.>.,.,.=.4 p  . .",
" . . . . . . . . . . .[ 7 d Y $.$.&.*.*.;.>.-.n 9  . . .",
" . . . . . . . . .` ` ) 6 , d F W #.&.&.o.L z 0 |  . . .",
" . . . . . . . .^ & % $ = a Z 7 3 4 k B n b i |  . . . .",
" . . . . . . .^ * % # + w  . .] p i A [ ( }  . . . . . .",
" . . . . . .^ * % # @ q m }  . . . . . . . . . . . . . .",
" . . . . .^ * % # @ q v }  . . . . . . . . . . . . . . .",
" . . . .^ * % # @ q v }  . . . . . . . . . . . . . . . .",
" . . .^ * % # @ q v }  . . . . . . . . . . . . . . . . .",
" . . .e % # @ q b }  . . . . . . . . . . . . . . . . . .",
" . . .r o @ q b }  . . . . . . . . . . . . . . . . . . .",
" . . .u ; O m }  . . . . . . . . . . . . . . . . . . . .",
" . . . . . . . . . . . . . . . . . . . . . . . . . . . .",
" . . . . . . . . . . . . . . . . . . . . . . . . . . . .",
" . . . . . . . . . . . . . . . . . . . . . . . . . . . ."
};
EOT
} # search_xpm }}}

sub filter_xpm { # {{{

=head2 filter_xpm()

Returns a symbol for eyeglasses.

=cut

  return <<'EOT';
/* XPM */
static char *filter[] = {
/* columns rows colors chars-per-pixel */
"20 18 8 1",
"  c black",
". c #008484",
"X c #00ADAD",
"o c #00C6C6",
"O c cyan",
"+ c #21DEDE",
"@ c #848484",
"# c None",
/* pixels */
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"##@ #########  #####",
"## #@####### ## @###",
"## # @    #      @##",
"## ## O++o @ O++o ##",
"## ## +ooX # +ooX ##",
"### # +ooX # +ooX ##",
"##### oXX. # oXX. ##",
"######    ###    ###",
"####################",
"####################",
"####################",
"####################"
};
EOT
} # filter_xpm }}}

sub filter_switch_xpm { # {{{

=head2 filter_switch_xpm()

Returns a symbol for crossed out eyeglasses.

=cut

  return <<'EOT';
/* XPM */
static char *filter_switch[] = {
/* columns rows colors chars-per-pixel */
"25 20 178 2",
"   c black",
".  c #010000",
"X  c #000102",
"o  c #010204",
"O  c #060000",
"+  c #020808",
"@  c #000D0B",
"#  c #000C0D",
"$  c #000D0D",
"%  c #000D0E",
"&  c #030D0E",
"*  c #00100F",
"=  c #001110",
"-  c #001212",
";  c #001213",
":  c #001514",
">  c #001615",
",  c #001617",
"<  c #001618",
"1  c #001A19",
"2  c #001C1A",
"3  c #130000",
"4  c #140000",
"5  c #1F0000",
"6  c #200000",
"7  c #220000",
"8  c #250000",
"9  c #2F0304",
"0  c #3A6C6D",
"q  c #400000",
"w  c #410000",
"e  c #440000",
"r  c #450000",
"t  c #703C3E",
"y  c #7C3837",
"u  c #7C3839",
"i  c #37AFAE",
"p  c #3AAEAE",
"a  c #429090",
"s  c #659B9B",
"d  c #649C9B",
"f  c #778A88",
"g  c #7A8888",
"h  c #6DBEBF",
"j  c #6EBCBC",
"k  c #75B9BA",
"l  c #77B9B8",
"z  c #8F2F30",
"x  c #803637",
"c  c #843332",
"v  c #843435",
"b  c #883233",
"n  c #8B3130",
"m  c #8B3131",
"M  c #942D2E",
"N  c #952D2E",
"B  c #952E2F",
"V  c #992B2A",
"C  c #9B2929",
"Z  c #9B2B2A",
"A  c #9C2828",
"S  c #9D2929",
"D  c #9D292A",
"F  c #9C2A29",
"G  c #9C2A2A",
"H  c #9F2929",
"J  c #A42627",
"K  c #A72525",
"L  c #A62627",
"P  c #A22729",
"I  c #A22827",
"U  c #A02829",
"Y  c #AA2222",
"T  c #A92425",
"R  c #AB2524",
"E  c #8D4948",
"W  c #838383",
"Q  c #868583",
"!  c #8C8080",
"~  c #938789",
"^  c #9BA9AA",
"/  c #9BABAB",
"(  c #9BBDBE",
")  c #BA9C9E",
"_  c #A8B8B8",
"`  c gray75",
"'  c #BEBFC1",
"]  c #BFC1BE",
"[  c #B1C7C5",
"{  c #B3C5C5",
"}  c #B5C5C4",
"|  c #B5C5C5",
" . c #B6C4C4",
".. c #B7C5C5",
"X. c #BAC3C2",
"o. c #BAC2C4",
"O. c #BBC4C3",
"+. c #B8C4C4",
"@. c #BAC4C5",
"#. c #BCC0C1",
"$. c #BDC1C2",
"%. c #BCC2C0",
"&. c #BCC2C2",
"*. c #BFC1C0",
"=. c #BFC0C2",
"-. c #BFC3C2",
";. c #C39796",
":. c #C0BFBD",
">. c #C0BEBF",
",. c #C3BFBC",
"<. c #C3BFBE",
"1. c #C6BCBB",
"2. c #C5BCBD",
"3. c #C4BEBE",
"4. c #C5BFBF",
"5. c #C7BDBC",
"6. c #C6BDBE",
"7. c #C7BDBE",
"8. c #C6BEBC",
"9. c #CBBBBB",
"0. c #CBBBBC",
"q. c #C8BDBB",
"w. c #CABCBB",
"e. c #C8BCBC",
"r. c #C9BDBD",
"t. c #C8BCBE",
"y. c #CABCBC",
"u. c #CCBABA",
"i. c #CEB9B8",
"p. c #CFBAB9",
"a. c #CEBABB",
"s. c #D5B7B7",
"d. c #D2B8B7",
"f. c #D4B8B7",
"g. c #D6B8B6",
"h. c #D1B9B9",
"j. c #D2B8B9",
"k. c #D6B8B8",
"l. c #D8B6B5",
"z. c #D8B6B7",
"x. c #DCB2B3",
"c. c #DFB3B2",
"v. c #DDB3B4",
"b. c #DEB4B5",
"n. c #E7AFAE",
"m. c #E9AFAE",
"M. c #EDADAD",
"N. c #E7AFB0",
"B. c #E4B1AE",
"V. c #E3B1B2",
"C. c #E2B2B0",
"Z. c #E2B2B2",
"A. c #E4B1B0",
"S. c #E5B2B1",
"D. c #F3A5A5",
"F. c #F7A3A3",
"G. c #F4A4A3",
"H. c #F5A4A3",
"J. c #F1ABAB",
"K. c #F8A2A1",
"L. c #FAA2A1",
"P. c #FCA0A1",
"I. c #FDA5A4",
"U. c #FFA5A4",
"Y. c #FEA6A5",
"T. c #C1BFC0",
"R. c #C3BFC0",
"E. c #C4BEC0",
"W. c #C0C0BE",
"Q. c #C1C0BE",
"!. c #C1C1BF",
"~. c #C2C1BF",
"^. c #C0C0C0",
"/. c #C1C1C1",
"(. c #C0C0C2",
"). c #C2C0C1",
"_. c gray76",
"`. c #C4C0C1",
/* pixels */
"^.^.^.^.T.T.-.^.^.^.^.^.-.^.^.^.` ^.-.-.T.T.^.^.^.",
"^.^.^.^.-.-.T.T.^.^.^.^.T.T.T.E.y.a.t.E.T.T.^.^.^.",
"^.^.^.^.^.^.^.^.^.^.^.^.^.T.E.a.b.Z.s.p.E.T.^.^.~.",
"^.^.^.R.^.^.` ^.^.^.^.^.T.1.h.Z.D.b V.s.t.T.T.^.~.",
"^.T.T.T.^.^.^.^.T.-.^.^.1.h.N.I.P Z u s.w.~.~.~.` ",
"^.^.T.^.^.^.^.` ^.^.^.1.h.V.P.H T H M.s.1.` ` ~.^.",
"^.^.T.^.Q o <.` ^.T.1.h.m.I.K Y H H.c.w.~.~.^.^.^.",
"^.^.^.^.o ~.W ` @.$.y.c.L.H L Z J.6 ! ^.` ~.^.^.^.",
"^.^.^.^.o ` o g ; $ 3 w H P m 9 o ; % f %.` ^.^.^.",
"^.^.^.^.o ` ` $ ( / ;.m H M 5 _ l j s > ..O.-.^.^.",
"^.^.^.^.o ` ^.+ ^ ~ u M z m.$ k p i a 1 [ X.` -.^.",
"T.^.` ` <.O w.4 ) t z z w j.< h i i a 1 [ X.` ` R.",
"^.^.^.R.1.9.V.r z B b E 6 ~.> d a a 0 ; ..$.^.^.^.",
"^.^.^.E.9.x.H.Z L G r 8 a.%.{ $ > > % ..o.` ^.^.^.",
"^.^.~.y.f.M.H R H F.Z.h.R.` ` @.....$.$.` ^.^.^.^.",
"^.` <.w.s.u H U I.B.j.1.^.-.` ` ^.^.^.^.-.^.^.^.^.",
"^.^.~.w.f.B.c H.Z.h.y.R.^.^.R.^.^.^.^.^.^.^.^.^.^.",
"^.^.~.1.i.s.B.Z.h.E.R.^.^.^.^.^.^.^.^.^.^.^.^.^.^.",
"^.^.^.~.E.1.9.9.y.R.^.^.^.-.^.^.^.^.^.^.^.^.^.^.^.",
"` ` ^.^.^.` <.^.T.T.^.^.^.^.^.^.^.^.^.^.^.^.^.^.^."
};
EOT
} # filter_switch_xpm }}}

sub thumbs_xpm { # {{{

=head2 thumbs_xpm()

Returns a symbol for "Thumbnail" Dialog.

=cut


return <<'EOT';
/* XPM */
static char *thumbs[] = {
/* columns rows colors chars-per-pixel */
"21 20 149 2",
"gX c #C3C1B2",
"a  c #04065D",
"O  c #000007",
"9. c #ABCCB9",
"9X c #C6C597",
"F. c #BDC2BE",
"'. c #C4BEBE",
"0X c #C3C4A4",
"^  c #AB2325",
"y  c #080846",
":  c #070B3B",
" . c #BDBED2",
"0. c #AACCBB",
"n  c #2C612D",
"-  c #000800",
"j. c #B2CAB4",
"y. c #ACD0AC",
"-X c #E1B3B5",
"v  c #25672A",
":X c #F1ADAE",
"jX c #C1C1B7",
"S. c #BCC3BC",
"e. c #A4D4A4",
"5X c #C7BACB",
"*X c #E2B2B2",
"2  c #090A3A",
"I  c #47CD48",
"K. c #AAC9CC",
"j  c #2B5F2F",
"/. c #B3C2D5",
"(. c #B3C2D7",
"x  c #246724",
"Z  c #797835",
"k. c #B5C8B4",
"k  c #216623",
"g. c #B2CAB2",
"G  c #787643",
"4X c #C0BECB",
"M  c #7A7A22",
"L  c #45CF46",
"1  c #0F063B",
"N. c #BAC6BA",
"u  c #04045A",
">X c #FBA5A6",
",X c #F8A3B6",
",  c #050C38",
"P  c #45CF48",
"oX c #D5B6BC",
"8. c #ACCCB4",
"E  c #58C05D",
"d. c #B4C4BA",
"u. c #A4D0B7",
"q. c #A4D3A5",
"=. c #9ADA9D",
"`  c #BEBEC6",
"&X c #EDABB9",
"pX c #C1C3AE",
"$X c #EBADAE",
"*. c #97DC99",
"Y  c #47CC4D",
"}  c #BDBED0",
"cX c #C1C0BC",
"J. c #BDC4BD",
"d  c #08035D",
"MX c #C0C0CA",
".X c #CEBABB",
"3X c #C0BEC9",
"B. c #BAC4BC",
"w  c #09064B",
"2. c #ABCFAB",
";  c #0A0000",
"bX c #C1C1BF",
"5  c #030947",
"7X c #D1B3D5",
"q  c #08074B",
"+X c #D2B8B9",
"/  c #A92425",
"e  c #09064D",
"tX c #C5C5A1",
"$  c #070000",
"4  c #06064C",
"`. c #C4BFBC",
"V  c #77793A",
"6X c #C0BCD3",
"1. c #8BE29E",
"Y. c #B7C5C6",
"@X c #DBB5B4",
"J  c #2EDE33",
"i. c #A5D1BA",
"z. c #B9C6B4",
"4. c #AECDAD",
"v. c #BAC5B7",
"D  c #747645",
"S  c #78783C",
"uX c #C3C3A9",
"vX c #C0C0BE",
"K  c #30DE31",
"B  c #7B7B25",
"H. c #BFC1BE",
"XX c #D5B7B7",
"O. c #BEBFD4",
"!. c #BDC1C4",
"fX c #C4C4AC",
"dX c #C3C2AE",
"). c #B1C2DC",
"zX c #C1C1B9",
"iX c #C3C3AB",
"Q  c #942D31",
"g  c #176F18",
":. c #96DBA5",
"#X c #DCB6B5",
"}. c #CABCBC",
"6. c #AFCEAF",
"<X c #C1BFC0",
"#  c #000600",
"T  c #56C05B",
"0  c #07084B",
")  c #C61819",
"7. c #ABCBB3",
"P. c #A4CBD0",
"8X c #D5B0DC",
"s  c #05075C",
"b. c #BFC3B5",
",. c #8DE58F",
"^. c #BAC1CB",
"r. c #A8D1A9",
"s. c #B6C7B7",
"!  c #A7242A",
"]. c #CABCBB",
"X  c #000300",
"A  c #797837",
"r  c #0E0548",
"*  c #00000B",
"I. c #AFC3DC",
"%. c #BEBFDD",
"f. c #B6C5BE",
" X c #CCBAB8",
"%X c #EBAEAD",
"(  c #AD2323",
"Z. c #BDC2BB",
"C. c #BCC3BB",
"+. c #BDBCDB",
"&. c #97DD97",
"h. c #B3CBB3",
"6  c #010C42",
"2X c #C3BEC5",
"eX c #C4C3A5",
"h  c #176F19",
"W  c #952D2E",
/* pixels */
"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
"<X'.}. X+X+X.X}.2X3X^.4X^.MXH.B.N.v.N.S.Z.",
"'.}.XX*X%X%X#XoX5X6X+.+.6X^.f.j.4.4.g.k.S.",
"}.XX$XW ( ^ Q &X7X1 w 0 : (.0.j k x n 2.k.",
"].@X>X^ ) ) ! ,X8Xr d u 5 I.i.v h g x q.j.",
"].@X>X/ ) ) ! ,X8Xr d a 5 ).u.v h g x q.h.",
"}.XX:XW ( ^ Q &X7X1 e 4 : /.9.j k k n y.k.",
"'.].XX*X$X$X-XoX5X6X+.+.O.^.d.j.4.4.g.v.C.",
"` `.cX; ; ; $ '.` * * * O ` F.X X # # F.Z.",
"Z.Z.b.v.z.v.v.S.!.MX3X4XMXH.` jXb.b.zXZ.Z.",
"Z.s.4.e.=.=.q.7.^.^.+.+.} ` zXiX0X0XfXgXzX",
"S.6.*.T L L E :.K.: 0 q : } pXD Z Z G tXdX",
"d.r.,.I J J Y 1.P.6 s u y O.iXV B M A 9XuX",
"k.r.,.I K K Y 1.P.6 a u y O.pXS B M Z 9XfX",
"N.4.&.T L P E :.K., 5 w 2 }  XD Z Z G tX X",
"C.v.6.q.=.=.q.8.Y. .%.+. .` b.iXeXeXuX Xb.",
"F.F.N.# - - # B.H.O O * X ` vXX X X # Z.J.",
"` zXZ.F.S.S.S.Z.` bXbX` bXbX` cXcXZ.cXbXbX",
"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
};
EOT

} # thumbs_xpm }}} }}}

sub dias_xpm { # {{{

=head2 dias_xpm()

Returns a symbol for "Diashow" Dialog.

=cut


return <<'EOT';
/* XPM */
static char *dias[] = {
/* columns rows colors chars-per-pixel */
"16 14 136 2",
"   c black",
".  c #010101",
"X  c #000202",
"o  c #000400",
"O  c #000500",
"+  c #000405",
"@  c #000504",
"#  c #000505",
"$  c #000605",
"%  c #000A00",
"&  c #000C00",
"*  c #000F00",
"=  c #000809",
"-  c #000909",
";  c #000A09",
":  c #000F09",
">  c #000D0C",
",  c #000C0E",
"<  c #000E0E",
"1  c #000E10",
"2  c #001000",
"3  c #001300",
"4  c #001602",
"5  c #001407",
"6  c #00170B",
"7  c #001900",
"8  c #001A00",
"9  c #001D00",
"0  c #001E00",
"q  c #001112",
"w  c #001212",
"e  c #001413",
"r  c #001617",
"t  c #001919",
"y  c #001D1C",
"u  c #003318",
"i  c #002523",
"p  c #002625",
"a  c #003421",
"s  c #007B2D",
"d  c #007636",
"f  c #03723D",
"g  c #00753D",
"h  c #00793D",
"j  c #146A3B",
"k  c #3F5F0C",
"l  c #3A5A29",
"z  c #216439",
"x  c #006F5D",
"c  c #007646",
"v  c #007C40",
"b  c #00755D",
"n  c #136946",
"m  c #1B6446",
"M  c #1B7E48",
"N  c #23784F",
"B  c #237756",
"V  c #237658",
"C  c #21765F",
"Z  c #23755E",
"A  c #2A715F",
"S  c #257363",
"D  c #22736D",
"F  c #227468",
"G  c #376A65",
"H  c #495139",
"J  c #008436",
"K  c #00883D",
"L  c #10863C",
"P  c #008246",
"I  c #008E64",
"U  c #008A76",
"Y  c #2AA69B",
"T  c #3CEFB7",
"R  c #19FADC",
"E  c #0BFBFA",
"W  c #17F7EC",
"Q  c #13FAE6",
"!  c #16F7F1",
"~  c #16F6F6",
"^  c #12F9F3",
"/  c #13FAF4",
"(  c #24F6D1",
")  c #3FE7DA",
"_  c #39EAD6",
"`  c #2FEBEC",
"'  c #21F4E1",
"]  c #24F2E6",
"[  c #21F2EC",
"{  c #21F1F1",
"}  c #32EBE6",
"|  c #35E9E8",
" . c #3AE6E6",
".. c #39E8E3",
"X. c #38E8E6",
"o. c #5E8E8E",
"O. c #5C908C",
"+. c #4EDEDE",
"@. c #51DDDC",
"#. c #51DDDE",
"$. c #56DBDA",
"%. c #56DADC",
"&. c #59D9DA",
"*. c #40EAC6",
"=. c #4DE2CF",
"-. c #41E6D5",
";. c #52E1CF",
":. c #43E3E3",
">. c #40E4E3",
",. c #64D4D5",
"<. c #68D4D4",
"1. c #7BCBCC",
"2. c #78CCCC",
"3. c #70D0CF",
"4. c #77FFFF",
"5. c #808080",
"6. c #9DBDBC",
"7. c #8AC4C5",
"8. c #8BFFFF",
"9. c #B6C4C4",
"0. c #B9C3C4",
"q. c #BCFFFF",
"w. c #DAF2A8",
"e. c #C0C0C0",
"r. c #C7FFFF",
"t. c #CFFFFF",
"y. c #E9FFFF",
"u. c #EBFFFF",
"i. c #F1FFFA",
"p. c #F1FFFF",
"a. c #F7FFFB",
"s. c #F4FFFF",
"d. c #F5FFFF",
"f. c #FBFFFA",
"g. c #F8FFFF",
"h. c #FEFFFF",
/* pixels */
"                                ",
"s.$ u.; u.; u.; u.; u.; p.$ u.; ",
"< w t y y y y y y y y t w w t y ",
"1.y &.#.$.$.#.+.+.$.<.2.7.r %.:.",
",.p :.>.#.@. . .X.#.t.u.p.w  .~ ",
"3.i | 4.8.8.4.{ { 8.r.u.i.6 } E ",
"6.t ` ^ ( [ / E E [ =.q.z 9 ) { ",
"H 4 ..W ( I R Q W ] *.c j 9 Y +.",
"w.8 ;._ P J K T ) U h d B 5 o.o.",
"k 8 u b g L s h u x f M A < 9.5.",
"l 4 m Z Z B N n D D S S G ; 9.e.",
"% % * * : : * * : < 1 < ; $     ",
"f.@ a.@ s.@ s.@ s.$ s.$ h.  h.  ",
"                                "
};
EOT

} # dias_xpm }}} }}}

sub rotate_left_xpm { # {{{

=head2 rotate_left_xpm( $color )

Returns a symbol for a "rotate left" arrow.
The $color parameter is optional.
Default color is "#FCFCFC".

=cut

  my $color = shift || "#FCFCFC";
  return <<"EOT";
/* XPM */
static char *rotate-left[] = {
/* columns rows colors chars-per-pixel */
\"22 20 4 2\",
\"   c #040204\",
\"X  c none\",
\"o  c $color\",
\".  c #848284\",
/* pixels */
\"X X X X X X X X X X X X X X X X X X X X X X \",
\"X X X X X X X X X X X X X X X X X X X X X X \",
\"X X X X X X X X X X X X X X X X X X X X X X \",
\"X X X X     X X           X X X X X X X X X \",
\"X X X X   o     o o o o o     X X X X X X X \",
\"X X X X   o o o o o o o o o o   X X X X X X \",
\"X X X X   o o o o         o o   . X X X X X \",
\"X X X X   o o o o   . . .   o o   X X X X X \",
\"X X X X   o o o o o   X X   o o   . X X X X \",
\"X X X X               . X   o o   . X X X X \",
\"X X X X X .   . . . . . X   o o   . X X X X \",
\"X X X X X   o   X X X X X   o o   . X X X X \",
\"X X X X X   o o           o o   . . X X X X \",
\"X X X X X X   o o o o o o o o   . X X X X X \",
\"X X X X X X X   o o o o o     . . X X X X X \",
\"X X X X X X X X           . . . X X X X X X \",
\"X X X X X X X X X . . . . . X X X X X X X X \",
\"X X X X X X X X X X X X X X X X X X X X X X \",
\"X X X X X X X X X X X X X X X X X X X X X X \",
\"X X X X X X X X X X X X X X X X X X X X X X \"
};
EOT
} # rotate_left_xpm }}}

sub rotate_right_xpm { # {{{

=head2 rotate_right_xpm( $color )

Returns a symbol for a "rotate right" arrow.
The $color parameter is optional.
Default color is "#FCFCFC".

=cut

  my $color = shift || "#FCFCFC";
  return <<"EOT";
/* XPM */
static char *rotate-right[] = {
/* columns rows colors chars-per-pixel */
\"22 20 4 2\",
\"   c #040204\",
\"X  c none\",
\"o  c $color\",
\".  c #848284\",
/* pixels */
\"X X X X X X X X X X X X X X X X X X X X X X \",
\"X X X X X X X X X X X X X X X X X X X X X X \",
\"X X X X X X X X X X X X X X X X X X X X X X \",
\"X X X X X X X X           X X     X X X X X \",
\"X X X X X X     o o o o o     o   . X X X X \",
\"X X X X X   o o o o o o o o o o   . X X X X \",
\"X X X X X   o o         o o o o   . X X X X \",
\"X X X X   o o   . . .   o o o o   . X X X X \",
\"X X X X   o o   . X   o o o o o   . X X X X \",
\"X X X X   o o   . X               . X X X X \",
\"X X X X   o o   . X X . . .   . . . X X X X \",
\"X X X X   o o   . X X X X   o   X X X X X X \",
\"X X X X X   o o           o o   . X X X X X \",
\"X X X X X   o o o o o o o o   . . X X X X X \",
\"X X X X X X     o o o o o   . . X X X X X X \",
\"X X X X X X X X           . . X X X X X X X \",
\"X X X X X X X X X . . . . . X X X X X X X X \",
\"X X X X X X X X X X X X X X X X X X X X X X \",
\"X X X X X X X X X X X X X X X X X X X X X X \",
\"X X X X X X X X X X X X X X X X X X X X X X \"
};
EOT
} # rotate_right_xpm }}}

sub exit_xpm { #{{{

=head2 exit_xpm( $color )

Returns a symbol for an "Exit" button.
The $color parameter for the text is optional.
Default color is "#000000".

=cut

  my $color = shift || "#000000";
  return <<"EOT";
/* XPM */
static char * exit_xpm[] = {
\"20 12 3 1\",
\" 	s None	c None\",
\".	c $color\",
\"X	c white\",
\"                    \",
\" . .. .   . . ..... \",
\" .    .   . .   .   \",
\" .     . .  .   .   \",
\" .     . .  .   .   \",
\" . .    .   .   .   \",
\" .      .   .   .   \",
\" .     . .  .   .   \",
\" .     . .  .   .   \",
\" .    .   . .   .   \",
\" . .. .   . .   .   \",
\"                    \"};
EOT
} # exit_xpm }}}

sub stop_xpm { #{{{

=head2 stop_xpm()

Returns a symbol for a "Stop" button.

=cut

  return <<'EOT';
/* XPM */
static char * stop_xpm[] = {
"20 20 3 1",
" 	s None	c None",
".	c red",
"X	c white",
"                    ",
"                    ",
"      ........      ",
"     ..........     ",
"    ............    ",
"   ..............   ",
"  ................  ",
"  ..cc.ccc.c..cc..  ",
"  ..c.c.c.c.c.c.c.  ",
"  ..c...c.c.c.c.c.  ",
"  ..cc..c.c.c.c.c.  ",
"  ...c..c.c.c.cc..  ",
"  .c.c..c.c.c.c...  ",
"  ..cc..c..c..c...  ",
"   ..............   ",
"    ............    ",
"     ..........     ",
"      ........      ",
"                    ",
"                    "};
EOT
} # stop_xpm }}}

sub eye_xpm { #{{{

=head2 eye_xpm()

Returns a symbol for an "Eye" button.

=cut

  return <<'EOT';
/* XPM */
static char *eye[] = {
/* columns rows colors chars-per-pixel */
"20 18 123 2",
"5  c #00004B",
"a  c gray26",
"@. c #A4A3B1",
"q  c #131142",
"O  c #0D0D0F",
"9. c #E7E7E7",
"^  c #9D9D9F",
"e  c #191A5D",
"-. c #C0C0C0",
"$  c #151515",
"'  c gray63",
"4  c #030244",
"<  c #333237",
"C  c gray46",
"f  c #42425A",
"y  c #28285A",
"{  c gray66",
":  c #2E2E36",
"0. c #EAEAEA",
" . c gray67",
"n  c #686868",
"-  c #0A0837",
"N  c #70706E",
"V  c #727272",
"y. c #F1F1F1",
"1. c #D7D7D7",
"v  c gray39",
"J  c #6B6B87",
"t  c #1E2049",
"l  c #5A5A5A",
"]  c gray64",
"4. c #CAC9E8",
"e. c #E6E6FF",
"<. c #D5D5D5",
"v. c #FDFFFE",
"S  c #7E7E7E",
"3  c #3A3A3A",
"_  c #8F8FB3",
"2  c gray22",
"I  c #8E8E8E",
"j  c #51514F",
"K  c #7E7D83",
"7  c #0A0851",
"&  c #050529",
"p  c #20217E",
"w. c #E0E0FA",
"x  c #5D5E60",
"R  c #8E8D9B",
"5. c #E3E1E2",
"b  c #68676D",
">  c #2B293F",
"V. c none",
"k  c #505251",
"g. c #FBFBFB",
"U  c #818092",
"G  c #515187",
"F  c #2B2B8B",
"Q  c #949597",
"M  c gray42",
":. c #C6C6C4",
"L  c #838182",
"t. c #EDECF2",
"1  c #35333E",
"6. c #E2E2E2",
"u  c #343247",
"p. c #F5F5F7",
"a. c #F6F5FF",
"#  c #0A0A12",
"T  c #888797",
"%  c gray12",
"$. c #B0B1B5",
"[  c #A3A4A9",
"   c #070707",
"7. c #E3E4E6",
",  c #323232",
"9  c #080959",
"P  c #898987",
"s  c #484743",
"8  c #0D0D57",
"|  c #AAAAAA",
"~  c #9A9A9C",
"E  c gray57",
"8. c gray90",
"d. c #FAF9F5",
",. c #D0D2CF",
"r. c #E8E7F9",
"m  c #6A686B",
"=  c #07073B",
">. c gray79",
"@  c #0A0911",
"u. c gray95",
"!  c #999798",
"X  c #05050D",
"q. c #EFEFEF",
"A  c gray48",
"=. c #908FC8",
"r  c #0F1060",
"*  c #06052F",
"`  c #9D9FAC",
"%. c #B8B7BC",
"X. c #ACACAC",
"f. c #F9F9F9",
"*. c #8381D5",
"Y  c #848490",
"}  c #A9A9A9",
"(  c #8585A7",
"l. c #FDFDFB",
".. c #AEADA9",
"o  c #0C0A0B",
"H  c #58579D",
"d  c #4E4E4E",
"i  c #2B296A",
".  c #060608",
"+. c #AFAFAF",
"3. c #DFDFDF",
"6  c #090947",
"&. c #BCBCBC",
"+  c #000115",
"W  c #959595",
"w  c #13124B",
"h  c #4F4E53",
"2. c #DDDDDD",
";  c #161535",
/* pixels */
"V.V.V.V.V.V.V.V.V.V.v.V.V.V.V.V.V.V.V.V.",
"V.V.V.l.V.V.V.V.V.V.V.v.V.V.v.V.V.V.V.V.",
"V.V.V.V.V.V.V.V.V.v.V.V.V.V.V.V.V.V.V.V.",
"V.V.V.V.V.V. .u.-.f.3.V.6.3.V.V.V.V.V.V.",
"V.V.V.l.S g.I X.M <.l y.X.} 9.q.V.V.V.V.",
"V.0.{ V.C +.| X.^ %.b t.~ +.I  .E V.V.V.",
"V.d.V L 8.d ! m h 1 u U : Q 2 >.V V.V.V.",
"V.] 5.C v $ o @ > ; * & + # < a 2.A u.V.",
"V.&.k N   N 1.r.=.8 7 6 t f X . l n f.V.",
"V.V.p.v P g.v.e.8 p *.H G v.Y O S v.V.V.",
"V.V.g.j ..l.V.4.9 F 5 i w a.V.W , g.V.V.",
"V.V.V.:.s d.V.w.e r 4 6 q a.V.n % V.V.V.",
"V.V.V.v.,.k x ` _ y = - J @.K 3 ' g.V.V.",
"V.V.V.V.v.v.7.[ T T ( ( R $.-.V.V.V.V.V.",
"V.V.V.V.V.V.v.V.V.v.v.V.V.V.V.V.V.V.V.V.",
"V.V.V.V.V.V.V.V.V.V.V.V.V.V.V.V.V.V.V.V.",
"V.V.V.V.V.V.V.V.V.V.V.V.V.V.V.V.V.V.V.V.",
"V.V.V.V.V.V.V.V.V.V.V.V.V.V.V.V.V.V.V.V."
};
EOT


} # eye_xpm }}}

sub noeye_xpm { #{{{

=head2 noeye_xpm()

Returns a symbol for an "Crossed out Eye" button.

=cut

  return <<'EOT';
/* XPM */
static char *noeye[] = {
/* columns rows colors chars-per-pixel */
"20 18 96 2",
"5  c #00004B",
"a  c gray26",
"O  c #0D0D0F",
"^  c #9D9D9F",
"-. c #C0C0C0",
"$  c #151515",
"'  c gray63",
"4  c #030244",
"<  c #333237",
"C  c gray46",
"f  c #42425A",
"y  c #28285A",
"{  c gray66",
"0. c #EAEAEA",
" . c gray67",
"n  c #686868",
"-  c #0A0837",
"N  c #70706E",
"V  c #727272",
"y. c #F1F1F1",
"1. c #D7D7D7",
"v  c gray39",
"J  c #6B6B87",
"t  c #1E2049",
"l  c #5A5A5A",
"]  c gray64",
"4. c #CAC9E8",
"e. c #E6E6FF",
"<. c #D5D5D5",
"v. c #FDFFFE",
"S  c #7E7E7E",
"3  c #3A3A3A",
"_  c #8F8FB3",
"2  c gray22",
"j  c #51514F",
"XX c #CC0000",
"R  c #8E8D9B",
"5. c #E3E1E2",
"b  c #68676D",
"V. c none",
"k  c #505251",
"g. c #FBFBFB",
"U  c #818092",
"G  c #515187",
"M  c gray42",
":. c #C6C6C4",
"t. c #EDECF2",
"L  c #838182",
"1  c #35333E",
"6. c #E2E2E2",
"u  c #343247",
"p. c #F5F5F7",
"a. c #F6F5FF",
"#  c #0A0A12",
"T  c #888797",
"%  c gray12",
"$. c #B0B1B5",
"[  c #A3A4A9",
"   c #070707",
",  c #323232",
"P  c #898987",
"s  c #484743",
"8  c #0D0D57",
"~  c #9A9A9C",
"E  c gray57",
"8. c gray90",
"d. c #FAF9F5",
",. c #D0D2CF",
"r. c #E8E7F9",
"=  c #07073B",
">. c gray79",
"@  c #0A0911",
"u. c gray95",
"!  c #999798",
"X  c #05050D",
"A  c gray48",
"=. c #908FC8",
"r  c #0F1060",
"*  c #06052F",
"%. c #B8B7BC",
"X. c #ACACAC",
"f. c #F9F9F9",
"Y  c #848490",
"}  c #A9A9A9",
"(  c #8585A7",
"l. c #FDFDFB",
".. c #AEADA9",
"o  c #0C0A0B",
"d  c #4E4E4E",
".  c #060608",
"+. c #AFAFAF",
"3. c #DFDFDF",
"6  c #090947",
"&. c #BCBCBC",
"W  c #959595",
"2. c #DDDDDD",
/* pixels */
"V.XXXXV.V.V.V.V.V.V.v.V.V.V.V.V.V.V.XXXX",
"V.V.XXXXV.V.V.V.V.V.V.v.V.V.v.V.V.XXXXV.",
"V.V.V.XXXXV.V.V.V.v.V.V.V.V.V.V.XXXXV.V.",
"V.V.V.V.XXXX .u.-.f.3.V.6.3.V.XXXXV.V.V.",
"V.V.V.l.S XXXXX.M <.l y.X.} XXXXV.V.V.V.",
"V.0.{ V.C +.XXXX^ %.b t.~ XXXX .E V.V.V.",
"V.d.V L 8.d ! XXXX1 u U XXXX2 >.V V.V.V.",
"V.] 5.C v $ o @ XXXX* XXXX# < a 2.A u.V.",
"V.&.k N   N 1.r.=.XXXXXXt f X . l n f.V.",
"V.V.p.v P g.v.e.8 XXXXXXG v.Y O S v.V.V.",
"V.V.g.j ..l.V.4.XXXX5 XXXXa.V.W , g.V.V.",
"V.V.V.:.s d.V.XXXXr 4 6 XXXXV.n % V.V.V.",
"V.V.V.v.,.k XXXX_ y = - J XXXX3 ' g.V.V.",
"V.V.V.V.v.XXXX[ T T ( ( R $.XXXXV.V.V.V.",
"V.V.V.V.XXXXv.V.V.v.v.V.V.V.V.XXXXV.V.V.",
"V.V.V.XXXXV.V.V.V.V.V.V.V.V.V.V.XXXXV.V.",
"V.V.XXXXV.V.V.V.V.V.V.V.V.V.V.V.V.XXXXV.",
"V.XXXXV.V.V.V.V.V.V.V.V.V.V.V.V.V.V.XXXX"
};
EOT

} # noeye_xpm }}}

sub lock_xpm { #{{{

=head2 lock_xpm()

Returns a symbol for a "Lock" button.

=cut

  return <<'EOT';
/* XPM */
static char *schloss[] = {
/* columns rows colors chars-per-pixel */
"20 20 161 2",
"a  c #836B3D",
"@. c #999186",
"'. c #F2F1ED",
"F. c #D5CFC3",
"^  c #91877B",
";X c #FBF9FA",
"n. c #C5C0BC",
"<  c #6D665E",
"f  c #826B41",
"y  c #7C7B79",
":  c #54504F",
"0. c #AFA69D",
" . c #A59476",
"n  c #8F7B58",
"N  c #94794C",
"-  c #7E653D",
"j. c #C2B499",
"y. c #A9A8A4",
"v  c #897655",
"-X c #F9F9F9",
"l  c #84704B",
":X c #FBFBFB",
"e. c #BBA887",
"=X c #FFFFF4",
"3  c #7E6843",
"*X c #FFFEF5",
"I  c #81807E",
"j  c #856F46",
"K. c #D7D7D7",
"7  c #7F6C4C",
"/. c #EEEDE9",
"&  c #7E663A",
"w. c #B5A78D",
"x  c #8D764C",
"R  c #98876B",
"b  c #88775D",
"Z  c #827E7D",
"k. c #C0B7A8",
"V. c #C9C5C4",
"k  c #836F4C",
"g. c #BBBAB8",
"G  c #9D845B",
"M  c #937B4D",
"L  c #9F885F",
"t. c #BDB19B",
"1  c #776243",
"N. c #DDD2BE",
"u  c #82673A",
"p. c #BCB3A4",
"a. c #BEB5A4",
"[  c #A08556",
"   c #765A33",
"E. c #F9EDDD",
",  c #64605F",
"P  c #8E826A",
"8  c #7E6F58",
"oX c gray96",
"~. c #E9E8E6",
"8. c #AAA498",
"d. c #BEBAB1",
">. c #9D9C9A",
"u. c #AFABAA",
"q. c #B1A285",
"L. c #D9D6D1",
"x. c #C3BFB6",
"{. c #F7F4EF",
"`  c #99907F",
"X. c #A3977F",
"T. c #E8DBCA",
"G. c #D0CFCD",
"*. c #979694",
"c  c #837254",
"Y  c #948568",
"|. c #FEF6E9",
"R. c #EDE5D2",
"c. c #C7BFB2",
"H  c #9D845C",
"J. c #D2D0D1",
"i  c #80673E",
".X c gray95",
"B. c gray78",
"w  c #77726E",
"7X c #FFFFFB",
"/  c #968976",
"e  c #757170",
"$  c #7C633A",
"'  c #9E927A",
"4  c #7C6847",
"z  c #8A7244",
"`. c #F2EFEA",
"V  c #8D7C60",
"1. c #A59C8B",
"Y. c #DBD9DA",
"@X c #FAF7F2",
"J  c #9D865C",
"]  c #9E927C",
"z. c #C2BEB5",
"i. c #B8B1A7",
"<. c #A09989",
"4. c #AEA28A",
"D  c #9F8353",
"v. c #CCC1AF",
"S  c #94825E",
"_  c #988A70",
"B  c #977C4D",
"H. c #DAD5CF",
"O. c #B09E7A",
"5. c #A2A19F",
">  c #5E5244",
"!. c #E7E7E7",
"m. c #CBC7BE",
"). c #F2EEE5",
"F  c #998258",
"g  c #846A47",
":. c #9A9899",
"}. c #F8F0E3",
"6. c #A4A09F",
"M. c #D1C8B9",
"#  c #7B633D",
"A. c #CECBC6",
"%  c #7F6739",
"0  c #6A6665",
"$. c #939290",
"7. c #A9A091",
"P. c #D9D5D4",
"8X c gray99",
"s  c #846C3E",
"|  c #A59073",
"~  c #998968",
"b. c #C2C1BF",
",. c #9E9D9B",
"r. c #B5AC9B",
"m  c #90784C",
"o. c #AE9B73",
"!  c #9D8964",
"r  c #797574",
"*  c #7C653C",
"wX c none",
"I. c #DFDCD7",
"W. c #E2E2E2",
"%. c #969291",
"[. c #F5F2ED",
"f. c #BCB9B4",
"#. c #9F9685",
"%X c #FCFBF7",
" X c #F1F1F1",
"Z. c #CEC9C3",
"(  c #998970",
"l. c #CDBEA9",
"o  c #7B6239",
"C. c #CDC9C0",
".  c #7B6337",
"D. c #D3CCC4",
"3. c #AF9F86",
"+. c #858482",
"6  c #7C694B",
"&. c #959394",
"h. c #BEBCBD",
";. c #9A9997",
"h  c #856E42",
"W  c #9F8960",
/* pixels */
"wXwXwXwXwXwXwXwXwXoXV.%.Z 6.Y.;XwXwXwXwX",
"wXwXwXwXwXwXwXwX~.5.0 *.e , y h.oXwXwXwX",
"wXwXwXwXwXwXwXoXI w $.;.*.;.Z +.B.oXwXwX",
"wXwXwXwXwXwXwXb.: *.>.g.G.G.u.y :.!.wXwX",
"wXwXwXwXwXwX{.w r ,.J. X8X%XP., &.K.wXwX",
"wXwXwXwX=XF.p.> @.k.`.wXwXwXn.: 5.K.:XwX",
"wXwXwX*XR.V 7 4 6 V 3.l.T.E.^ < y.W.wXwX",
"wXwXwX=Xj.k - $ $ # # 1 6 b 8 ` f. XwXwX",
"wXwXwX}.V s i o $ o & * - 3 n w.C.-XwXwX",
"wXwX*Xv.l * o o $ o   % & h o.O.m.-XwXwX",
"wXwX|._ 3 . o o o $ $ * & x e.X.Z.;XwXwX",
"wX*XN.c - . o $   * $   s W q.1.I.:XwXwX",
"wX*X4.v j f * . . . . * z o.] i.).wXwXwX",
"wX*Xt.~ ! W H G m a u a M O.#.A.oXwXwXwX",
"wXwXM.( ~ W g   N [ D B J  .8.!.wXwXwXwX",
"wXwX).a.] ( R | W F L L S ' d..XwXwXwXwX",
"wXwX*X/.H.z.0.7./ _ Y Y P <.L.:XwXwXwXwX",
"wXwXwXwX;X.X~.I.D.c.a.r.0.x./.wXwXwXwXwX",
"wXwXwXwXwXwXwXwX%X@X[.).).'.wXwXwXwXwXwX",
"wXwXwXwXwXwXwXwXwXwXwXwXwXwXwXwXwXwXwXwX"
};
EOT
} # lock_xpm }}}

sub money_xpm { # {{{

=head2 money_xpm()

Returns a 32 x 32 symbol for money.

=cut

  return <<'EOT';
/* XPM */
static char *geld[] = {
/* columns rows colors chars-per-pixel */
"25 25 256 2",
"   c #0D5C7B",
".  c #104C68",
"X  c #1E5A6C",
"o  c #14516B",
"O  c #155E7D",
"+  c #195973",
"@  c #1D5D78",
"#  c #0D4866",
"$  c #1D637C",
"%  c #186577",
"&  c #314F57",
"*  c #355153",
"=  c #23596C",
"-  c #24566F",
";  c #215C71",
":  c #225E7A",
">  c #395E67",
",  c #3D625A",
"<  c #2E676E",
"1  c #2B6473",
"2  c #276678",
"3  c #366C79",
"4  c #3C717A",
"5  c #6C5B3F",
"6  c #7D5F3D",
"7  c #4E4E49",
"8  c #465455",
"9  c #514C46",
"0  c #595C59",
"q  c #555A57",
"w  c #45696C",
"e  c #4B6D6C",
"r  c #456C67",
"t  c #4B6972",
"y  c #526A67",
"u  c #5C7877",
"i  c #625F5A",
"p  c #6C6650",
"a  c #786142",
"s  c #7C6F56",
"d  c #646965",
"f  c #7B7462",
"g  c #7E7868",
"h  c #777874",
"j  c #6A7674",
"k  c #1B6483",
"l  c #1D6B84",
"z  c #1C688A",
"x  c #166686",
"c  c #1F738F",
"v  c #256C84",
"b  c #236C8B",
"n  c #2B6B84",
"m  c #2A6D8A",
"M  c #236D90",
"N  c #26738C",
"B  c #2B728D",
"V  c #2D788F",
"C  c #257492",
"Z  c #2B7593",
"A  c #2B7994",
"S  c #2C7C9B",
"D  c #2A7599",
"F  c #326D86",
"G  c #376C8B",
"H  c #327384",
"J  c #33738D",
"K  c #337D8B",
"L  c #387587",
"P  c #337C94",
"I  c #347C9B",
"U  c #3C7994",
"Y  c #3B7D99",
"T  c #397595",
"R  c #477886",
"E  c #447C91",
"W  c #517D8A",
"Q  c #667C84",
"!  c #747F81",
"~  c #7C806F",
"^  c #78867C",
"/  c #36808B",
"(  c #338295",
")  c #34829B",
"_  c #3B819C",
"`  c #3D879A",
"'  c #3B83A1",
"]  c #3B89A5",
"[  c #3F8CAC",
"{  c #3789A1",
"}  c #438198",
"|  c #418999",
" . c #4A8293",
".. c #4A8697",
"X. c #558A88",
"o. c #51909B",
"O. c #5F959F",
"+. c #588E9A",
"@. c #438DA4",
"#. c #4C8BA3",
"$. c #4A8DAA",
"%. c #4485A1",
"&. c #4190A4",
"*. c #4A92AD",
"=. c #4596AC",
"-. c #4696B3",
";. c #4D95B2",
":. c #4E9AB4",
">. c #4F9CB8",
",. c #538FA3",
"<. c #5394AA",
"1. c #519BAC",
"2. c #5896AB",
"3. c #589AAD",
"4. c #5695A4",
"5. c #529BB3",
"6. c #5899B4",
"7. c #5C9EB9",
"8. c #549EB9",
"9. c #54A2B9",
"0. c #5DA2BE",
"q. c #5AA1B5",
"w. c #688486",
"e. c #6A8189",
"r. c #6B8E90",
"t. c #63928C",
"y. c #68969B",
"u. c #788688",
"i. c #748C93",
"p. c #7A918B",
"a. c #779796",
"s. c #6A9CB4",
"d. c #619DB7",
"f. c #7C9BA4",
"g. c #6199A8",
"h. c #62A1B8",
"j. c #6CA4B4",
"k. c #67A6BA",
"l. c #78AAB9",
"z. c #7BB7B7",
"x. c #71A5A6",
"c. c #5CA3C1",
"v. c #6BABC4",
"b. c #64A8C1",
"n. c #7AB5C5",
"m. c #7AB6CF",
"M. c #76B4CC",
"N. c #7AB6D0",
"B. c #81572D",
"V. c #855B33",
"C. c #94673E",
"Z. c #AA6732",
"A. c #8F6E4B",
"S. c #8A6F51",
"D. c #95744E",
"F. c #9A7956",
"G. c #857458",
"H. c #82887E",
"J. c #938164",
"K. c #998061",
"L. c #9E927A",
"P. c #B2834D",
"I. c #B58456",
"U. c #A59073",
"Y. c #DA935F",
"T. c #C69C74",
"R. c #EAAD7E",
"E. c #808684",
"W. c #859B9C",
"Q. c #8A9A99",
"!. c #929687",
"~. c #80A39F",
"^. c #86A9A4",
"/. c #8BACB7",
"(. c #8CB4BC",
"). c #89B9B8",
"_. c #96ABA7",
"`. c #93ACB0",
"'. c #9CBBB4",
"]. c #99B7B6",
"[. c #A7BEB4",
"{. c #B7B1A1",
"}. c #AEAA8D",
"|. c #81B7CC",
" X c #84BAC7",
".X c #82BCD4",
"XX c #88BED7",
"oX c #9ABEC0",
"OX c #95BDC4",
"+X c #96C4BF",
"@X c #A8C4BD",
"#X c #8BC2C8",
"$X c #8BC2D2",
"%X c #88C5DD",
"&X c #87C4D3",
"*X c #9CCACD",
"=X c #95C4CA",
"-X c #95CBD2",
";X c #99C7D1",
":X c #9BCCD9",
">X c #94C6D5",
",X c #94D2D4",
"<X c #98D3D5",
"1X c #9DDBDE",
"2X c #99D4DB",
"3X c #A4C3C4",
"4X c #A2C5C8",
"5X c #A6CDCC",
"6X c #AAC8C8",
"7X c #A2CED5",
"8X c #A3D0CE",
"9X c #A8D1C7",
"0X c #A3D3D4",
"qX c #A3D2DD",
"wX c #A2DBDB",
"eX c #ABD4D4",
"rX c #B5CBC6",
"tX c #B6D6CB",
"yX c #BDDEDD",
"uX c #B6D6D1",
"iX c #AADCE6",
"pX c #B6DAE5",
"aX c #A8E2E3",
"sX c #BCE2E5",
"dX c #BBE9EC",
"fX c #B8E4ED",
"gX c #B7ECF2",
"hX c #BBEBF1",
"jX c #CEA780",
"kX c #CCB194",
"lX c #D1AF8A",
"zX c #D9B38E",
"xX c #DCBE9C",
"cX c #E1AE81",
"vX c #F0B482",
"bX c #EDB789",
"nX c #E3C09A",
"mX c #E7D8AF",
"MX c #C0D7C5",
"NX c #C4DEDD",
"BX c #D5D7D2",
"VX c #C6E3DD",
"CX c #D0E7DF",
"ZX c #C4E3E3",
"AX c #C0E6EC",
"SX c #C3EBEB",
"DX c #C9E6E4",
"FX c #CEEDE4",
"GX c #CCEAEB",
"HX c #C5EAF0",
"JX c #D1EAE3",
"KX c #DDE8E2",
"LX c #DDF5E5",
"PX c #E3EDE8",
"IX c #EAF7F0",
"UX c #E0F7E5",
/* pixels */
"V.jXnXD.a S.J.J.s f ^ [.VXZXZXe.y ^ , 9XSX8Xa.+X@X",
"C.B.D.A.F.a G.L.g H.[.yXSXSXDXZXe ~.x.r eXSX].uXUX",
"cXI.V.lXK.a s !.Q.`.;XiXgXdXAXSX5Xe a.e f.HXZXFXUX",
"vXbXT.xXJ.p g _./. .X L  XgXhXHXAXr.w & t 6XGXFXUX",
"Y.vXlXU.f !._.(.E - %.2 X l.gXgXAXAXf.Q i.! uXJXLX",
"Z.F.kXf u.`.(.|.- $.XXN.U X #X-X;XHXpXi.u i.e.DXJX",
"P.F.kXW./.s.s..Xk E %X%X&Xn 3 n. XqXAX4XW.].'.@XVX",
"mX}._./.- # # J %.o N.%XM.5.$ 1.n.|.pXsX`.rXCXCXFX",
"tX@X).= G m.d.. d.: G v.c.c.m Y M.n. XfXsXDXCXIXPX",
"wXwX&X .|.XXXXn $.6.+ T 7.c.M I v.v.z.$XdXyXrXPXBX",
"wXwX2X#XOX>X>XT E b.$.@ m m b ;.0.b.k.j.2XdXDX@XPX",
",Xy.z.8X+XOXXXG Y s.d.2.Y I >.[ ' ) ` } 4.-XpXNXPX",
"-XX.X.+X9X).x.1 o.O.3  .7.9.-.] S Z v B } 4.iXsX'.",
"aX).^ t.eXx.g.1 X.< < o.3.9.) ( A C I $ B J } iXqX",
"aX1X1.X.,X$X,.+ % H 4.1.9.=.) c Z ] I I k b F s.hX",
"1X,X,Xz.2X&XK n v v ( ( ` ` ( l C I I M M I J U >X",
",X,X1X,X2Xo.H % $ N x N K K K % v N M D z z I 6.,.",
",X,X,X<X+X4 < L V C   l % % K $ % z x x D [ I 7.k.",
"<X0X9X8X~.r w R 5.) x x % l N k x D b S D -.;.$.h.",
"0X*X8XtXp.y * t 3 K z ) N { v $ k k M =.] ' >.*.*.",
"0X7X4X6X^ 0 7 8 > 1 m C x ) | 2 2 _ D ' -.' -.;.*.",
":XqX=X6XQ.0 7 p 8 > = P [ ( | o.@ ' *.' *.$.I ;.8.",
"qX:X;XoX6Xd 7 i q Q W L =.=.&.@.@.B $.$.%.<.$._ v.",
":X:X;XOXoX_.d h 0 h i.X.4.=.] ;.8.I ' ;.$.$.6.v.|.",
":X;X>XOXOX4Xu.h E.j a.i.R 6.5.@.0.c.D ;.*.7..X|.l."
};
EOT
} # money_xpm }}}

sub box_nonsel_xpm { # {{{

=head2 box_nonsel_xpm( $color )

Returns a symbol for a not selected checkbox.
The $color parameter is optional.
Default color is "#FFFFFF".

=cut

  my $color = shift || '#FFFFFF';
  return <<"EOT";
/* XPM */
static char * file_xpm[] = {
\"14 12 3 1\",
\" 	s None	c None\",
\".	c #000000000000\",
\"x	c $color\",
\"..............\",
\".xxxxxxxxxxxx.\",
\".xxxxxxxxxxxx.\",
\".xxxxxxxxxxxx.\",
\".xxxxxxxxxxxx.\",
\".xxxxxxxxxxxx.\",
\".xxxxxxxxxxxx.\",
\".xxxxxxxxxxxx.\",
\".xxxxxxxxxxxx.\",
\".xxxxxxxxxxxx.\",
\".xxxxxxxxxxxx.\",
\"..............\"};
EOT
} # box_nonsel_xpm }}}

sub box_yellow_xpm { # {{{

=head2 box_yellow_xpm( $color )

Returns a symbol for a not selected yellow checkbox
The $color parameter is optional.
Default color is "yellow".

=cut

  my $color = shift || "yellow";
  return <<"EOT";
/* XPM */
static char * file_xpm[] = {
\"14 12 3 1\",
\" 	s None	c None\",
\".	c #000000000000\",
\"x	c $color\",
\"..............\",
\".xxxxxxxxxxxx.\",
\".xxxxxxxxxxxx.\",
\".xxxxxxxxxxxx.\",
\".xxxxxxxxxxxx.\",
\".xxxxxxxxxxxx.\",
\".xxxxxxxxxxxx.\",
\".xxxxxxxxxxxx.\",
\".xxxxxxxxxxxx.\",
\".xxxxxxxxxxxx.\",
\".xxxxxxxxxxxx.\",
\"..............\"};
EOT
} # box_yellow_xpm }}}

sub box_sel_xpm { # {{{

=head2 box_sel_xpm( $color )

Returns a symbol for a selected checkbox
The $color parameter is optional.
Default color is "yellow".

=cut

  my $color = shift || "yellow";
  return <<"EOT";
/* XPM */
static char * file_xpm[] = {
\"14 12 3 1\",
\" 	s None	c None\",
\".	c #000000000000\",
\"x	c $color\",
\"..............\",
\".xxxxxxxxxxxx.\",
\".x.xxxxxxx.xx.\",
\".xx.xxxxx.xxx.\",
\".xxx.xxx.xxxx.\",
\".xxxx.x.xxxxx.\",
\".xxxxx.xxxxxx.\",
\".xxxx.x.xxxxx.\",
\".xxx.xxx.xxxx.\",
\".xx.xxxxx.xxx.\",
\".x.xxxxxxx.xx.\",
\"..............\"};
EOT
} # box_sel_xpm }}}

1;

__END__

=head2 EXPORT

None by default. There are export tags :all and :arrows which can
be used to import all methods or only the arrow methods.


=head1 AUTHOR

Lorenz Domke, E<lt>lorenz.domke@gmx.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Lorenz Domke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

Revision History: {{{1
  $Log: $


# vim:ft=perl:foldmethod=marker:foldcolumn=4
