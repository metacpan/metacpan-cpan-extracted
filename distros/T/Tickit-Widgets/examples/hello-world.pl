#!/usr/bin/perl

use strict;
use warnings;

use Tickit;

use Tickit::Widget::Box;
use Tickit::Widget::Static;

my $box = Tickit::Widget::Box->new(
   style => { bg => "green" },
   child_lines => '80%',
   child_cols => '80%',
)->set_child(
   Tickit::Widget::Static->new(
      text => "Hello, world!",
      align => "centre", valign => "middle",
      style => { bg => "black" },
   )
);

Tickit->new( root => $box )->run;
