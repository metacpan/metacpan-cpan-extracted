use strict;
use warnings;

use lib 't/lib';

use Test::Fatal;
use Test::More 0.88;
use Test::XMLRPC::Lite;
use Test::WP::API;

use Test::Fatal;
use Test::More 0.88;

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
    my $media = $api->media()->new( attachment_id => 1244 );
    isa_ok( $media, 'WP::API::Media' );

    local $Test::XMLRPC::Lite::CallTest = sub {
        is( shift, 'wp.getMediaItem', 'method passed to XMLRPC::Lite->call' );
        is( shift, 42,         'second argument to XMLRPC::Lite->call' );
        is( shift, 'testuser', 'third argument to XMLRPC::Lite->call' );
        is( shift, 'testpass', 'fourth argument to XMLRPC::Lite->call' );
        is( shift, 1244,       'fifth argument to XMLRPC::Lite->call' );
    };

    local $Test::XMLRPC::Lite::ResponseXML = <<'EOF';
<methodResponse>
  <params>
    <param>
      <value>
      <struct>
  <member><name>attachment_id</name><value><string>1244</string></value></member>
  <member><name>date_created_gmt</name><value><dateTime.iso8601>20130720T16:01:42</dateTime.iso8601></value></member>
  <member><name>parent</name><value><int>0</int></value></member>
  <member><name>link</name><value><string>http://test.exploreveg.org/files/2013/07/3rd-annual-vegan-main-dish-competition-at-the-state-fair10.jpg</string></value></member>
  <member><name>title</name><value><string>3rd-annual-vegan-main-dish-competition-at-the-state-fair.jpg</string></value></member>
  <member><name>caption</name><value><string></string></value></member>
  <member><name>description</name><value><string></string></value></member>
  <member><name>metadata</name><value><struct>
  <member><name>width</name><value><int>2530</int></value></member>
  <member><name>height</name><value><int>1668</int></value></member>
  <member><name>file</name><value><string>2013/07/3rd-annual-vegan-main-dish-competition-at-the-state-fair10.jpg</string></value></member>
  <member><name>sizes</name><value><struct>
  <member><name>thumbnail</name><value><struct>
  <member><name>file</name><value><string>3rd-annual-vegan-main-dish-competition-at-the-state-fair10-150x150.jpg</string></value></member>
  <member><name>width</name><value><int>150</int></value></member>
  <member><name>height</name><value><int>150</int></value></member>
  <member><name>mime-type</name><value><string>image/jpeg</string></value></member>
</struct></value></member>
  <member><name>medium</name><value><struct>
  <member><name>file</name><value><string>3rd-annual-vegan-main-dish-competition-at-the-state-fair10-300x197.jpg</string></value></member>
  <member><name>width</name><value><int>300</int></value></member>
  <member><name>height</name><value><int>197</int></value></member>
  <member><name>mime-type</name><value><string>image/jpeg</string></value></member>
</struct></value></member>
  <member><name>large</name><value><struct>
  <member><name>file</name><value><string>3rd-annual-vegan-main-dish-competition-at-the-state-fair10-1024x675.jpg</string></value></member>
  <member><name>width</name><value><int>1024</int></value></member>
  <member><name>height</name><value><int>675</int></value></member>
  <member><name>mime-type</name><value><string>image/jpeg</string></value></member>
</struct></value></member>
</struct></value></member>
  <member><name>image_meta</name><value><struct>
  <member><name>aperture</name><value><double>2</double></value></member>
  <member><name>credit</name><value><string></string></value></member>
  <member><name>camera</name><value><string>CYBERSHOT</string></value></member>
  <member><name>caption</name><value><string></string></value></member>
  <member><name>created_timestamp</name><value><int>1157322900</int></value></member>
  <member><name>copyright</name><value><string></string></value></member>
  <member><name>focal_length</name><value><string>9.7</string></value></member>
  <member><name>iso</name><value><string>320</string></value></member>
  <member><name>shutter_speed</name><value><string>0.0333333333333</string></value></member>
  <member><name>title</name><value><string></string></value></member>
</struct></value></member>
</struct></value></member>
  <member><name>thumbnail</name><value><string>http://test.exploreveg.org/files/2013/07/3rd-annual-vegan-main-dish-competition-at-the-state-fair10-150x150.jpg</string></value></member>
</struct>
      </value>
    </param>
  </params>
</methodResponse>
EOF

    my %expect = (
        attachment_id => 1244,
        parent        => 0,
        link =>
            'http://test.exploreveg.org/files/2013/07/3rd-annual-vegan-main-dish-competition-at-the-state-fair10.jpg',
        title =>
            '3rd-annual-vegan-main-dish-competition-at-the-state-fair.jpg',
        caption  => undef,
        metadata => {
            width  => 2530,
            height => 1668,
            file =>
                '2013/07/3rd-annual-vegan-main-dish-competition-at-the-state-fair10.jpg',
            image_meta => {
                aperture          => 2,
                credit            => q{},
                camera            => 'CYBERSHOT',
                caption           => q{},
                created_timestamp => 1157322900,
                copyright         => q{},
                focal_length      => 9.7,
                iso               => 320,
                shutter_speed     => '0.0333333333333',
                title             => q{},
            },
            sizes => {
                thumbnail => {
                    file =>
                        '3rd-annual-vegan-main-dish-competition-at-the-state-fair10-150x150.jpg',
                    width       => 150,
                    height      => 150,
                    'mime-type' => 'image/jpeg',
                },
                medium => {
                    file =>
                        '3rd-annual-vegan-main-dish-competition-at-the-state-fair10-300x197.jpg',
                    width       => 300,
                    height      => 197,
                    'mime-type' => 'image/jpeg',
                },
                large => {
                    file =>
                        '3rd-annual-vegan-main-dish-competition-at-the-state-fair10-1024x675.jpg',
                    width       => 1024,
                    height      => 675,
                    'mime-type' => 'image/jpeg',
                },
            },
        },
        thumbnail =>
            'http://test.exploreveg.org/files/2013/07/3rd-annual-vegan-main-dish-competition-at-the-state-fair10-150x150.jpg',
    );

    for my $meth ( sort keys %expect ) {
        is_deeply( $media->$meth(), $expect{$meth}, $meth );
    }

    for my $meth (qw( link thumbnail )) {
        isa_ok( $media->$meth(), 'URI', "\$media->$meth" );
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
        name      => 'foo.txt',
        type      => 'text/plain',
        bits      => 'some text',
        overwrite => 1,
    );

    local $Test::XMLRPC::Lite::CallTest = sub {
        is( shift, 'wp.uploadFile', 'method passed to XMLRPC::Lite->call' );
        is( shift, 42,              'second argument to XMLRPC::Lite->call' );
        is( shift, 'testuser',      'third argument to XMLRPC::Lite->call' );
        is( shift, 'testpass',      'fourth argument to XMLRPC::Lite->call' );
        is_deeply(
            @_,
            \%p,
            'got expected media creation parameters'
        );
    };

    local $Test::XMLRPC::Lite::ResponseXML = <<'EOF';
<methodResponse>
  <params>
    <param>
      <value>
      <struct>
  <member><name>id</name><value><string>99</string></value></member>
  <member><name>file</name><value><string>foo.txt</string></value></member>
  <member><name>url</name><value><string>http://example.com/foo.txt</string></value></member>
  <member><name>type</name><value><string>text/plain</string></value></member>
      </struct>
      </value>
    </param>
  </params>
</methodResponse>
EOF

    my $media = $api->media()->create(%p);

    isa_ok( $media, 'WP::API::Media' );
}

done_testing();
