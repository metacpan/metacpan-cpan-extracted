use strict;
use warnings;
use Test::More qw(no_plan);
use Test::NoWarnings;
use t_live::lib::Utils;

my $mixi = login_to('list_diary.pl');

my $rules = {
  subject     => 'string',
  description => 'string',
  time        => 'datetime',
  link        => 'uri',
  count       => 'integer',
  images      => {
    link       => 'uri',
    thumb_link => 'uri',
  },
};

date_format('%Y-%m-%d %H:%M');

run_tests('list_diary') or ok 1, 'skipped: no tests';

sub test {
  my @items = $mixi->list_diary->parse(@_);

  return ok 1, 'skipped: no diary' unless @items;

  foreach my $item ( @items ) {
    matches( $item => $rules );
  }
}
