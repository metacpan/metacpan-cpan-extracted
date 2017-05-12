# NAME

WebApp::Helpers::JsonEncoder - Simple role for en/decoding JSON

# SYNOPSIS

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

# DESCRIPTION

[WebApp::Helpers::JsonEncoder](https://metacpan.org/pod/WebApp::Helpers::JsonEncoder) is simple role that adds JSON-handling
methods to the consuming object.  It's dead simple, but since I've
copied-and-pasted this about a thousand times, it's time for it to go
to CPAN!

This role holds a JSON encoder/decoder object.  utf8 support is turned
on by default.

# METHODS

## encode\_json( $perl\_struct )

Produces the JSON representation of `$perl_struct`.

## decode\_json( $json\_string )

Turns a valid JSON string into a perl data structure.

## json\_bool( $value )

Returns the truthiness of `$value` as a JSON boolean.

# LICENSE

Copyright (C) Fitz Elliott.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

frew: Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

# CONTRIBUTORS

felliott: Fitz Elliott <felliott@fiskur.org>
