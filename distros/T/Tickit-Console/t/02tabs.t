#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;

use Tickit::Test;

use Tickit::Console;

my $win = mk_window;

my $console = Tickit::Console->new;

$console->set_window( $win );

my @tabs = map { $console->add_tab( name => $_ ) } qw( Tab0 Tab1 Tab2 );

flush_tickit;

is_display( [ BLANKLINES(23),
              [TEXT("[",fg=>7,bg=>4),TEXT("Tab0",fg=>14,bg=>4),TEXT("]Tab1 Tab2 ",fg=>7,bg=>4),TEXT("",bg=>4)],
              BLANKLINE() ],
            'Display after ->add_tab' );

is_cursorpos( 24, 0, 'Cursor position after ->add_tab' );

is( $console->active_tab_index, 0, '$console->active_tab_index' );
identical( $console->active_tab, $tabs[0], '$console->active_tab' );

is( $tabs[0]->index, 0,     '$tab[0]->index' );
is( $tabs[0]->name, "Tab0", '$tab[0]->name' );

$tabs[0]->set_name( "Newname" );

is( $tabs[0]->name, "Newname", '$tab[0]->name after ->set_name' );

flush_tickit;

is_display( [ BLANKLINES(23),
              [TEXT("[",fg=>7,bg=>4),TEXT("Newname",fg=>14,bg=>4),TEXT("]Tab1 Tab2 ",fg=>7,bg=>4),TEXT("",bg=>4)],
              BLANKLINE() ],
            'Display after $tab->set_name' );

$console->activate_tab( 1 );

is( $console->active_tab_index, 1, '$console->active_tab_index after ->activate_tab' );
identical( $console->active_tab, $tabs[1], '$console->active_tab after ->activate_tab' );

flush_tickit;

is_display( [ BLANKLINES(23),
              [TEXT(" Newname[",fg=>7,bg=>4),TEXT("Tab1",fg=>14,bg=>4),TEXT("]Tab2 ",fg=>7,bg=>4),TEXT("",bg=>4)],
              BLANKLINE() ],
            'Display after ->activate_tab' );

done_testing;
