package UR::Role::MethodModifier::After;
use strict;
use warnings;

our $VERSION = "0.47"; # UR $VERSION;

use UR;

UR::Object::Type->define(
    class_name => 'UR::Role::MethodModifier::After',
    is => 'UR::Role::MethodModifier',
);

sub type { 'after' }

sub create_wrapper_sub {
    my($self, $original_sub) = @_;

    my $after = $self->code;
    return sub {
        my @rv;
        my $wantarray = wantarray;
        if ($wantarray) {
            @rv = $original_sub->(@_);
        } elsif (defined $wantarray) {
            $rv[0] = $original_sub->(@_);
        } else {
            $original_sub->(@_);
        }

        if ($wantarray) {
            () = $after->(\@rv, @_);
        } elsif (defined $wantarray) {
            my $i = $after->($rv[0], @_);
        } else {
            $after->(undef, @_);
        }

        if ($wantarray) {
            return @rv;
        } elsif (defined $wantarray) {
            return $rv[0];
        } else {
            return;
        }
    };
}

1;
