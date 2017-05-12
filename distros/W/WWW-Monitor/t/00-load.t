#!perl

use Test::More tests => 6;

BEGIN {
  use_ok( 'WWW::Monitor::Task');
  use_ok( 'WWW::Monitor' );
  use_ok('LWP::UserAgent');
  use_ok('Schedule::Cron');
  use_ok('Cache::File');
  use_ok('Text::WordDiff');
  
}

diag( "Testing WWW::Monitor $WWW::Monitor::VERSION, Perl $], $^X" );
