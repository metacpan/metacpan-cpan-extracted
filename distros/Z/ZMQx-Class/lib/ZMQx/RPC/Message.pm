package ZMQx::RPC::Message;
use strict;
use warnings;
use Moose;
use Carp qw(croak);

has 'header' => ( is => 'ro', isa => 'ZMQx::RPC::Header' );
has 'payload' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

has 'serializable_types' => (
    is      => 'ro',
    default => sub {
        { 'JSON' => \&JSON::XS::encode_json, };
    }
);
has 'deserializable_types' => (
    is      => 'ro',
    default => sub {
        { 'JSON' => \&JSON::XS::decode_json, };
    }
);

sub _encode_payload {
    my ( $self, $payload ) = @_;
    my $type = $self->header->type;
    my @wire_payload;
    if ( $type eq 'string' || $type eq 'raw' ) {
        while ( my ( $index, $val ) = each(@$payload) ) {
            croak("ref not allowed in string/raw message at pos $index")
                if ref($val);

            # TODO allow string ref so we can send DVD images :-)
            push( @wire_payload, $val );
            if ( $type eq 'string' ) {

                # converts characters to utf8
                utf8::encode( $wire_payload[-1] );
            }
            else {
                # will croak if contains code points > 255
                utf8::downgrade( $wire_payload[-1] );
            }
        }
    }
    elsif ( my $serializer = $self->serializable_types->{$type} ) {
        @wire_payload = map { ref($_) ? $serializer->($_) : $_ } @$payload;
    }
    else {
        croak "type >$type< not defined";
    }
    return \@wire_payload;
}

sub _decode_payload {
    my ( $self, $wire_payload ) = @_;
    my $type = $self->header->type;
    my @payload;
    if ( $type eq 'string' || $type eq 'raw' ) {
        return $self->payload($wire_payload);

        #        while (my ($index, $val) = each (@$payload)) {
        #            croak("ref not allowed in string/raw message at pos $index") if ref($val);
        #            # TODO allow string ref so we can send DVD images :-)
        #            push(@wire_payload, $val);
        #            if ($type eq 'string') {
        #                # converts characters to utf8
        #                utf8::encode($wire_payload[-1]);
        #            }
        #            else {
        #                # will croak if contains code points > 255
        #                utf8::downgrade($wire_payload[-1]);
        #            }
        #        }
    }
    elsif ( my $deserializer = $self->deserializable_types->{$type} ) {
        while (my ($i, $v) = each @$wire_payload) {
            eval {
                push (@payload, $deserializer->($v));
                1;
            } or die "Problem deserialising parameter $i for " . ($self->can('command') ? $self->command : $self )  . " as $type: $@";
        }
    }
    else {
        croak "type >$type< not defined";
    }
    $self->payload( \@payload );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ZMQx::RPC::Message

=head1 VERSION

version 0.006

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Validad AG.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
