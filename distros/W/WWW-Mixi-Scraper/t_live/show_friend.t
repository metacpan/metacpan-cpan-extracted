use strict;
use warnings;
use Test::More qw(no_plan);
use Test::NoWarnings;
use t_live::lib::Utils;

my $mixi = login_to('show_friend.pl');

my $rules = {
  name  => 'string',
  image => 'uri',
  count => 'integer',
  link  => 'uri',
  description => 'string',
};

run_tests('show_friend') or ok 1, 'skipped: no tests';

sub test {
  my $friend = $mixi->show_friend->parse(@_);

  my $profile = $friend->{profile};
  foreach my $key ( keys %{ $profile } ) {
    ok $key;
    matches( $profile => { $key => 'string' } );
  }

  my $outline = $friend->{outline};
  matches( $outline => $rules );
}
