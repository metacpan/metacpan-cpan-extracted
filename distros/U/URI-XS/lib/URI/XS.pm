package URI::XS;
use 5.012;
use XS::Framework;

our $VERSION = '2.1.4';

XS::Loader::bootstrap();

require overload;
overload->import(
    '""'     => \&to_string,
    'eq'     => \&equals,
    'bool'   => \&to_bool,
    #'='      => sub {$_[0]},
    fallback => 1,
);

sub connect_port {
    my $self = shift;
    my $msg = '$uri->connect_port is deprecated, use $uri->port instead.';
    warn "\e[95m$msg\e[0m";
    return $self->port;
}

sub connect_location {
    my $self = shift;
    my $msg = '$uri->connect_location is deprecated, use $uri->location instead.';
    warn "\e[95m$msg\e[0m";
    return $self->location;
}

1;
