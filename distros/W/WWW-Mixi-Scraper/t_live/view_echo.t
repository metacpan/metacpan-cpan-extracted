use strict;
use warnings;
use Test::More skip_all => 'this plugin is deprecated';
use Test::NoWarnings;
use t_live::lib::Utils;

my $mixi = login_to('view_echo.pl');

my $rules = {
  link       => 'uri', 
  id         => 'integer',
  time       => 'integer',
  name       => 'string',
  comment    => 'string',
};

run_tests('view_echo') or ok 1, 'skipped: no tests';

sub test {
  my $echo = $mixi->view_echo->parse(@_);

  matches( $echo => $rules );
}
