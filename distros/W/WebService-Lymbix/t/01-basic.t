use Test::Most 0.25;

use WebService::Lymbix;

my $auth_key             = $ENV{LYMBIX_AUTH_KEY} || 'password';
my $accept_type          = 'application/json';
my $article_reference_id = '12345';
my $version              = $ENV{LYMBIX_API_VER} || '2.2';
my $lymbix;

subtest 'Init' => sub {

    # Minimum requirement init
    $lymbix = WebService::Lymbix->new( auth_key => $auth_key );
    ok( $lymbix,
        'Successfully initialized with auth_key and other default values' );
    isa_ok( $lymbix, 'WebService::Lymbix' );

    # Optional keys
    $lymbix = WebService::Lymbix->new(
        auth_key             => $auth_key,
        accept_type          => $accept_type,
        article_reference_id => $article_reference_id,
    );
    ok( $lymbix, 'Successfully initialized with optional keys' );
    isa_ok( $lymbix, 'WebService::Lymbix' );
};

subtest 'Init sanity checks' => sub {

    dies_ok { WebService::Lymbix->new() } 'Expected to die with no params';
    dies_ok { WebService::Lymbix->new( auth_key_invalid => $auth_key ) }
    'Expected to die on invalid parameters';
    dies_ok { WebService::Lymbix->new( accept_type => $accept_type ) }
    'Expected to die on missing required params';
    dies_ok {
        WebService::Lymbix->new(
            accept_type          => $accept_type,
            article_reference_id => $article_reference_id
          )
    }
    'Expected to die on missing required params';
    dies_ok {
        WebService::Lymbix->new(
            auth_key    => $auth_key,
            accept_type => 'llll'
          )
    }
    'Expect to die on invalid value for accept_type';
};

done_testing();
