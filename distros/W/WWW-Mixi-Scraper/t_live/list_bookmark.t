use strict;
use warnings;
use Test::More skip_all => 'this plugin is deprecated';
use Test::NoWarnings;
use t_live::lib::Utils;

my $mixi = login_to('list_bookmark.pl');

my $rules = {
  id         => 'string',
  name       => 'string',
  last_login => 'string',
  link       => 'uri',
};

run_tests('list_bookmark') or ok 1, 'skipped: no tests';

sub test {
  my @items = $mixi->list_bookmark->parse(@_);

  return ok 1, 'skipped: no bookmarks' unless @items;

  foreach my $item ( @items ) {
    matches( $item => $rules );
  }
}
