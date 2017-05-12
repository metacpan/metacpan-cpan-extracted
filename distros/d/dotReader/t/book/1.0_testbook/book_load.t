#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

use Test::More (
  'no_plan'
  );

BEGIN { use_ok('dtRdr::Book::ThoutBook_1_0_jar') };

my $test_book = 'test_packages/0_jars/thout1_test.jar';
(-e $test_book) or die "missing '$test_book' file!";

my $book = dtRdr::Book::ThoutBook_1_0_jar->new();
ok($book, 'constructor');
ok($book->load_uri($test_book), 'load');

my @nodes = split(/\n/, 
'0
about_desc
about_author
about_copyright
about_legal
about
level_3_node
level_2_node
level_1_node
1
pre
image_gif
image_png
links
leaf_icon_example
toc_icon_example
render_false_child_1
render_false_child_2
render_false
visible_false_child_1
visible_false_child_2
visible_false
renderchildren_false_child_1
renderchildren_false_child_2
renderchildren_false_child_3
showpage_about
renderchildren_false
node_attributes
advancedtopics_externallinks
2
copy_true
html_test
todo
root'
);

foreach my $id (@nodes) {
  my $content = eval { $book->get_content_by_id($id); };
  ok(!$@, "survived get for '$id'") or diag("error: $@");;
  ok($content, "there is content for '$id'");
}

