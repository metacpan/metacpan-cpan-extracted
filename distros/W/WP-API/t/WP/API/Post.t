use strict;
use warnings;

use lib 't/lib';

use Test::Fatal;
use Test::More 0.88;
use Test::XMLRPC::Lite;
use Test::WP::API;

use XMLRPC::Lite;
use WP::API;

my $api = WP::API->new(
    blog_id          => 42,
    username         => 'testuser',
    password         => 'testpass',
    proxy            => 'http://example.com/xmlrpc.php',
    server_time_zone => 'America/Chicago',
    _xmlrpc_class    => 'Test::XMLRPC::Lite'
);

{
    my $post = $api->post()->new( post_id => 1252 );
    isa_ok( $post, 'WP::API::Post' );

    local $Test::XMLRPC::Lite::CallTest = sub {
        is( shift, 'wp.getPost', 'method passed to XMLRPC::Lite->call' );
        is( shift, 42,           'second argument to XMLRPC::Lite->call' );
        is( shift, 'testuser',   'third argument to XMLRPC::Lite->call' );
        is( shift, 'testpass',   'fourth argument to XMLRPC::Lite->call' );
        is( shift, 1252,         'fifth argument to XMLRPC::Lite->call' );
    };

    local $Test::XMLRPC::Lite::ResponseXML = <<'EOF';
<methodResponse>
  <params>
    <param>
      <value>
      <struct>
  <member><name>post_id</name><value><string>1252</string></value></member>
  <member><name>post_title</name><value><string>Test</string></value></member>
  <member><name>post_date</name><value><dateTime.iso8601>20130721T11:38:55</dateTime.iso8601></value></member>
  <member><name>post_date_gmt</name><value><dateTime.iso8601>20130721T16:38:55</dateTime.iso8601></value></member>
  <member><name>post_modified</name><value><dateTime.iso8601>20130721T11:38:55</dateTime.iso8601></value></member>
  <member><name>post_modified_gmt</name><value><dateTime.iso8601>20130721T16:38:55</dateTime.iso8601></value></member>
  <member><name>post_status</name><value><string>publish</string></value></member>
  <member><name>post_type</name><value><string>post</string></value></member>
  <member><name>post_name</name><value><string>test</string></value></member>
  <member><name>post_author</name><value><string>1</string></value></member>
  <member><name>post_password</name><value><string></string></value></member>
  <member><name>post_excerpt</name><value><string></string></value></member>
  <member><name>post_content</name><value><string>body</string></value></member>
  <member><name>post_parent</name><value><string>0</string></value></member>
  <member><name>post_mime_type</name><value><string></string></value></member>
  <member><name>link</name><value><string>http://test.exploreveg.org/2013/07/21/test/</string></value></member>
  <member><name>guid</name><value><string>http://test.exploreveg.org/?p=1252</string></value></member>
  <member><name>menu_order</name><value><int>0</int></value></member>
  <member><name>comment_status</name><value><string>closed</string></value></member>
  <member><name>ping_status</name><value><string>closed</string></value></member>
  <member><name>sticky</name><value><boolean>0</boolean></value></member>
  <member><name>post_thumbnail</name><value><array><data>
</data></array></value></member>
  <member><name>post_format</name><value><string>standard</string></value></member>
  <member><name>terms</name><value><array><data>
  <value><struct>
  <member><name>term_id</name><value><string>1</string></value></member>
  <member><name>name</name><value><string>Uncategorized</string></value></member>
  <member><name>slug</name><value><string>uncategorized</string></value></member>
  <member><name>term_group</name><value><string>0</string></value></member>
  <member><name>term_taxonomy_id</name><value><string>1</string></value></member>
  <member><name>taxonomy</name><value><string>category</string></value></member>
  <member><name>description</name><value><string></string></value></member>
  <member><name>parent</name><value><string>0</string></value></member>
  <member><name>count</name><value><int>1</int></value></member>
</struct></value>
</data></array></value></member>
  <member><name>custom_fields</name><value><array><data>
  <value><struct>
  <member><name>id</name><value><string>3085</string></value></member>
  <member><name>key</name><value><string>_yoast_wpseo_canonical</string></value></member>
  <member><name>value</name><value><string></string></value></member>
</struct></value>
</data></array></value></member>
</struct>
      </value>
    </param>
  </params>
</methodResponse>
EOF

    my %expect = (
        post_title     => 'Test',
        post_status    => 'publish',
        post_type      => 'post',
        post_name      => 'test',
        post_author    => 1,
        post_password  => undef,
        post_excerpt   => undef,
        post_content   => 'body',
        post_parent    => 0,
        post_mime_type => undef,
        link           => 'http://test.exploreveg.org/2013/07/21/test/',
        guid           => 'http://test.exploreveg.org/?p=1252',
        menu_order     => 0,
        comment_status => 'closed',
        ping_status    => 'closed',
        sticky         => 0,
        post_thumbnail => {},
        post_format    => 'standard',
        terms          => [
            {
                term_id          => 1,
                name             => 'Uncategorized',
                slug             => 'uncategorized',
                term_group       => 0,
                term_taxonomy_id => 1,
                taxonomy         => 'category',
                description      => q{},
                parent           => 0,
                count            => 1,
            },
        ],
        custom_fields => [
            {
                id    => 3085,
                key   => '_yoast_wpseo_canonical',
                value => q{},
            },
        ],
        enclosure => {},
    );

    for my $meth ( sort keys %expect ) {
        is_deeply( $post->$meth(), $expect{$meth}, $meth );
    }

    is(
        format_datetime_value( $post->post_date_gmt() ),
        '2013-07-21T16:38:55 UTC',
        'post_date_gmt'
    );

    is(
        format_datetime_value( $post->post_date() ),
        '2013-07-21T11:38:55 America/Chicago',
        'post_date'
    );

    is(
        format_datetime_value( $post->post_modified_gmt() ),
        '2013-07-21T16:38:55 UTC',
        'post_date_gmt'
    );

    is(
        format_datetime_value( $post->post_modified() ),
        '2013-07-21T11:38:55 America/Chicago',
        'post_date'
    );

    for my $meth (qw( link guid )) {
        isa_ok( $post->$meth(), 'URI', "\$post->$meth" );
    }
}

{
    my $dt = DateTime->new(
        year      => 2013,
        month     => 7,
        day       => 21,
        hour      => 15,
        minute    => 56,
        second    => 27,
        time_zone => 'UTC',
    );

    my %p = (
        post_title    => 'Foo',
        post_date_gmt => $dt,
        post_content  => 'This is the body',
        post_author   => 42,
    );

    my %expect = %p;
    $expect{post_date_gmt} = $dt->format_cldr(q{YYYMMdd'T'HH:mm:ss});
    $expect{post_status}   = 'publish';

    local $Test::XMLRPC::Lite::CallTest = sub {
        is( shift, 'wp.newPost', 'method passed to XMLRPC::Lite->call' );
        is( shift, 42,           'second argument to XMLRPC::Lite->call' );
        is( shift, 'testuser',   'third argument to XMLRPC::Lite->call' );
        is( shift, 'testpass',   'fourth argument to XMLRPC::Lite->call' );
        is_deeply( shift, \%expect, 'got expected post creation parameters' );
    };

    local $Test::XMLRPC::Lite::ResponseXML = <<'EOF';
<methodResponse>
  <params>
    <param>
      <value><string>1284</string></value>
    </param>
  </params>
</methodResponse>
EOF

    my $post = $api->post()->create(%p);

    isa_ok( $post, 'WP::API::Post' );
}

done_testing();
