use strict;
use warnings;
use Test::More tests => 23;
use Test::Exception;
use lib qw(lib);
use WWW::Mixpanel;

my $YOUR_TESTING_API_TOKEN = $ENV{MIXPANEL_TESTING_API_TOKEN};
my $YOUR_TESTING_API_KEY   = $ENV{MIXPANEL_TESTING_API_KEY};
my $YOUR_TESTING_API_SEC   = $ENV{MIXPANEL_TESTING_API_SEC};

my $skip = 0;
if ( !$YOUR_TESTING_API_TOKEN || !$YOUR_TESTING_API_KEY || !$YOUR_TESTING_API_SEC ) {
  $skip = 1;
  my $d = <<INFO;

  To run the data request tests, you must set the following env vars:
  MIXPANEL_TESTING_API_TOKEN, MIXPANEL_TESTING_API_KEY, MIXPANEL_TESTING_API_SEC
  and re-run the tests.

  These can be obtained from your mixpanel account page.
INFO

  diag $d;
}

SKIP: {
  skip '', 23 unless !$skip;
  ok( my $mp = WWW::Mixpanel->new( $YOUR_TESTING_API_TOKEN, 0, $YOUR_TESTING_API_KEY,
                                   $YOUR_TESTING_API_SEC ) );
  ok( $mp->track( 'www-mixpanel data1', 'distinct_id' => 'abc' ), 'Submit Data1' );
  ok( $mp->track( 'www-mixpanel data2', 'distinct_id' => 'abc', prop => 'prop1' ), 'Submit Data2' );

  # We no longer create funnels in track, instead see the arb_funnels undocumented (but stable)
  # test below.
  ok( $mp->track( 'login',
                  distinct_id => 'abcd',
                  gender      => 'male', ),
      'Submit Funnel' );
  ok( $mp->track( 'login',
                  distinct_id => 'abc',
                  gender      => 'male', ),
      'Submit Funnel' );
  ok( $mp->track( 'logout',
                  distinct_id => 'abc',
                  gender      => 'male', ),
      'Submit Funnel' );

  sleep(5);

  is( $mp->data( 'events',
                 event    => [ 'www-mixpanel data1', 'www-mixpanel data2' ],
                 type     => 'general',
                 unit     => 'day',
                 interval => '2' )->{legend_size},
      2, 'events' );

  ok( $mp->data( 'events',
                 event    => [ 'www-mixpanel data1', 'www-mixpanel data2' ],
                 type     => 'general',
                 unit     => 'day',
                 format   => 'csv',
                 interval => '2' ),
      'events csv' );

  ok( $mp->data( [qw/events top/], type => 'general', ), 'events top' );

  ok( $mp->data( 'events/top', type => 'general', ), 'events/top' );

  is( @{ $mp->data( 'events/top', type => 'general', limit => 2 )->{events} },
      2, 'events/top limit=>2' );

  ok( $mp->data( 'events/names', type => 'unique' ), 'events/names' );

  is( @{ $mp->data( 'events/names', type => 'general', limit => 2 ) }, 2, 'events/names limit=>2' );

  ok( $mp->data( 'retention',
                 retention_type => 'compounded',
                 event          => 'www-mixpanel data2',
                 unit           => 'day' ),
      'event/retention' );

  ok( @{$mp->data( 'events/properties',
                   event    => 'www-mixpanel data2',
                   name     => 'prop',
                   type     => 'general',
                   unit     => 'hour',
                   interval => 2, )->{data}->{series} },
      'events/properties' );

  is( $mp->data( 'events/properties',
                 event    => 'www-mixpanel data2',
                 name     => 'prop',
                 type     => 'general',
                 unit     => 'hour',
                 values   => 'prop1',
                 interval => 1 )->{legend_size},
      1,
      'events/properties value' );

  is( $mp->data( 'events/properties',
                 event    => 'www-mixpanel data2',
                 name     => 'prop',
                 type     => 'general',
                 unit     => 'hour',
                 values   => [ 'unknown1', 'unknown2' ],
                 interval => 1 )->{legend_size},
      0,
      'events/properties values' );

  ok( defined( $mp->data( 'events/properties/top',
                          event    => 'www-mixpanel data2',
                          type     => 'general',
                          unit     => 'hour',
                          interval => 3 )->{prop} ),
      'events/properties/top' );

  is( @{$mp->data( 'events/properties/values',
                   event    => 'www-mixpanel data2',
                   name     => 'prop',
                   type     => 'unique',
                   unit     => 'month',
                   interval => 1,
                   limit    => 1, ) }[0],
      'prop1',
      'events/properties/values' );

  is( @{ $mp->data('funnels/list') }, 0, 'funnels/list' );

  ### UNDOCUMENTED BUT STABLE API ENDPIONT ###
  ### This lets us create a funnel query on the fly given a set of events
  ### Optional parameters are those which appear in funnels/ such as to_date from_date interval, etc.
  my $funnel_data =
    $mp->data( 'arb_funnels', events => [ { "event" => 'login' }, { "event" => 'logout' } ] );
  my @date = sort keys %{ $funnel_data->{data} };
  is( @{ $funnel_data->{data}->{ pop @date }->{steps} }, 2, 'arb_funnels' );

  # Test malformed JSON request
  dies_ok {
    $mp->data( 'events',
               event    => [ 'www-mixpanel data1', 'www-mixpanel data2' ],
               type     => 'general',
               unit     => 'day2',
               interval => '2' );
  }
  'Malformed Unit Dies Ok';

  # # Test malformed CSV request
  dies_ok {
    $mp->data( 'events',
               event    => [ 'www-mixpanel data1', 'www-mixpanel data2' ],
               type     => 'general',
               unit     => 'day2',
               format   => 'csv',
               interval => '2' );
  }
  'Malformed Unit CSV dies ok';
} # end SKIP

done_testing;
