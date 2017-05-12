use strict;
use warnings;
use Test::More skip_all => 'this plugin is deprecated';
use Test::NoWarnings;
use t_live::lib::Utils;

my $mixi = login_to('res_echo.pl');

my $rules = {
  link       => 'uri', 
  id         => 'integer',
  time       => 'integer',
  name       => 'string',
  comment    => 'string',
};

run_tests('res_echo') or ok 1, 'skipped: no tests';

sub test {
  my @items = $mixi->res_echo->parse(@_);

  return ok 1, 'skipped: no res echo' unless @items;

  foreach my $item ( @items ) {
    matches( $item => $rules );
  }
}
