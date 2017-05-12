# ex:ts=4:sw=4:sts=4:et
package Transmission::Torrent::File;
# See Transmission::Client for copyright statement.

=head1 NAME

Transmission::Torrent::File - file within a Transmission torrent

=cut

use Moose;
use Transmission::Types ':all';

with 'Transmission::AttributeRole';

=head1 ATTRIBUTES

=head2 id

 $int = $self->id;

This file index in the files list.

=cut

has id => (
    is => 'ro',
    isa => 'Int',
    default => -1,
);

=head2 length

 $num = $self->length;

File size in bytes.

=head2 name

 $str = $self->name;

=head2 bytes_completed

 $num = $self->bytes_completed;

Bytes downloaded.

=head2 wanted

 $bool = $self->wanted;

Flag which decides if this file will be downloaded or not.

=cut

has wanted => (
    is => 'rw',
    isa => boolean,
    coerce => 1,
    default => 1,
);

=head2 priority

 $int = $self->priority;

Low, Normal or High, with the respectable values: -1, 0 and 1.

=cut

has priority => (
    is => 'rw',
    isa => number,
    coerce => 1,
    default => 0,
);

{
    my %read = (
        key             => string,
        length          => number,
        name            => string,
        bytesCompleted  => number,
    );

    for my $camel (keys %read) {
        my $name = __PACKAGE__->_camel2Normal($camel);
        has $name => (
            is => 'ro',
            isa => $read{$camel},
            coerce => 1,
            writer => "_set_$name",
        );
    }
}

=head1 METHODS

=head2 BUILDARGS

 $hash_ref = $class->BUILDARGS(\%args);

Convert keys in C<%args> from "CamelCase" to "camel_case".

=cut

sub BUILDARGS {
    my $self = shift;
    my $args = $self->SUPER::BUILDARGS(@_);

    for my $camel (keys %$args) {
        my $key = __PACKAGE__->_camel2Normal($camel);
        $args->{$key} = delete $args->{$camel};
    }

    return $args;
}

=head1 LICENSE

=head1 AUTHOR

See L<Transmission::Client>

=cut

1;
