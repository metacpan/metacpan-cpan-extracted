#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test 0.70; # mk_tickit

use Tickit::App::Plugin::EscapePrefix;

my $tickit = mk_tickit;

Tickit::App::Plugin::EscapePrefix->apply( $tickit );

my @key_events;
$tickit->rootwin->bind_event( key => sub {
   my ( $win, undef, $info ) = @_;
   push @key_events, [ $info->type => $info->str ];
   return 0;
} );
$tickit->rootwin->bind_event( expose => sub {
   my ( $win, undef, $info ) = @_;
   my $rb = $info->rb;
   $rb->clear;
} );

my $term = $tickit->term;

# ESC, a => M-a
{
   $term->emit_key( type => "key", str => "Escape" );
   flush_tickit;

   ok( !@key_events, 'no key events after ESC' );

   is_display( [
         BLANKLINES(24),
         [TEXT("ESC-",rv=>1)],
      ],
      'display after <Escape>'
   );

   $term->emit_key( type => "text", str => "a" );
   flush_tickit;

   is_deeply( \@key_events, [ [ key => "M-a" ] ] );

   is_display( [
         BLANKLINES(25),
      ],
      'display after prefixed key'
   );
}

# ESC timeout
{
   undef @key_events;
   $term->emit_key( type => "key", str => "Escape" );

   flush_tickit;

   is_display( [
         BLANKLINES(24),
         [TEXT("ESC-",rv=>1)],
      ],
      'display after <Escape>'
   );

   flush_tickit 5;

   ok( !@key_events, 'no key events after ESC timeout' );

   is_display( [
         BLANKLINES(25),
      ],
      'display after Escape timeout'
   );

   $term->emit_key( type => "text", str => "a" );
   flush_tickit;

   is_deeply( \@key_events, [ [ text => "a" ] ] );
}

done_testing;
