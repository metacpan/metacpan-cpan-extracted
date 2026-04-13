#!perl
use strict;
use warnings;
use Test::More import => [ qw( done_testing is isa_ok subtest ) ];
use lib 'lib', 't/lib';

use Test::Bugzilla;
use WebService::Bugzilla::Attachment;

my $bz = Test::Bugzilla->new(
    base_url => 'http://bugzilla.example.com/rest',
    api_key  => 'abc',
);

subtest 'Get attachment' => sub {
    my $attachment = $bz->attachment->get(9);
    isa_ok($attachment, 'WebService::Bugzilla::Attachment', 'get attachment returns attachment object');
    is($attachment->filename, 'readme.md', 'attachment filename is correct');
};

subtest 'Search attachments' => sub {
    my $bug_attachments = $bz->attachment->search(bug_id => 123);
    isa_ok($bug_attachments, 'ARRAY', 'search returns arrayref');
    is(scalar @{ $bug_attachments }, 1, 'one attachment returned');
    isa_ok($bug_attachments->[0], 'WebService::Bugzilla::Attachment', 'first element is attachment object');
};

subtest 'Create attachment' => sub {
    my $new_attachment = $bz->attachment->create(123, data => 'content', name => 'test.txt');
    isa_ok($new_attachment, 'WebService::Bugzilla::Attachment', 'create returns attachment object');
    is($new_attachment->id, 456, 'new attachment id is correct');
    is($new_attachment->bug_id, 123, 'new attachment bug_id is correct');
};

subtest 'Update attachment' => sub {
    my $updated_attachment = $bz->attachment->update(9, description => 'new desc');
    isa_ok($updated_attachment, 'WebService::Bugzilla::Attachment', 'update returns attachment object');
    is($updated_attachment->id, 9, 'updated attachment id is preserved');
};

subtest 'Update attachment via instance method' => sub {
    my $attachment = $bz->attachment->get(9);
    my $inst_updated_attachment = $attachment->update(description => 'updated again');
    isa_ok($inst_updated_attachment, 'WebService::Bugzilla::Attachment', 'instance update returns attachment object');
};

done_testing();
