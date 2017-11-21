package eris::role::dictionary::hash;
# ABSTRACT: Simple dictionary implementation based off a hash

use Moo::Role;
use namespace::autoclean;
with qw(eris::role::dictionary);

our $VERSION = '0.004'; # VERSION


requires qw(hash);


sub lookup {
    my ($self,$field) = @_;

    my $entry = undef;
    my $dict  = $self->hash;
    if( exists $dict->{$field} ) {
        $entry = {
            field => $field,
            ref $dict->{$field} eq 'HASH' ? %{ $dict->{$field} }
                : ( description => $dict->{$field} ),
        };
    }
    return $entry;
}


sub fields {
    my ($self) = @_;
    return [ sort keys %{ $self->hash }  ];
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::role::dictionary::hash - Simple dictionary implementation based off a hash

=head1 VERSION

version 0.004

=head1 SYNOPSIS

Simplest possible dictionary implementation

    package my::app::dictionary::business;

    use Moo;
    with qw(
        eris::role::dictionary::hash
    );

    sub hash {
        return {
            'customer_id'     => "Our customer ID field",
            'store_id'        => "Our store ID field",
            'price_usd'       => "Object price in USD",
            'transaction_key' => "Transaction Identifier",
        }
    }

=head1 METHODS

=head2 lookup($field)

Find the field in the hash, returns a hashref in the format:

    {
       field => $field,
       description => $lookup_hash{$field},
    }

Or if the hash value is a hash reference, we return:

    {
       field => $field,
       %{ $lookup_hash{$field} },
    }

=head2 fields()

Returns the sorted list of keys in the lookup hash

=head1 INTERFACE

=head2 hash

Return a HashRef with the field names as keys and a string description of the field.

May also return a HashRef with field names as keys and a HashRef as a value.  Those key/value
pairs will be returned to the C<lookup()> function.

=head1 SEE ALSO

L<eris::role::dictionary>, L<eris::dictionary>, L<eris::dictionary::cee>

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
