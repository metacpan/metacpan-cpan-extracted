#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use String::Tagged;

use Tickit::Console;

my $win = mk_window;

my $console = Tickit::Console->new;
$console->set_window( $win );

# Just timestamp, plain
{
   my $tab = $console->add_tab(
      name => "Tabname",
      timestamp_format => "[%H:%M:%S] ",
   );

   $tab->append_line( "First line",
      time => 123456789, # 1973/11/29 21:33:09
   );

   flush_tickit;

   is_display( [ [TEXT("[21:33:09] First line")],
                 BLANKLINES(22),
                 [TEXT("[",fg=>7,bg=>4),TEXT("Tabname",fg=>14,bg=>4),TEXT("]",fg=>7,bg=>4),TEXT("",bg=>4)],
                 BLANKLINE() ],
               'Display after tab->append_line with timestamp' );

   $console->remove_tab( $tab );
}

# Just timestamp, String::Tagged
{
   my $tab = $console->add_tab(
      name => "Tabname",
      timestamp_format => String::Tagged->new( "[%H:%M] " )
         ->apply_tag( 1, 2, fg => "red" )
         ->apply_tag( 4, 2, fg => "blue" ),
   );

   $tab->append_line( "First line",
      time => 123456789, # 1973/11/29 21:33:09
   );

   flush_tickit;

   is_display( [ [TEXT("["), TEXT("21",fg=>1), TEXT(":"), TEXT("33",fg=>4), TEXT("] First line")],
                 BLANKLINES(22),
                 [TEXT("[",fg=>7,bg=>4),TEXT("Tabname",fg=>14,bg=>4),TEXT("]",fg=>7,bg=>4),TEXT("",bg=>4)],
                 BLANKLINE() ],
               'Display after tab->append_line with formatted timestamp' );

   $console->remove_tab( $tab );
}

# Time + Datestamp, appending
{
   my $tab = $console->add_tab(
      name => "Tabname",
      timestamp_format => "[%H:%M] ",
      datestamp_format => "- day is now %Y/%m/%d -",
   );

   $tab->append_line( "First line",
      time => 123456789, # 1973/11/29 21:33:09
   );
   $tab->append_line( "Second line",
      time => 123456792, # 1973/11/29 21:33:12
   );
   $tab->append_line( "Third line",
      time => 123498765, # 1973/11/30 09:12:45
   );

   flush_tickit;

   is_display( [ [TEXT("- day is now 1973/11/29 -")],
                 [TEXT("[21:33] First line")],
                 [TEXT("[21:33] Second line")],
                 [TEXT("- day is now 1973/11/30 -")],
                 [TEXT("[09:12] Third line")],
                 BLANKLINES(18),
                 [TEXT("[",fg=>7,bg=>4),TEXT("Tabname",fg=>14,bg=>4),TEXT("]",fg=>7,bg=>4),TEXT("",bg=>4)],
                 BLANKLINE() ],
               'Display after tab->append_line with datestamp' );

   $console->remove_tab( $tab );
}

# Time + Datestamp, prepending
{
   my $tab = $console->add_tab(
      name => "Tabname",
      timestamp_format => "[%H:%M] ",
      datestamp_format => "- day is now %Y/%m/%d -",
   );

   $tab->prepend_line( "First line",
      time => 123456789, # 1973/11/29 21:33:09
   );
   $tab->prepend_line( "Second line",
      time => 123456787, # 1973/11/29 21:33:07
   );
   $tab->prepend_line( "Third line",
      time => 123345678, # 1973/11/28 14:41:18
   );

   flush_tickit;

   is_display( [ [TEXT("- day is now 1973/11/28 -")],
                 [TEXT("[14:41] Third line")],
                 [TEXT("- day is now 1973/11/29 -")],
                 [TEXT("[21:33] Second line")],
                 [TEXT("[21:33] First line")],
                 BLANKLINES(18),
                 [TEXT("[",fg=>7,bg=>4),TEXT("Tabname",fg=>14,bg=>4),TEXT("]",fg=>7,bg=>4),TEXT("",bg=>4)],
                 BLANKLINE() ],
               'Display after tab->append_line with datestamp' );

   $console->remove_tab( $tab );
}

done_testing;
