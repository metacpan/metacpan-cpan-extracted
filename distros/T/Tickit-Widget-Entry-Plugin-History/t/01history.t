#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Entry;
use Tickit::Widget::Entry::Plugin::History;

my $win = mk_window;

my $entered;
my $entry = Tickit::Widget::Entry->new(
   on_enter => sub { ( undef, $entered ) = @_; },
);

my @history;
Tickit::Widget::Entry::Plugin::History->apply( $entry,
   storage => \@history,
);

$entry->set_window( $win );

flush_tickit;

sub presskeys
{
   my ( $text ) = @_;

   foreach my $chr ( split //, $text ) {
      presskey( $chr eq "\n" ?
         ( key => "Enter" ) :
         ( text => $chr )
      );
   }
}

# initial entry
{
   presskeys "hello";
   flush_tickit;

   is_display( [ "hello" ],
      'Display after initial typing' );

   presskeys "\n";
   flush_tickit;

   is_display( [ ],
      'Display after initial entry' );
   is( $entered, "hello", 'on_enter invoked' );
   is_deeply( \@history, [ "hello" ], 'storage after initial entry' );
}

# Enter more for history
presskeys "more\n";
presskeys "text\n";

is_deeply( \@history, [ "hello", "more", "text" ],
   'storage after more entries' );

# replay
{
   presskey key => "Up";
   flush_tickit;

   is_display( [ "text" ],
      'Display after history replay' );

   presskey key => "Up";
   flush_tickit;

   is_display( [ "more" ],
      'Display after history replay further' );

   presskey key => "Down";
   flush_tickit;

   is_display( [ "text" ],
      'Display after history replay down' );

   undef $entered;
   presskeys "\n";
   flush_tickit;

   is_display( [ ],
      'Display after replay commit' );
   is( $entered, "text", 'on_enter invoked' );
}

done_testing;
