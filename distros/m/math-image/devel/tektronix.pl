#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.


# /usr/share/doc/xterm/ctlseqs.txt.gz
use strict;



{
  print "\e[?38h"; # DECTEK
  print "\037"; # alpha
  print "\e\f"; # clear screen

     line(0,0, 1000,1000);

  # for (my $x = 0; $x < 30; $x += 16) {
  #   my $y = $x/16;
  #   line($x,$y+40, $x,$y+60);
  # }
  print "\037"; # alpha
  $|=1;
  sleep 100;
  exit 0;
}

{
  # TEK_LINK_BLOCK_SIZE 1024
  my $size = 1000;
  $|=0;
  print "\e[?38h"; # DECTEK
  my $y = 0;
  for ($y = 0; $y < 500; $y += 10) {
    foreach my $x (1 .. $size) {
      line($x,$y, $x,$y+5);
    }
  }
  print "\037"; # text mode
  $|=1;
  sleep 2;

  $|=0;
  print "\e\f"; # clear screen

 # print "\e[?38h"; # DECTEK
  foreach my $x (1 .. $size) {
    line($x,$y+40, $x,$y+60);
  }
  # print "\037"; # text mode
  $|=1;
  sleep 100;
  exit 0;
}

{
  require App::MathImage::Image::Base::Tektronix;
  print "\e[?38h"; # DECTEK
  print "\033\f"; # clear screen
  my $image = App::MathImage::Image::Base::Tektronix->new;

  # $image->line (10,10, 100,50, 'black');
  # $image->rectangle (20,20, 50,100, 'black', 1);
  # $image->rectangle (220,20, 250,100, 'black', 1);
  # $image->line (310,10, 400,50, 'black');

  $image->rectangle (20,20, 700,500, 'green', 1);
  # $image->rectangle (220,20, 250,100, 'red', 1);
  # $image->line (310,10, 400,50, 'blue');
  # $image->line (10,10, 100,10, 'blue');
  # $image->line (10,10, 10,100, 'blue');
  # $image->ellipse (220,120, 450,400, 'red', 1);
  $image->save;


  $|=1;
  sleep 100;
  exit 0;
}
{
  print "\e[?38h"; # DECTEK
  $|=0;
  $|=1;
  sleep 1;  # wait for the tektronix window to open

  line(50,50, 200,200);
  print "\e\f"; # clear screen
  line(300,200, 450,50);

  $|=0;
  $|=1;
  exit 0;
  print "\037";  # alpha mode
  print "\e\003";  # switch to VT100 mode


  # print "\e\f"; # clear screen
  # print "\e\003";  # switch to VT100 mode
  # print "\e[?38h"; # DECTEK
  # print "\e\003";  # switch to VT100 mode
  # print "\e[?38h"; # DECTEK
  # print "\e\f"; # clear screen
  # $|=0;
  # $|=1;
  # sleep 2;
  # # print "\e[!p"; # soft reset
  # # print "\e[?38h"; # enter Tektronix Mode (DECTEK)
  # # # print "\e\003";  # switch to VT100 mode
  #  sleep 100;
  exit 0;
}

{
  # TEK_LINK_BLOCK_SIZE 1024
  my $size = 1000;
  $|=0;
  print "\e[?38h"; # DECTEK
  my $y = 0;
  for ($y = 0; $y < 500; $y += 10) {
    foreach my $x (1 .. $size) {
      line($x,$y, $x,$y+5);
    }
  }
  print "\037"; # text mode
  $|=1;
  sleep 2;

  $|=0;
  print "\e\f"; # clear screen

 # print "\e[?38h"; # DECTEK
  foreach my $x (1 .. $size) {
    line($x,$y+40, $x,$y+60);
  }
  # print "\037"; # text mode
  $|=1;
  sleep 100;
  exit 0;
}


{
  sub packxy {
    my ($x,$y) = @_;
    # 12-bit addressing
    return pack('C5',
                0x20 | (($y >> 7) & 0x1F),                  # high Y
                0x60 | (($x & 0x03) | (($y << 2) & 0x0C),   # extra low two
                0x60 | (($y >> 2) & 0x1F),                  # low Y
                0x20 | (($x >> 7) & 0x1F),                  # high X
                0x40 | (($x >> 2) & 0x1F));                 # low X
  }
  sub draw {
    my ($x,$y) = @_;
    print packxy($x,$y);
  }
  sub move {
    my ($x,$y) = @_;
    print "\035";
    draw($x,$y);
  }

  sub xy {
    my ($x,$y) = @_;
    line($x,$y,$x,$y);
  }
  sub line {
    my ($x1,$y1, $x2,$y2) = @_;
    print "\035".packxy($x1,$y1).packxy($x2,$y2);

    # move($x1,$y1);
    # draw($x2,$y2);
  }


  print "\e]0;my title\e\\";

  # print "\e[8;10;60t"; # size in chars
  # print "\e[9;1t";  # maximize
  # print "\e[2t"; # iconify

  print "\e]15;red\e\\";

  print "\e[?38h"; # DECTEK
  # print "\e[4;100;200t";
  # print "\e\x0C";
  # print "\e\x38";
  # print "\e\x60\x1D\x21\x72\x22";

  # print "\033\f"; # clear screen
  # move (5,5);
  # draw(1023,256);
  # draw(50,10);
  # draw(10,50);

  # print "\e[31m";

  line(200,200, 60,0);
  line(100,0, 0,60);
  xy(300,300);
  move(0,0);
  print "\037"; # text mode
  $|=1;
  sleep 100;
  exit 0;
}
