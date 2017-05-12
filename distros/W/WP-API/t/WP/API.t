use strict;
use warnings;

use lib 't/lib';
use Test::XMLRPC::Lite;

use Test::Fatal;
use Test::More 0.88;

use XMLRPC::Lite;
use WP::API;

my $api = WP::API->new(
    blog_id          => 42,
    username         => 'testuser',
    password         => 'testpass',
    proxy            => 'http://example.com/xmlrpc.php',
    server_time_zone => 'UTC',
    _xmlrpc_class    => 'Test::XMLRPC::Lite'
);

{
    my @params = ( 'foo', 99, { x => 'y' } );

    local $Test::XMLRPC::Lite::CallTest = sub {
        is( shift, 'test.Method', 'method passed to XMLRPC::Lite->call' );
        is( shift, 42,            'second argument to XMLRPC::Lite->call' );
        is( shift, 'testuser',    'third argument to XMLRPC::Lite->call' );
        is( shift, 'testpass',    'fourth argument to XMLRPC::Lite->call' );
        is_deeply(
            \@_, \@params,
            'additional parameters to XMLRPC::Lite->call'
        );
    };

    local $Test::XMLRPC::Lite::ResponseXML = <<'EOF';
<?xml version="1.0" encoding="UTF-8"?>
<methodResponse>
  <params>
    <param>
      <value>
        <struct>
          <member><name>post_id</name><value><string>1252</string></value></member>
          <member><name>post_title</name><value><string>Test</string></value></member>
        </struct>
      </value>
    </param>
  </params>
</methodResponse>
EOF

    my $result = $api->call( 'test.Method', @params );

    is_deeply(
        $result,
        {
            post_id    => 1252,
            post_title => 'Test',
        },
        'result from XMLRPC::Lite->call'
    );
}

{
    local $Test::XMLRPC::Lite::ResponseXML = <<'EOF';
<?xml version="1.0" encoding="UTF-8"?>
<methodResponse>
  <fault>
    <value>
      <struct>
        <member>
          <name>faultCode</name>
          <value><int>400</int></value>
        </member>
        <member>
          <name>faultString</name>
          <value><string>Insufficient arguments passed to this XML-RPC method.</string></value>
        </member>
      </struct>
    </value>
  </fault>
</methodResponse>
EOF

    like(
        exception { $api->call('test.Method') },
        qr/\QError calling test.Method XML-RPC method: Code = 400 - String = Insufficient arguments passed to this XML-RPC method./,
        'fault result from XMLRPC::Lite->call'
    );
}

{
    local $Test::XMLRPC::Lite::ResponseXML = <<'EOF';
<?xml version="1.0" encoding="UTF-8"?>
<methodResponse>
  <params>
    <param>
      <value>
      <array><data>
  <value><struct>
  <member><name>isAdmin</name><value><boolean>1</boolean></value></member>
  <member><name>url</name><value><string>http://test.exploreveg.org/</string></value></member>
  <member><name>blogid</name><value><string>5</string></value></member>
  <member><name>blogName</name><value><string>Compassionate Action for Animals</string></value></member>
  <member><name>xmlrpc</name><value><string>http://test.exploreveg.org/xmlrpc.php</string></value></member>
</struct></value>
</data></array>
      </value>
    </param>
  </params>
</methodResponse>
EOF

    my $api = WP::API->new(
        username         => 'testuser',
        password         => 'testpass',
        proxy            => 'http://example.com/xmlrpc.php',
        server_time_zone => 'UTC',
        _xmlrpc_class    => 'Test::XMLRPC::Lite'
    );

    is( $api->blog_id(), 5, 'got blog_id from server' );
}

{
    local $Test::XMLRPC::Lite::ResponseXML = <<'EOF';
<?xml version="1.0" encoding="UTF-8"?>
<methodResponse>
  <params>
    <param>
      <value>
      <array><data>
  <value><struct>
  <member><name>isAdmin</name><value><boolean>1</boolean></value></member>
  <member><name>url</name><value><string>http://test.exploreveg.org/</string></value></member>
  <member><name>blogid</name><value><string>5</string></value></member>
  <member><name>blogName</name><value><string>Compassionate Action for Animals</string></value></member>
  <member><name>xmlrpc</name><value><string>http://test.exploreveg.org/xmlrpc.php</string></value></member>
</struct></value>
<value><struct>
  <member><name>isAdmin</name><value><boolean>1</boolean></value></member>
  <member><name>url</name><value><string>http://test2.exploreveg.org/</string></value></member>
  <member><name>blogid</name><value><string>6</string></value></member>
  <member><name>blogName</name><value><string>Compassionate Action for Animals 2</string></value></member>
  <member><name>xmlrpc</name><value><string>http://test2.exploreveg.org/xmlrpc.php</string></value></member>
</struct></value>
</data></array>
      </value>
    </param>
  </params>
</methodResponse>
EOF

    my $api = WP::API->new(
        username         => 'testuser',
        password         => 'testpass',
        proxy            => 'http://example.com/xmlrpc.php',
        server_time_zone => 'UTC',
        _xmlrpc_class    => 'Test::XMLRPC::Lite'
    );

    like(
        exception { $api->blog_id() },
        qr/This user belongs to more than one blog. Please supply a blog_id to the WP::API constructor/,
        'cannot determine blog_id if user belongs to more than one blog'
    );
}

done_testing();
