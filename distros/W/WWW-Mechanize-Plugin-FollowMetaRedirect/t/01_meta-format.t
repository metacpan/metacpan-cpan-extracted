use strict;
use warnings;
use Test::More;
use URI::file;

BEGIN {
    use_ok( 'WWW::Mechanize' );
    use_ok( 'WWW::Mechanize::Plugin::FollowMetaRedirect' );
    can_ok( 'WWW::Mechanize', 'follow_meta_redirect' );
}

# success
for my $n( 1 .. 13, 21 ){
  my $mech = WWW::Mechanize->new;
  my $uri = URI::file->new_abs( sprintf "t/assets/meta_format_%02d.html", $n )->as_string;

  # load initial page
  $mech->get( $uri );
  ok( $mech->success, "Fetched: $uri" ) or die "cannot load test html!";

  # follow
  ok( $mech->follow_meta_redirect( ignore_wait => 1 ), "follow meta refresh link: $n" );

  # check
  ok( $mech->is_html, "is html: $n" );
  ok( $mech->content =~ /test ok\./, "result html: $n" );
}

# failure
for my $n( 22 .. 23 ){
  my $mech = WWW::Mechanize->new;
  my $uri = URI::file->new_abs( sprintf "t/assets/meta_format_%02d.html", $n )->as_string;

  # load initial page
  $mech->get( $uri );
  ok( $mech->success, "Fetched: $uri" ) or die "cannot load test html!";

  # follow
  ok( ! $mech->follow_meta_redirect( ignore_wait => 1 ), "no follow meta refresh link: $n" );

  # check
  ok( $mech->is_html, "is html: $n" );
  ok( $mech->content !~ /test ok\./, "result html not loaded: $n" );
}

done_testing;

__END__