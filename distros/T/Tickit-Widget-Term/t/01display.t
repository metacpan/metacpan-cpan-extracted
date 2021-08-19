#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Term;

my $root = mk_window;

my $widget = Tickit::Widget::Term->new;

ok( defined $widget, 'defined $widget' );

$widget->set_window( $root );
flush_tickit;

# Initial blank state
{
   is_display( [],
      'Display initially' );
}

sub clear
{
   # clear
   $widget->write_input( "\e[H\e[2J" );
   $widget->flush;
   flush_tickit;
}

# Plain text output
{
   $widget->write_input( "ABCDE" );
   $widget->flush;
   flush_tickit;

   is_display( [ [TEXT("ABCDE"), BLANK(75)] ],
      'Display after plaintext write' );

   # Lets not go too far with testing CSI sequences; we're not supposed to be
   # unit-testing libvterm itself
   $widget->write_input( "\e[20HFGHIJ" );
   $widget->flush;
   flush_tickit;

   is_display( [ [TEXT("ABCDE"), BLANK(75)],
                 BLANKLINES(18),
                 [TEXT("FGHIJ"), BLANK(75)] ],
      'Display after cursor move + text' );
}

# Some formatting
{
   clear();
   $widget->write_input( sprintf "\e[%dm%s\e[m", @{$_}[1,0] ) for
      [ bold => 1 ], [ under => 4 ], [ italic => 3 ], [ reverse => 7 ];
   $widget->flush;
   flush_tickit;

   is_display( [
         [TEXT("bold",b=>1), TEXT("under",u=>1), TEXT("italic",i=>1), TEXT("reverse",rv=>1), BLANK(58)]
      ],
      'Display after formatted output' );
}

# Some colours
{
   clear();
   $widget->write_input( sprintf "\e[%dmCOL%d\e[m", $_+30, $_ ) for ( 1, 2, 4 );
   $widget->flush;
   flush_tickit;

   is_display( [
         [TEXT("COL1",fg=>1), TEXT("COL2",fg=>2), TEXT("COL4",fg=>4), BLANK(68)]
      ],
      'Display after coloured output' );
}

done_testing;
