use strict;
use warnings;
use Test::More skip_all => 'this plugin is deprecated';
use Test::NoWarnings;
use t_live::lib::Utils;

my $mixi = login_to('show_log.pl');

my $rules = {
  time => 'datetime',
  name => 'string',
  link => 'uri',
};

date_format('%m-%d %H:%M');

run_tests('show_log') or ok 1, 'skipped: no tests';

sub test {
  my @items = $mixi->show_log->parse(@_);

  return ok 1, 'skipped: no logs' unless @items;

  foreach my $item ( @items ) {
    matches( $item => $rules );
  }
}
