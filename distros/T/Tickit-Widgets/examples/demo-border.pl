#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widgets qw( Border Static );

my $border = Tickit::Widget::Border->new(
   h_border => 4, v_border => 2,
   bg => "green",
   child => Tickit::Widget::Static->new(
      text => "Hello, world!",
      align => "centre", valign => "middle",
      bg => "black",
   ),
);

Tickit->new( root => $border )->run;
