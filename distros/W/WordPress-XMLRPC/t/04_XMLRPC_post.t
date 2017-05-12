use Test::Simple 'no_plan';
use strict;
use lib './lib';
require './t/test.pl';
use WordPress::XMLRPC;
no strict 'refs';

ok(1,'starting test.');

assure_fulltesting();




my $w = WordPress::XMLRPC->new(_conf('./t/wppost'));

### $w

my $publish = $w->publish;
### $publish
#





### POST

my $newPost = $w->newPost({title => 'test_test_1', description => 'bogus content' });
### $newPost
ok($newPost, "new post returns id $newPost");

my $editPost = $w->editPost($newPost, 
   { title => 'test_test_1', description => 'bogus content edited' });
### $editPost
ok( $editPost,'editPost succeeds');


my $getPost = $w->getPost($newPost);
## $getPost;

ok( ref $getPost eq 'HASH', 'getPost returns hash ref');


my $getRecentPosts = $w->getRecentPosts;
ok( ref $getRecentPosts eq 'ARRAY', 'getRecent Posts returns array ref');
## $getRecentPosts


my $deletePost = $w->deletePost($newPost);
### $deletePost
ok($deletePost,'deletePost()');




