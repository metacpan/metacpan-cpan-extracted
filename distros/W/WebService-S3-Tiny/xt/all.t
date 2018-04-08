use strict;
use warnings;

use Socket;
use Test::More;
use WebService::S3::Tiny;

# Block until minio is up.
BEGIN {
    socket my $sock, PF_INET, SOCK_STREAM, 0 or die $!;

    my $addr = sockaddr_in 9000, inet_aton 'minio';

    my $i;
    until ( connect $sock, $addr ) {
        select undef, undef, undef, .1;
        die 'Minio never came up' if ++$i > 50;
    }
}

my $s3 = WebService::S3::Tiny->new(
    access_key => 'access_key',
    host       => 'http://minio:9000',
    secret_key => 'secret_key',
);

is $s3->put_bucket('bucket')->{status}, 200, 'put_bucket("bucket")';
is $s3->put_bucket('bucket')->{status}, 409, 'put_bucket("bucket")';

is $s3->put_object( 'bucket', 'object', 'foo' )->{status}, 200,
    'put_object("bucket", "object", "foo")';

is $s3->put_object( 'bucket', 'object', 'bar' )->{status}, 200,
    'put_object("bucket", "object", "bar")';

is $s3->get_object( 'bucket', 'object' )->{content}, 'bar',
    'get_object("bucket", "object")';

is $s3->get_object( 'bucket', 'object2' )->{status}, 404,
    'get_object("bucket", "object2")';

like $s3->get_bucket('bucket')->{content}, qr(<Key>object</Key>),
    'get_bucket("bucket")';

like $s3->get_bucket( 'bucket', {}, { 'list-type' => 2 } )->{content}, qr(<Key>object</Key>),
    'get_bucket("bucket", {}, { "list-type" => 2 })';

is $s3->delete_object('bucket', 'object')->{status}, 204,
    'delete_bucket("bucket", "object")';

is $s3->delete_object('bucket', 'object')->{status}, 204,
    'delete_bucket("bucket", "object")';

is $s3->delete_bucket('bucket')->{status}, 204, 'delete_bucket("bucket")';
is $s3->delete_bucket('bucket')->{status}, 404, 'delete_bucket("bucket")';

done_testing;
