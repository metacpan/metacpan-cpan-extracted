#!perl -T

BEGIN {
  use Config;
  if (! $Config{'useithreads'}) {
      print("1..0 # Skipped: Perl not compiled with 'useithreads'\n");
      exit(0);
  }
}

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::Editor::Easy' );
}

diag( "Testing Text::Editor::Easy $Text::Editor::Easy::VERSION, Perl $], $^X" );
