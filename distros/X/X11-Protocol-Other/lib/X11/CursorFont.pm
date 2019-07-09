# Copyright 2011, 2012, 2013, 2014, 2017 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.

BEGIN { require 5 }
package X11::CursorFont;
use strict;
use vars qw($VERSION @ISA @EXPORT_OK %CURSOR_GLYPH @CURSOR_NAME);

use Exporter;
@ISA = ('Exporter');
@EXPORT_OK = qw(%CURSOR_GLYPH @CURSOR_NAME);

# uncomment this to run the ### lines
#use Smart::Comments;

$VERSION = 31;

%CURSOR_GLYPH
  = (
     # (shell-command "perl -n -e '/define XC_([^ ]*).*?([0-9]+)/ and $1 ne q{num_glyphs} and printf qq{     %-25s => %s,\n},$1,$2' </usr/include/X11/cursorfont.h" 'insert)

     X_cursor                  => 0,
     arrow                     => 2,
     based_arrow_down          => 4,
     based_arrow_up            => 6,
     boat                      => 8,
     bogosity                  => 10,
     bottom_left_corner        => 12,
     bottom_right_corner       => 14,
     bottom_side               => 16,
     bottom_tee                => 18,
     box_spiral                => 20,
     center_ptr                => 22,
     circle                    => 24,
     clock                     => 26,
     coffee_mug                => 28,
     cross                     => 30,
     cross_reverse             => 32,
     crosshair                 => 34,
     diamond_cross             => 36,
     dot                       => 38,
     dotbox                    => 40,
     double_arrow              => 42,
     draft_large               => 44,
     draft_small               => 46,
     draped_box                => 48,
     exchange                  => 50,
     fleur                     => 52,
     gobbler                   => 54,
     gumby                     => 56,
     hand1                     => 58,
     hand2                     => 60,
     heart                     => 62,
     icon                      => 64,
     iron_cross                => 66,
     left_ptr                  => 68,
     left_side                 => 70,
     left_tee                  => 72,
     leftbutton                => 74,
     ll_angle                  => 76,
     lr_angle                  => 78,
     man                       => 80,
     middlebutton              => 82,
     mouse                     => 84,
     pencil                    => 86,
     pirate                    => 88,
     plus                      => 90,
     question_arrow            => 92,
     right_ptr                 => 94,
     right_side                => 96,
     right_tee                 => 98,
     rightbutton               => 100,
     rtl_logo                  => 102,
     sailboat                  => 104,
     sb_down_arrow             => 106,
     sb_h_double_arrow         => 108,
     sb_left_arrow             => 110,
     sb_right_arrow            => 112,
     sb_up_arrow               => 114,
     sb_v_double_arrow         => 116,
     shuttle                   => 118,
     sizing                    => 120,
     spider                    => 122,
     spraycan                  => 124,
     star                      => 126,
     target                    => 128,
     tcross                    => 130,
     top_left_arrow            => 132,
     top_left_corner           => 134,
     top_right_corner          => 136,
     top_side                  => 138,
     top_tee                   => 140,
     trek                      => 142,
     ul_angle                  => 144,
     umbrella                  => 146,
     ur_angle                  => 148,
     watch                     => 150,
     xterm                     => 152,
    );
### %CURSOR_GLYPH

@CURSOR_NAME[values %CURSOR_GLYPH] = keys %CURSOR_GLYPH;
$#CURSOR_NAME |= 1;   # odd number of entries
### @CURSOR_NAME

# or for explicit CURSOR_NAME list ... but that fills in the odd elements
# with undefs, where values/keys leaves them uninitialised
#  = (
#    # (shell-command "perl -n -e '/define XC_([^ ]*).*?([0-9]+)/ and $1 ne q{num_glyphs} and do { printf qq{     %-30s # %d\n}, qq{q{$1},}, $i; $i+=2 }' </usr/include/X11/cursorfont.h" 'insert)
#   );

1;
__END__

=for stopwords Xlib Xmu glyph glyphs Ryde RGB multi-colour

=head1 NAME

X11::CursorFont - cursor font glyph names and numbers

=for test_synopsis my ($X)

=head1 SYNOPSIS

 use X11::CursorFont '%CURSOR_GLYPH';
 my $num = $CURSOR_GLYPH{'fleur'};               # is 52
 my $name = $X11::CursorFont::CURSOR_NAME[52];   # is "fleur"

=head1 DESCRIPTION

This is the names and numbers of the glyphs in the X11 cursor font which
contains various standard mouse pointer cursors.

C<%CURSOR_GLYPH> maps a glyph name to its character number in the font,

    $CURSOR_GLYPH{'fleur'}     # is 52

C<@CURSOR_NAME> conversely is indexed by character number and gives the
glyph name,

    $CURSOR_NAME[52]           # is "fleur"

Each glyph has an associated mask at character number glyph+1 which is the
shape of the cursor (the displayed vs transparent pixels).  So the character
numbers are always even and in C<@CURSOR_NAME> only the even character
positions have names.

The cursor images can be viewed with the usual C<xfd> font display program,

     xfd -fn cursor

The names are per the Xlib F</usr/include/X11/cursorfont.h> file, without
the C<XC_> prefixes.  The full list is

=cut

# List generated by
# (shell-command "perl -n -e '/define XC_([^ ]*).*?([0-9]+)/ and do { printf qq{    %-20s  %3d\n}, $1, $2;}' </usr/include/X11/cursorfont.h" 'insert)

=pod

    Name                  Number

    X_cursor                0    default fat X
    arrow                   2
    based_arrow_down        4
    based_arrow_up          6
    boat                    8
    bogosity               10
    bottom_left_corner     12
    bottom_right_corner    14
    bottom_side            16
    bottom_tee             18
    box_spiral             20    a square spiral
    center_ptr             22
    circle                 24
    clock                  26
    coffee_mug             28
    cross                  30
    cross_reverse          32
    crosshair              34    "+" shape
    diamond_cross          36
    dot                    38
    dotbox                 40
    double_arrow           42
    draft_large            44
    draft_small            46
    draped_box             48
    exchange               50
    fleur                  52
    gobbler                54
    gumby                  56
    hand1                  58
    hand2                  60
    heart                  62
    icon                   64
    iron_cross             66
    left_ptr               68
    left_side              70
    left_tee               72
    leftbutton             74
    ll_angle               76
    lr_angle               78
    man                    80
    middlebutton           82
    mouse                  84
    pencil                 86
    pirate                 88    skull and crossbones
    plus                   90
    question_arrow         92
    right_ptr              94
    right_side             96
    right_tee              98
    rightbutton           100
    rtl_logo              102
    sailboat              104
    sb_down_arrow         106
    sb_h_double_arrow     108
    sb_left_arrow         110
    sb_right_arrow        112
    sb_up_arrow           114
    sb_v_double_arrow     116
    shuttle               118
    sizing                120
    spider                122
    spraycan              124
    star                  126
    target                128
    tcross                130
    top_left_arrow        132
    top_left_corner       134
    top_right_corner      136
    top_side              138
    top_tee               140
    trek                  142
    ul_angle              144
    umbrella              146
    ur_angle              148
    watch                 150    a good "busy" indicator
    xterm                 152    a vertical insertion bar

C<X_cursor> is the usual default when the server first starts or when the
root window is set to cursor "None".

=head1 VARIABLES

=over

=item C<%X11::CursorFont::CURSOR_GLYPH>

A mapping of glyph name to cursor font character number.

=item C<@X11::CursorFont::CURSOR_NAME>

A table of cursor font character number to glyph name.

=back

=head1 EXPORTS

Nothing is exported by default, but C<%CURSOR_GLYPH> and C<@CURSOR_NAME> can
be selected in usual C<Exporter> style (see L<Exporter>),

    use X11::CursorFont '%CURSOR_GLYPH', '@CURSOR_NAME';

=head1 EXAMPLE

To create a cursor from a desired glyph,

    my $cursor_name = 'spraycan';
    my $cursor_glyph = $CURSOR_GLYPH{$cursor_name}; # number

    my $cursor_font = $X->new_rsrc;
    $X->OpenFont ($cursor_font, "cursor"); # cursor font

    my $cursor = $X->new_rsrc;
    $X->CreateGlyphCursor
           ($cursor,
            $cursor_font,  # font
            $cursor_font,  # mask font
            $cursor_glyph,      # glyph
            $cursor_glyph + 1,  # and its mask
            0,0,0,                  # foreground, black
            0xFFFF,0xFFFF,0xFFFF);  # background, white

    $X->CloseFont ($cursor_font);

    # then use $cursor with CreateWindow or ChangeWindowAttributes
    #       cursor => $cursor

The C<$cursor_font> could be kept open if used repeatedly.  Opening and
closing isn't a round-trip, so an open when needed may be enough.

Any RGB colours can be given in C<CreateGlyphCursor()>, but actual
appearance on screen will be limited by the hardware.

All cursors in the core protocol are two-colours with pixels fully opaque or
fully transparent as per this create.  The RENDER extension, when available,
can make multi-colour and partial transparency if desired (see
L<X11::Protocol::Ext::RENDER>).

=head1 SEE ALSO

L<X11::Protocol>,
L<X11::KeySyms>

F</usr/include/X11/cursorfont.h> and listing in the Xlib manual appendix B
(C<http://www.x.org/docs/X11/> or
F</usr/share/doc/libx11-dev/libX11.txt.gz>).

Xlib Xmu C<XmuCursorNameToIndex()> (C<http://www.x.org/docs/Xmu/> or
F</usr/share/doc/libxmu-headers/Xmu.txt.gz>)

L<xfd(1)> to display the cursor font.

L<xsetroot(1)> to change the root window cursor.

=head1 HOME PAGE

L<http://user42.tuxfamily.org/x11-protocol-other/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2017 Kevin Ryde

X11-Protocol-Other is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

X11-Protocol-Other is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.

=cut
