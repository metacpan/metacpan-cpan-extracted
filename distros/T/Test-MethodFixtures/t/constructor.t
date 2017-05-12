use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::MethodFixtures;
use TestMethodFixtures::Dummy;
use Path::Tiny qw( path );

my $pkg = 'Test::MethodFixtures::Storage::File';

eval "require $pkg";

my $skip_storage_file = $@ ? 1 : 0;

my $class = 'Test::MethodFixtures';
my $new_dir = path('t/.methodfixtures/tmp');
END { $new_dir->remove_tree if $new_dir->is_dir }

subtest with_no_args => sub {
SKIP: {
        skip "Skipping - can't use $pkg", 5 if $skip_storage_file;

        ok my $obj = $class->new(), "new with no args";
        is $obj->mode, 'playback', 'default mode is playback';
        ok my $storage = $obj->storage, "got storage attribtue";
        isa_ok $storage, 'Test::MethodFixtures::Storage::File';
        is $storage->dir, 't/.methodfixtures', 'default directory ok';
    }
};

subtest with_dir => sub {
SKIP: {
        skip "Skipping - can't use $pkg", 5 if $skip_storage_file;

        $new_dir->mkpath;

        ok my $obj = $class->new( { dir => $new_dir } ),
            "override default directory";
        is $obj->mode, 'playback', 'default mode is playback';
        ok my $storage = $obj->storage, "got storage attribtue";
        isa_ok $storage, 'Test::MethodFixtures::Storage::File';
        is $storage->dir, $new_dir, 'overridden default directory ok';
    }
};

subtest with_new_class => sub {

    ok my $obj = $class->new( { storage => '+TestMethodFixtures::Dummy' } ),
        "new with storage class";
    is $obj->mode, 'playback', 'default mode is playback';
    ok my $storage = $obj->storage, "got storage attribtue";
    isa_ok $storage, 'TestMethodFixtures::Dummy';

};

subtest with_new_object => sub {
    ok my $obj
        = Test::MethodFixtures->new(
        { storage => TestMethodFixtures::Dummy->new() } ),
        "new with storage object";
    is $obj->mode, 'playback', 'default mode is playback';
    ok my $storage = $obj->storage, "got storage attribtue";
    isa_ok $storage, 'TestMethodFixtures::Dummy';

};

done_testing();

