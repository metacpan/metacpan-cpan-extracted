package UR::Namespace::Command::Define::Datasource::RdbmsWithAuth;

use strict;
use warnings;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => "UR::Namespace::Command::Define::Datasource::Rdbms",
    has => [
        login => { is => 'String',
                   doc => 'User to log in with',
                 },
        auth => {
                 is => 'String',
                 doc => 'Password to log in with',
                },
        owner => {
                 is => 'String',
                 doc => 'Owner/schema to connect to',
                },
    ],
    is_abstract => 1,
);


sub _resolve_module_body {
    my $self = shift;

    my $src = $self->SUPER::_resolve_module_body(@_);

    my $login = $self->login;
    $src .= "sub login { '$login' }\n";

    my $auth = $self->auth;
    $src .= "sub auth { '$auth' }\n";

    my $owner = $self->owner;
    $src .= "sub owner { '$owner' }\n";

    return $src;
}

1;

