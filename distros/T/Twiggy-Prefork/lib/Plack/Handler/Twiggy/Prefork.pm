package Plack::Handler::Twiggy::Prefork;

use strict;
use warnings;

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub run {
    my ($self, $app) = @_;

    my $class = $ENV{SERVER_STARTER_PORT} ?
        'Twiggy::Prefork::Server::SS' : 'Twiggy::Prefork::Server';
    eval "require $class";
    die if $@;

    $class->new(%{$self})->run($app);
}
    

1;

__END__


