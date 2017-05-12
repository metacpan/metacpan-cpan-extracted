#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Console;

my $win = mk_window;

my $console = Tickit::Console->new;

$console->set_window( $win );

my @global_keys;
$console->bind_key( 'A-x' => sub {
   push @global_keys, [ @_ ];
});

presskey( key => "A-x" );
flush_tickit;

is_deeply( \@global_keys,
           [ [ $console, 'A-x' ] ],
           'Console-level key binding receives key' );
undef @global_keys;

my $tab = $console->add_tab( name => "Tab" );

presskey( key => "A-x" );
flush_tickit;

is_deeply( \@global_keys,
           [ [ $console, 'A-x' ] ],
           'Console-level key binding receives key with tab focused' );
undef @global_keys;

{
   my @tab_keys;
   $tab->bind_key( 'A-x' => sub {
      push @tab_keys, [ @_ ];
   });

   presskey( key => "A-x" );
   flush_tickit;

   is_deeply( \@tab_keys,
              [ [ $tab, 'A-x' ] ],
              'Tab-level key binding receives key' );
   is( scalar @global_keys, 0,
      'Console-level key binding does not receive key with tab focused' );

   undef @tab_keys;

   $tab->bind_key( 'A-x' => undef );

   presskey( key => "A-x" );
   flush_tickit;

   is( scalar @tab_keys, 0,
      'Removed tab-level key binding no longer receives key' );
   is_deeply( \@global_keys,
              [ [ $console, "A-x" ] ],
              'Console-level keybinding receives key again' );
}

done_testing;
