package WebApp::Helpers::JsonEncoder;

use strict;
use warnings;

use JSON::MaybeXS qw(JSON);

use Moo::Role;

our $VERSION = "0.01";


has _json_encoder => (
   is => 'ro',
   lazy => 1,
   builder => '_build_json_encoder',
   handles => {
      encode_json => 'encode',
      decode_json => 'decode',
   },
);
sub _build_json_encoder { JSON->new->utf8(1); }


sub json_bool { $_[1] ? JSON->true : JSON->false }


1;
__END__

=encoding utf-8

=head1 NAME

WebApp::Helpers::JsonEncoder - Simple role for en/decoding JSON

=head1 SYNOPSIS

    package MyTunes::Resource::CD;

    use Moo;
    with 'WebApp::Helpers::JsonEncoder';

    has title      => (is => 'rw');
    has artist     => (is => 'rw');
    has genre      => (is => 'rw');
    has is_touring => (is => 'rw');

    sub to_json {
        my ($self) = @_;
        return $self->encode_json( {
            title      => $self->title,
            artist     => $self->artist,
            genre      => $self->genre,
            is_touring => $self->json_bool( $self->is_touring ),
        } );
    }

    sub from_json {
        my ($self, $request) = @_;
        my $data = $self->decode_json($request);
        for my $field (qw(title artist genre is_touring)) {
            $self->$field( $data->{ $field } );
        }

        return;
    }


=head1 DESCRIPTION

L<WebApp::Helpers::JsonEncoder> is simple role that adds JSON-handling
methods to the consuming object.  It's dead simple, but since I've
copied-and-pasted this about a thousand times, it's time for it to go
to CPAN!

This role holds a JSON encoder/decoder object.  utf8 support is turned
on by default.

=head1 METHODS

=head2 encode_json( $perl_struct )

Produces the JSON representation of C<$perl_struct>.

=head2 decode_json( $json_string )

Turns a valid JSON string into a perl data structure.

=head2 json_bool( $value )

Returns the truthiness of C<$value> as a JSON boolean.

=head1 LICENSE

Copyright (C) Fitz Elliott.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

frew: Arthur Axel "fREW" Schmidt E<lt>frioux+cpan@gmail.comE<gt>

=head1 CONTRIBUTORS

felliott: Fitz Elliott E<lt>felliott@fiskur.orgE<gt>

=cut

