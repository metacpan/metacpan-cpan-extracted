package UR::Role::MethodModifier::Before;
use strict;
use warnings;

our $VERSION = "0.47"; # UR $VERSION;

use UR;

UR::Object::Type->define(
    class_name => 'UR::Role::MethodModifier::Before',
    is => 'UR::Role::MethodModifier',
);

sub type { 'before' }

sub create_wrapper_sub {
    my($self, $original_sub) = @_;

    my $before = $self->code;
    return sub {
        if (wantarray) {
            () = $before->(@_);
        } elsif (defined wantarray) {
            my $rv = $before->(@_);
        } else {
            $before->(@_);
        }
        $original_sub->(@_);
    };
}

1;
