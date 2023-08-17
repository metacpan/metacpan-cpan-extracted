#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use Test::Exception;
use Digest::MD5::File qw(file_md5_hex);
use File::stat;
use File::Slurp;
use LWP::UserAgent;
use WebService::Rackspace::CloudFiles;

unless ( $ENV{'CLOUDFILES_EXPENSIVE_TESTS'} ) {
    plan skip_all => 'Testing this module for real costs money.';
}

my $cloudfiles = WebService::Rackspace::CloudFiles->new(
    user     => $ENV{'CLOUDFILES_USER'},
    key      => $ENV{'CLOUDFILES_KEY'},
    location => $ENV{'CLOUDFILES_LOCATION'},
);
isa_ok( $cloudfiles, 'WebService::Rackspace::CloudFiles' );

my $container = $cloudfiles->create_container( name => 'testing' );
isa_ok( $container, 'WebService::Rackspace::CloudFiles::Container', 'container' );
isa_ok( $container->cloudfiles, 'WebService::Rackspace::CloudFiles' );
is( $container->name, 'testing', 'container name is testing' );

my $container2 = $cloudfiles->container( name => 'testing' );
isa_ok( $container2, 'WebService::Rackspace::CloudFiles::Container', 'container' );
isa_ok( $container2->cloudfiles, 'WebService::Rackspace::CloudFiles' );
is( $container2->name, 'testing', 'container name is testing' );

is( $container->object_count, 0, 'container has no objects' );
is( $container->bytes_used,   0, 'container uses no bytes' );
is( $container->objects->all, 0, 'container has no objects' );

my $one = $container->object( name => 'one.txt' );
isa_ok( $one, 'WebService::Rackspace::CloudFiles::Object', 'container' );
isa_ok( $one->cloudfiles, 'WebService::Rackspace::CloudFiles' );
isa_ok( $one->container,  'WebService::Rackspace::CloudFiles::Container' );
is( $one->container->name, 'testing', 'container name is testing' );
is( $one->name,            'one.txt', 'object name is one.txt' );

$one->object_metadata({
        description => 'this is a description',
        useful_number => 17,
        'Access-Control-Allow-Origin' => '*',
    });

$one->put('this is one');

## these will fail on an account that doesn't have anything in it yet
## a case that is likely when just installing the module, so move them 
## to be after we've created something.
ok( $cloudfiles->total_bytes_used, 'use some bytes' );
ok( $cloudfiles->containers,       'have some containers' );

## now we wipe $one, and retrieve it.  This makes sure we aren't just
## seeing the values we already put in locally.
$one = undef;

$one = $container->object( name => 'one.txt' );

is( $one->get,  'this is one', 'got content for one.txt' );
is( $one->size, 11,            'got size for one.txt' );
is( $one->etag, '855a8e4678542fd944455ee350fa8147', 'got etag for one.txt' );
is( $one->content_type, 'binary/octet-stream',
    'got content_type for one.txt' );
isa_ok( $one->last_modified, 'DateTime', 'got last_modified for one.txt' );
is( $one->object_metadata->{'useful_number'}, 17, 'numeric metadata works');
is( $one->object_metadata->{'description'}, 'this is a description', 'string metadata works');

my $filename = 't/one.txt';
$one->get_filename($filename);
is( read_file($filename), 'this is one', 't/one.txt has correct value' );
is( -s $filename,         11,            'got size for t/one.txt' );
is( file_md5_hex($filename),
    '855a8e4678542fd944455ee350fa8147',
    'got etag for t/one.txt'
);
is( stat($filename)->mtime,
    $one->last_modified->epoch,
    'got last_modified for t/one.txt'
);

my @objects = $container->objects->all;
is( @objects, 1, 'listing one object' );
my $object = $objects[0];
is( $object->name, 'one.txt', 'list has right name' );
is( $object->etag, '855a8e4678542fd944455ee350fa8147',
    'list has right etag' );
is( $object->size, '11', 'list has right size' );
is( $object->content_type, 'binary/octet-stream',
    'list has right content type' );
isa_ok( $object->last_modified, 'DateTime', 'list has a last modified' );

# Testing some CDN features
$container->cdn_enable;
ok($container->cdn_uri, 'CDN HTTP URL');
ok($container->cdn_ssl_uri, 'CDN HTTPS URL');
ok($one->cdn_url, 'CDN HTTP URL for object');
ok($one->cdn_ssl_url, 'CDN HTTPS URL for object');

my $ua = LWP::UserAgent->new;
my $res = $ua->head($one->cdn_url);
ok($res->is_success, 'Requesting CDN HTTP URL');
my $h = $res->header('Access-Control-Allow-Origin');
is($h, '*', 'CORS header exists correctly');

#not purging in these tests because the $one->delete call will fail
#ok($one->purge_cdn, 'Purging CDN Object');

$one->delete;
throws_ok(
    sub { $one->get },
    qr/Object one.txt not found/,
    'got 404 when getting one.txt'
);
throws_ok(
    sub { $one->get_filename($filename) },
    qr/Object one.txt not found/,
    'got 404 when get_filenameing one.txt'
);
throws_ok(
    sub { $one->delete },
    qr/Object one.txt not found/,
    'got 404 when deleting one.txt'
);

my $two
    = $container->object( name => 'two.txt', content_type => 'text/plain' );
$two->put_filename('t/one.txt');

my $another_two = $container->object( name => 'two.txt', cache_value => 1);
is( $another_two->get,  'this is one', 'got content for two.txt' );
is( $another_two->size, 11,            'got size for two.txt' );
is( $another_two->etag,
    '855a8e4678542fd944455ee350fa8147',
    'got etag for two.txt'
);
is( $another_two->content_type, 'text/plain',
    'got content_type for two.txt' );
isa_ok( $another_two->last_modified, 'DateTime',
    'got last_modified for two.txt' );

## change the value in CloudFiles, but don't let our $another_two object 
## know about it.
my $value_changer = $container->object( name => 'two.txt' );
is ($value_changer->get, 'this is one', 're-retrieved content for two.txt');
$value_changer->put("this is two");

is( $another_two->get,  'this is one', 'got cached content for two.txt' );
is( $another_two->get(1), 'this is two', 'forced retrieval of two.txt');  

## set the value back to what it was originally.
$value_changer->put("this is one");


my $and_another_two = $container->object( name => 'two.txt' );
$and_another_two->head;
is( $and_another_two->size, 11, 'got size for two.txt' );
is( $and_another_two->etag,
    '855a8e4678542fd944455ee350fa8147',
    'got etag for two.txt'
);

is( $and_another_two->content_type,
    'text/plain', 'got content_type for two.txt' );
isa_ok( $and_another_two->last_modified,
    'DateTime', 'got last_modified for two.txt' );

@objects = $container->objects->all;
is( @objects, 1, 'listing one object' );
$object = $objects[0];
is( $object->name, 'two.txt', 'list has right name' );
is( $object->etag, '855a8e4678542fd944455ee350fa8147',
    'list has right etag' );
is( $object->size,         '11',         'list has right size' );
is( $object->content_type, 'text/plain', 'list has right content type' );
isa_ok( $object->last_modified, 'DateTime', 'list has a last modified' );

$another_two->delete;

#not purging in these tests because the $container->delete call would fail
#ok($container->purge_cdn, 'Purging CDN Container');
$container->delete;

done_testing();
