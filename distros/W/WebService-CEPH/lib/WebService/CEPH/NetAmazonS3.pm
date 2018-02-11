=encoding utf8

=head1 WebService::CEPH::NetAmazonS3

Driver for CEPH is based on Net::Amazon::S3.

Made rather not on the basis Net::Amazon::S3, but on the basis Net::Amazon::S3::Client
see POD https://metacpan.org/pod/Net::Amazon::S3::Client
There is a separate documentation and it is said that this is a newer interface, while in the Net::Amazon::S3, there is no link to this.

Goes into private methods and not documented features of Net :: Amazon :: S3, due to the fact that
Net :: Amazon :: S3 is not well-documented in principle, and there is not enough public functionality in it.

The stability of this solution is provided by the integration test netamazons3_integration, which in theory tests everything.
The problems can only be if you installed this module, then updated Net :: Amazon :: S3 to a new version that did not exist yet,
which broke back compatibility of private methods.

The interface of this module is documented. Stick to what is documented, WebService :: CEPH counts on all this.
You can write your driver with the same interface, but with a different implementation.

=cut

package WebService::CEPH::NetAmazonS3;

our $VERSION = '0.016'; # VERSION

use strict;
use warnings;
use Carp;
use Time::Local;
use Net::Amazon::S3;
use HTTP::Status;
use Digest::MD5 qw/md5_hex/;


sub _time { # for mocking in tests
    time()
}

=head2 new

Constructor

protocol - 'http' or 'https'

host - Amazon S3 host or CEPH

bucket - (mandatory for all operations except the request for the bucket list) the name of the bucket, this bucket will be used for all object operations

key - access key

secret - access secret

=cut

sub new {
    my ($class, %args) = @_;

    my $self = bless +{}, $class;

    $self->{$_}     = delete $args{$_} // confess "Missing $_" for (qw/protocol host key secret/);
    $self->{bucket} = delete $args{bucket};

    confess "Unused arguments %args" if %args;
    confess "protocol should be 'http' or 'https'" unless $self->{protocol} =~ /^https?$/;

    my $s3 = Net::Amazon::S3->new({
        aws_access_key_id     => $self->{key},
        aws_secret_access_key => $self->{secret}, # TODO: фильтровать в логировании?
        host                  => $self->{host},
        secure                => $self->{protocol} eq 'https',
        retry                 => 1,
    });

    $self->{client} =  Net::Amazon::S3::Client->new( s3 => $s3 );
    $self;
}

=head2 _request_object

Private method. Returns the Net :: Amazon :: S3 :: Client :: Bucket object, which can then be used. Used in code several times

=cut

sub _request_object {
    my ($self) = @_;

    confess "Missing bucket" unless $self->{bucket};

    $self->{client}->bucket(name => $self->{bucket});
}

=head2 get_buckets_list

Returns buckets list

=cut

sub get_buckets_list {
    my ($self) = @_;

    return $self->{client}->buckets->{buckets};
}

=head2 upload_single_request

Uploads data.

Parameters:

1) $self

2) $key - object name

3) data itself (blob)

4) Content-Type, optional

Upload an object for one request (non-multipart upload), put a private ACL, add a custom x-amz-meta-md5 header, which equals md5 hex from the file

=cut

sub upload_single_request {
    my ($self, $key) = (shift, shift); # after shifts: $_[0] - value, $_[1] - content-type

    my $md5 = md5_hex($_[0]);
    my $object = $self->_request_object->object(
        key => $key,
        acl_short => 'private',
        $_[1] ? ( content_type => $_[1] ) : ()
    );
    $object->user_metadata->{'md5'} = $md5;
    $object->_put($_[0], length($_[0]), $md5); # private _put so we can re-use md5. only for that.
}

=head2 list_multipart_uploads

Returns a list multipart_upload

Parameters:

none

Returns:
   [
        {
            key       => 'Upload key',
            upload_id => 'Upload ID',
            initiated => 'Init date',
            initiated_epoch => same as initiated but in epoch time format
            initiated_age_seconds => simply time() - initiated_epoch ie upload age
        },
        ...
    ]

=cut

sub list_multipart_uploads {
    my ($self) = @_;

    $self->{client}->bucket(name => $self->{bucket});

    my $http_request = Net::Amazon::S3::HTTPRequest->new(
        s3     => $self->{client}->s3,
        method => 'GET',
        path   => $self->{bucket} . '?uploads',
    )->http_request;

    my $xpc = $self->{client}->_send_request_xpc($http_request);

    my @uploads;
    my $t0 = _time();
    foreach my $node ( $xpc->findnodes(".//s3:Upload") ) {

        my $initiated = $xpc->findvalue( ".//s3:Initiated", $node );

        my ($y, $m, $d, $hour, $min, $sec) = $initiated =~ /^(\d{4})\-(\d{2})\-(\d{2})T(\d{2}):(\d{2}):(\d{2})/
            or confess "Bad date $initiated";
        my $initiated_epoch = timegm($sec, $min, $hour, $d, $m - 1, $y); # interpret time as GMT+00 time and convert to epoch

        push @uploads, {
            key       => $xpc->findvalue( ".//s3:Key", $node ),
            upload_id => $xpc->findvalue( ".//s3:UploadId", $node ),
            initiated => $initiated,
            initiated_epoch => $initiated_epoch,
            initiated_age_seconds => $t0 - $initiated_epoch,
        };

    }

    return \@uploads;
}

=head2 delete_multipart_upload

Deletes upload

Parameters:
   $key, $upload_id


=cut

sub delete_multipart_upload {
    my ($self, $key, $upload_id) = @_;

    $self->{client}->bucket(name => $self->{bucket});

    my $http_request = Net::Amazon::S3::Request::AbortMultipartUpload->new(
        s3                  => $self->{client}->s3,
        bucket              => $self->{bucket},
        key                 => $key,
        upload_id           => $upload_id,
    )->http_request;

    $self->{client}->_send_request_raw($http_request);
}

=head2 initiate_multipart_upload

Initiates multipart upload

Parameters:

1) $self

2) $key - object name

3) md5 from data

Initiates multipart upload, sets x-amz-meta-md5 to md5 value of the file (needs to be calculated in advance and pass it as a parameter).
Returns a reference to a structure of an undocumented nature, which should be used later to work with this multipart upload

=cut

sub initiate_multipart_upload {
    my ($self, $key, $md5, $content_type) = @_;

    confess "Missing bucket" unless $self->{bucket};

    my $object = $self->_request_object->object( key => $key, acl_short => 'private' );

    my $http_request = Net::Amazon::S3::Request::InitiateMultipartUpload->new(
        s3     => $self->{client}->s3,
        bucket => $self->{bucket},
        key    => $key,
        headers => +{
            'X-Amz-Meta-Md5' => $md5,
            $content_type ? ( 'Content-type' => $content_type ) : ()
        }
    )->http_request;

    my $xpc = $self->{client}->_send_request_xpc($http_request);
    my $upload_id = $xpc->findvalue('//s3:UploadId');
    confess "Couldn't get upload id from initiate_multipart_upload response XML"
      unless $upload_id;

    +{ key => $key, upload_id => $upload_id, object => $object, md5 => $md5};
}

=head2 upload_part

Uploads part of the data when multipart uploading

Parameters:

1) $self

2) $multipart_upload - reference, obtained from initiate_multipart_upload

3) $part_number - part number, from 1 and higher.

Works only if parts were uploaded in turn with increasing numbers (which is natural, if it is sequential uploading,
and makes it impossible for parallel upload from different processes)

Returns nothing

=cut

sub upload_part {
    my ($self, $multipart_upload, $part_number) = (shift, shift, shift);

    $multipart_upload->{object}->put_part(
        upload_id => $multipart_upload->{upload_id},
        part_number => $part_number,
        value => $_[0]
    );

    # TODO:Part numbers should be in accessing order (in case someone uploads in parallel) !
    push @{$multipart_upload->{parts} ||= [] }, $part_number;
    push @{$multipart_upload->{etags} ||= [] }, md5_hex($_[0]);
}

=head2 complete_multipart_upload

Finalize multipart upload

Parameters:

1) $self

2) $multipart_upload - reference, obtained from initiate_multipart_upload

returns nothing. throws an exception, if something is wrong.

=cut

sub complete_multipart_upload {
    my ($self, $multipart_upload) = @_;

    $multipart_upload->{object}->complete_multipart_upload(
        upload_id => $multipart_upload->{upload_id},
        etags => $multipart_upload->{etags},
        part_numbers => $multipart_upload->{parts}
    );
}

=head2 download_with_range

Downloads an object with the HTTP Range header (ie, part of the data).

Parameters:

1) $self

2) $key - object name

3) $first - first byte for Range

4) $last - last byte for Range

If $first, $last are missing or undef, the entire file is downloaded, without the Range header

If $last is missing, downloads data from a specific position to the end (as well as in the Range specification).

If the object is missing, returns an empty list. If other error - an exception.

Returns:

1) Scalar Ref on downloaded data

2) The number of remaining bytes that can still be downloaded (or undef, if $first parameter was not present)

3) ETag header with deleted quotes (or undef if it is missing)

4) X-Amz-Meta-Md5 header (or undef if it is missing)

=cut

sub download_with_range {
    my ($self, $key, $first, $last) = @_;

    confess "Missing bucket" unless $self->{bucket};

    # TODO: How and when to validate ETag here?
    my $http_request = Net::Amazon::S3::Request::GetObject->new(
        s3     => $self->{client}->s3,
        bucket => $self->{bucket},
        key    => $key,
        method => 'GET',
    )->http_request;

    if (defined $first) {
        $last //= '';
        $http_request->headers->header("Range", "bytes=$first-$last");
    }

    my $http_response = $self->{client}->_send_request_raw($http_request);
    #print $http_request->as_string, $http_response->as_string ;
    if ( $http_response->code == 404 && $http_response->decoded_content =~ m!<Code>NoSuchKey</Code>!) {
        return;
    }
    elsif (is_error($http_response->code)) {
        my ($err) = $http_response->decoded_content =~ m!<Code>(.*)</Code>!;
        $err //= 'none';
        confess "Unknown error ".$http_response->code." $err";
    } else {
        my $left = undef;
        if (defined $first) {
            my $range = $http_response->header('Content-Range') // confess;
            my ($f, $l, $total) = $range =~ m!bytes (\d+)\-(\d+)/(\d+)! or confess;
            $left = $total - ( $l + 1);
        }

        my $etag = $http_response->header('ETag');
        if ($etag) {
            $etag =~ s/^"//;
            $etag =~ s/"$//;
        }

        my $custom_md5 = $http_response->header('X-Amz-Meta-Md5');

        return (\$http_response->decoded_content, $left, $etag, $custom_md5);
    }
}

=head2 size

Gets the size of the object using the HTTP HEAD request.

Parameters:

1) $self

2) $key - object name

If the object does not exist, it returns undef. If other error - an exception. Returns size in bytes.

=cut

sub size {
    my ($self, $key) = @_;

    confess "Missing bucket" unless $self->{bucket};

    my $http_request = Net::Amazon::S3::Request::GetObject->new(
        s3     => $self->{client}->s3,
        bucket => $self->{bucket},
        key    => $key,
        method => 'HEAD',
    )->http_request;

    my $http_response = $self->{client}->_send_request_raw($http_request);
    if ( $http_response->code == 404) { # It's not possible to distinct between NoSuchkey and NoSuchBucket??
        return undef;
    }
    elsif (is_error($http_response->code)) {
        confess "Unknown error ".$http_response->code;
    }
    else {
        return $http_response->header('Content-Length') // 0;
    }



}

=head2 delete

Deletes an object

Parameters:

1) $self

2) $key - object name

Returns nothing. If the object did not exist, does not signal about it.

=cut

sub delete {
    my ($self, $key) = @_;

    $self->_request_object->object( key => $key )->delete;
}

=head2 query_string_authentication_uri

Returns Query String Authentication URL for key $key, with expire time $expires

=cut

sub query_string_authentication_uri {
    my ($self, $key, $expires) = @_;

    $self->_request_object->object( key => $key, expires => $expires )->query_string_authentication_uri;
}


1;
