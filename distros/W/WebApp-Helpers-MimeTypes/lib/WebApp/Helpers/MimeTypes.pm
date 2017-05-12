package WebApp::Helpers::MimeTypes;

use strict;
use warnings;

use MIME::Types;

use Moo::Role;

our $VERSION = "0.02";


has mime_types => (is => 'ro', lazy => 1,  builder => 1);
sub _build_mime_types { MIME::Types->new }

sub mime_type_for {
    my ($self, $ext) = @_;
    return $self->mime_types->mimeTypeOf($ext)->type();
}




1;
__END__

=encoding utf-8

=head1 NAME

WebApp::Helpers::MimeTypes - simple role for MIME::Types support

=head1 SYNOPSIS

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

=head1 DESCRIPTION

L<WebApp::Helpers::MimeTypes> is a simple role that holds a
L<MIME::Types> object and provides some sugar methods.  I
work a lot with Microsoft Excel 2007 files, and I hate trying to
remember their mime-type
(C<application/vnd.openxmlformats-officedocument.spreadsheetml.sheet>).

=head1 ATTRIBUTES

=head2 mime_types

A L<MIME::Types> object.

=head1 METHODS

=head2 mime_type_for( $extension )

Returns the MIME type for a file with the given C<$extension> e.g.
C<mime_type_for('csv')> returns C<'text/comma-separated-values'>.

=head1 LICENSE

Copyright (C) Fitz Elliott.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Fitz Elliott E<lt>felliott@fiskur.orgE<gt>

=cut

