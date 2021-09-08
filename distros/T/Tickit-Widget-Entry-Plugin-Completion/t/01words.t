#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Entry;
use Tickit::Widget::Entry::Plugin::Completion;

my $win = mk_window;

my $entry = Tickit::Widget::Entry->new;

Tickit::Widget::Entry::Plugin::Completion->apply( $entry,
   words => [qw( zero one two three four five )],
   use_popup => 0,
);

$entry->set_window( $win );

flush_tickit;

# Single unique match
{
   presskey text => "z";
   presskey key => "Tab";
   flush_tickit;

   is_display( [ "zero " ],
      'Display after unique match' );
   is( $entry->text, "zero ", '$entry->text after unique match' );
}

# Multiple matches
{
   presskey text => "t";
   presskey key => "Tab";
   flush_tickit;

   is_display( [ "zero t" ],
      'Display after multiple match' );
   is( $entry->text, "zero t", '$entry->text after multiple match' );

   presskey text => "w";
   presskey key => "Tab";
   flush_tickit;

   is_display( [ "zero two " ],
      'Display after multiple match finished' );
   is( $entry->text, "zero two ", '$entry->text after multiple match finished' );
}

done_testing;
