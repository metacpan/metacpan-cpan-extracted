#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Static;
use Tickit::Widget::Tabbed;

# Account for Tickit 0.44's whole-tree RB rendering
sub TERMLINE
{
        my $line = shift;

        my @ret;
        while(@_) {
                my $col = shift;
                my $exp = shift;

                if( $Tickit::Window::VERSION >= '0.44' ) {
                        push( @ret, "$line,$col" => [ @$exp ] ), next if !@ret;

                        # If the previous code ends in an erasech, it must be moveend=1
                        $ret[-1][-1][2] = 1 if $ret[-1][-1][0] eq "erasech";
                        push @{ $ret[-1] }, @$exp;
                }
                else {
                        push @ret, "$line,$col" => $exp;
                }
        }

        return @ret;
}

my $win = mk_window;

my @statics = map { Tickit::Widget::Static->new( text => "Widget $_" ) } 0 .. 2;

my $widget = Tickit::Widget::Tabbed->new( tab_position => "right" );

ok( defined $widget, 'defined $widget' );

$widget->add_tab( $statics[$_], label => "tab$_" ) for 0 .. $#statics;

$widget->set_window( $win );

ok( defined $statics[0]->window, '$static has window after ->set_window $win' );

flush_tickit;

is_termlog( {
        TERMLINE( 0,
                0  => [ SETPEN, PRINT("Widget 0"),
                        SETBG(undef), ERASECH(66) ],
                74 => [ SETPEN(fg => 7,bg => 4), PRINT("< "),
                        SETPEN(fg => 14,bg => 4), PRINT("tab0") ],
        ),

        TERMLINE( 1,
                0  => [ SETBG(undef), ERASECH(74) ],
                74 => [ SETPEN(fg => 7,bg => 4), PRINT("  "),
                        SETPEN(fg => 7,bg => 4), PRINT("tab1") ],
        ),

        TERMLINE( 2,
                0  => [ SETBG(undef), ERASECH(74) ],
                74 => [ SETPEN(fg => 7,bg => 4), PRINT("  "),
                        SETPEN(fg => 7,bg => 4), PRINT("tab2") ],
        ),

        ( map { TERMLINE( $_,
                0  => [ SETBG(undef), ERASECH(74) ],
                74 => [ SETBG(4), ERASECH(6) ],
                ) } 3 .. 24 ),
        }, 'Termlog initially' );

is_display( [ [TEXT("Widget 0"), BLANK(66), TEXT("< ",fg=>7,bg=>4), TEXT("tab0",fg=>14,bg=>4)],
              [BLANK(74), TEXT("  tab1",fg=>7,bg=>4)],
              [BLANK(74), TEXT("  tab2",fg=>7,bg=>4)] ],
            'Display initially' );

$widget->next_tab;

flush_tickit;

is_termlog( {
        TERMLINE( 0,
                0  => [ SETPEN, PRINT("Widget 1"),
                        SETBG(undef), ERASECH(66) ],
                74 => [ SETPEN(fg => 7,bg => 4), PRINT("  "),
                        SETPEN(fg => 7,bg => 4), PRINT("tab0") ],
        ),

        TERMLINE( 1,
                0  => [ SETBG(undef), ERASECH(74) ],
                74 => [ SETPEN(fg => 7,bg => 4), PRINT("< "),
                        SETPEN(fg => 14,bg => 4), PRINT("tab1") ],
        ),

        TERMLINE( 2,
                0  => [ SETBG(undef), ERASECH(74) ],
                74 => [ SETPEN(fg => 7,bg => 4), PRINT("  "),
                        SETPEN(fg => 7,bg => 4), PRINT("tab2") ],
        ),

        ( map { TERMLINE( $_,
                0  => [ SETBG(undef), ERASECH(74) ],
                74 => [ SETBG(4), ERASECH(6) ]
                ) } 3 .. 24 ),
        }, 'Termlog after ->next_tab' );

is_display( [ [TEXT("Widget 1"), BLANK(66), TEXT("  tab0",fg=>7,bg=>4)],
              [BLANK(74), TEXT("< ",fg=>7,bg=>4), TEXT("tab1",fg=>14,bg=>4)],
              [BLANK(74), TEXT("  tab2",fg=>7,bg=>4)] ],
            'Display after ->next_tab' );

$widget->add_tab( Tickit::Widget::Static->new( text => "Another static" ), label => "newtab" );

flush_tickit;

is_termlog( {
        TERMLINE( 0,
                0  => [ SETPEN, PRINT("Widget 1"),
                        SETBG(undef), ERASECH(64) ],
                72 => [ SETPEN(fg => 7,bg => 4), PRINT("    "),
                        SETPEN(fg => 7,bg => 4), PRINT("tab0") ],
        ),

        TERMLINE( 1,
                0  => [ SETBG(undef), ERASECH(72) ],
                72 => [ SETPEN(fg => 7,bg => 4), PRINT("<<< "),
                        SETPEN(fg => 14,bg => 4), PRINT("tab1") ],
        ),

        TERMLINE( 2,
                0  => [ SETBG(undef), ERASECH(72) ],
                72 => [ SETPEN(fg => 7,bg => 4), PRINT("    "),
                        SETPEN(fg => 7,bg => 4), PRINT("tab2") ],
        ),

        TERMLINE( 3,
                0  => [ SETBG(undef), ERASECH(72) ],
                72 => [ SETPEN(fg => 7,bg => 4), PRINT("  "),
                        SETPEN(fg => 7,bg => 4), PRINT("newtab") ],
        ),

        ( map { TERMLINE( $_,
                0  => [ SETBG(undef), ERASECH(72) ],
                72 => [ SETBG(4), ERASECH(8) ],
                ) } 4 .. 24 ),
        }, 'Termlog after ->add_tab' );

is_display( [ [TEXT("Widget 1"), BLANK(64), TEXT("    tab0",fg=>7,bg=>4)],
              [BLANK(72), TEXT("<<< ",fg=>7,bg=>4), TEXT("tab1",fg=>14,bg=>4)],
              [BLANK(72), TEXT("    tab2",fg=>7,bg=>4)],
              [BLANK(72), TEXT("  newtab",fg=>7,bg=>4)] ],
            'Display after ->add_tab' );

done_testing;
