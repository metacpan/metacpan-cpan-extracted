use strict;
use warnings;

BEGIN { *CORE::GLOBAL::gmtime =  sub(;$) { CORE::gmtime(1440938160) } }

use Test::More;
use WebService::S3::Tiny;

my $s3 = WebService::S3::Tiny->new(
    access_key => 'access',
    host       => 'http://s3.host.com',
    secret_key => 'secret',
);

is $s3->signed_url( GET => 'maibucket', 'path/to/my+file.jpg', 3600),
    'http://s3.host.com/maibucket/path/to/my%2Bfile.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=access%2F20150830%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20150830T123600Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=10fcd77ceb592d5b8b7561949fd3f56829005976118799b8e2e06ddee23687ed',
    'signed_url';

done_testing;
