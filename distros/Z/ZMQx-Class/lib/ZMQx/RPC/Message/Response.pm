package ZMQx::RPC::Message::Response;
use Moose;
use strict;
use warnings;
use Carp qw(croak);
extends 'ZMQx::RPC::Message';

has 'status' => (is=>'ro',isa=>'Int'); # TODO enum
has 'request' => (is=>'ro',isa=>'ZMQx::RPC::Message::Request');
has '+header' => (default=>sub {
    return ZMQx::RPC::Header->new(
        type=>'string',
    );
});
has 'post_send' => (is=>'rw',isa=>'CodeRef');

sub new_error {
    my ($class, $status, $error, $request) = @_;

    # check if $error is an object and do something..
    my %new = (
        status=>$status,
        payload=>[ ''.$error ],
    );
    $new{request} = $request if $request;
    return $class->new( %new );
}

sub pack {
    my $self = shift;

    my $wire_payload = $self->_encode_payload($self->payload);
    unshift(@$wire_payload, $self->status, $self->header->pack);
    return $wire_payload;
}

sub unpack {
    my ($class, $msg) = @_;

    my $status = shift(@$msg);
    my $header = shift(@$msg);
    my $res = ZMQx::RPC::Message::Response->new(
        status=>$status,
        header => ZMQx::RPC::Header->unpack($header),
    );
    $res->_decode_payload($msg);
    return $res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ZMQx::RPC::Message::Response

=head1 VERSION

version 0.006

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Validad AG.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
