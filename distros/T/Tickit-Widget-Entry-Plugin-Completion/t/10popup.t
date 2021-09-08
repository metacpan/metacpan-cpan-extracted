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
   words => [qw( zero one two three four five twelve )],
);

$entry->set_window( $win );

flush_tickit;

# No menu on unique match
{
   presskey text => "z";
   presskey key => "Tab";
   flush_tickit;

   is_display( [ "zero " ],
      'Display after unique match' );
   is( $entry->text, "zero ", '$entry->text after unique match' );
}

# Menu on multiple match
{
   presskey text => "t";
   presskey key => "Tab";
   flush_tickit;

   is_display(
      [ [TEXT("zero t")],
        [BLANK(5), TEXT("th",fg=>0,bg=>2,u=>1), TEXT("ree",fg=>0,bg=>2)],
        [BLANK(5), TEXT("tw",fg=>0,bg=>2,u=>1), TEXT("...",fg=>0,bg=>2)], ],
      'Display with popup menu' );
   is( $entry->text, "zero t", '$entry->text after menu popup' );

   # Narrow down the matches
   presskey text => "w";
   flush_tickit;

   is_display(
      [ [TEXT("zero tw")],
        [BLANK(5), TEXT("twe",fg=>0,bg=>2,u=>1), TEXT("lve",fg=>0,bg=>2)],
        [BLANK(5), TEXT("two",fg=>0,bg=>2,u=>1), TEXT("   ",fg=>0,bg=>2)], ],
      'Display with popup menu 2' );
   is( $entry->text, "zero tw", '$entry->text after menu popup 2' );

   # Backspace can go back
   presskey key => "Backspace";
   flush_tickit;

   is_display(
      [ [TEXT("zero t")],
        [BLANK(5), TEXT("th",fg=>0,bg=>2,u=>1), TEXT("ree",fg=>0,bg=>2)],
        [BLANK(5), TEXT("tw",fg=>0,bg=>2,u=>1), TEXT("...",fg=>0,bg=>2)], ],
      'Display with popup menu 3' );
   is( $entry->text, "zero t", '$entry->text after menu popup 3' );

   # Another key completes the match
   presskey text => "w";
   presskey text => "o";
   flush_tickit;

   is_display(
      [ [TEXT("zero two")],
        [BLANK(80)],
        [BLANK(80)], ],
      'Display after popup done' );
   is( $entry->text, "zero two ", '$entry->text after popup done' );
}

# <Escape> to dismiss menu
{
   presskey text => "f";
   presskey key => "Tab";
   flush_tickit;

   is_display(
      [ [TEXT("zero two f")],
        [BLANK(9), TEXT("fi",fg=>0,bg=>2,u=>1), TEXT("ve",fg=>0,bg=>2)],
        [BLANK(9), TEXT("fo",fg=>0,bg=>2,u=>1), TEXT("ur",fg=>0,bg=>2)], ],
      'Display with popup menu' );
   is( $entry->text, "zero two f", '$entry->text after menu popup' );

   presskey key => "Escape";
   flush_tickit;

   is_display(
      [ [TEXT("zero two f")],
        [BLANK(80)],
        [BLANK(80)], ],
      'Display after popup dismissed' );
   is( $entry->text, "zero two f", '$entry->text after popup done' );
}

done_testing;
