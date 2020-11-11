#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Identity;

use Tickit::Test;

use Tickit::Widget::Static;
use Tickit::Widget::GridBox;

my $win = mk_window;

my @statics = map { Tickit::Widget::Static->new( text => "Widget $_" ) } 0 .. 5;

my $widget = Tickit::Widget::GridBox->new;

ok( defined $widget, 'defined $widget' );

$widget->add( 0, 0, $statics[0], col_expand => 1, row_expand => 1 );
$widget->add( 0, 1, $statics[1], col_expand => 1, row_expand => 1 );
$widget->add( 1, 0, $statics[2], col_expand => 1, row_expand => 1 );
$widget->add( 1, 1, $statics[3], col_expand => 1, row_expand => 1 );

is( $widget->lines, 2, '$widget->lines after ->add' );
is( $widget->cols, 16, '$widget->cols after ->add' );

is( $widget->rowcount, 2, '$widget->rowcount' );
is( $widget->colcount, 2, '$widget->colcount' );

identical( $widget->get( 0, 0 ), $statics[0], '->get( 0, 0 )' );
identical( $widget->get( 1, 1 ), $statics[3], '->get( 1, 1 )' );

is_deeply( [ $widget->get_row( 0 ) ], [ $statics[0], $statics[1] ],
   '$widget->get_row' );

is_deeply( [ $widget->get_col( 0 ) ], [ $statics[0], $statics[2] ],
   '$widget->get_col' );

$widget->set_window( $win );

ok( defined $statics[0]->window, '$statics[0] has window after $widget->set_window' );

flush_tickit;

is_display( [ [TEXT("Widget 0"), BLANK(32), TEXT("Widget 1"), BLANK(32)],
              BLANKLINES(11),
              [TEXT("Widget 2"), BLANK(32), TEXT("Widget 3"), BLANK(32)],
              BLANKLINES(12) ],
            'Display initially' );

$widget->set_style(
   col_spacing => 10,
   row_spacing => 3,
);

flush_tickit;

is_display( [ [TEXT("Widget 0"), BLANK(27+10), TEXT("Widget 1"), BLANK(27)],
              BLANKLINES(10+3),
              [TEXT("Widget 2"), BLANK(27+10), TEXT("Widget 3"), BLANK(27)],
              BLANKLINES(10) ],
            'Display after changing spacing' );

$widget->add( 0, 2, $statics[4] ); # no expand
$widget->add( 1, 2, $statics[5] ); # no expand

is( $widget->colcount, 3, '$widget->colcount after adding column' );

flush_tickit;

is_display( [ [TEXT("Widget 0"), BLANK(18+10), TEXT("Widget 1"), BLANK(18+10), TEXT("Widget 4")],
              BLANKLINES(10+3),
              [TEXT("Widget 2"), BLANK(18+10), TEXT("Widget 3"), BLANK(18+10), TEXT("Widget 5")],
              BLANKLINES(10) ],
            'Display after adding more cells without expand' );

$widget->remove( 1, 1 );

flush_tickit;

is_display( [ [TEXT("Widget 0"), BLANK(18+10), TEXT("Widget 1"), BLANK(18+10), TEXT("Widget 4")],
              BLANKLINES(10+3),
              [TEXT("Widget 2"), BLANK(18+10), BLANK(8), BLANK(18+10), TEXT("Widget 5")],
              BLANKLINES(10) ],
            'Display after removing a cell' );

$widget->remove( 1, 2 );
$widget->remove( 0, 2 );

flush_tickit;

# Each of the following test blocks is supposed to restore the screen back to
# this state, so it helps to save it here.

my @screen = ( [TEXT("Widget 0"), BLANK(27+10), TEXT("Widget 1"), BLANK(27)],
                BLANKLINES(10+3),
                [TEXT("Widget 2"), BLANK(27+10), BLANK(8), BLANK(27)],
                BLANKLINES(10) );

is_display( \@screen,
            'Display after removing an entire column' );

# insert/delete row
{
   my @more_statics = map { Tickit::Widget::Static->new( text => "Widget $_" ) } 6, 7;

   $widget->insert_row( 1, \@more_statics );

   is( $widget->rowcount, 3, '->rowcount after ->insert_row' );

   identical( $widget->get( 1, 0 ), $more_statics[0], '->get on new row' );
   identical( $widget->get( 2, 0 ), $statics[2], '->get on existing moved row' );

   flush_tickit;

   is_display( [ [TEXT("Widget 0"), BLANK(27+10), TEXT("Widget 1"), BLANK(27)],
                 BLANKLINES(11),
                 [TEXT("Widget 6"), BLANK(27+10), TEXT("Widget 7"), BLANK(27)],
                 BLANKLINES(3),
                 [TEXT("Widget 2"), BLANK(27+10), BLANK(8), BLANK(27)],
                 BLANKLINES(8) ],
               'Display after ->insert_row' );

   $widget->delete_row( 1 );

   flush_tickit;

   is_display( \@screen, 'Display after ->delete_row' );
}

# insert/delete col
{
   my @more_statics = map { Tickit::Widget::Static->new( text => "Widget $_" ) } 6, 7;

   $widget->insert_col( 1, \@more_statics );

   is( $widget->colcount, 3, '->colcount after ->insert_col' );

   identical( $widget->get( 0, 1 ), $more_statics[0], '->get on new col' );
   identical( $widget->get( 0, 2 ), $statics[1], '->get on existing moved col' );

   flush_tickit;

   is_display( [ [TEXT("Widget 0"), BLANK(28), TEXT("Widget 6"), BLANK(10), TEXT("Widget 1"), BLANK(18)],
                 BLANKLINES(10+3),
                 [TEXT("Widget 2"), BLANK(28), TEXT("Widget 7"), BLANK(36)],
                 BLANKLINES(10) ],
               'Display after ->insert_col' );

   $widget->delete_col( 1 );

   flush_tickit;

   is_display( \@screen, 'Display after ->delete_col' );
}

# incremental building by row
{
   my $gridbox = Tickit::Widget::GridBox->new;
   $gridbox->append_row( [
      map { Tickit::Widget::Static->new( text => $_ ) } 1 .. 3
   ] ) for 1 .. 2;

   is( $gridbox->rowcount, 2, '->rowcount 2 after incremental build by row' );
   is( $gridbox->colcount, 3, '->colcount 3 after incremental build by row' );
}

# incremental building by col
{
   my $gridbox = Tickit::Widget::GridBox->new;
   $gridbox->append_col( [
      map { Tickit::Widget::Static->new( text => $_ ) } 1 .. 3
   ] ) for 1 .. 2;

   is( $gridbox->rowcount, 3, '->rowcount 3 after incremental build by col' );
   is( $gridbox->colcount, 2, '->colcount 2 after incremental build by col' );
}

# append_row with options
{
   my $gridbox = Tickit::Widget::GridBox->new;
   $gridbox->append_row( [
      Tickit::Widget::Static->new( text => "left" ),
      { child => Tickit::Widget::Static->new( text => "right" ), col_expand => 1 }
   ] );

   is_deeply( { $gridbox->child_opts( $gridbox->get( 0, 1 ) ) },
      { col_expand => 1, row_expand => 0 },
      '->append_row accepts hashes with extra opts' );
}

# append_col with options
{
   my $gridbox = Tickit::Widget::GridBox->new;
   $gridbox->append_col( [
      Tickit::Widget::Static->new( text => "top" ),
      { child => Tickit::Widget::Static->new( text => "bottom" ), row_expand => 1 }
   ] );

   is_deeply( { $gridbox->child_opts( $gridbox->get( 1, 0 ) ) },
      { col_expand => 0, row_expand => 1 },
      '->append_col accepts hashes with extra opts' );
}

done_testing;
