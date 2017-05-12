# NAME

WebApp::Helpers::MimeTypes - simple role for MIME::Types support

# SYNOPSIS

    package MyTunes::Resource::CD;

    use Moo;
    with 'WebApp::Helpers::MimeTypes';

    sub to_excel {
        my ($self) = @_;

        my ($filehandle) = $self->make_temp_file();
        return [
            200, ['Content-Type' => $self->mime_type_for('xlsx')],
            [ $filehandle ],
        ];
    }

# DESCRIPTION

[WebApp::Helpers::MimeTypes](https://metacpan.org/pod/WebApp::Helpers::MimeTypes) is a simple role that holds a
[MIME::Types](https://metacpan.org/pod/MIME::Types) object and provides some sugar methods.  I
work a lot with Microsoft Excel 2007 files, and I hate trying to
remember their mime-type
(`application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`).

# ATTRIBUTES

## mime\_types

A [MIME::Types](https://metacpan.org/pod/MIME::Types) object.

# METHODS

## mime\_type\_for( $extension )

Returns the MIME type for a file with the given `$extension` e.g.
`mime_type_for('csv')` returns `'text/comma-separated-values'`.

# LICENSE

Copyright (C) Fitz Elliott.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Fitz Elliott <felliott@fiskur.org>
