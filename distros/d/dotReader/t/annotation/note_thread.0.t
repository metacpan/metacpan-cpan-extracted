#!/usr/bin/perl

use strict;
use warnings;

use inc::testplan(1,
  2 + # use_ok
  3 + # ABook
  11 * 5 * 5
);
use lib 'inc';
use dtRdrTestUtil::ABook;

BEGIN {use_ok('dtRdr::Note');}
BEGIN {use_ok('dtRdr::NoteThread');}

my $book = ABook_new_1_0('test_packages/t1.short/book.xml');
my $node = $book->find_toc('page1');

sub pathify {
  my $string = shift;
  return(map({s/^ *//;
    (length($_) ? [split(/ +/, $_)] : ())
    } split(/\n/, $string)));
}
sub note {
  my (@path) = @_;

  my $id = pop(@path);
  my $nt = dtRdr::Note->create(
    id => $id,
    node => $node,
    range => [undef, undef], # no position
    title => lc($id),
    content => "this is note '$id'",
    (@path ? (references => [reverse(@path)]) : ()),
  );

}

=for aside
perl -e 'srand;
  for(0..9) {
    print "[", join(",",
      sort({rand() < 0.5} eval($ARGV[0]))), "],\n";
  }'
0..9

=cut

sub tree_test {
  my %args = @_;
  my @paths = @{$args{paths}};
  my @random = @{$args{random}};
  my $check = $args{check};

  my @orders = ([0..$#paths], @random);

  #die join("\n", map({">" . join(",", @$_)} @paths));
  my @notes = map({note(@$_)} @paths);

  # get id's for missing parents too
  my %unique = map({$_ => 1} map({@$_} @paths));
  my @id_list = sort(keys(%unique));
  foreach my $order (@orders) {
    #warn join(",", map({$_->id} @notes[@$order]));
    my (@trees) = eval {
      dtRdr::NoteThread->create(@notes[@$order])
    };
    ok(! $@, 'survived');
    $check->(@trees);

    my @got_list = sort(map({$_->rmap(sub {$_[0]->id})} @trees));

    is_deeply(\@got_list, \@id_list, 'got them all');
    $_->DESTROY for(@trees);
  }
} # end sub tree_test

my $check_A = sub {
  my ($tree, @else) = @_;
  ok($tree, 'got a tree');
  is(scalar(@else), 0, 'one tree');
  is($tree->id, 'A', 'got root');
};
tree_test( # complete tree
  paths => [pathify("
    A
    A AA
    A AA AAA
    A AA AAA AAAA
    A AA AAA AAAA AAAAA
    A AA AAA AAAA AAAAA AAAAAA
    A AA AAA AAAB
    A AA AAA AAAB AAABA
    A AA AAA AAAB AAABB
    A AA AAA AAAC
  ")],
  random => [
    [1,0,2,3,4,5,7,6,8,9],
    [9,8,5,6,7,1,4,0,3,2],
    [4,1,0,2,3,5,9,8,7,6],
    [7,6,9,1,8,0,3,2,4,5],
    [8,4,9,6,5,2,3,1,0,7],
    [9,8,4,1,5,0,3,2,6,7],
    [4,5,2,1,3,0,7,6,9,8],
    [2,1,0,3,5,4,9,6,7,8],
    [4,5,2,1,0,3,7,6,8,9],
    [5,4,0,1,2,3,6,7,8,9],
  ],
  check => $check_A,
);

tree_test( # now with some missing
  paths => [pathify("
    A
    A AA AAA AAAA AAAAA
    A AA AAA AAAA AAAAA AAAAAA
    A AA AAA AAAB AAABA
    A AA AAA AAAB AAABB
    A AA AAA AAAC
  ")],
  random => [
    [4,5,2,0,3,1],
    [5,0,1,3,2,4],
    [3,2,1,0,5,4],
    [4,1,5,0,2,3],
    [5,4,2,3,1,0],
    [4,5,3,2,0,1],
    [4,3,2,1,0,5],
    [3,2,1,0,4,5],
    [0,1,3,2,4,5],
    [4,5,0,1,3,2],
  ],
  check => $check_A,
);
tree_test( # and without root
  paths => [pathify("
    A AA
    A AA AAA
    A AA AAA AAAA
    A AA AAA AAAA AAAAA
    A AA AAA AAAA AAAAA AAAAAA
    A AA AAA AAAB
    A AA AAA AAAB AAABA
    A AA AAA AAAB AAABB
    A AA AAA AAAC
  ")],
  random => [
    [1,0,2,3,4,5,7,6,8],
    [8,5,6,7,1,4,0,3,2],
    [4,1,0,2,3,5,8,7,6],
    [7,6,1,8,0,3,2,4,5],
    [8,4,6,5,2,3,1,0,7],
    [8,4,1,5,0,3,2,6,7],
    [4,5,2,1,3,0,7,6,8],
    [2,1,0,3,5,4,6,7,8],
    [4,5,2,1,0,3,7,6,8],
    [5,4,0,1,2,3,6,7,8],
  ],
  check => $check_A,
);
tree_test( # and without first parent
  paths => [pathify("
    A
    A AA AAA
    A AA AAA AAAA
    A AA AAA AAAA AAAAA
    A AA AAA AAAA AAAAA AAAAAA
    A AA AAA AAAB
    A AA AAA AAAB AAABA
    A AA AAA AAAB AAABB
    A AA AAA AAAC
  ")],
  random => [
    [1,0,2,3,4,5,7,6,8],
    [8,5,6,7,1,4,0,3,2],
    [4,1,0,2,3,5,8,7,6],
    [7,6,1,8,0,3,2,4,5],
    [8,4,6,5,2,3,1,0,7],
    [8,4,1,5,0,3,2,6,7],
    [4,5,2,1,3,0,7,6,8],
    [2,1,0,3,5,4,6,7,8],
    [4,5,2,1,0,3,7,6,8],
    [5,4,0,1,2,3,6,7,8],
  ],
  check => $check_A,
);
tree_test( # and without any parents
  paths => [pathify("
    A AA AAA AAAA AAAAA AAAAAA
    A AA AAA AAAB AAABA
    A AA AAA AAAB AAABB
    A AA AAA AAAC
  ")],
  random => [
    [0,1,3,2],
    [1,0,2,3],
    [1,0,3,2],
    [2,0,3,1],
    [2,1,0,3],
    [2,3,0,1],
    [2,3,1,0],
    [3,0,1,2],
    [3,0,2,1],
    [3,2,0,1],
  ],
  check => $check_A,
);


# vim:ts=2:sw=2:et:sta
