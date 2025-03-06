package WWW::Suffit::Server::API::NoAPI;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Server::API::NoAPI - The Suffit NoAPI controller

=head1 SYNOPSIS

    use WWW::Suffit::Server::API::NoAPI;

=head1 DESCRIPTION

The Suffit NoAPI controller

=head1 METHODS

List of internal methods

=head2 file_download

See L</"GET /api/file/FILEPATH">

=head2 file_list

See L</"GET /api/file">

=head2 file_remove

See L</"DELETE /api/file/FILEPATH">

=head2 file_upload

See L</"PUT /api/file/FILEPATH">

=head1 API METHODS

List of API methods

=head2 DELETE /api/file/FILEPATH

Remove file from server

    # curl -v -H "Authorization: Bearer eyJh...GBew" \
      -X DELETE \
      https://localhost:8695/api/file/foo/bar/test123.txt

    > DELETE /api/file/foo/bar/test123.txt HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...GBew
    >
    < HTTP/1.1 200 OK
    < Content-Length: 30
    < Content-Type: application/json;charset=UTF-8
    < Date: Wed, 14 Aug 2024 11:27:09 GMT
    < Server: OWL/1.11
    <
    {
      "code": "E0000",
      "status": true
    }

=head2 GET /api/file

Get a list of files on the server (manifest)

    # curl -v -H "Authorization: Bearer eyJh...s5aM" \
      https://localhost:8695/api/file

    > GET /api/file HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...s5aM
    >
    < HTTP/1.1 200 OK
    < Content-Length: 1081
    < Content-Type: application/json;charset=UTF-8
    < Date: Wed, 14 Aug 2024 11:17:42 GMT
    < Server: OWL/1.11
    < Vary: Accept-Encoding
    <
    {
      "documentroot": "/home/foo/tmp/owl/public",
      "manifest": [
        {
          "absf": "/",
          "directory": "/",
          "filename": "",
          "id": 9962787,
          "mdate": 1701365824,
          "path": "/",
          "perms": 509,
          "pid": 0,
          "size": 4096,
          "type": "folder"
        },
        {
          "absf": "/foo",
          "directory": "/",
          "filename": "foo",
          "id": 9962956,
          "mdate": 1690565423,
          "path": "foo",
          "perms": 509,
          "pid": 9962787,
          "size": 4096,
          "type": "folder"
        },
        {
          "absf": "/foo/bar",
          "directory": "/foo",
          "filename": "bar",
          "id": 9962957,
          "mdate": 1723634001,
          "path": "foo/bar",
          "perms": 509,
          "pid": 9962956,
          "size": 4096,
          "type": "folder"
        },
        {
          "absf": "/foo/bar/test123.txt",
          "directory": "/foo/bar",
          "filename": "test123.txt",
          "id": 9963558,
          "mdate": 1723634001,
          "path": "foo/bar/test123.txt",
          "perms": 436,
          "pid": 9962957,
          "size": 490,
          "type": "file"
        },
      ],
      "status": true
    }

=head2 GET /api/file/FILEPATH

Download file from server

    # curl -v -H "Authorization: Bearer eyJh...GBew" \
      https://localhost:8695/api/file/foo/bar/test123.txt

    > GET /api/file/foo/bar/test123.txt HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...GBew
    >
    < HTTP/1.1 200 OK
    < Accept-Ranges: bytes
    < Content-Length: 490
    < Content-Type: text/plain;charset=UTF-8
    < Date: Wed, 14 Aug 2024 11:24:32 GMT
    < ETag: "5946bf06113340241d59cbf2c940eede"
    < Last-Modified: Wed, 14 Aug 2024 11:13:21 GMT
    < Server: OWL/1.11
    <
    ...content of the file...

=head2 PUT /api/file/FILEPATH

Upload file to server

    # curl -v -H "Authorization: Bearer eyJh...GBew" \
      -X PUT -F size=490 \
      -F md5=acaa9dd36fe3b6758e91129170910378 -F fileraw=@test123.txt \
      https://localhost:8695/api/file/foo/bar/test123.txt

    > PUT /api/file/foo/bar/test123.txt HTTP/1.1
    > Host: localhost:8695
    > User-Agent: curl/7.68.0
    > Accept: */*
    > Authorization: Bearer eyJh...GBew
    > Content-Length: 902
    > Content-Type: multipart/form-data; boundary=...
    >
    < HTTP/1.1 200 OK
    < Content-Length: 182
    < Content-Type: application/json;charset=UTF-8
    < Date: Wed, 14 Aug 2024 11:13:21 GMT
    < Server: OWL/1.11
    <
    {
      "code": "E0000",
      "file": "/home/foo/tmp/owl/public/foo/bar/test123.txt",
      "md5": "acaa9dd36fe3b6758e91129170910378",
      "size": "490",
      "status": true,
      "uploaded": "2024-08-14T11:13:21Z"
    }

=head2 ERROR CODES

List of NoAPI Suffit API error codes

    API   | HTTP  | DESCRIPTION
   -------+-------+-------------------------------------------------
    E1110   [400]   No file path specified
    E1111   [400]   Incorrect file path
    E1112   [404]   File not found
    E1113   [500]   Can't upload file
    E1114   [500]   Can't upload file: file is lost
    E1115   [400]   File size mismatch
    E1116   [400]   File md5 checksum mismatch
    E1117   [---]   Reserved
    E1118   [---]   Reserved
    E1119   [---]   Reserved

B<*> -- this code will be defined later on the interface side

See also list of common Suffit API error codes in L<WWW::Suffit::API/"ERROR CODES">

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojolicious>, L<WWW::Suffit>, L<WWW::Suffit::Server>, L<WWW::Suffit::API>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Mojo::Base 'Mojolicious::Controller';

use File::Find qw/find/;
use File::stat;

use Mojo::JSON qw / true false /;
use Mojo::File qw/path/;
use Mojo::Util qw/decode/;
use Mojo::Date;

use WWW::Suffit::Util qw/ md5sum /;
use WWW::Suffit::Const qw/ USERNAME_REGEXP /;

sub file_list {
    my $self = shift;
    my $src = $self->app->documentroot;
    my $root = stat($src);

    my @manifest = ({
        id          => $root->ino,
        pid         => 0,
        filename    => '',
        directory   => '/',
        path        => '/',
        perms       => $root->mode & 07777,
        size        => $root->size,
        mdate       => $root->mtime,
        type        => 'folder',
        absf        => '/',
    });
    find({  follow      => 1,
            follow_skip => 2,
            wanted      => sub
    {
        my $fn = $_;
        my $dir = $File::Find::dir;
        return 0 if $fn =~ /^\./;
        return 0 unless -f $fn or -d $fn;
        my $type = -d $fn ? 'folder' : 'file';
        my $sb = stat($fn);
        my $dirf = path($dir)->to_rel($src)->to_string; # Directory (rel)
           $dirf =~ s/^\.*\/*/\//;
        my $absf = path("/", $dirf, $fn)->to_string; # File path (abs)
        my $relf = path($dirf, $fn)->to_string; # File path (rel)
           $relf =~ s/^\.*\/+//;

        # Out
        push @manifest, {
            id          => $sb->ino,
            pid         => stat($dir)->ino,
            filename    => decode('UTF-8', $fn) // '',
            directory   => decode('UTF-8', $dirf) // '',
            path        => decode('UTF-8', $relf) // '',
            perms       => $sb->mode & 07777,
            size        => $sb->size,
            mdate       => $sb->mtime,
            type        => $type,
            absf        => decode('UTF-8', $absf) // '',
        };
    }}, $src);

    # Correct manifest
    my $unfl = _unflatten(\@manifest);
    my $fl = _flatten($unfl);

    return $self->render(json => {
        status          => true,
        documentroot    => $src,
        manifest        => $fl,
    });
}
sub file_download {
    my $self = shift;
    my $filepath = $self->param('filepath') // '';
    return 1 if $self->_validate_filepath($filepath); # Validate filepath

    # Set paths
    my $path = path($self->app->documentroot, $filepath);

    # Get full file name
    my $fullfilename = $path->to_string;

    # Check file
    return $self->reply->json_error(404 => "E1112: File not found: \"$filepath\"")
        unless (-e $fullfilename and -f $fullfilename and -s $fullfilename);

    # Send file
    return $self->reply->static($filepath)
}
sub file_upload {
    my $self = shift;
    my $filepath = $self->param('filepath') // '';
    return 1 if $self->_validate_filepath($filepath); # Validate filepath

    # Set paths
    my $path_file = path($self->app->documentroot, $filepath);
    my $path_dir = $path_file->dirname->make_path;
    my $path_name = $path_file->to_string;

    # Upload file @fileraw@
    my $fileuploaded = $self->req->upload('fileraw');
    if ($fileuploaded) {
        my $size = $fileuploaded->size;
        my $name = $fileuploaded->filename;
        $fileuploaded->move_to($path_name);
        my $md5  = md5sum($path_name);

        # Check uploaded file
        return $self->reply->json_error(500 => "E1114: Can't upload file \"$filepath\": file is lost")
            unless -e $path_name;

        # Check size
        my $expected_size = $self->param("size") || 0;
        if ($expected_size && $expected_size != $size) {
            $path_file->remove;
            return $self->reply->json_error(400 =>
                sprintf("E1115: File size mismatch: expected=\"%s\"; got=\"%s\"", $expected_size, $size));
        }

        # Check md5sum
        my $expected_md5 = $self->param("md5") // '';
        if (length($expected_md5) && $expected_md5 ne $md5) {
            $path_file->remove;
            return $self->reply->json_error(400 =>
                sprintf("E1116: File md5 checksum mismatch: expected=\"%s\"; got=\"%s\"", $expected_md5, $md5));
        }
    } else {
        return $self->reply->json_error(500 => "E1113: Can't upload file \"$filepath\"");
    }

    # Result
    return $self->reply->json_ok({
        file        => $path_name,
        size        => $self->param("size"),
        md5         => $self->param("md5"),
        uploaded    => Mojo::Date->new(time)->to_datetime, # RFC 3339
    });
}
sub file_remove {
    my $self = shift;
    my $filepath = $self->param('filepath') // '';
    return 1 if $self->_validate_filepath($filepath); # Validate filepath

    # Set paths
    my $path = path($self->app->documentroot, $filepath);

    # Get full file name
    my $fullfilename = $path->to_string;

    # Check file
    return $self->reply->json_error(404 => "E1112: File not found: \"$filepath\"")
        unless (-e $fullfilename and -f $fullfilename and -s $fullfilename);

    # Delete file
    $path->remove;

    # Result
    return $self->reply->json_ok;
}

sub _unflatten {
    my $arr = shift // [];
    my $parent = shift // {id => 0};
    my $tree = shift // [];

    my @children = grep { $_->{pid} == $parent->{id} } @$arr;
    return $tree unless scalar @children;

    if ($parent->{id} == 0) {
        $tree = [@children];
    } else {
        $parent->{items} = [@children];
    }

    foreach my $child (@children) {
        &_unflatten($arr, $child);
    }

    return $tree;
}
sub _flatten {
    my $tree = shift // [];
    my $arr = [];

    foreach my $child (sort { $b->{type} cmp $a->{type} || $a->{filename} cmp $b->{filename} } @$tree) {
        if (exists $child->{items}) {
            my $children = &_flatten($child->{items});
            delete $child->{items};
            push @$arr, $child;
            push @$arr, @$children;
        } else {
            push @$arr, $child
        }
    }

    return $arr;
}
sub _validate_filepath { # Returns true if invalid!
    my $self = shift;
    my $filepath = shift // $self->param('filepath') // '';
    my @test = split /\//, $filepath;
    return $self->reply->json_error(400 => "E1110: No file path specified") unless scalar @test;
    my $status = 1;
    foreach my $d (@test) {
        unless (defined($d) && length($d) && (length($d) <= 64) && $d =~ USERNAME_REGEXP) {
            $status = 0;
            last;
        }
        if (($d =~ /\.{2,}/) || ($d =~ /^[~]/)) {
            $status = 0;
            last;
        }
    }
    return $self->reply->json_error(400 => "E1111: Incorrect file path") unless $status;
    return;
}

1;

__END__
