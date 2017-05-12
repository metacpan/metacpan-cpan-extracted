#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

use Test::More (
  'no_plan'
  );

BEGIN { use_ok('dtRdr::Book::ThoutBook_1_0_jar');  }

my $test_book = 'test_packages/0_jars/thout1_test.jar';
(-e $test_book) or die "missing '$test_book' file!";

my $book = dtRdr::Book::ThoutBook_1_0_jar->new();
ok($book, 'constructor');
ok($book->load_uri($test_book), 'load');

my $toc = $book->toc;


{
  my $current_toc = $book->find_toc('root');
  ok($current_toc->id eq '0', 'root node yields first child');
  

  $current_toc = $book->next_node($current_toc);
  ok($current_toc->id eq 'about', 'next node = about?');
  #diag('page next - should give us the [about] node');

  $current_toc = $book->next_node($current_toc);
  ok($current_toc->id eq 'level_1_node', 'next node = level_1_node?');
  #diag('page next - Since about render children is true, we should get level_1_node');
  
  $current_toc = $book->prev_node($current_toc);
  ok($current_toc->id eq 'about_legal', 'prev node = about_legal?');
}

 #Test problem areas
{
  # prevpage is showpage
  my $current_toc = $book->find_toc('advancedtopics_externallinks');
  $current_toc = $book->prev_node($current_toc);
  ok($current_toc->id eq 'showpage_about', 'prev node showpage test');
}

{
  # nextpage is showpage
  my $current_toc = $book->find_toc('renderchildren_false_child_3');
  $current_toc = $book->next_node($current_toc);
  ok($current_toc->id eq 'showpage_about', 'next node showpage test');
}

TODO: {
  local $TODO = 'prev node with visible false';
  # showparent if visible="false"
  my $current_toc = $book->find_toc('codecopytest');
  $current_toc = $book->prev_node($current_toc);
  ok($current_toc->id eq 'copy_true', 'prev node visible false');
}
