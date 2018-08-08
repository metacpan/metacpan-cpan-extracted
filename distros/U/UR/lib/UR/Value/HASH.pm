package UR::Value::HASH;

use strict;
use warnings;

require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Value::HASH',
    is => ['UR::Value::PerlReference'],
);

sub __display_name__ {
    my $self = shift;
    my $hash = $self->id;
    my @values;
    for my $key (sort keys %$hash) {
        next unless defined $hash->{$key};
        push @values, "$key => '".( defined $hash->{$key} ? $hash->{$key} : '' ). "'";
    }
    my $join = ( defined $_[0] ) ? $_[0] : ','; # Default join is a comma
    return join($join, @values);
}

sub to_text {
    my $self = shift;
    my $hash = $self->id;
    my @tokens;
    for my $key (sort keys %$hash) {
        push @tokens, '-'.$key;
        next if not defined $hash->{$key} or $hash->{$key} eq '';
        if ( my $ref = ref $hash->{$key} ) {
            if ( $ref ne 'ARRAY' ) {
                $self->warning_message("Can not convert hash to text. Cannot handle $ref for $key");
                return;
            }
            push @tokens, @{$hash->{$key}};
        }
        else {
            push @tokens, $hash->{$key};
        }
    }
    my $join = ( defined $_[0] ) ? $_[0] : ' '; # Default join is a space
    return UR::Value::Text->get( join($join, @tokens));
}

1;

