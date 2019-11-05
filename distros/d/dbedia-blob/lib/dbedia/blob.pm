package dbedia::blob;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.01';

use Moose;
use MooseX::Types::Path::Class;
use MooseX::Types::URI qw(Uri);
use namespace::autoclean;

use Digest::SHA qw(sha256_hex);
use URI;
use Path::Class qw();
use YAML::Syck qw();
use File::MimeInfo qw();
use File::MimeInfo::Magic qw();
use Net::SCP qw();
use Path::Class qw(file dir);
use File::Temp;

has 'file' => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    required => 1,
    coerce   => 1,
);
has 'file_chksum' => (
    is         => 'rw',
    isa        => 'Str',
    required   => 1,
    lazy_build => 1,
);
has 'file_url' => (
    is         => 'rw',
    isa        => Uri,
    required   => 1,
    lazy_build => 1,
    coerce     => 1,
);
has 'file_path' => (
    is         => 'rw',
    isa        => 'Str',
    required   => 1,
    lazy_build => 1,
);
has 'file_meta' => (
    is         => 'rw',
    isa        => 'HashRef',
    required   => 1,
    lazy_build => 1,
);
has 'base_uri' => (
    is       => 'ro',
    isa      => Uri,
    required => 1,
    default  => sub {default_base_uri()},
    lazy     => 1,
    coerce   => 1,
);

sub default_base_uri {
    return URI->new('https://b.dbedia.com/');
}

sub _build_file_chksum {
    return sha256_hex($_[0]->file->slurp() . '');
}

sub _build_file_url {
    my ($self) = @_;
    my $file_url = $self->base_uri->clone;
    $file_url->path($file_url->path . $self->file_chksum . '/' . $self->file->basename);
    return $file_url;
}

sub _build_file_path {
    my ($self) = @_;
    my $file_hex = $self->file_chksum;
    return Path::Class::file(
        substr($file_hex, 0, 2),
        substr($file_hex, 2, 2),
        substr($file_hex, 4, 2),
        substr($file_hex, 6)
    ) . '';
}

sub file_meta_yaml {
    return YAML::Syck::Dump($_[0]->file_meta);
}

sub _build_file_meta {
    my ($self)    = @_;
    my $file      = $self->file;
    my $mime_type = File::MimeInfo::Magic::mimetype($file->openr);
    $mime_type = File::MimeInfo::mimetype($file->basename)
        if (($mime_type eq 'text/plain') || ($mime_type eq 'application/octet-stream'));
    return {
        filename  => $file->basename,
        mime_type => $mime_type,
        size      => $file->stat->size,
    };
}

sub file_meta_path {
    return $_[0]->file_path . '.yml';
}

sub upload {
    my ($self, $hostname) = @_;

    $hostname //= 'dbedia-blob';
    my $file = $self->file;

    my $scp = Net::SCP->new($hostname);
    $scp->cwd('blobs') or die $scp->{errstr};

    my $path      = $self->file_path;
    my $path_meta = $self->file_meta_path;
    my $temp_file = File::Temp->new(UNLINK => 1);

    if ($scp->get($path_meta, $temp_file)) {
        warn 'skipping ' . $file . ' already exists';
    }
    else {
        file($temp_file)->spew($self->file_meta_yaml);
        $scp->mkdir(file($path)->dir) or die $scp->{errstr};
        $scp->put($temp_file, $path_meta) or die $scp->{errstr};
        $scp->put($file,      $path)      or die $scp->{errstr};
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

dbedia::blob - interface to (not only) b.dbedia.com blob storage

=head1 SYNOPSIS

    use dbedia::blob;

    my $blob = dbedia::blob->new(file => $file);
    say $blob->file_path;
    say $blob->file_url;
    say $blob->file_meta->{mime_type};
    say $blob->file_meta_yaml;

    $blob->upload;

=head1 DESCRIPTION

Module to upload files to blob server with their sha256 checksum as a part
of their name. So for example C<swagger-ui.js> becomes
L<https://b.dbedia.com/e3d4e875f9d0b751bc7276e6472e96a5262cabc64b060540da190bfdc0e36dec/swagger-ui.js>
and will be stored under F<e3/d4/e8/75f9d0b751bc7276e6472e96a5262cabc64b060540da190bfdc0e36dec>
on a target server.

=head1 METHODS

=head2 new(file => ..., base_uri => ...)

Object constructor

=head2 file

Object accessor with file location on local filesystem.

=head2 base_uri

Object accessor with base location on blob server. Default to L<https://b.dbedia.com/>
but can be anything like C<http://you-server/blob-path/>.

=head2 file_chksum

C<file> sha256 hex checksum.

=head2 file_url

Web url for a C<file> based on the checksum and base_uri.

=head2 file_path

File path on a blob server.

=head2 file_meta

Return file meta has with original C<filename>, C<mime_type> and C<size>.
For example:

    {   filename  => 'swagger-ui.js',
        mime_type => 'application/javascript',
        size      => 355197,
    }

=head2 file_meta_yaml

Returns L</file_meta> yaml.

=head2 file_meta_path

File meta data (yaml) path on a blob server.

=head2 upload($hostname)

Using L<Net::SCP> will upload L</file> to C<$hostname> server. Default is
C<dbedia-blob> which can be configured in F<~/.ssh/config> to point to
any hostname/username/auth configuration of your liking.

In case file is already present will print warning about skipping.

=head2 default_base_uri

Returns L<https://b.dbedia.com/> uri.

=head1 EXAMPLE NGINX CONFIG

configuration to serve blobs via nginx:

    server {
        server_name  b.dbedia.com;

        access_log /var/log/nginx/b.dbedia-access.log;

        root   /srv/www/b.dbedia.com;
        index  index.html index.htm;

        location / {
            expires 5m;
        }
        location ~ "^(/..)(..)(..)(.{58})(.*)$" {
            alias /srv/www/b.dbedia.com/$1/$2/$3/$4;
            expires 24h;
        }
    }

=head1 CONTRIBUTORS

The following people have contributed to the Sys::Path by committing their
code, sending patches, reporting bugs, asking questions, suggesting useful
advice, nitpicking, chatting on IRC or commenting on my blog (in no particular
order):

    you?

=head1 AUTHOR

Jozef Kutej

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
