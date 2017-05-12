use strict;
use warnings;
use Test::More qw(no_plan);
use Test::NoWarnings;
use t_live::lib::Utils;

my $mixi = login_to('list_message.pl');

my $rules = {
  subject  => 'string',
  name     => 'string',
  time     => 'datetime',
  link     => 'uri',
# envelope => 'uri',    # outbox doesn't have this
# status   => 'string', # not yet implemented
};

date_format('%m-%d');

run_tests('list_message') or ok 1, 'skipped: no tests';

sub test {
  my @items = $mixi->list_message->parse(@_) ;

  return ok 1, 'skipped: no messages' unless @items;

  foreach my $item ( @items ) {
    matches( $item => $rules );
  }
}
