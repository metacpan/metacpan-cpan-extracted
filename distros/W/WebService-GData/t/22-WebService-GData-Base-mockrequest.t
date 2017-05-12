use Test::More tests=>24;

use Test::Mock::LWP;

my %RHeaders = ();
my $UA       = undef;
my $Method   = undef;
my $Content  = undef;

$Mock_request->mock(
    content_type => sub {
    }
  )->mock(
    header => sub {
        my ( $this, $header, $content ) = @_;
        $RHeaders{$header} = $content if ( $header && $content );
        return $RHeaders{$header};
    }
  )->mock(
    method => sub {
        my ( $this, $method ) = @_;
        $Method = $method if ($method);
        return $Method;
    }
  )->mock(
    content => sub {
        my ( $this, $content ) = @_;
        $Content = $content if ($content);
        return $Content;

    }
  );

$Mock_ua->mock(
    agent => sub {
        my ( $this, $agent ) = @_;
        $UA = $agent if ($agent);
        return $UA;
    }
);

$Mock_response->mock(
    content => sub {
        return '{}';
    }
);

use WebService::GData::Base;
use WebService::GData::Constants qw(:all);

my $base = new WebService::GData::Base();

$base->query->alt('atom');
my $resp = $base->get('http://www.example.com/?alt=json');

ok(
    $base->get_uri eq 'http://www.example.com/',
    'get_uri sends back the uri without the query string.'
);

ok(
    $Mock_request->header('GData-Version') == $base->query->get('v'),
    'GData-Version header has been set to the query object v parameter value.'
);

ok(
    !$Mock_request->header('Content-Length'),
    'Content-Length is not set for a get request.'
);

ok(
    $base->user_agent_name eq 'WebService::GData::Base/'
      . $WebService::GData::Base::VERSION,
    'the user agent is set to the package name and version.'
);

ok( $resp eq '{}',
    'get sends back the raw response if alt is not set to jsonc*.' );

$base->query->alt('json');
$resp = $base->get('http://www.example.com/?alt=atom');

ok( ref($resp) eq 'HASH',
    'get sends back a perl object if alt is set to jsonc*.' );

my $mockauth = new MockAuth;
$base->auth($mockauth);

ok( ref( $base->auth ) eq 'MockAuth', 'auth object as been properly set.' );

ok(
    $base->user_agent_name eq $mockauth->source
      .' '. ref($base) . '/'
      . $WebService::GData::Base::VERSION,
    'the user agent name is properly set.'
);

$base->enable_compression('true');
ok(
    $base->user_agent_name eq $mockauth->source
      .' '. ref($base) . '/'
      . $WebService::GData::Base::VERSION.' (gzip)',
    'the user agent name is properly set.'
);

$base->enable_compression('false');
ok(
    $base->user_agent_name eq $mockauth->source
      .' '. ref($base) . '/'
      . $WebService::GData::Base::VERSION,
    'the user agent name is properly set.'
);
$base->user_agent_name('bot');
$base->enable_compression('true');
ok(
    $base->user_agent_name eq $mockauth->source
      .' bot '. ref($base) . '/'
      . $WebService::GData::Base::VERSION.' (gzip)',
    'the user agent name is properly set.'
);
$base->user_agent_name('');
$base->enable_compression('false');
ok(
    $base->user_agent_name eq $mockauth->source
      .' '. ref($base) . '/'
      . $WebService::GData::Base::VERSION,
    'the user agent name is properly set.'
);

$resp = $base->insert( 'http://www.example.com', '<title>tete</title>' );

ok(
    $Mock_request->new_args()->[1] eq 'POST',
    'the request is a POST for insert method.'
);

ok(
    $Mock_request->header('Authorization') eq 'key=test',
    'auth object authorization header has been set.'
);
ok(
    $Mock_request->header('Testing') == 1,
    'auth object service header has been set.'
);

my $xml_content = q[<title>tete</title>];
ok( $Mock_request->content() eq $xml_content,
    'insert contents is present.' );
ok( $resp eq '{}', 'insert sends back the raw response from the server.' );

$resp = $base->update( 'http://www.example.com', '<title>eeee</title>' );

ok(
    $Mock_request->new_args()->[1] eq 'PUT',
    'the request is a PUT for update method.'
);

ok( $resp eq '{}', 'update sends back the raw response from the server.' );

$base->override_method(TRUE);

$resp = $base->update( 'http://www.example.com', '<title>eeee</title>' );

ok(
    $Mock_request->new_args()->[1] eq 'POST',
    'the request is a POST for update method if override_method is set to true.'
);
ok(
    $Mock_request->header('X-HTTP-Method-Override') eq 'PUT',
'the X-HTTP-Method-Override is PUT for update method if override_method is set to true.'
);

$resp = $base->delete('http://www.example.com');
ok(
    $Mock_request->new_args()->[1] eq 'POST',
    'the request is a POST for delete method if override_method is set to true.'
);
ok(
    $Mock_request->header('X-HTTP-Method-Override') eq 'DELETE',
'the X-HTTP-Method-Override is DELETE for delete method if override_method is set to true.'
);

$base->override_method(FALSE);

$resp = $base->delete('http://www.example.com');
ok(
    $Mock_request->new_args()->[1] eq 'DELETE',
'the request is a DELETE for delete method if override_method is set back to false.'
);

package MockAuth;
use base 'WebService::GData';

sub source {
    return 'MyApp-MyCompany-Version';
}

sub set_authorization_headers {
    my ( $this, $base, $req ) = @_;
    $req->header( 'Authorization', 'key=test' );

}

sub set_service_headers {
    my ( $this, $base, $req ) = @_;
    $req->header( 'Testing', 1 );
}
