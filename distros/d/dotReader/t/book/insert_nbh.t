#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta

# unit-test our way through the Notes, Bookmarks, Highlights insertion

use strict;
use warnings;

=for TODO

Test cases that we need for point and span annotations.

(some of these might belong in find.t)

  x highlight at the beginning of a node
  x highlight within a node
  o note/bookmark within a node
  o copy=true popup link

  o children
    o create
      o note/bookmark made within child of visible node

      o highlight within child of visible node
      o highlight entering ...
      o highlight spanning ...
      o highlight leaving ...

      o highlight leaving one child entering another

    o insert
      o copy=true popup link in child of visible node

  o showpage
    o note/bookmark within showpage node

    o highlight within showpage node
    o highlight entering showpage node
    o highlight spanning showpage node
    o highlight leaving showpage node


=end TODO

=cut

use Test::More;
my $test_book;
BEGIN {
  $test_book = 'books/test_packages/QuickStartGuide.jar';
  unless(-e $test_book) {
    plan skip_all => 'extra books/ dir not available';
  }
  else {
    plan 'no_plan';
  }
}

use XML::Parser::Expat;

BEGIN { use_ok('dtRdr::Book::ThoutBook_1_0_jar') };
BEGIN { use_ok('dtRdr::Highlight') };

local $SIG{__WARN__};

my $book = dtRdr::Book::ThoutBook_1_0_jar->new();
ok($book, 'constructor');
ok($book->load_uri($test_book), 'load');

# setup the data
my $node = ($book->toc->children)[1];
ok($node, 'got node');
ok($node->get_title eq 'INTRODUCTION', 'title check');

# this does it all, but maybe we need to step-through it
my $content = $book->get_content($node);
ok($content, 'got node content');

# look for cache data
my $chars = eval { $book->get_cache_chars($node) };
ok(!$@, 'alive') or warn "eek '$@'";
ok($chars);

my $hl_id1;
# now add some stuff
{
  # these numbers have to be updated if we change the convention
  # (we better not change the convention once we have numbers in the field.)
  my ($rs, $re) = (17,58);

  my $highlight = dtRdr::Highlight->create(node => $node, range => [$rs, $re]);
  $hl_id1 = $highlight->id;
  $book->add_highlight($highlight);
  my $content = $book->get_content($node);

  # dump to file to debug
  if(0 or $ENV{D1}) { open(my $f, '>', '/tmp/thecontent'); print $f $content; }

  # and check the content for highlight tags
  ok($content, 'got content');
  ok($content =~ m/<span/, 'has a span');
  eval { XML::Parser::Expat->new()->parse($content) };
  ok(! $@, 'xml parses') or diag("error " . join(" ", split(/[\n\r]+/, $@)));

  # make $content smaller for diagnosibility
  $content =~ s/.*<body>//s or die;
  $content =~ s/cross-platform +multi-document +help +system.*//s or die;
  like($content, qr/<span class="[^"]*">ThoutReader.*TM.*is\s+an open source \(GPL 2.0\)<\/span/);

  # checking this one in reverse
  my $lwing = "INTRODUCTION The ";
  my $string = "ThoutReaderTM is an open source (GPL 2.0)";
  my $rwing = " cross-platform multi-document help system";
  my $range = eval {$book->locate_string($node, $string, $lwing, $rwing); };
  ok(! $@, 'still alive');
  isa_ok($range, 'dtRdr::Range');
  is($range->a, $rs);
  is($range->b, $re);
}

# try a round-trip find/insert/check
{
  diag("round-trip check");
  # search for:
  my $lwing  = "an open source (GPL 2.0) cross-platform multi-document " .
               "help system (written in Java) that ";
  my $string = "organizes new and existing content";
  my $rwing  = ". Developers can browse, search, bookmark, and append " .
               "a library of their favorite reference documentation";

  # feed it a node, string, and two wings
  my $range = eval {$book->locate_string($node, $string, $lwing, $rwing); };
  ok(! $@, 'still alive');
  # make sure it comes up with the right location
  isa_ok($range, 'dtRdr::Range');
  my $highlight = dtRdr::Highlight->create(node => $node, range => $range);
  isa_ok($highlight, 'dtRdr::Highlight');
  $book->add_highlight($highlight);
  my $content = $book->get_content($node);
  # dump to file to debug
  if(0 or $ENV{D2}) { open(my $f, '>', '/tmp/thecontent'); print $f $content; }
  # make $content smaller for diagnosibility
  $content =~ s/.*$hl_id1//s or die;
  $content =~ s/To +get +the +most +out +of.*//s or die;
  like($content, qr/<span class="[^"]*">organizes new and existing content<\/span/);
}
{
  diag("end-of-node check");
  # search for:
  my $lwing  = "Use OSoft's high site traffic to distribute your content. ";
  my $string = 'Contact us at author@osoft.com';
  my $rwing  = ' ';

  # feed it a node, string, and two wings
  my $range = eval {$book->locate_string($node, $string, $lwing, $rwing); };
  ok(! $@, 'still alive');
  # make sure it comes up with the right location
  isa_ok($range, 'dtRdr::Range');
  my $highlight = dtRdr::Highlight->claim($range);
  isa_ok($highlight, 'dtRdr::Highlight');
  is($highlight->node->id, 14, 'the expected node');

  my $hl_id = $highlight->id;

  $book->add_highlight($highlight);
  my $content = $book->get_content($node);
  # dump to file to debug
  if(0 or $ENV{D3}) { open(my $f, '>:utf8', '/tmp/thecontent'); print $f $content; }
  # make $content smaller for diagnosibility
  $content =~ s/.*traffic to distribute your content. //s or die;
  like($content, qr/<span class="[^"]*">Contact us at .*\.com.*<\/span/);
}
