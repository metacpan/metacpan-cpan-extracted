package Yote::Server::App;

use strict;
use warnings;

use Yote::Server;

use Digest::MD5;

use base 'Yote::ServerObj';

sub _acct_class { "Yote::Server::Acct" }

#
# Override and call _create_account
#
sub create_account {
    die "May not create account via website";
}

sub _create_account {
    my( $self, $un, $pw, $class_override ) = @_;
    my $accts = $self->get__accts({});

    if( $accts->{lc($un)} ) {
        $self->_err( "Unable to create account" );
    }

    my $acct = $self->{STORE}->newobj( { user => $un }, $class_override || $self->_acct_class );
    $acct->set__password_hash( crypt( $pw, length( $pw ) . Digest::MD5::md5_hex($acct->{ID} ) )  );

    # TODO - create an email infrastructure for account validation
    $acct->set_app( $self );
    
    $accts->{lc($un)} = $acct;
    $acct;
} #_create_account

sub logout {
    my $self = shift;
    my $root = $self->{SESSION}{SERVER_ROOT};
    $root->_destroy_session( $self->{SESSION}->get__token ) if $root;
    delete $self->{SESSION};
    1;
} #logout

sub login {
    my( $self, $un, $pw ) = @_;

    # returns account, cookie. only way to get account object
    my $acct = $self->get__accts({})->{lc($un)};

    # doing it like this so a failed attempt has about the same amount of time
    # as an attempt against a nonexistant account. maybe random microsleep?
    my $pwh = crypt( $pw, length( $pw ) . Digest::MD5::md5_hex($acct ? $acct->{ID} : $self->{ID} ) );
    if( $acct && $pwh eq $acct->get__password_hash ) {
        # this and Yote::ServerRoot::fetch_app are the only ways to expose the account obj
        # to the UI. If the UI calls for an acct object it wasn't exposed to, Yote::Server
        # won't allow it. fetch_app only calls it if the correct cookie token is passed in
        $self->{SESSION}->set_acct( $acct );
        $acct->_onLogin;
        return $acct;
    }
    $self->_err( "Incorrect login" );
} #login

1;
