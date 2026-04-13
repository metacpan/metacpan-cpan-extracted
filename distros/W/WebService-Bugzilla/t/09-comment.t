#!perl
use strict;
use warnings;
use Test::More import => [ qw( done_testing is isa_ok subtest ) ];
use lib 'lib', 't/lib';

use Test::Bugzilla;
use WebService::Bugzilla::Comment;
use WebService::Bugzilla::UserDetail;

my $bz = Test::Bugzilla->new(
    base_url => 'http://bugzilla.example.com/rest',
    api_key  => 'abc',
);

subtest 'Get comments by bug ID' => sub {
    my $comments = $bz->comment->get(123);
    isa_ok($comments, 'ARRAY', 'get comments returns arrayref');
    is(scalar @{$comments}, 1, 'one comment returned');
    isa_ok($comments->[0], 'WebService::Bugzilla::Comment', 'first element is Comment object');
    is($comments->[0]->bug_id, 123, 'comment bug_id mapped correctly');
    is($comments->[0]->text, 'Hello', 'comment text is correct');
};

subtest 'Get comment by ID' => sub {
    my $comment = $bz->comment->get_by_id(77);
    isa_ok($comment, 'WebService::Bugzilla::Comment', 'get_by_id returns Comment object');
    is($comment->id, 77, 'comment id is correct');
};

subtest 'Create comment' => sub {
    my $new_comment = $bz->comment->create(123, comment => 'A new comment');
    isa_ok($new_comment, 'WebService::Bugzilla::Comment', 'create returns Comment object');
    is($new_comment->id, 500, 'new comment id is correct');
    is($new_comment->bug_id, 123, 'new comment bug_id is correct');
};

subtest 'Get comment reactions' => sub {
    my $reactions = $bz->comment->get_reactions(77);
    isa_ok($reactions, 'HASH', 'get_reactions returns hashref');
    isa_ok($reactions->{'+1'}, 'ARRAY', 'reactions +1 is arrayref');
    isa_ok($reactions->{'+1'}[0], 'WebService::Bugzilla::UserDetail', 'reaction element is UserDetail');
    is($reactions->{'+1'}[0]->name, 'dev@example.com', 'reaction user name is correct');
};

subtest 'Get comment reactions via instance method' => sub {
    my $comment = $bz->comment->get_by_id(77);
    my $inst_reactions = $comment->get_reactions;
    isa_ok($inst_reactions, 'HASH', 'instance get_reactions returns hashref');
};

subtest 'Update comment reactions' => sub {
    my $upd_reactions = $bz->comment->update_reactions(77, add => ['+1']);
    isa_ok($upd_reactions, 'HASH', 'update_reactions returns hashref');
    isa_ok($upd_reactions->{'+1'}[0], 'WebService::Bugzilla::UserDetail', 'updated reaction is UserDetail');
};

subtest 'Search comment tags' => sub {
    my $tags = $bz->comment->search_tags('spa');
    isa_ok($tags, 'ARRAY', 'search_tags returns arrayref');
    is($tags->[0], 'spam', 'tag value correct');
};

subtest 'Update comment tags' => sub {
    my $upd_tags = $bz->comment->update_tags(77, add => ['spam']);
    isa_ok($upd_tags, 'ARRAY', 'update_tags returns arrayref');
};

subtest 'Render comment text' => sub {
    my $html = $bz->comment->render(text => 'Hello world', id => 123);
    is($html, '<p>Hello world</p>', 'render returns HTML paragraph');
};

subtest 'Render comment via instance method' => sub {
    my $comment = $bz->comment->get_by_id(77);
    my $inst_html = $comment->render;
    is($inst_html, '<p>Hello world</p>', 'instance render returns HTML paragraph');
};

done_testing();
