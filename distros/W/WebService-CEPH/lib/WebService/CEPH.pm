=encoding utf8

=head1 NAME

WebService::CEPH

=head1 DESCRIPTION

CEPH client for simple workflow, supporting multipart uploads.

Clint for CEPH, without a low-level code to communicate with the Amazon S3 library (it is placed in a separate class).

Lower-level library is responsible for error handling (exceptions and failed requests retries), unless otherwise guaranteed in this documentation.

Constructor parameters:

Required parameters:

protocol - http/https

host - backend host

key - access key

secret - access secret

Optional parameters:

bucket - name of the bucket (not needed just to get the list of buckets)

driver_name - at the moment only 'NetAmazonS3' is supported

multipart_threshold - the size threshold in bytes used for multipart uploads

multisegment_threshold - the size threshold in bytes used for multisegment downloads

query_string_authentication_host_replace - host/protocol on which to replace the URL in query_string_authentication_uri
should start with the protocol (http / https), then the host, at the end optional slash.
This parameter is needed if you want to change the host for return to clients (you have a cluster) or protocol (https for external clients)

=cut

package WebService::CEPH;

our $VERSION = '0.016'; # VERSION

use strict;
use warnings;
use Carp;
use WebService::CEPH::NetAmazonS3;
use Digest::MD5 qw/md5_hex/;
use Fcntl qw/:seek/;

use constant MINIMAL_MULTIPART_PART => 5*1024*1024;

sub _check_ascii_key { confess "Key should be ASCII-only" unless $_[0] !~ /[^\x00-\x7f]/ }

=head2 new

Constructor. See the parameters above.

=cut

sub new {
    my ($class, %args) = @_;

    my $self = bless +{}, $class;

    # mandatory
    $self->{$_} = delete $args{$_} // confess "Missing $_"
        for (qw/protocol host key secret/);
    # optional
    for (qw/bucket driver_name multipart_threshold multisegment_threshold query_string_authentication_host_replace/) {
        if (defined(my $val = delete $args{$_})) {
            $self->{$_} = $val;
        }
    }

    confess "Unused arguments: @{[ %args]}" if %args;

    $self->{driver_name} ||= "NetAmazonS3";
    $self->{multipart_threshold} ||= MINIMAL_MULTIPART_PART;
    $self->{multisegment_threshold}  ||= MINIMAL_MULTIPART_PART;

    confess "multipart_threshold should be greater or eq. MINIMAL_MULTIPART_PART (5Mb) (now multipart_threshold=$self->{multipart_threshold}"
        if $self->{multipart_threshold} < MINIMAL_MULTIPART_PART;

    my $driver_class = __PACKAGE__."::".$self->{driver_name}; # should be loaded via "use" at top of file
    $self->{driver} = $driver_class->new(map { $_ => $self->{$_} } qw/protocol host key secret bucket/ );

    $self;
}




=head2 upload

Uploads the file into CEPH. If the file already exists, it is replaced. If the data is larger than a certain size, multipart upload is started. Returns nothing

Parameters:

0th - $self

1-st - key name

2-nd - scalar, key data

3-rd - Content-type. If undef, the default binary / octet-stream is used

=cut

sub upload {
    my ($self, $key) = (shift, shift); #  after these params: $_[0] - data, $_[1] - Content-type
    $self->_upload($key, sub { substr($_[0], $_[1], $_[2]) }, length($_[0]), md5_hex($_[0]), $_[1], $_[0]);
}

=head2 upload_from_file

Same as upload method, but reads from file.

Parameters:

0th - $self

1-st - key name

2-nd - file name (if scalar), otherwise opens filehandle

3-rd - Content-type. If undef, the default binary / octet-stream is used

Double walks through the file, calculating md5. The file should not be a pipe, its size should not vary.

=cut

sub upload_from_file {
    my ($self, $key, $fh_or_filename, $content_type) = @_;
    my $fh = do {
        if (ref $fh_or_filename) {
            $fh_or_filename
        }
        else {
            open my $f, "<", $fh_or_filename;
            binmode $f;
            $f;
        }
    };

    my $md5 = Digest::MD5->new;
    $md5->addfile($fh);
    seek($fh, 0, SEEK_SET);

    $self->_upload(
        $key,
        sub { read($_[0], my $data, $_[2]) // confess "Error reading data $!\n"; $data },
        -s $fh, $md5->hexdigest, $content_type, $fh
    );
}

=head2 _upload

Private method for upload/upload_from_file

Parameters

1) self

2) key

3) iterator with interface (data, offset, length). "data" must correspond to the last parameter of this function (ie (6))

4) data length

5) previously calculated md5 from the data

6) Content-type. If undef, the default binary / octet-stream is used

7) data. or a scalar. or filehandle

=cut


sub _upload {
    # after that $_[0] is data (scalar or filehandle)
    my ($self, $key, $iterator, $length, $md5_hex, $content_type) = (shift, shift, shift, shift, shift, shift);

    confess "Bucket name is required" unless $self->{bucket};

    _check_ascii_key($key);

    if ($length > $self->{multipart_threshold}) {
        my $multipart = $self->{driver}->initiate_multipart_upload($key, $md5_hex, $content_type);

        my $len = $length;
        my $offset = 0;
        my $part = 0;
        while ($offset < $len) {
            my $chunk = $iterator->($_[0], $offset, $self->{multipart_threshold});

            $self->{driver}->upload_part($multipart, ++$part, $chunk);

            $offset += $self->{multipart_threshold};
        }
        $self->{driver}->complete_multipart_upload($multipart);
    }
    else {
        $self->{driver}->upload_single_request($key, $iterator->($_[0], 0, $length), $content_type);
    }

    return;
}

=head2 download

Downloads data from an object named $key and returns it. If the object does not exist, it returns undef.

If the size of the object is actually greater than multisegment_threshold, the object will be downloaded by several requests with heading Range
(ie, multi segment download).

At the moment there is a workaround for the bug http://lists.ceph.com/pipermail/ceph-users-ceph.com/2016-June/010704.html,
in connection with this, an extra HTTP request is always made - the request for the length of the file. Plus Race condition is not excluded.

=cut

sub download {
    my ($self, $key) = @_;
    my $data;
    # workaround for CEPH bug http://lists.ceph.com/pipermail/ceph-users-ceph.com/2016-June/010704.html
    my $cephsize = $self->size($key);
    if (defined($cephsize) && $cephsize == 0) {
        return '';
    } else {
        # / workaround for CEPH bug
        _download($self, $key, sub { $data .= $_[0] }) or return;
        return $data;
    }
}

=head2 download_to_file

Downloads the data of the object with the name $key to the file $fh_or_filename.
If the object does not exist, it returns undef
(in this case the output file will be corrupted and, possibly, partially written due to the case of race condition - delete this data yourself,
or delete it using the download method). Otherwise, returns the size of the written data.
The output file is opened in overwrite mode, if this is the file name, if it is a filehandle, it is trimmed to zero length and written from the beginning.

If the size of the object is actually greater than multisegment_threshold, the object will be downloaded by several requests with heading Range
(ie, multi segment download).

At the moment there is a workaround for the bug http://lists.ceph.com/pipermail/ceph-users-ceph.com/2016-June/010704.html,
in connection with this, an extra HTTP request is always made - the request for the length of the file. Plus Race condition is not excluded.

=cut

sub download_to_file {
    my ($self, $key, $fh_or_filename) = @_;

    my $fh = do {
        if (ref $fh_or_filename) {
            seek($fh_or_filename, SEEK_SET, 0);
            truncate($fh_or_filename, 0);
            $fh_or_filename
        }
        else {
            open my $f, ">", $fh_or_filename;
            binmode $f;
            $f;
        }
    };

    # workaround for CEPH bug http://lists.ceph.com/pipermail/ceph-users-ceph.com/2016-June/010704.html
    my $cephsize = $self->size($key);
    if (defined($cephsize) && $cephsize == 0) {
        return 0;
    }
    else {
        # / workaround for CEPH bug
        my $size = 0;
        _download($self, $key, sub {
            $size += length($_[0]);
            print $fh $_[0] or confess "Error writing to file $!"
        }) or return;
        return $size;
    }
}

=head2 _download

Private method for download/download_to_file

Parameters:

1) self

2) key name

3) appender - the closure in which the data for recording will be transmitted. it should accumulate them somewhere to itself or write to a file that it knows.

=cut

sub _download {
    my ($self, $key, $appender) = @_;

    confess "Bucket name is required" unless $self->{bucket};

    _check_ascii_key($key);

    my $offset = 0;
    my $check_md5 = undef;
    my $md5 =  Digest::MD5->new;
    my $got_etag = undef;
    while() {
        my ($dataref, $bytesleft, $etag, $custom_md5) = $self->{driver}->download_with_range($key, $offset, $offset + $self->{multisegment_threshold});

        # Return undef if object not found
        # If object suddently disappeared during multisegment download, it means someone deleted it. So we have to return undef it this case.
        # However, when downloading to file, some data could have been already written to file. Remove this file by yourself.
        return unless ($dataref);

        if (defined $got_etag) {
            # Someone replaced file during download process. According to HTTP, ETag must be different for different files
            #(though it does not have to be the same for same files).
            # Throw an exception in this case...
            # TODO: retry requests if file changed during download
            confess "File changed during download. Race condition. Please retry request"
                unless $got_etag eq $etag;
        }
        else {
            $got_etag = $etag;
        }

        # Check md5 if ETag was normal with md5 (it was not a multipart upload)
        if (!defined $check_md5) {
            my ($etag_md5) = $etag =~ /^([0-9a-f]+)$/;

            confess "ETag looks like valid md5 and x-amz-meta-md5 presents but they do not match"
                if ($etag_md5 && $custom_md5 && $etag_md5 ne $custom_md5);
            if ($etag_md5) {
                $check_md5 = $etag_md5;
            } elsif ($custom_md5) {
                $check_md5 = $custom_md5;
            } else {
                $check_md5 = 0;
            }
        }
        if ($check_md5) {
            $md5->add($$dataref);
        }

        $offset += length($$dataref);
        $appender->($$dataref);
        last unless $bytesleft;
    };
    if ($check_md5) {
        my $got_md5 = $md5->hexdigest;
        confess "MD5 missmatch, got $got_md5, expected $check_md5" unless $got_md5 eq $check_md5;
    }
    1;
}

=head2 size

Returns the size of the object named $key in bytes, if the key does not exist, returns undef

=cut

sub size {
    my ($self, $key) = @_;

    confess "Bucket name is required" unless $self->{bucket};

    _check_ascii_key($key);

    $self->{driver}->size($key);
}

=head2 delete

Removes an object named $key, returns nothing. If the object does not exist, it does not produce an error

=cut

sub delete {
    my ($self, $key) = @_;

    confess "Bucket name is required" unless $self->{bucket};

    _check_ascii_key($key);

    $self->{driver}->delete($key);
}

=head2 query_string_authentication_uri

Returns Query String Authentication URL for key $key, with expire $expires

$expires - epoch time. But a low-level library can accept other formats. make sure that the input data is validated and you transfer exactly epoch

Replaces the host if there is a query_string_authentication_host_replace option (see the constructor)

=cut

sub query_string_authentication_uri {
    my ($self, $key, $expires) = @_;

    _check_ascii_key($key);
    $expires or confess "Missing expires";

    my $uri = $self->{driver}->query_string_authentication_uri($key, $expires);
    if ($self->{query_string_authentication_host_replace}) {
        my $replace = $self->{query_string_authentication_host_replace};
        $replace .= '/' unless $replace =~ m!/$!;
        $uri =~ s!^https?://[^/]+/!$replace!;
    }
    $uri;
}

=head2 get_buckets_list

Returns buckets list

WARNING

The method throws error "Attribute (owner_id) does not pass the type constraint because:
Validation failed for 'OwnerId'"

Notifications sent to the developers:
http://tracker.ceph.com/issues/16806
https://github.com/rustyconover/net-amazon-s3/issues/18

=cut

sub get_buckets_list {
    my ($self) = @_;

    return $self->{driver}->get_buckets_list;
}

=head2 list_multipart_uploads

Returns the list of multipart downloads in a bucket

=cut

sub list_multipart_uploads {
    my ($self) = @_;

    confess "Bucket name is required" unless $self->{bucket};

    return $self->{driver}->list_multipart_uploads();
}

=head2 delete_multipart_upload

Deletes multipart download in bucket

Positional parameters: $key, $upload_id

Returns nothing

=cut

sub delete_multipart_upload {
    my ( $self, $key, $upload_id ) = @_;

    confess "Bucket name is required" unless $self->{bucket};
    confess "key and upload ID is required" unless $key && $upload_id;

    $self->{driver}->delete_multipart_upload($key, $upload_id);
}

1;
