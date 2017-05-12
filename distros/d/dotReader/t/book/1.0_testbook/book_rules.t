#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

use constant {D => 0};

use XML::Parser::Expat;
use Test::More (
  'no_plan'
  );

BEGIN { use_ok('dtRdr::Book::ThoutBook_1_0_jar') };

my $test_book = 'test_packages/0_jars/thout1_test.jar';
(-e $test_book) or die "missing '$test_book' file!";

my $book = dtRdr::Book::ThoutBook_1_0_jar->new();
ok($book, 'constructor');
ok($book->load_uri($test_book), 'load');

D and diag('running node rules test');
{
  D and diag('testing get_content_by_id');
  my $id = 'render_false';
  my $content = eval { $book->get_content_by_id($id); };
  ok(! $@, 'still alive');
  ok($content, 'got some content');
  like($content, qr/This is the first child node/, 'get_content_by_id');
  # is valid?
  eval { XML::Parser::Expat->new()->parse($content) };
  ok(! $@, 'xml parses') or warn("error " . join(" ", split(/[\n\r]+/, $@)));
}

{
  D and diag('testing render children=false');
  my $id = 'renderchildren_false';
  my $content = eval { $book->get_content_by_id($id); };
  ok($content, 'got some content');
  #print "[$content]";
  like($content, qr/This nodes children should not be rendered when clicking on this node/, 'check node content');
  unlike($content, qr/this is the content for render_children_false_child_1/, 'check child 1 was ommited');
  unlike($content, qr/this is the content for render_children_false_child_2/, 'check child 2 was ommited');
  # is valid?
  eval { XML::Parser::Expat->new()->parse($content) };
  ok(! $@, 'xml parses') or warn("error " . join(" ", split(/[\n\r]+/, $@)));
}

{

  D and diag('testing render=false');

  my $id = 'render_false';
  my $content = eval { $book->get_content_by_id($id); };
  ok($content, 'got some content');
  #print "[$content]";
  unlike($content, qr/This text should not appear because it is in a render = false node/, 'check render=false');
  # is valid?
  eval { XML::Parser::Expat->new()->parse($content) };
  ok(! $@, 'xml parses') or warn("error " . join(" ", split(/[\n\r]+/, $@)));
}

{
  D and diag('testing showpage');
  my $id = 'showpage_about';
  my $content = eval { $book->get_content_by_id($id); };
  ok($content, 'got some content');
  #print "[$content]";
  unlike($content, qr/This text should not show up when you click the showpage/, 'check that this node doesn\'t render');
  like($content, qr/About this document/, 'check that about node does render');
  # is valid?
  eval { XML::Parser::Expat->new()->parse($content) };
  ok(! $@, 'xml parses') or warn("error " . join(" ", split(/[\n\r]+/, $@)));
}
  
{
  D and diag('testing code copy nodes');
  my $id = 'samscodecopytest';
  my $content = eval { $book->get_content_by_id($id); };
  ok($content, 'got some content');
 # is valid?
  eval { XML::Parser::Expat->new()->parse($content) };
  ok(! $@, 'xml parses') or warn("error " . join(" ", split(/[\n\r]+/, $@)));
}
# TODO: {
#   local $TODO = "advanced test GUI - not implemented yet";
#   {
#     D and diag('TODO testing visible="false"');
#   }
#     
#   {
#     D and diag('TODO testing TOC Icons');
#   }
#     
#   {
#     D and diag('TODO testing copy="true"');
#   }
#     
#   {
#     D and diag('TODO testing document encoding');
#   }
# }
