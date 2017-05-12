use strict;
use warnings;
use Test::More skip_all => 'this plugin is deprecated';
use Test::NoWarnings;
use t_live::lib::Utils;

my $mixi = login_to('recent_echo.pl');

my $rules = {
  link       => 'uri', 
  id         => 'integer',
  time       => 'integer',
  name       => 'string',
  comment    => 'string',
  icon       => 'uri',
  reply_name => 'string',
  reply_id   => 'integer',
};

run_tests('recent_echo') or ok 1, 'skipped: no tests';

sub test {
  my @items = $mixi->recent_echo->parse(@_);

  return ok 1, 'skipped: no recent echo' unless @items;

  foreach my $item ( @items ) {
    matches( $item => $rules );
  }
}
