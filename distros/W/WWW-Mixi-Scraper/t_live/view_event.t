use strict;
use warnings;
use Test::More qw(no_plan);
use Test::NoWarnings;
use t_live::lib::Utils;

my $mixi = login_to('view_event.pl');

my $rules = {
  subject     => 'string',
  link        => 'uri_if_remote',
  time        => 'datetime',
  date        => 'string',
  deadline    => 'string',
  location    => 'string',
  description => 'string',
  images => {
    link       => 'uri',
    thumb_link => 'uri',
  },
  name        => 'string',
  name_link   => 'maybe_uri',
# join        => 'integer', # not yet implemented
  community => {
    name => 'string',
    link => 'maybe_uri',
  },
  list => {
    count   => 'integer',
    subject => 'maybe_string',
    link    => 'maybe_uri',
  },
  comments => {
    subject     => 'string',
    name        => 'string',
    name_link   => 'maybe_uri',
    description => 'string',
    time        => 'datetime',
    link        => 'uri_if_remote',
    images => {
      link       => 'uri',
      thumb_link => 'uri',
    },
  },
# not yet implemented
#  pages => {
#    current => 'string',
#    link    => 'uri',
#    subject => 'string',
#  },
};

date_format('%Y-%m-%d %H:%M');

run_tests('view_event') or ok 1, 'skipped: no tests';

sub test {
  my $event = $mixi->view_event->parse(@_);

  matches( $event => $rules );
}
