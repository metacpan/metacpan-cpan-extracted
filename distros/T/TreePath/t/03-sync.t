use utf8;
use strict;

#use open qw(:std :utf8);
use Test::More 'no_plan';
use lib 't/lib';

use Schema::TPathSync;


# test synchonization between dbix backend and treepath

my $schema = Schema::TPathSync->connect('t/conf/treewithsync.yml');
$schema->deploy;
$schema->_populate;


my $tp = $schema->treepath;
is ( $tp->count, 21, 'tree has 21 nodes');

my @pages    = $tp->search({source => 'Page'});
is(@pages, 11, "tree has 11 pages");
is( $schema->resultset('Page')->search()->count, 11, 'db has 11 pages');

my @comments = $tp->search({source => 'Comment'});
is(@comments, 8, "Tree 8 comments");
is( $schema->resultset('Comment')->search()->count, 8, 'db has 8 comments');

my @files = $tp->search({source => 'File'});
is(@files, 2, "Tree 2 files");
is( $schema->resultset('File')->search()->count, 2, 'db has 2 files');


my $new_page = $schema->resultset('Page')->create({ name => 'New Page', parent_id => 1 });

# treepath is synchronized
is ( $schema->treepath->count, 22, 'tree has 22 nodes');


# Update name of New Page
$new_page->name('NewName');
ok($new_page->update,'update rs (name => NewName)');
my $newname = $tp->search({source => 'Page', name => 'NewName'});
is($newname->{name}, 'NewName', 'node is updated');

# delete page new_page;
ok($new_page->delete, 'delete rs page (new_page)');
is ( $schema->treepath->count, 21, 'tree has 21 nodes');


ok( my $root_rs = $schema->resultset('Page')->search({name => '/' })->single,'search root in db');
ok( $root_rs->add_to_files({ file => "test.png" }), "Add a new root file");

ok( my $coeur_rs = $schema->resultset('Page')->search({name => '♥' })->single,'search ♥ in db');
ok( $coeur_rs->add_to_files({ file => "test.png" }), "Add same file to ♥");

#is ( $schema->treepath->count, 22, 'tree has 22 nodes');
#my $files = $tp->root->{files};
#is(scalar @$files, 3, 'root has 3 files');
