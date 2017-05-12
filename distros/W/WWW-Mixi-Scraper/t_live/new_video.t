use strict;
use warnings;
use Test::More qw(no_plan);
use Test::NoWarnings;
use t_live::lib::Utils;

my $mixi = login_to('new_video.pl');

my $rules = {
  subject => 'string',
  name    => 'string',
  time    => 'datetime',
  link    => 'uri',
};

date_format('%m-%d %H:%M');

run_tests('new_video') or ok 1, 'skipped: no tests';

sub test {
  my @items = $mixi->new_video->parse(@_);

  return ok 1, 'skipped: no new videos' unless @items;

  foreach my $item ( @items ) {
    matches( $item => $rules );
  }
}
