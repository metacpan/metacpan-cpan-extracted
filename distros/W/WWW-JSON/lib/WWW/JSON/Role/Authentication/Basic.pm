package WWW::JSON::Role::Authentication::Basic;
use Moo::Role;
use MIME::Base64;
requires 'authentication';
requires 'ua';


sub _validate_Basic {
    my ( $self, $auth ) = @_;
    for (qw/username password/) {
        die "Required parameter $_ missing for " . __PACKAGE__ . " authentication"
          unless exists( $auth->{$_} );
    }
}

sub _auth_Basic {
    my ( $self, $auth, $req ) = @_;
    $req->header( Authorization => 'Basic '
          . encode_base64( join( ':', @$auth{qw/username password/} ), '' ) );

}

1;
