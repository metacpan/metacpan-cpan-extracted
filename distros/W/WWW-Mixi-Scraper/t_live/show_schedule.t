use strict;
use warnings;
use Test::More qw(no_plan);
use Test::NoWarnings;
use t_live::lib::Utils;
use Encode;

my $mixi = login_to('show_schedule.pl');

my $rules = {
  subject => 'string',
  link    => 'uri',
  name    => 'string',
  time    => 'datetime',
  icon    => 'uri',
};

date_format('%Y-%m-%d');

run_tests('show_schedule') or ok 1, 'skipped: no tests';

sub test {
  my @items = $mixi->show_schedule->parse(@_);

  return ok 1, 'skipped: no schedule items' unless @items;

  foreach my $item ( @items ) {
    matches( $item => $rules );
  }
}
