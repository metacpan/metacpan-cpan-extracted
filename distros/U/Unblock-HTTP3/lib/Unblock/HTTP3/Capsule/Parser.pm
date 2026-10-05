package Unblock::HTTP3::Capsule::Parser;

use strict;
use warnings;

use Carp qw(croak);

use Unblock::HTTP3 ();
use Unblock::HTTP3::Capsule ();
use Unblock::HTTP3::_Bytes ();

our $VERSION = '0.03';

sub _decimal_mod {
    my ($value, $divisor) = @_;

    my $remainder = 0;

    for my $digit (split //, "$value") {
        $remainder = ($remainder * 10 + ord($digit) - 48) % $divisor;
    }

    return $remainder;
}

sub _is_grease_type {
    my ($type) = @_;

    return 0 if length($type) < 2;
    return 0 if length($type) == 2 && $type lt '23';

    return _decimal_mod($type, 41) == 23 ? 1 : 0;
}

sub new {
    my ($class, %option) = @_;

    my $handlers_supplied = exists $option{handlers};
    my $handlers = delete $option{handlers};
    my $on_capsule = delete $option{on_capsule};
    my $max_capsule_size = exists($option{max_capsule_size})
        ? delete($option{max_capsule_size})
        : 4 * 1024 * 1024;

    $handlers = {} unless defined $handlers;

    croak 'handlers must be a hash reference'
        unless ref($handlers) eq 'HASH';
    croak 'on_capsule must be a code reference'
        if defined($on_capsule) && ref($on_capsule) ne 'CODE';
    croak 'max_capsule_size must be a non-negative integer'
        if !defined($max_capsule_size)
            || ref($max_capsule_size)
            || "$max_capsule_size" !~ /\A[0-9]+\z/;
    croak 'unknown Capsule parser option: ' . join(', ', sort keys %option)
        if %option;

    my %normalized_handlers;

    for my $raw_type (keys %$handlers) {
        my $type = Unblock::HTTP3::Capsule::_normalize_varint(
            $raw_type,
            'Capsule handler type',
        );
        my $callback = $handlers->{$raw_type};

        croak "Capsule type $type is reserved for greasing"
            if _is_grease_type($type);
        croak "Capsule handler for type $type must be a code reference"
            unless ref($callback) eq 'CODE';
        croak "duplicate Capsule handler type $type"
            if exists $normalized_handlers{$type};

        $normalized_handlers{$type} = $callback;
    }

    return bless {
        handlers         => \%normalized_handlers,
        on_capsule       => $on_capsule,
        polling          => (!$handlers_supplied && !defined($on_capsule))
            ? 1
            : 0,
        max_capsule_size => 0 + $max_capsule_size,
        queue            => [],
        buffer           => '',
        stage            => 'type',
        type             => undef,
        remaining        => 0,
        value            => '',
        interested       => 0,
        finished         => 0,
    }, $class;
}

sub _is_interested {
    my ($self, $type) = @_;

    return 0 if _is_grease_type($type);
    return 1 if exists $self->{handlers}{$type};
    return 1 if defined $self->{on_capsule};
    return 1 if $self->{polling};

    return 0;
}

sub _emit {
    my ($self) = @_;

    if ($self->{interested}) {
        my $capsule = Unblock::HTTP3::Capsule->new(
            type  => $self->{type},
            value => $self->{value},
        );

        my $handler = $self->{handlers}{ $self->{type} };

        if (defined $handler) {
            $handler->($self, $capsule);
        } elsif (defined $self->{on_capsule}) {
            $self->{on_capsule}->($self, $capsule);
        } elsif ($self->{polling}) {
            push @{ $self->{queue} }, $capsule;
        }
    }

    $self->{stage} = 'type';
    $self->{type} = undef;
    $self->{remaining} = 0;
    $self->{value} = '';
    $self->{interested} = 0;

    return;
}

sub feed {
    my ($self, $bytes) = @_;

    croak 'feed() cannot be called after finish()'
        if $self->{finished};

    $bytes = Unblock::HTTP3::_Bytes::byte_string(
        'Capsule Protocol bytes',
        $bytes,
    );

    $self->{buffer} .= $bytes;

    while (1) {
        if ($self->{stage} eq 'type') {
            my ($type, $length) =
                Unblock::HTTP3::Capsule::_decode_varint($self->{buffer}, 0);
            return $self unless defined $type;

            substr($self->{buffer}, 0, $length, '');
            $self->{type} = $type;
            $self->{stage} = 'length';
            next;
        }

        if ($self->{stage} eq 'length') {
            my ($length, $encoded_length) =
                Unblock::HTTP3::Capsule::_decode_varint($self->{buffer}, 0);
            return $self unless defined $length;

            substr($self->{buffer}, 0, $encoded_length, '');

            $self->{remaining} = 0 + $length;
            $self->{interested} =
                $self->_is_interested($self->{type});

            if (
                $self->{interested}
                && $length > $self->{max_capsule_size}
            ) {
                croak "Capsule type $self->{type} length $length exceeds "
                    . "configured maximum $self->{max_capsule_size}";
            }

            $self->{value} = '';

            if ($self->{remaining} == 0) {
                $self->_emit;
                next;
            }

            $self->{stage} = 'value';
            next;
        }

        if ($self->{stage} eq 'value') {
            return $self unless length $self->{buffer};

            my $take = length($self->{buffer});
            $take = $self->{remaining}
                if $take > $self->{remaining};

            my $chunk = substr($self->{buffer}, 0, $take, '');
            $self->{value} .= $chunk
                if $self->{interested};
            $self->{remaining} -= $take;

            if ($self->{remaining} == 0) {
                $self->_emit;
                next;
            }

            return $self;
        }

        croak "unknown Capsule parser state '$self->{stage}'";
    }
}

sub next_capsule {
    my ($self, @args) = @_;
    croak 'next_capsule() does not accept arguments' if @args;
    return shift @{ $self->{queue} };
}

sub finish {
    my ($self, @args) = @_;
    croak 'finish() does not accept arguments' if @args;

    return $self if $self->{finished};

    if (
        $self->{stage} ne 'type'
        || length($self->{buffer})
    ) {
        croak 'Capsule Protocol stream ended with a truncated Capsule';
    }

    $self->{finished} = 1;
    return $self;
}

sub is_finished {
    my ($self, @args) = @_;
    croak 'is_finished() does not accept arguments' if @args;
    return $self->{finished} ? 1 : 0;
}

1;

__END__

=head1 NAME

Unblock::HTTP3::Capsule::Parser - incremental RFC 9297 Capsule parser

=head1 SYNOPSIS

    my $parser = Unblock::HTTP3::Capsule::Parser->new;

    $parser->feed($bytes);

    while (my $capsule = $parser->next_capsule) {
        ...
    }

    $parser->finish;

=head1 DESCRIPTION

The parser accepts arbitrary chunks from an HTTP data stream. Capsule type,
length, and value fields may be split across input chunks.

With no callbacks, complete L<Unblock::HTTP3::Capsule> objects are queued for
C<next_capsule>.

Handlers can be registered for specific Capsule Types. An C<on_capsule>
callback can be used as a catch-all. Unknown unregistered types are skipped.
GREASE Capsule Types are ignored and cannot be assigned application semantics.

=head1 CONSTRUCTOR

=head2 new

Useful options are:

=over 4

=item C<handlers>

Hash reference mapping Capsule Types to callbacks.

=item C<on_capsule>

Catch-all callback for complete Capsules.

=item C<max_capsule_size>

Maximum retained Capsule Value size. The default is 4 MiB.

=back

=head1 METHODS

=head2 feed

Adds bytes to the incremental parser.

Returns the Parser.

=head2 next_capsule

Returns the next queued L<Unblock::HTTP3::Capsule>, or undef.

=head2 finish

Marks the input stream complete.

A truncated final Capsule is rejected.

=head2 is_finished

True after a clean C<finish>.

=head1 SEE ALSO

L<Unblock::HTTP3::Capsule>, L<Unblock::HTTP3::Capsule::Stream>

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

This software is available under the MIT License.

=cut
