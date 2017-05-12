package WWW::JSON::Role::Authentication::OAuth2;
use Moo::Role;
use Safe::Isa;
requires 'authentication';
requires 'ua';

sub _validate_OAuth2 {
    my ( $self, $auth ) = @_;
    die "Must pass a Net::OAuth2::AccessToken object when using "
      . __PACKAGE__
      . " authentication."
      unless $auth->$_isa('Net::OAuth2::AccessToken');
}

sub _auth_OAuth2 {
    my ( $self, $auth, $req ) = @_;
    $req->header( Authorization => 'Bearer ' . $auth->access_token );
}

1;
