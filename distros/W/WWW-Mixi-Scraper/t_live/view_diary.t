use strict;
use warnings;
use Test::More qw(no_plan);
use Test::NoWarnings;
use t_live::lib::Utils;

my $mixi = login_to('view_diary.pl');

my $rules = {
  subject     => 'string',
  description => 'string',
  time        => 'datetime',
  link        => 'uri',
# not yet implemented
#  level => {
#    description => 'string',
#    link        => 'uri',
#  },
  comments => {
    name        => 'string',
    description => 'string',
    time        => 'datetime',
    link        => 'uri',
  },
  images => {
    link       => 'uri',
    thumb_link => 'uri',
  },
};

date_format('%Y-%m-%d %H:%M');

run_tests('view_diary') or ok 1, 'skipped: no tests';

sub test {
  my $diary = $mixi->view_diary->parse(@_);

  matches( $diary => $rules );
}
