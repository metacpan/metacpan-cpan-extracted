use strict;
use warnings;
use Test::More;

BEGIN { use_ok( 'WWW::YouTube::Info::Simple' ) };

# "Gmail Theater Act 1" http://www.youtube.com/watch?v=_YUugB4IUl4
my $id = '_YUugB4IUl4'; my @args; push @args, $id;
my $yt = new_ok( 'WWW::YouTube::Info::Simple' => \@args );

SKIP: {
  my $info = $yt->get_info();
  skip "get_resolution() might fail! (\$info->{status} ne 'ok')", 1 if $info->{status} ne 'ok';

  SKIP: {
    eval {
      my $url = $yt->get_resolution();
    };
    skip "get_resolution() might fail! (not available)", 1 if $@;

    ok( my $url = $yt->get_resolution(), "get_resolution() on VIDEO_ID '$id'" );
  };
};

done_testing();

