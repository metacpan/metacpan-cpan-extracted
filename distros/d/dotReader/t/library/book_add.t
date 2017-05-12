#!/usr/bin/perl


use Test::More 'no_plan';
use File::Path qw(rmtree);

use strict;
use warnings;

BEGIN {use_ok('dtRdr::Library::YAMLLibrary')};
BEGIN {use_ok('dtRdr::Book::ThoutBook_1_0')};
BEGIN {use_ok('dtRdr::Book::ThoutBook_1_0_jar')};

my $LIBLOC = 't/library/';
my $LIBFILE = $LIBLOC . $$ . 'testlib.yml';

# Toss the test library if it exists
unlink $LIBFILE if (-e $LIBFILE);

dtRdr::Library::YAMLLibrary->create($LIBFILE);
my $library = dtRdr::Library::YAMLLibrary->new();
$library->load_uri($LIBFILE);
ok($library, 'constructor');
my @books = $library->get_book_info();
is(scalar(@books), 0);
my $sdir = 'test_store';
my $sdirpath = $LIBLOC . '/' . $sdir;
if(-e $sdirpath) {
  rmtree($sdirpath) or die "cannot clear $sdirpath";
}
eval {
  $library->set_storage($sdir);
};
ok($@, 'smack');
mkdir($sdirpath) or die "ack $!";
eval {
  $library->set_storage($sdir);
};
ok(! $@, 'not smack') or warn "$@";

# open book
my $book0 = dtRdr::Book::ThoutBook_1_0->new;
$book0->load_uri('test_packages/indexing_check/book.xml');
# add
$book0->add_to_library($library);

# just in case
$book0->toc_is_cached and
  die "that book should not have a cached toc";

{
  my @books = $library->get_book_info();
  is(scalar(@books), 1);
  my $b = $books[0];
  is($b->intid, 0);
  is($b->book_id, $book0->id,  'book_id');
  is($b->title, $book0->title, 'title');
  my $lib_again = dtRdr::Library::YAMLLibrary->new();
  $lib_again->load_uri($LIBFILE);
  my @rebooks = $lib_again->get_book_info;
  is(scalar(@rebooks), 1);
  is($rebooks[0]->book_id, $book0->id, 're-book_id');
}
ok(-e "$sdirpath/indexing_check/toc_data.toc", 'cache');
ok(-e "$sdirpath/indexing_check/toc_data.toc.stb", 'cache');

{
  my $lib_again = dtRdr::Library::YAMLLibrary->new();
  $lib_again->load_uri($LIBFILE);
  my $rebook = $lib_again->open_book(intid => 0);
  ok($rebook);
  is($rebook->id, $book0->id);
  ok($rebook->toc_is_cached, 'cache loaded');

}

my $book1 = dtRdr::Book::ThoutBook_1_0_jar->new;
$book1->load_uri('test_packages/0_jars/indexing_check.jar');
$book1->toc_is_cached and
  die "that book should not have a cached toc";
$book1->add_to_library($library);
{
  my @books = $library->get_book_info();
  is(scalar(@books), 2);
  my $b = $books[1];
  is($b->intid, 1);
  is($b->book_id, $book1->id,  'book_id');
  is($b->title, $book1->title, 'title');
  my $lib_again = dtRdr::Library::YAMLLibrary->new();
  $lib_again->load_uri($LIBFILE);
  my @rebooks = $lib_again->get_book_info;
  is(scalar(@rebooks), 2);
  is($rebooks[1]->book_id, $book0->id, 're-book_id');
}
{
  my $lib_again = dtRdr::Library::YAMLLibrary->new();
  $lib_again->load_uri($LIBFILE);
  my $rebook = $lib_again->open_book(intid => 1);
  ok($rebook);
  is($rebook->id, $book1->id);
  ok($rebook->toc_is_cached, 'cache loaded');

}

unlink $LIBFILE if (-e $LIBFILE);

# vim:ts=2:sw=2:et:sta
