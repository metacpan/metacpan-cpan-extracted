#!/usr/bin/perl

use strict;
use warnings;

use inc::testplan(1,
    3  # use_ok
  + 1  # use ABook
  + 2  # ABook
  + 4  # misc
  + 4  # count
  + 1  # count
  + 4  # threads
  + 1  # not thread
  + 2  # ABook
  + 5  # reapply
);
use lib 'inc';
use dtRdrTestUtil::ABook;

BEGIN {use_ok('dtRdr::Note');}
BEGIN {use_ok('dtRdr::NoteThread');}
BEGIN { use_ok('dtRdr::Annotation::IO'); }

use File::Path qw(
  mkpath
  rmtree
);

my $storage_dir = 't/annotation/temp';
rmtree($storage_dir);
(-d $storage_dir) and die "oops -- cannot cleanup $storage_dir";
mkpath($storage_dir);
(-d $storage_dir) or die "oops -- cannot create $storage_dir";

sub note {
  my ($node, @path) = @_;

  my $id = pop(@path);
  my $nt = dtRdr::Note->create(
    id => $id,
    node => $node,
    range => [undef, undef], # no position
    title => lc($id),
    content => "this is note '$id'",
    (@path ? (references => [reverse(@path)]) : ()),
  );
  return($nt);
}

{ # big scope here
my $book = ABook_new_1_0('test_packages/t1.short/book.xml');
my $node = $book->find_toc('page1');
my $anno_io;
$anno_io = dtRdr::Annotation::IO->new(uri => $storage_dir);
ok($anno_io, 'constructor');
isa_ok($anno_io, 'dtRdr::Annotation::IO');
isa_ok($anno_io, 'dtRdr::Annotation::IO::YAML');
ok(! $anno_io->items_for($book), 'nothing there');

$anno_io->apply_to($book);
$book->add_note(my $note2 = note($node, qw(A AA AAA)));
is(scalar($anno_io->items_for($book)), 1, 'count');
$book->add_note(my $note3 = note($node, qw(A AA AAA AAAA)));
is(scalar($anno_io->items_for($book)), 2, 'count');
$book->add_note(my $note4 = note($node, qw(A AA AAA AAAB)));
is(scalar($anno_io->items_for($book)), 3, 'count');
$book->add_note(my $note1 = note($node, qw(A)));
is(scalar($anno_io->items_for($book)), 4, 'count');

# and a few that are totally unrelated
$book->add_note(my $note_q = note($node, qw(B)));
$book->add_note(my $note_r = note($node, qw(C)));
$book->add_note(my $note_r1 = note($node, qw(C CC)));
is(scalar($anno_io->items_for($book)), 7, 'count');

{ # check the thread builder
  my $check = $book->note_thread($note1);
  isa_ok($check, 'dtRdr::NoteThread');
  my @got = sort($check->rmap(
    sub {my ($n) = @_; $n->id . ($n->is_dummy ? '.d' : '')}
  ));
  is_deeply([@got], [qw(A AA.d AAA AAAA AAAB)], 'threaded correctly');
}
{ # again from non-root
  my $check = $book->note_thread($note4);
  isa_ok($check, 'dtRdr::NoteThread');
  my @got = sort($check->rmap(
    sub {my ($n) = @_; $n->id . ($n->is_dummy ? '.d' : '')}
  ));
  is_deeply([@got], [qw(A AA.d AAA AAAA AAAB)], 'threaded correctly');
}
{ # and with not a thread
  my $check = $book->note_thread($note_q);
  isa_ok($check, 'dtRdr::Note');
}

# cleanup the unrelated stuff
$book->delete_note($_) for($note_q, $note_r, $note_r1);

} # end big scope
{ # big scope here
# start again with on-disk checks
my $book = ABook_new_1_0('test_packages/t1.short/book.xml');
my $node = $book->find_toc('page1');
my $anno_io;
$anno_io = dtRdr::Annotation::IO->new(uri => $storage_dir);
ok($anno_io, 'constructor');
isa_ok($anno_io, 'dtRdr::Annotation::IO');
isa_ok($anno_io, 'dtRdr::Annotation::IO::YAML');
is(scalar($anno_io->items_for($book)), 4, 'got some files now');
eval { $anno_io->apply_to($book); };
ok(! $@, 'survived application') or die $@, ' ';

} # end big scope

# cleanup after ourselves
rmtree($storage_dir) unless(@ARGV);

# vim:ts=2:sw=2:et:sta
