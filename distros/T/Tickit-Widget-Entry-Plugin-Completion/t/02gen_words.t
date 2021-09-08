#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Entry;
use Tickit::Widget::Entry::Plugin::Completion;

my $win = mk_window;

my $entry = Tickit::Widget::Entry->new;

my %args_to_gen_words;
Tickit::Widget::Entry::Plugin::Completion->apply( $entry,
   gen_words => sub {
      %args_to_gen_words = @_;
      return qw( abcde );
   },
   use_popup => 0,
);

$entry->set_window( $win );

flush_tickit;

# First word
{
   presskey text => "a";
   presskey text => "b";
   presskey key => "Tab";
   flush_tickit;

   is( $args_to_gen_words{entry}, $entry, 'entry arg to gen_words' );
   is( $args_to_gen_words{word}, "ab", 'word arg to gen_words' );
   is( $args_to_gen_words{wordpos}, 0, 'wordpos arg to gen_words' );

   is_display( [ "abcde " ],
      'Display after first word' );
   is( $entry->text, "abcde ", '$entry->text after first word' );
}

# Second word
{
   presskey text => "a";
   presskey key => "Tab";
   flush_tickit;

   is( $args_to_gen_words{entry}, $entry, 'entry arg to gen_words' );
   is( $args_to_gen_words{word}, "a", 'word arg to gen_words' );
   is( $args_to_gen_words{wordpos}, 6, 'wordpos arg to gen_words' );

   is_display( [ "abcde abcde " ],
      'Display after second word' );
   is( $entry->text, "abcde abcde ", '$entry->text after second word' );
}

done_testing;
