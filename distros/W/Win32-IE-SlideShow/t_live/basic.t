use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;
use Win32::IE::SlideShow;

my @slides;
foreach my $text ( qw( first second third ) ) {
  push @slides, "<html><body><h1>$text slide</h1></body></html>";
}

lives_ok { test(); };
lives_ok { test( FullScreen => 1 ); };
lives_ok { test( TheaterMode => 1 ); };
lives_ok { test( Top => 0, Left => 0 ); };
lives_ok { test( Height => 200, Width => 500 ); };
lives_ok { test( TopMost => 1 ); };
lives_ok { test( TopMost => 1, FullScreen => 1 ); };
lives_ok { test( TopMost => 1, TheaterMode => 1 ); };
lives_ok { test( TopMost => 1, Top => 0, Left => 0 ); };
lives_ok { test( TopMost => 1, Height => 200, Width => 500 ); };

sub test {
  my $show = Win32::IE::SlideShow->new(@_);
  $show->set( @slides );
  while( $show->has_next ) {
    $show->next;
    sleep 1;
  }
  $show->quit;

  sleep 3;  # wait a bit until IE actually goes away.
}
