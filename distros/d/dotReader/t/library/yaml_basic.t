use strict;
use warnings;

use Test::More;

my @BOOKLOC;
BEGIN {
  @BOOKLOC = (
    'books/test_packages/FreeBSD_Developers_Handbook.jar',
    'test_packages/other/osoft_9Perl5.8manual_en.jar',
    'books/test_packages/FreeBSD_Developers_Handbook/' .
      'FreeBSDDevelopersHandbook.xml',
  );
  unless((-e $BOOKLOC[0]) and (-e $BOOKLOC[2])) {
    plan skip_all => 'extra books/ dir not available';
  }
  else {
    plan 'no_plan';
  }
}

BEGIN {use_ok('dtRdr::Library::YAMLLibrary')};

my $LIBLOC = 't/library/';
my $LIBFILE = $LIBLOC . $$ . 'testlib.yml';

# Toss the test library if it exists
unlink $LIBFILE if (-e $LIBFILE);

# TODO these id's are improper
my $BOOK1 = 'FreeBSD Developers\' Handbook';
my $BOOK2 = 'Perl 5.8 Documentation';
# we can have two copies of an id if they're a different title
my $BOOK3 = 'FreeBSD Developers\' Handbook';

# first run
{
  dtRdr::Library::YAMLLibrary->create($LIBFILE);
  my $library = dtRdr::Library::YAMLLibrary->new();
  $library->load_uri($LIBFILE);
  ok($library, 'constructor');

  isa_ok($library, 'dtRdr::Library');


  is($library->add_book(
    book_id => $BOOK1,
    title   => $BOOK1,
    uri   => '../../'.$BOOKLOC[0],
    type    => 'Thout_1_0_jar'
  ), 0);
  is($library->add_book(
    book_id    => $BOOK2,
    title => $BOOK2,
    uri   => '../../'.$BOOKLOC[1],
    type  => 'Thout_1_0_jar'
  ), 1);
  is($library->add_book(
    book_id    => $BOOK3,
    title => $BOOK3 . ' (unzipped)',
    uri   => '../../'.$BOOKLOC[2],
    type  => 'Thout_1_0'
  ), 2);
  ok(1, 'Added books');

  my @books = $library->get_book_info();
  ok(@books == 3, "Book info hashes");
  can_ok($_, 'title') for(@books);
  ok($books[0]->title   eq $BOOK1, "checked book info hash");
  ok($books[1]->title   eq $BOOK2, "checked book info hash");
  is($books[2]->intid, 2, "checked book info hash");
  ok($books[2]->book_id eq $BOOK3, "checked book info hash");
  ok($books[2]->title   eq $BOOK3 . ' (unzipped)', "checked book info hash");

  $library->set_name('test library');
  ok($library->name eq 'test library', 'name set');
  $library->set_id('42');
  is($library->id, '42', 'id set');
  eval {$library->set_id('something else')};
  ok($@, 'denied');
  like($@, qr/^the library's id is locked: '42'/, 'locked');

  undef($library);
}

# second run
{
my $library = dtRdr::Library::YAMLLibrary->new();
$library->load_uri($LIBFILE);
isa_ok($library, 'dtRdr::Library');
is($library->name, 'test library', 'name ok');
is($library->id, '42', 'id ok');
is($library->type, $library->LIBTYPE, 'type ok');

my @books = $library->get_book_info();
ok(@books == 3, 'book set');

my $book = $library->open_book(title => $BOOK1);
isa_ok($book, 'dtRdr::Book');
isa_ok($book, 'dtRdr::Book::ThoutBook_1_0_jar');

my (@toc) = $book->toc->children;
my $toc = $toc[0];
isa_ok($toc, 'dtRdr::TOC');
}
{
my $library = dtRdr::Library::YAMLLibrary->new();
$library->load_uri($LIBFILE);
isa_ok($library, 'dtRdr::Library');

my @books = $library->get_book_info();
ok(@books == 3, 'book set');

my $book = $library->open_book(title => $BOOK3 . ' (unzipped)');
isa_ok($book, 'dtRdr::Book');
isa_ok($book, 'dtRdr::Book::ThoutBook_1_0');

my (@toc) = $book->toc->children;
my $toc = $toc[0];
isa_ok($toc, 'dtRdr::TOC');
}

unlink $LIBFILE if (-e $LIBFILE);
# vim:ts=2:sw=2:et:sta
