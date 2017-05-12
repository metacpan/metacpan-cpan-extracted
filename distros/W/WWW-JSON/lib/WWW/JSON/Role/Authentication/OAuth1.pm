package WWW::JSON::Role::Authentication::OAuth1;
use Moo::Role;
use Net::OAuth;
use URI;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;
requires 'authentication';
requires 'ua';

sub _validate_OAuth1 {
    my ( $self, $auth ) = @_;
    for (qw/consumer_key consumer_secret token token_secret/) {
        die "Required parameter $_ missing for " . __PACKAGE__ . " authentication"
          unless exists( $auth->{$_} );
    }
}

sub _auth_OAuth1 {
    my ( $self, $auth, $req) = @_;
    my $q = URI->new;
    # FIXME if we're sending a JSON payload we need to decode instead of this
    $q->query($req->content);
    my $request = Net::OAuth->request("protected resource")->new(
        %$auth,
        request_url      => $req->uri,
        request_method   => $req->method,
        signature_method => 'HMAC-SHA1',
        timestamp        => time(),
        nonce            => _nonce(),
        extra_params     => {$q->query_form},
    );
    $request->sign;
    $request->to_authorization_header;
    $req->header( Authorization => $request->to_authorization_header );
}

sub _nonce {
    my @chars = ( 'A' .. 'Z', 'a' .. 'z', '0' .. '9' );
    my $nonce = time;
    for ( 1 .. 15 ) {
        $nonce .= $chars[ rand @chars ];
    }
    return $nonce;
}
1;
