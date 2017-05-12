use strict;
use warnings;
use Test::More;
use URI::file;
use Time::HiRes qw(time);

BEGIN {
    use_ok( 'WWW::Mechanize' );
    use_ok( 'WWW::Mechanize::Plugin::FollowMetaRedirect' );
    can_ok( 'WWW::Mechanize', 'follow_meta_redirect' );
}

# active check 1
{
  my $mech = WWW::Mechanize->new;
  my $uri = URI::file->new_abs("t/assets/waiting_01.html")->as_string;

  # load initial page
  $mech->get( $uri );
  ok( $mech->success, "Fetched: $uri" ) or die "cannot load test html!";

  # follow
  my $start = time;
  ok( $mech->follow_meta_redirect, "follow meta refresh link" );
  ok( time - $start >= ( $^O eq 'MSWin32' ? 0.95 : 1.00 ), "waiting sec" );    # win32 doesn't count extact 1.0 sec :(

  # check
  ok( $mech->is_html, "is html" );
  ok( $mech->content =~ /test ok\./, "result html" );
}

# active check 2
{
  my $mech = WWW::Mechanize->new;
  my $uri = URI::file->new_abs("t/assets/waiting_01.html")->as_string;

  # load initial page
  $mech->get( $uri );
  ok( $mech->success, "Fetched: $uri" ) or die "cannot load test html!";

  # follow
  my $start = time;
  ok( $mech->follow_meta_redirect( ignore_wait => 0 ), "follow meta refresh link" );
  ok( time - $start >= ( $^O eq 'MSWin32' ? 0.95 : 1.00 ), "waiting sec" );

  # check
  ok( $mech->is_html, "is html" );
  ok( $mech->content =~ /test ok\./, "result html" );
}

# negative check 1
{
  my $mech = WWW::Mechanize->new;
  my $uri = URI::file->new_abs("t/assets/waiting_01.html")->as_string;

  # load initial page
  $mech->get( $uri );
  ok( $mech->success, "Fetched: $uri" ) or die "cannot load test html!";

  # follow
  my $start = time;
  ok( $mech->follow_meta_redirect( ignore_wait => 1 ), "follow meta refresh link" );
  ok( time - $start < 0.90, "waiting sec" );

  # check
  ok( $mech->is_html, "is html" );
  ok( $mech->content =~ /test ok\./, "result html" );
}

done_testing;

__END__