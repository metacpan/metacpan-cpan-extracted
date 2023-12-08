package WWW::Suffit::Client::NoAPI;
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

WWW::Suffit::Client::NoAPI - The Suffit API client library for NoAPI methods

=head1 SYNOPSIS

    use WWW::Suffit::Client::NoAPI;

=head1 DESCRIPTION

This library provides NoAPI methods for access to Suffit API servers

=head1 NOAPI METHODS

List of predefined the Suffit NoAPI methods

=head2 download

    my $status = $client->download("file.txt", "/tmp/file.txt");

Request for download an file from the server by file path.
The method returns status of operation: 0 - Error; 1 - Ok

=head2 manifest

    my $status = $client->manifest;

Gets list of files (manifest) from server
The method returns status of operation: 0 - Error; 1 - Ok

=head2 remove

    my $status = $client->remove("/foo/bar/file.txt");

Request for deleting the file from server.
The method returns status of operation: 0 - Error; 1 - Ok

=head2 upload

    my $status = $clinet->upload("/tmp/file.txt", "/foo/bar/file.txt");

Upload an file to the server by file path

=head1 DEPENDENCIES

L<Mojolicious>, L<WWW::Suffit>

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojo::UserAgent>, L<WWW::Suffit::UserAgent>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.01';

use parent qw/ WWW::Suffit::Client /;

use Mojo::Asset::File;
use Mojo::File qw/path/;

use WWW::Suffit::Const qw/ :MIME /;
use WWW::Suffit::Util qw/ md5sum /;

## SUFFIT NoAPI METHODS

sub manifest {
    my $self = shift;
    return $self->request(GET => $self->str2url("file"), # e.g.: api/file
        { # Headers
            Accept => CONTENT_TYPE_JSON, # "*/*"
        }
    );
}
sub download {
    my $self = shift;
    my $rfile = shift; # Remote file: t.txt
    my $lfile = shift; # Local file (full file path to save)

    # Remote file
    $rfile =~ s/^\/+//;
    my $status = $self->request(GET => $self->str2url(sprintf("file/%s", $rfile)));
    return $status unless $status;

    # Local file
    my $filepath = path($lfile);
    my $filename = $filepath->basename;
    $self->res->save_to($lfile);
    return 1 if $filepath->stat->size;
    $self->error("Can't download file $filename");
    $self->status(0);
    return 0;
}
sub upload {
    my $self = shift;
    my $lfile = shift; # Local file (full file path to save)
    my $rfile = shift; # Remote file: t.txt

    # Local file
    my $filepath = path($lfile);
    my $filename = $filepath->basename;
    my $asset_file = Mojo::Asset::File->new(path => $filepath);

    # Remote file
    $rfile =~ s/^\/+//;

    # Request
    return $self->request(PUT => $self->str2url(sprintf("file/%s", $rfile)) =>
        { # Headers
            'Content-Type' => 'multipart/form-data',
        },
        form => {
            size => $asset_file->size,
            md5 => md5sum($asset_file->path),
            fileraw => {
                file        => $asset_file,
                filename    => $filename,
                'Content-Type' => 'application/octet-stream',
            },
        },
    );
}
sub remove {
    my $self = shift;
    my $rfile = shift;
       $rfile =~ s/^\/+//;
    return $self->request(DELETE => $self->str2url(sprintf("file/%s", $rfile)));
}

1;

__END__
