use Test::More tests => 43;
BEGIN { use_ok('Moose'); 
        use_ok('Carp');
        use_ok('LWP::UserAgent');
        use_ok('Net::OAuth'); 
        use_ok('URI');
        use_ok('XML::Simple'); 
        use_ok('WWW::Formspring'); };

my $fs;
my @test_cases = ( { args => {},
                     results => [ '', 
                                  '', 
                                  '', 
                                  'http://www.formspring.me/oauth/request_token',
                                  'http://www.formspring.me/oauth/authorize',
                                  'http://www.formspring.me/oauth/access_token',
                                  'oob',
                                  'http://beta-api.formspring.me',
                                 ],
                      predicates => [ '',
                                      '',
                                      '',
                                      '',
                                    ],
                   }, #default constructor
                   { args => { username => 'worr2400', 
                               consumer_key => 'aaa', 
                               consumer_secret => 'bbb',
                               callback_url => 'http://formspring.me',
                             },
                     results => [ 'worr2400',
                                  'aaa',
                                  'bbb',
                                  'http://www.formspring.me/oauth/request_token',
                                  'http://www.formspring.me/oauth/authorize',
                                  'http://www.formspring.me/oauth/access_token',
                                  'http://formspring.me',
                                  'http://beta-api.formspring.me',
                                 ],
                     predicates => [ 1,
                                     1,
                                     1,
                                     1,
                                   ],
                   },); #loaded with arguments

my @functions = ( "_nonce",
                  "_xmlify",
                  "get_request_token",
                  "get_access_token",
                  "_unauth_connect",
                  "answered_count",
                  "answered_details",
                  "profile_details",
                  "search_profiles",
                );

can_ok( "WWW::Formspring", @functions );

# These tests test whether setting options in the constructor works, as well
# as all the accessor methods and predicates
foreach my $test (@test_cases) {
    $fs = WWW::Formspring->new($test->{'args'});
    isa_ok( $fs, 'WWW::Formspring' );
    is( $fs->has_username, $test->{'predicates'}->[0],       'has_username()' );
    if ( $fs->has_username ) {
        is( $fs->username, $test->{'results'}->[0],          'get username' );
    }

    is( $fs->has_consumer_key, $test->{'predicates'}->[1],   'has_consumer_key()' );
    if ( $fs->has_consumer_key ) {
        is( $fs->consumer_key, $test->{'results'}->[1],      'get consumer_key' );
    }

    is( $fs->has_consumer_secret, $test->{'predicates'}->[2],'has_consumer_secret()' );
    if ( $fs->has_consumer_secret ) {
        is( $fs->consumer_secret, $test->{'results'}->[2],   'get consumer_secret' );
    }

    is( $fs->request_url, $test->{'results'}->[3],       'get request_url' );
    is( $fs->auth_url, $test->{'results'}->[4],          'get auth_url' );
    is( $fs->access_url, $test->{'results'}->[5],        'get access_url' );
    is( $fs->callback_url, $test->{'results'}->[6],      'get callback_url' );
    is( $fs->api_url, $test->{'results'}->[7],           'get api_url' );
    isa_ok( $fs->ua, 'LWP::UserAgent' );
}

my %params = ( username         => 'worr',
               consumer_key     => 'aaaa',
               consumer_secret  => 'bbbb',
               callback_url     => 'http://google.com',
             );

# Test mutators
$fs = WWW::Formspring->new;
$fs->username($params{'username'});
$fs->consumer_key($params{'consumer_key'});
$fs->consumer_secret($params{'consumer_secret'});
$fs->callback_url($params{'callback_url'});

is( $fs->username, $params{'username'},                 'set username' );
is( $fs->consumer_key, $params{'consumer_key'},         'set consumer_key' );
is( $fs->consumer_secret, $params{'consumer_secret'},   'set consumer_secret' );
is( $fs->callback_url, $params{'callback_url'},         'set callback_url' );

my @callback_urls = ( 'oob',
                      'http://google.com/',
                      'https://google.com/',
                      'http://google.com/index.php',
                      'http://101.com/',
                      'http://google.com',
                      'http://openbsd.org',
                      'http://www',
                    );

# Test valid values for callback_url
foreach my $callback_url (@callback_urls) {
    $fs->callback_url($callback_url);
    is( $fs->callback_url, $callback_url,               "callback_url $callback_url" );
}
