use strict;
use warnings;
use Test::More qw(no_plan);
use Test::NoWarnings;
use t_live::lib::Utils;

my $mixi = login_to('view_message.pl');

my $rules = {
  subject     => 'string',
  name        => 'string',
  description => 'string',
  time        => 'datetime',
  link        => 'uri',
  image       => 'uri',
};

date_format('%Y-%m-%d %H:%M');

run_tests('view_message') or ok 1, 'skipped: no tests';

sub test {
  my $message = $mixi->view_message->parse(@_);

  matches( $message => $rules );
}
