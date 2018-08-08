package UR::Role::MethodModifier::Around;
use strict;
use warnings;

our $VERSION = "0.47"; # UR $VERSION;

use UR;

UR::Object::Type->define(
    class_name => 'UR::Role::MethodModifier::Around',
    is => 'UR::Role::MethodModifier',
);

sub type { 'around' }

sub create_wrapper_sub {
    my($self, $original_sub) = @_;

    my $around = $self->code;
    return sub {
        $around->($original_sub, @_);
    };
}

1;
