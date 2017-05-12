#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

use inc::testplan(1,
  2 + # use_ok
  2 + # open_book
  3 * 13 + # check_toc
  3 * 26   # note_test
);

BEGIN {use_ok('dtRdr::Book::ThoutBook_1_0') };
BEGIN {use_ok('dtRdr::Note');}

use lib 'inc';
use dtRdrTestUtil::Expect;

my $book = open_book(
  'dtRdr::Book::ThoutBook_1_0',
  'test_packages/anno_check_nopos.0/book.xml'
);

check_toc(['B'..'O']);

# pre-populate the cache
$book->get_node_characters($book->find_toc($_)) for('B'..'O');

sub nopos_note {
  my ($node_id) = @_;
  my $node = $book->find_toc($node_id);
  $node or die;
  my $nt = dtRdr::Note->create(
    id => $node_id,
    node => $node,
    range => [undef,undef]
  );
  $book->add_note($nt);
  return($nt);
}
sub check_note {
  my ($id, $expect, @others) = @_;
  #warn "check $id\n";
  my $nt = nopos_note($id);
  note_test($id, $expect);
  while(@others) {
    my $node = shift(@others);
    my $want = shift(@others);
    note_test($node, $want);
  }
  $book->delete_note($nt);
}

# a simple terminal node
check_note('B', 'B ');

# a node with nested children
check_note(
  'C', 'C D E ',
  'D', 'D E ',
  'E', 'E '
);
check_note(
  'D', 'D E ',
  'C', 'D E ',
  'E', 'E '
);
check_note(
  'L', 'L M N O ',
  'M', 'M N ',
  'N', 'N ',
  'O', 'O ',
);
check_note(
  'M', 'M N ',
  'L', 'M N ',
);
check_note(
  'N', 'N ',
  'M', 'N ',
  'L', 'N ',
);
check_note(
  'O', 'O ',
  'L', 'O ',
);

check_note('F', 'F ');

check_note(
  'G', 'G I K ',
  'I', 'I K ',
  'K', 'K ',
);

check_note(
  'I', 'I K ',
  'G', 'I K ',
  'K', 'K ',
);
# notes on a rc=0 node do not get done because the calculated word_end
# is way bigger than the actual number of characters in the node

# notes in child nodes need to get the endpoint right, which might be an
# issue if they have children that aren't rendered
