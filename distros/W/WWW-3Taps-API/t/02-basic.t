use Test::More;
use Test::Exception;
use HTTP::Response;

BEGIN { use_ok('WWW::3Taps::API'); }

sub _build_response_ok {
  my $content = shift;
  my $res = HTTP::Response->new( 200, 'OK' );
  $res->content($content);
  return $res;
}

sub _build_response_err {
  my $res = HTTP::Response->new( 404, 'Not Found' );
  $res->content('ERROR');
  return $res;
}

my $three_tap = WWW::3Taps::API->new(
  agent_id => '3taps-developers',
  auth_id  => 'fc275ac3498d6ab0f0b4389f8e94422c'
);

sub test_request {
  my ( $request_cb, $test_cb ) = @_;
  my $ua = $three_tap->_ua;
  $ua->remove_handler('request_send');
  $ua->add_handler(
    request_send => sub {
      $test_cb->(@_);
      return _build_response_ok('{}');
    }
  );
  $request_cb->();
  $ua->remove_handler('request_send');
  $ua->add_handler( request_send => sub { return _build_response_ok('{}') } );
}

ok( $three_tap, 'ok' );

$three_tap->_ua->add_handler(
  request_send => sub { return _build_response_ok('{}') } );

ok( $three_tap->search( location => 'LAX+OR+NYC', category => 'VAUT' ),
  'search' );

ok( $three_tap->count( location => 'LAX', category => 'VAUT' ), 'count' );

ok(
  $three_tap->range(
    location    => 'LAX',
    category    => 'VAUT',
    annotations => '{"make":"porsche"}',
    fields      => 'year,price'
  ),
  'range'
);

ok( $three_tap->summary( text => 'toyota', dimension => 'source' ), 'summary' );

ok(
  $three_tap->update_status(
    postings => [
      {
        source     => "E_BAY",
        externalID => "3434399120",
        status     => "sent",
        timestamp  => "2011/12/21 01:13:28",
        attributes => { postKey => "3JE8VFD" }
      },
      {
        source     => "E_BAY",
        externalID => "33334399121",
        status     => "sent",
        timestamp  => "2011/12/21 01:13:28",
        attributes => { postKey => "3JE8VFF" }
      }
    ]
  ),
  'status/update'
);

ok( $three_tap->system_status, 'status/system' );

ok(
  $three_tap->get_status(
    ids => [
      { source => 'CRAIG', externalID => '3434399120' },
      { source => 'CRAIG', externalID => '33334399121' }
    ]
  ),
  'status/get'
);

# reference/location

ok( $three_tap->reference_location,        'reference/location' );
ok( $three_tap->reference_location('NYC'), 'reference/location/NYC' );

# reference/category

ok( $three_tap->reference_category, 'reference/category' );
ok( $three_tap->reference_category( code => 'VAUT' ),
  'reference/category/VAUT' );

test_request(
  sub {
    ok( $three_tap->reference_category( code => 'VAUT', annotations => 1 ),
      'reference/category/VAUT?annotations=1' );
  },
  sub {
    is(
      shift->uri->path_query,
      '/reference/category/VAUT?annotations=true',
      'request\'s path and params are ok'
    );
  }
);

# reference/source

test_request(
  sub { ok( $three_tap->reference_source, 'reference/source' ) },
  sub {
    is( shift->uri->path_query, '/reference/source',
      'request\'s path and params are ok' );
  }
);

test_request(
  sub { ok( $three_tap->reference_source('E_BAY'), 'reference/source' ) },
  sub {
    is( shift->uri->path_query, '/reference/source/E_BAY',
      'request\'s path and params are ok' );
  }
);

# reference/modified

test_request(
  sub {
    dies_ok { $three_tap->reference_modified() }
    'reference/modified dies without args';
  },
  sub {
  }
);

test_request(
  sub { ok( $three_tap->reference_modified('category'), 'reference/modified' ) }
  ,
  sub {
    is(
      shift->uri->path_query,
      '/reference/modified/category',
      'request\'s path and params are ok'
    );
  }
);

# posting/get

test_request(
  sub {
    dies_ok { $three_tap->posting_get() } 'posting/get dies without args';
  },
  sub {
  }
);

test_request(
  sub { ok( $three_tap->posting_get('foo'), 'posting/get' ) },
  sub {
    is( shift->uri->path_query, '/posting/get/foo',
      'request\'s path and params are ok' );
  }
);

# posting/create

ok(
  $three_tap->posting_create(
    postings => [
      {
        annotations => {
          brand => "Specialized",
          color => "red"
        },
        body        => "Thisisatestpost.One.",
        category    => "SGBI",
        currency    => "USD",
        externalURL => "http://www.ebay.com",
        heading     => "TestPost1inBicyclesForSaleCategory",
        location    => "LAX",
        price       => "1",
        timestamp   => '20101130232514',
        source      => "E_BAY"
      }
    ]
  ),
  'posting/create'
);

# posting/update

ok(
  $three_tap->posting_update(
    postings => [
      [ 'X73XFP', { price       => '20.00' } ],
      [ 'X73XFN', { accountName => 'anonymous-X73XFN@mailserver.com' } ]
    ]
  ),
  'posting/update'
);

# posting/delete

ok( $three_tap->posting_delete( postings => [ 'X73XFP', 'X73XFN' ] ),
  'posting/delete' );

# posting/exists

# ok(
#   $three_tap->posting_exists(
#     postings => [
#       { source => 'E_BAY', externalID => '220721553191' },
#       { source => 'CRAIG', externalID => '191' },
#       { source => 'AMZON', externalID => '370468535518' }
#     ]
#   ),
#   'posting/exists'
# );

# posting/error
#ok( $three_tap->posting_error('foo'), 'posting_error' );

# geocoder/geocode

ok(
  $three_tap->geocoder_geocode(
    postings => [
      { text    => 'San Francisco, California' },
      { country => 'USA', state => 'CA', city => 'Los Angeles' }
    ]
  ),
  'geocoder/geocode'
);

# notifications/firehose

ok(
  $three_tap->notifications_firehose(
    text     => 'honda',
    category => 'VAUT',
    location => 'LAX',
    name     => 'Hondas in LA'
  ),
  'notifications/firehose'
);

# notifications/delete

ok(
  $three_tap->notifications_delete(
    id     => '1873',
    secret => "201d7288b4c18a679e48b31c72c30ded"
  ),
  'notifications/delete'
);

# notifications/get

ok(
  $three_tap->notifications_get(
    id     => '1873',
    secret => "201d7288b4c18a679e48b31c72c30ded"
  ),
  'notifications/get'
);

# notifications/create

ok(
  $three_tap->notifications_create(
    text        => 'red',
    location    => 'LAX',
    source      => 'CRAIG',
    annotations => { price => "200", make => "honda" },
    email       => 'dfoley@3taps.com',
    name        => 'red things in los angeles'
  ),
  'notifications/create'
);

$three_tap->_ua->remove_handler('request_send');
$three_tap->_ua->add_handler(
  request_send => sub { return _build_response_ok('{invalid \json ]00*d>:)') }
);

dies_ok { $three_tap->search( location => 'LAX+OR+NYC', category => 'VAUT' ) }
'search fails ok on bad json';

dies_ok { $three_tap->count( location => 'LAX', category => 'VAUT' ) }
'count dies ok on bad json';

$three_tap->_ua->remove_handler('request_send');
$three_tap->_ua->add_handler(
  request_send => sub { return _build_response_err() } );

dies_ok { $three_tap->search( location => 'LAX+OR+NYC', category => 'VAUT' ) }
'search fails ok on response fail';

dies_ok { $three_tap->count( location => 'LAX', category => 'VAUT' ) }
'count dies ok on response fail';

done_testing;
