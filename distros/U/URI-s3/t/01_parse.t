use strict;
use Test::More 0.98;

use URI;

my $uri = URI->new('s3://example-bucket/path/to/object');
isa_ok $uri, 'URI::s3';

is $uri->bucket, 'example-bucket', 'bucket';
is $uri->key,    'path/to/object', 'key';

done_testing;
