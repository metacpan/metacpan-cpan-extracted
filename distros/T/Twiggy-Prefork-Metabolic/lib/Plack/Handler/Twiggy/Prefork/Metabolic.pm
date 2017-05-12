package Plack::Handler::Twiggy::Prefork::Metabolic;
use strict;
use warnings;

sub new {
    my $class = shift;
    return bless {@_}, $class;
}

sub run {
    my ($self, $app) = @_;

    my $class = $ENV{SERVER_STARTER_PORT}
        ? 'Twiggy::Prefork::Metabolic::Server::SS'
        : 'Twiggy::Prefork::Metabolic::Server';
    eval "require $class";
    die $@ if $@;

    return $class->new(%{$self})->run($app);
}

1;

__END__
