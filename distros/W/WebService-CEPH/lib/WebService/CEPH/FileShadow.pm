=encoding utf8



=head1 WebService::CEPH::FileShadow

Child class of WebService::CEPH.

Constructor parameters are the same as for WebService::CEPH, plus there are mode and fs_shadow_path parameters:
mode - 's3' or 's3-fs' or 'fs'

fs_shadow_path - path to the file system, points to the directory, the final slash is optional.

In s3 mode, everything works like WebService :: CEPH, the files are downloaded and uploaded to the CEPH using the s3 protocol.

In the 's3-fs' mode when uploading a file, a copy of file is created in the file system.
First, the file is uploaded to s3, then to the file system and if an exception was thrown at that time, the previous step would not be canceled.
If a download fails in 's3-fs' mode, no failover on the file system is made.
In the 'fs' mode, file upload and download is made using only file system, not S3.

Metainformation (x-amz-meta-md5, content-type in the file system is not saved).
In the download_to_file, upload_from_file methods in the fs mode, working with local files is done as much as possible
compatible with the 's3' mode (umask permissions when creating files, truncate and seek modes when working with filehandles).

The object key name can not contain characters that are insecure for the file system (for example '../', '/ ..')
otherwise there will be an exception thrown.
However, it is the caller that is really responsible for security.

=cut

package WebService::CEPH::FileShadow;

our $VERSION = '0.016'; # VERSION

use strict;
use warnings;
use Carp;
use Fcntl qw/:seek/;
use File::Copy;
use File::Slurp qw/read_file/;
use File::Path qw(make_path);
use parent qw( WebService::CEPH );


sub new {
    my ($class, %options) = @_;
    my %new_options;

    $new_options{$_} = delete $options{$_} for (qw/fs_shadow_path mode/);

    !defined or m!/$! or $_ .= '/' for $new_options{fs_shadow_path};
    confess "mode should be 's3', 's3-fs' or 'fs', but it is '$new_options{mode}'"
        unless $new_options{mode} =~ /^(s3|s3\-fs|fs)$/;

    confess "you specified mode to work with filesystem ($new_options{mode}), please define fs_shadow_path then"
        if $new_options{mode} =~ /fs/ && !$new_options{fs_shadow_path};

    my $self = $class->SUPER::new(%options);

    $self->{$_} = $new_options{$_} for keys %new_options;

    $self;
}

sub _filepath {
    my ($self, $key, $should_mkpath) = @_;
    confess "key expected" unless defined $key;
    confess "unsecure key" if $key eq '.';
    confess "unsecure key" if $key =~ m!\.\./!;
    confess "unsecure key" if $key =~ m!/\.\.!;
    confess "constructor should normalize path" unless $self->{fs_shadow_path} =~ m!/$!;
    my $dir = $self->{fs_shadow_path}.$self->{bucket}."/";
    make_path($dir) if ($should_mkpath);
    $dir.$key;
}
sub upload {
    my ($self, $key) = (shift, shift);

    if ($self->{mode} =~ /s3/) {
        $self->SUPER::upload($key, $_[0], $_[1]);
    }
    if ($self->{mode} =~ /fs/) {
        my $path = $self->_filepath($key, 1);
        open my $f, ">", $path or confess;
        binmode $f;
        print $f $_[0] or confess;
        close $f or confess;
    }
}

sub upload_from_file {
    my ($self, $key, $fh_or_filename, $content_type) = @_;

    if ($self->{mode} =~ /s3/) {
        $self->SUPER::upload_from_file($key, $fh_or_filename, $content_type);
    }
    if ($self->{mode} =~ /fs/) {
        my $path = $self->_filepath($key, 1);
        seek($fh_or_filename, 0, SEEK_SET) if (ref $fh_or_filename);
        copy($fh_or_filename, $path);
    }
}

sub download {
    my ($self, $key) = @_;

    if ($self->{mode} =~ /s3/) {
        return $self->SUPER::download($key);
    }
    elsif ($self->{mode} =~ /fs/) {
        return scalar read_file( $self->_filepath($key), binmode => ':raw' )
    }
}

sub download_to_file {
    my ($self, $key, $fh_or_filename) = @_;

    if ($self->{mode} =~ /s3/) {
        $self->SUPER::download_to_file($key, $fh_or_filename);
    }
    elsif ($self->{mode} =~ /fs/) {
        copy( $self->_filepath($key), $fh_or_filename );
    }
}

sub size {
    my ($self, $key) = @_;

    if ($self->{mode} =~ /s3/) {
        return $self->SUPER::size($key);
    }
    elsif ($self->{mode} =~ /fs/) {
        return -s $self->_filepath($key);
    }
}

sub delete {
    my ($self, $key) = @_;

    if ($self->{mode} =~ /s3/) {
        $self->SUPER::delete($key);
    }
    elsif ($self->{mode} =~ /fs/) {
        unlink($self->_filepath($key));
    }
}

sub query_string_authentication_uri {
    my ($self, $key, $expires) = @_;

    if ($self->{mode} =~ /s3/) {
        $self->SUPER::query_string_authentication_uri($key, $expires);
    }
    else {
        confess "Unimplemented in fs mode";
    }
}

1;
