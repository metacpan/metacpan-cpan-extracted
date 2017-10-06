package WebService::Qiita::V2::Client;
use strict;
use warnings;

use WebService::Qiita::V2::Client::Methods;

sub new {
    my ($class, $params) = @_;

    $params ||= {};
    my $args = {
        methods => WebService::Qiita::V2::Client::Methods->new,
        token => undef,
        team => undef,
    };
    $args = {%$args, %$params};
    my $self = bless $args, $class;
    $self;
}

sub AUTOLOAD {
    my $self = shift;
    my $method = our $AUTOLOAD;
    my (@args) = @_;

    $self->call($method, @args);
}

sub DESTROY {}

sub call {
    my ($self, $method, @args) = @_;

    $method =~ s/.*:://;

    my $common_args;
    $common_args->{headers} = { Authorization => "Bearer " . $self->{token} } if $self->{token};
    $common_args->{team} = $self->{team} if $self->{team};
    push @args, $common_args if defined $common_args;

    $self->{methods}->$method(@args);
}

sub get_error {
    my $self = shift;
    return $self->{methods}->{error};
}

1;
__END__

