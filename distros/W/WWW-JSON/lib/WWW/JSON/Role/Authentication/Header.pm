package WWW::JSON::Role::Authentication::Header;
use Moo::Role;
requires 'authentication';
requires 'ua';

sub _validate_Header {
    my ( $self, $auth ) = @_;
    die "Required header string missing for " . __PACKAGE__ . " authentication"
      unless defined($auth);
}

sub _auth_Header {
    my ( $self, $auth, $req ) = @_;
    $req->header( Authorization => $auth );
}

1;
