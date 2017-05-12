use strict;
use warnings;
use Test::More skip_all => 'this plugin is deprecated';
use Test::NoWarnings;
use t_live::lib::Utils;

my $mixi = login_to('new_music.pl');

my $rules = {
  subject => 'string',
  name    => 'string',
  time    => 'datetime',
  link    => 'uri',
};

date_format('%Y-%m-%d');

run_tests('new_music') or ok 1, 'skipped: no tests';

sub test {
  my @items = $mixi->new_music->parse(@_);

  return ok 1, 'skipped: no new music' unless @items;

  foreach my $item ( @items ) {
    matches( $item => $rules );
  }
}
