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

See L<WWW::Suffit::API/"GET /api/file/FILEPATH">

=head2 file_list

See L<WWW::Suffit::API/"GET /api/file">

=head2 file_remove

See L<WWW::Suffit::API/"DELETE /api/file/FILEPATH">

=head2 file_upload

See L<WWW::Suffit::API/"PUT /api/file/FILEPATH">

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojolicious>, L<WWW::Suffit>, L<WWW::Suffit::Server>, L<WWW::Suffit::API>

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
