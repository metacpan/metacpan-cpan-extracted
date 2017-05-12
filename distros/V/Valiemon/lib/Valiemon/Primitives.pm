package Valiemon::Primitives;
use strict;
use warnings;
use utf8;

use Scalar::Util qw(looks_like_number);
use Types::Serialiser;
use Test::Deep qw(eq_deeply);

sub new {
    my ($class, $options) = @_;
    return bless {
        options => $options || +{},
    }, $class;
}

sub is_object {
    my ($self, $obj) = @_;
    (defined $obj && ref $obj eq 'HASH') ? 1 : 0;
}

sub is_array {
    my ($self, $obj) = @_;
    (defined $obj && ref $obj eq 'ARRAY') ? 1 : 0;
}

sub is_string {
    my ($self, $obj) = @_;
    (defined $obj && ref $obj eq '') ? 1 : 0; # really?
}

sub is_number {
    my ($self, $obj) = @_;
    # avoid from JSON::Boolean treated as number.
    (defined $obj && ref $obj eq '' && looks_like_number($obj)) ? 1 : 0;
}

sub is_integer {
    my ($self, $obj) = @_;
    $self->is_number($obj) && $obj =~ qr/^-?\d+$/ ? 1 : 0; # TODO find more better way
}

sub is_boolean {
    my ($self, $obj) = @_;
    return $self->{options}->{use_json_boolean}
        ? $self->is_boolean_json($obj)
        : $self->is_boolean_perl($obj)
}

sub is_boolean_perl { # 1 or 0
    my ($self, $obj) = @_;
    (defined $obj && looks_like_number($obj) && ($obj == 1 || $obj == 0)) ? 1 : 0; # TODO invalidate 0.0
}

sub is_boolean_json {
    my ($self, $obj) = @_;
    return 1 if defined $obj && Types::Serialiser::is_bool($obj);
    return 1 if ref $obj eq 'SCALAR' && looks_like_number($$obj) && ($$obj == 1 || $$obj == 0);
    return 0;
}

sub is_null {
    my ($self, $obj) = @_;
    !defined($obj) ? 1 : 0;
}

# json schema core: 3.6 JSON value equality
sub is_equal {
    my ($self, $a, $b) = @_;
    return 1 if !defined($a) && !defined($b);
    return 1 if $self->is_boolean($a) && $self->is_boolean($b) && $a == $b;
    return 1 if $self->is_string($a) && $self->is_string($b) && "$a" eq "$b"; # ah
    return 1 if $self->is_number($a) && $self->is_number($b) && $a == $b;
    return 1 if eq_deeply($a, $b); # array & object
    return 0;
}

1;
