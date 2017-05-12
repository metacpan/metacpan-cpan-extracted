#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

use inc::testplan(1,
  5    # use_ok
  + 2  # slaps
  + 2 + 3 + 4 # create/check
  + 6 # anno_io
  + 12 # finder
);

BEGIN {
  use_ok('dtRdr::Book') or die;
  use_ok('dtRdr::Highlight') or die;
  use_ok('dtRdr::Note') or die;
  use_ok('dtRdr::Bookmark') or die;
  use_ok('dtRdr::Annotation::IO') or die;
}

########################################################################
sub make_anno {
  my ($type, $book, $node, %also) = @_;
  $type = 'dtRdr::' . $type;
  return $type->create(
    node => $book->toc->get_by_id($node),
    range => [undef,undef],
    %also,
  );
}
########################################################################

my $id = 'xF0D8058ADB3911DB8F2B386E7806B258';

{
# check the strictures
eval {dtRdr::Book::Zombie->new};
ok($@, 'slap');
like($@, qr/must have id/);
}

{
# make the book
my $book = dtRdr::Book::Zombie->new(id => $id);
ok($book, 'create');
is($book->id, $id, 'id check');

my $hl = eval {make_anno('Highlight', $book, 'page1',
  range => [10, 15],
  id  => 'foo',
)};

ok($hl);
ok(eval {$book->add_highlight($hl)});
ok(eval {$book->delete_highlight($hl)});
my $hr = eval {$hl->serialize};
ok($hr);
is($hr->{book}, $id);
my $anno = eval{dtRdr::Highlight->deserialize($hr, book => $book)};
ok($anno);
is_deeply($anno->serialize, $hr);
}

########################################################################
# now try with anno_io
{

use test_inc::tempdir;
my $storage_dir = wants 't/book/temp';

my $book = dtRdr::Book::Zombie->new(id => $id);

my $anno_io = dtRdr::Annotation::IO->new(uri => $storage_dir);
$anno_io->apply_to($book);

my $hl1 = $book->add_highlight(make_anno('Highlight', $book, 'page1',
  range => [10, 15],
  id  => 'foo',
));
is(scalar($anno_io->items_for($book)), 1, 'count');

my $hl2 = $book->add_highlight(make_anno('Highlight', $book, 'page1',
  range => [16, 20],
));
is(scalar($anno_io->items_for($book)), 2, 'count');

my $nt1 = $book->add_note(make_anno('Note', $book, 'page1',
  content => 'a note on page1',
  title => 'the note',
  id => 'noteA',
));
is(scalar($anno_io->items_for($book)), 3, 'count');

my $nt2 = $book->add_note(make_anno('Note', $book, 'page1',
  content => 'I disagree with your note on page1',
  title => 'Re: the note',
  references => [$nt1->id, $nt1->references],
  id => 'noteAA',
));
is(scalar($anno_io->items_for($book)), 4, 'count');

my $nt3 = $book->add_note(make_anno('Note', $book, 'page1',
  content => 'I think bob was right.',
  title => 'Re: the note',
  references => [$nt2->id, $nt2->references],
  id => 'noteAAA',
));
is(scalar($anno_io->items_for($book)), 5, 'count');

my $nt4 = $book->add_note(make_anno('Note', $book, 'page1',
  content => 'I also think bob was right.',
  title => 'Re: the note',
  references => [$nt2->id, $nt2->references],
  id => 'noteAAB',
));
my @items = $anno_io->items_for($book);
is(scalar(@items), 6, 'count');
# check the finder deeper than root!
foreach my $type (qw(Note Highlight)) {
  my @list = map({$_->{id}}
    grep({$_->{type} eq "dtRdr::$type"} @items));
  my $method = 'find_' . lc($type);
  foreach my $id (@list) {
    my $hl = $book->$method($id);
    ok($hl, "found '$id'");
    is($hl->id, $id);
  }
}

} # end with anno_io

done;
