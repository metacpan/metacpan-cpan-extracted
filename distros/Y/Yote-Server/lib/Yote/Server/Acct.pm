package Yote::Server::Acct;

use strict;
use warnings;

use Yote::Server;

use base 'Yote::ServerObj';

sub _onLogin {}

sub logout {
    my $self = shift;
    my $server = $self->{SESSION}{SERVER};
    $server->_destroy_session( $self->{SESSION}->get__token );
} #logout

1;

__END__
