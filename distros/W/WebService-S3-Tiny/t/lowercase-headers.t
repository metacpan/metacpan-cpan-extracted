use strict;
use warnings;

use Test::More;
use WebService::S3::Tiny;

{
    no warnings 'redefine';

    *HTTP::Tiny::request = sub { \@_ };
}

my $s3 = WebService::S3::Tiny->new(
    access_key => 1,
    host       => 1,
    secret_key => 1,
);

my $req = $s3->put_object( foo => 'bar', 'baz', { 'Foo-Bar' => 'Baz' } );

is $req->[3]{headers}{'foo-bar'}, 'Baz';

done_testing;
