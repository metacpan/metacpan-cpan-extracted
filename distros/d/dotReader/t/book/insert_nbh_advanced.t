#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

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

use dtRdr::Logger;
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

my @highlights;
{
  my @hl_table = qw(
   17 58
   20 40
   21 30
   22 50
   18 35
  );
  my @to_highlight = map({[$hl_table[$_*2], $hl_table[$_*2+1]]} 0..($#hl_table/2));
  foreach my $pair (@to_highlight) {
    my $highlight = dtRdr::Highlight->create(node => $node, range => $pair);
    push(@highlights, $highlight);
    $book->add_highlight($highlight);
  }

  my $content = $book->get_content($node);

  if(0 or $ENV{D1}) { open(my $f, '>', '/tmp/thecontent'); print $f $content; }

  eval { XML::Parser::Expat->new()->parse($content) };
  ok(! $@, 'xml parses') or diag("error " . join(" ", split(/[\n\r]+/, $@)));

  # TODO check that tree for correctness
  my @tags = $content =~ m#(</?span[^>]*>)#g;
  0 and warn "\nfound ", join("\n  ", '', @tags), "\n";

  # How?  -- XML parse, an open-spans stack, and collect characters for open spans, right?
}
# now delete all of those highlights and start again
$book->delete_highlight($_) for @highlights;
@highlights = ();
{
  my @remain = $book->node_highlights($node);
  ok(!@remain, 'delete');
}
{
  warn "TODO: test more cases";
}
