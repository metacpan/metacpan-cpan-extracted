package URI::XS;
use 5.012;
use XS::Framework;

our $VERSION = '1.1.7';

use Export::XS::Auto
    ALLOW_LEADING_AUTHORITY => 1,
    PARAM_DELIM_SEMICOLON   => 2,
;

XS::Loader::bootstrap();

require overload;
overload->import(
    '""'     => \&to_string,
    'eq'     => sub {
        return ($_[0]->to_string eq $_[1]) unless ref $_[1];
        return $_[0]->equals($_[1]);
    },
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
