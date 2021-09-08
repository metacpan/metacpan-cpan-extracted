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
   ignore_case => 1,
   use_popup => 0,
);

$entry->set_window( $win );

flush_tickit;

# Single match
{
   presskey text => "Z";
   presskey key => "Tab";
   flush_tickit;

   is_display( [ "zero " ],
      'Display after match ignoring case' );
   is( $entry->text, "zero ", '$entry->text after match ignoring case' );
}

done_testing;
