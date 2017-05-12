use strict;
use warnings;
use Test::More qw(no_plan);
use Test::NoWarnings;
use t_live::lib::Utils;

my $mixi = login_to('list_comment.pl');

my $rules = {
  subject => 'string',
  name    => 'string',
  time    => 'datetime',
  link    => 'uri',
};

date_format('%Y-%m-%d %H:%M');

run_tests('list_comment') or ok 1, 'skipped: no tests';

sub test {
  my @items = $mixi->list_comment->parse(@_);

  return ok 1, 'skipped: no comments' unless @items;

  foreach my $item ( @items ) {
    matches( $item => $rules );
  }
}
