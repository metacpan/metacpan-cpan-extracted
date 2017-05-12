package Plack::Handler::Twiggy::TLS;

use strict;
use warnings;

use Twiggy::Server::TLS;

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub run {
    my ($self, $app) = @_;

    Twiggy::Server::TLS->new(%$self)->run($app);
}
    

1;
