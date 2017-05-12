use strict;
use warnings;

use lib 't/lib';
use Test::Mock::REST::Client;
use Test::Most;

if ( Test::Mock::REST::Client::missing_responses ) {
    Test::Most::plan(
        skip_all =>
          sprintf(
"missing saved HTTP responses in %s, rerun tests with environment variable BIGDOOR_TEST_SAVE_RESPONSES defined",
            $Test::Mock::REST::Client::response_directory )
    );
}
elsif ( ( exists $ENV{BIGDOOR_TEST_SAVE_RESPONSES} || exists $ENV{BIGDOOR_TEST_LIVESERVER} )
    && !( exists $ENV{BIGDOOR_API_KEY} && exists $ENV{BIGDOOR_API_SECRET} ) )
{
    Test::Most::plan( skip_all =>
"ENV{BIGDOOR_API_KEY} and/or ENV{BIGDOOR_API_SECRET} undefined while running against live server"
    );
}
else {
    Test::Most::plan( tests => 23 );
}

use JSON;
#use Smart::Comments -ENV;

## Setup

## TODO move to module
our $TEST_APP_KEY    = $ENV{BIGDOOR_API_KEY}    || '28d3da80bf36fad415ab57b3130c6cb6';
our $TEST_APP_SECRET = $ENV{BIGDOOR_API_SECRET} || 'B66F956ED83AE218612CB0FBAC2EF01C';

my $module = 'WWW::BigDoor';

use_ok( $module );
can_ok( $module, 'new' );

my $client = new WWW::BigDoor( $TEST_APP_SECRET, $TEST_APP_KEY );

isa_ok( $client, $module );

## Setup

my $restclient = Test::Mock::REST::Client::setup_mock( $client );
use_ok( 'REST::Client' );

my $response;

use_ok( 'WWW::BigDoor::Attribute' );
can_ok( 'WWW::BigDoor::Attribute', 'new' );
can_ok( 'WWW::BigDoor::Attribute', 'all' );
can_ok( 'WWW::BigDoor::Attribute', 'load' );
can_ok( 'WWW::BigDoor::Attribute', 'save' );
can_ok( 'WWW::BigDoor::Attribute', 'remove' );

my $attributes = WWW::BigDoor::Attribute->all( $client );
cmp_deeply(
    $attributes,
    [
        bless(
            {
                attributes           => [],
                created_timestamp    => 1263941758,
                end_user_description => undef,
                end_user_title       => undef,
                friendly_id          => '7a0670c7e0cb4bc280cc67276fce5754',
                id                   => 13,
                modified_timestamp   => 1265983532,
                pub_description      => 'Attribute used to associate preview related URLs',
                pub_title            => 'Preview',
                read_only            => 1,
                resource_name        => 'attribute'
            },
            'WWW::BigDoor::Attribute'
        ),
        bless(
            {
                pub_title       => 'Full',
                pub_description => 'Attribute used to associate full image URLs for virtual goods',
                end_user_description => undef,
                end_user_title       => undef,
                attributes           => [],
                friendly_id          => '86836696b39347c789df0ac06966c724',
                id                   => 14,
                modified_timestamp   => 1265983532,
                created_timestamp    => 1263941797,
                read_only            => 1,
                resource_name        => 'attribute'
            },
            'WWW::BigDoor::Attribute'
        ),

        
        bless(
           {
             attributes => [],
             created_timestamp => 1292637738,  
             end_user_description => '',
             end_user_title => 'Deal',
             friendly_id => 'deal',
             id => 13557,
             modified_timestamp => 1292637738, 
             pub_description => '',
             pub_title => 'Deal',
             read_only => 1,
             resource_name => 'attribute'
           },
            'WWW::BigDoor::Attribute'
        ),
        bless(
           {
             attributes => [],
             created_timestamp => 1292637640,  
             end_user_description => '',
             end_user_title => 'Deal Purchase Currency Sink',
             friendly_id => 'deal_purchase_currency_sink',
             id => 13555,
             modified_timestamp => 1292637640, 
             pub_description => '',
             pub_title => 'Deal Purchase Currency Sink',
             read_only => 1,
             resource_name => 'attribute'
           },
            'WWW::BigDoor::Attribute'
        ),
        bless(
           {
             attributes => [],
             created_timestamp => 1292637678,  
             end_user_description => '',
             end_user_title => 'Deal Purchase Currency Source',
             friendly_id => 'deal_purchase_currency_source',
             id => 13556,
             modified_timestamp => 1292637678, 
             pub_description => '',
             pub_title => 'Deal Purchase Currency Source',
             read_only => 1,
             resource_name => 'attribute'
           },

            'WWW::BigDoor::Attribute'
        ),
        bless(
           {
           attributes => [],
           created_timestamp => 1292637594,
           end_user_description => '',
           end_user_title => 'Pilot Purchase Currency',
           friendly_id => 'pilot_purchase_currency',
           id => 13554,
           modified_timestamp => 1292637594,
           pub_description => '',
           pub_title => 'Pilot Purchase Currency',
           read_only => 1,
           resource_name => 'attribute'
           },

            'WWW::BigDoor::Attribute'
        ),
    ],
    'should be 2 predefined attributes at the beginning'
);

my $attribute_payload = {
    pub_title            => 'Test Attirubute',
    pub_description      => 'test description',
    end_user_title       => 'end user title',
    end_user_description => 'end user description',
};
my $attribute_obj = new WWW::BigDoor::Attribute( $attribute_payload );

cmp_deeply(
    $attribute_obj,
    bless(
        {
            pub_title            => 'Test Attirubute',
            pub_description      => 'test description',
            end_user_title       => 'end user title',
            end_user_description => 'end user description',
        },
        'WWW::BigDoor::Attribute'
    ),
    'attribute_obj matches deeply'
);

$attribute_obj->save( $client );
is( $client->get_response_code, 201, 'response for attribute_obj->save matches' );

cmp_deeply(
    $attribute_obj,
    bless(
        {
            pub_title            => 'Test Attirubute',
            pub_description      => 'test description',
            end_user_title       => 'end user title',
            end_user_description => 'end user description',
            resource_name        => 'attribute',
            friendly_id          => ignore(),
            modified_timestamp   => re( '\d{10}' ),
            created_timestamp    => re( '\d{10}' ),
            read_only            => 0,
            id                   => re( '\d+' ),
            attributes           => [],
        },
        'WWW::BigDoor::Attribute'
    ),
    'attribute_obj matches deeply'
);

use_ok( 'WWW::BigDoor::URL' );

my $url_payload = {
    pub_title            => 'Test URL',
    pub_description      => 'test description',
    end_user_title       => 'end user title',
    end_user_description => 'end user description',
    url                  => 'http://example.com/',
};
my $url_obj = new WWW::BigDoor::URL( $url_payload );

$url_obj->save( $client );
is( $client->get_response_code, 201, 'response for url_obj->save matches' );

cmp_deeply(
    $url_obj,
    bless(
        {
            pub_title            => 'Test URL',
            pub_description      => 'test description',
            end_user_title       => 'end user title',
            end_user_description => 'end user description',
            attributes           => [],
            is_for_end_user_ui   => undef,
            is_media_url         => undef,
            resource_name        => 'url',
            modified_timestamp   => re( '\d{10}' ),
            created_timestamp    => re( '\d{10}' ),
            read_only            => 0,
            id                   => re( '\d+' ),
            url                  => 'http://example.com/',
        },
        'WWW::BigDoor::URL'
    ),
    'url_obj matches deeply'
);

$attribute_obj->associate_with( $url_obj, $client );
is( $client->get_response_code, 201, 'response code for $attribute_obj->associate_with matches' );

$url_obj->load( $client );
is( $client->get_response_code, 200, 'response code for $url_obj->load matches' );

cmp_deeply(
    $url_obj,
    bless(
        {
            pub_title            => 'Test URL',
            pub_description      => 'test description',
            end_user_title       => 'end user title',
            end_user_description => 'end user description',
            attributes           => [
                {
                    pub_title            => 'Test Attirubute',
                    pub_description      => 'test description',
                    end_user_title       => 'end user title',
                    end_user_description => 'end user description',
                    resource_name        => 'attribute',
                    friendly_id          => ignore(),
                    modified_timestamp   => re( '\d{10}' ),
                    created_timestamp    => re( '\d{10}' ),
                    read_only            => 0,
                    id                   => re( '\d+' ),
                    attributes           => [],
                }
            ],
            is_for_end_user_ui => undef,
            is_media_url       => undef,
            resource_name      => 'url',
            modified_timestamp => re( '\d{10}' ),
            created_timestamp  => re( '\d{10}' ),
            read_only          => 0,
            id                 => re( '\d+' ),
            url                => 'http://example.com/',
        },
        'WWW::BigDoor::URL'
    ),
    'url_obj matches deeply'
);

$url_obj->remove( $client );
is( $client->get_response_code, 204, 'response code for url_obj->remove matches' );

$attribute_obj->remove( $client );
is( $client->get_response_code, 204, 'response code for attribute_obj->remove matches' );

$attributes = WWW::BigDoor::Attribute->all( $client );
cmp_deeply(
    $attributes,
    [
        bless(
            {
                attributes           => [],
                created_timestamp    => 1263941758,
                end_user_description => undef,
                end_user_title       => undef,
                friendly_id          => '7a0670c7e0cb4bc280cc67276fce5754',
                id                   => 13,
                modified_timestamp   => 1265983532,
                pub_description      => 'Attribute used to associate preview related URLs',
                pub_title            => 'Preview',
                read_only            => 1,
                resource_name        => 'attribute'
            },
            'WWW::BigDoor::Attribute'
        ),
        bless(
            {
                pub_title       => 'Full',
                pub_description => 'Attribute used to associate full image URLs for virtual goods',
                end_user_description => undef,
                end_user_title       => undef,
                attributes           => [],
                friendly_id          => '86836696b39347c789df0ac06966c724',
                id                   => 14,
                modified_timestamp   => 1265983532,
                created_timestamp    => 1263941797,
                read_only            => 1,
                resource_name        => 'attribute'
            },
            'WWW::BigDoor::Attribute'
        ),

        
        bless(
           {
             attributes => [],
             created_timestamp => 1292637738,  
             end_user_description => '',
             end_user_title => 'Deal',
             friendly_id => 'deal',
             id => 13557,
             modified_timestamp => 1292637738, 
             pub_description => '',
             pub_title => 'Deal',
             read_only => 1,
             resource_name => 'attribute'
           },
            'WWW::BigDoor::Attribute'
        ),
        bless(
           {
             attributes => [],
             created_timestamp => 1292637640,  
             end_user_description => '',
             end_user_title => 'Deal Purchase Currency Sink',
             friendly_id => 'deal_purchase_currency_sink',
             id => 13555,
             modified_timestamp => 1292637640, 
             pub_description => '',
             pub_title => 'Deal Purchase Currency Sink',
             read_only => 1,
             resource_name => 'attribute'
           },
            'WWW::BigDoor::Attribute'
        ),
        bless(
           {
             attributes => [],
             created_timestamp => 1292637678,  
             end_user_description => '',
             end_user_title => 'Deal Purchase Currency Source',
             friendly_id => 'deal_purchase_currency_source',
             id => 13556,
             modified_timestamp => 1292637678, 
             pub_description => '',
             pub_title => 'Deal Purchase Currency Source',
             read_only => 1,
             resource_name => 'attribute'
           },

            'WWW::BigDoor::Attribute'
        ),
        bless(
           {
           attributes => [],
           created_timestamp => 1292637594,
           end_user_description => '',
           end_user_title => 'Pilot Purchase Currency',
           friendly_id => 'pilot_purchase_currency',
           id => 13554,
           modified_timestamp => 1292637594,
           pub_description => '',
           pub_title => 'Pilot Purchase Currency',
           read_only => 1,
           resource_name => 'attribute'
           },

            'WWW::BigDoor::Attribute'
        ),
    ],
    'should be 2 attributes at the end'
);
