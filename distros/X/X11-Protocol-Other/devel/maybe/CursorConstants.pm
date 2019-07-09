# Copyright 2011, 2013, 2017 Kevin Ryde

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
package X11::CursorConstants;
use strict;

use vars '$VERSION';
$VERSION = 10;


# Generated with:
# (shell-command "perl -n -e '/define XC_([^ ]*).*?([0-9]+)/ and do { printf qq{use constant %-20s => %d;\n}, $1, $2;}' </usr/include/X11/cursorfont.h" 'insert)

use constant num_glyphs           => 154;
use constant X_cursor             => 0;
use constant arrow                => 2;
use constant based_arrow_down     => 4;
use constant based_arrow_up       => 6;
use constant boat                 => 8;
use constant bogosity             => 10;
use constant bottom_left_corner   => 12;
use constant bottom_right_corner  => 14;
use constant bottom_side          => 16;
use constant bottom_tee           => 18;
use constant box_spiral           => 20;
use constant center_ptr           => 22;
use constant circle               => 24;
use constant clock                => 26;
use constant coffee_mug           => 28;
use constant cross                => 30;
use constant cross_reverse        => 32;
use constant crosshair            => 34;
use constant diamond_cross        => 36;
use constant dot                  => 38;
use constant dotbox               => 40;
use constant double_arrow         => 42;
use constant draft_large          => 44;
use constant draft_small          => 46;
use constant draped_box           => 48;
use constant exchange             => 50;
use constant fleur                => 52;
use constant gobbler              => 54;
use constant gumby                => 56;
use constant hand1                => 58;
use constant hand2                => 60;
use constant heart                => 62;
use constant icon                 => 64;
use constant iron_cross           => 66;
use constant left_ptr             => 68;
use constant left_side            => 70;
use constant left_tee             => 72;
use constant leftbutton           => 74;
use constant ll_angle             => 76;
use constant lr_angle             => 78;
use constant man                  => 80;
use constant middlebutton         => 82;
use constant mouse                => 84;
use constant pencil               => 86;
use constant pirate               => 88;
use constant plus                 => 90;
use constant question_arrow       => 92;
use constant right_ptr            => 94;
use constant right_side           => 96;
use constant right_tee            => 98;
use constant rightbutton          => 100;
use constant rtl_logo             => 102;
use constant sailboat             => 104;
use constant sb_down_arrow        => 106;
use constant sb_h_double_arrow    => 108;
use constant sb_left_arrow        => 110;
use constant sb_right_arrow       => 112;
use constant sb_up_arrow          => 114;
use constant sb_v_double_arrow    => 116;
use constant shuttle              => 118;
use constant sizing               => 120;
use constant spider               => 122;
use constant spraycan             => 124;
use constant star                 => 126;
use constant target               => 128;
use constant tcross               => 130;
use constant top_left_arrow       => 132;
use constant top_left_corner      => 134;
use constant top_right_corner     => 136;
use constant top_side             => 138;
use constant top_tee              => 140;
use constant trek                 => 142;
use constant ul_angle             => 144;
use constant umbrella             => 146;
use constant ur_angle             => 148;
use constant watch                => 150;
use constant xterm                => 152;

1;
__END__

=for stopwords Xlib glyph Ryde

=head1 NAME

X11::CursorConstants - cursor font glyph constants

=head1 SYNOPSIS

 use X11::CursorConstants;
 my $glyphnum = X11::CursorConstants::crosshair(); # is 34

=head1 DESCRIPTION

This is the glyphs of the X11 "cursor" font as Perl constant subrs.  The
cursor font is the usual way to create mouse pointer cursors of various
standard shapes.

The subr names are per the Xlib F</usr/include/X11/cursorfont.h>, without
the C<XC_> prefixes.  Each glyph is a character for the foreground shape,
and the next character is the background mask.

    X11::CursorConstants::fleur(),       # glyph
    X11::CursorConstants::fleur() + 1,   # and its mask

So for example to create a "crosshair" cursor,

    my $cursor_font = $X->new_rsrc;
    $X->OpenConstants ($cursor_font, "cursor");

    my $cursor = $X->new_rsrc;
    $X->CreateGlyphCursor
          ($cursor,
           $cursor_font,  # font
           $cursor_font,  # mask font
           X11::CursorConstants::crosshair(),      # glyph
           X11::CursorConstants::crosshair() + 1,  # and its mask
           0,0,0,                  # foreground, black
           0xFFFF,0xFFFF,0xFFFF);  # background, white

All cursors can be viewed with the C<xfd> font display program,

     xfd -fn cursor

=head1 CONSTANTS

There's no exporting, since it's unlikely more than a handful will be
needed, and usually only in one or two places each.  The full list is

=cut

# List generated by
# (shell-command "perl -n -e '/define XC_([^ ]*).*?([0-9]+)/ and do { printf qq{    %-20s  %3d\n}, $1, $2;}' </usr/include/X11/cursorfont.h" 'insert)

=pod

    Constant             Value

    X_cursor                0
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
    crosshair              34
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

    num_glyphs            154

C<X11::CursorConstants::num_glyphs()> is how many glyphs plus masks are in
the font, ie. characters C<0> to C<num_glyphs-1> exist.

=head1 SEE ALSO

L<X11::AtomConstants>,
L<X11::KeySyms>,
L<X11::Protocol>
L<X11::Protocol::Other>,
L<xfd(1)>

F</usr/include/X11/cursorfont.h> and listed in the Xlib manual appendix B
(F</usr/share/doc/libx11-dev/libX11/libX11.txt.gz>).

Xlib Xmu C<XmuCursorNameToIndex()>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/x11-protocol-other/index.html>

=head1 LICENSE

Copyright 2011, 2013, 2017 Kevin Ryde

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
