#!/usr/bin/perl

use strict;
use warnings;

########################################################################
# We could probably get away without freezing the time, but if a test
# happens just as the second rolls over, that would break.
my $time_on;
sub FREEZE_TIME { # click!
  my ($sub) = @_;
  my $time = $time_on = CORE::time;
  $sub->();
  $time_on = undef;
  return($time);
}
BEGIN { # yes, finally some way to slow time!
  *CORE::GLOBAL::time = sub {
    if($time_on) {
      return($time_on);
    }
    else {
      return(CORE::time());
    }
  };
} # end watchmaker bits
########################################################################

use inc::testplan(1,
  + 3      # use_ok
  + 3      # time
  + 5      # public
  + 3      # time
  + 4      # public
  + 17 * 2 # ...
  + 20     # notification checks
);

BEGIN { use_ok('dtRdr::Book::ThoutBook_1_0'); }
BEGIN { use_ok('dtRdr::Annotation::IO'); }
BEGIN { use_ok('dtRdr::Highlight') };

use test_inc::tempdir;

local $SIG{__WARN__};

my $storage_dir = wants 't/annotation/temp';

my $book_uri = 'test_packages/indexing_check/book.xml';
(-e $book_uri) or die "missing '$book_uri' ?!";

my $pub_data;
{ # big scope here

my $anno_io;
$anno_io = dtRdr::Annotation::IO->new(uri => $storage_dir);
ok($anno_io, 'constructor');
isa_ok($anno_io, 'dtRdr::Annotation::IO');
isa_ok($anno_io, 'dtRdr::Annotation::IO::YAML');

my $book = dtRdr::Book::ThoutBook_1_0->new();
ok($book, 'book');
isa_ok($book, 'dtRdr::Book');

$book->load_uri($book_uri);

ok(! $anno_io->items_for($book), 'nothing there');

$anno_io->apply_to($book);

my $toc = $book->toc;
{
  my $node = $toc->get_by_id('B');
  my $hl0 = dtRdr::Highlight->create(
    node => $node,
    range => [0, 1],
    id => 'foo'
    );
  ok(!defined($hl0->create_time), 'no create time yet');
  my $create_time = FREEZE_TIME(sub { $book->add_highlight($hl0); });
  is($hl0->create_time, $create_time, 'set creation time');
  ok(!defined($hl0->mod_time), 'no mod time');

  # check the make_public interface
  is($hl0->public, undef, 'no public attrib');
  $pub_data = $hl0->make_public(owner => 'bob', server => 'joe');
  ok($pub_data, 'made public');
  is($hl0->public, $pub_data);
  $book->change_highlight($hl0);
  {
    my $plain = $hl0->serialize;
    ok(exists($plain->{public}), 'serialized public attrib');
    is_deeply($plain->{public}, {%$pub_data});
  }

  # check the finger-wagging
  eval { $book->add_highlight($hl0) };
  ok($@, 'denied');
  like($@, qr/duped.*foo/, 'useful message');
}
is(scalar($anno_io->items_for($book)), 1, 'count');

# and a few for good measure
$book->add_highlight( dtRdr::Highlight->create(
    node => $toc->get_by_id('B'), range => [0, 3], id => 'bar'
));
is(scalar($anno_io->items_for($book)), 2, 'count');
$book->add_highlight( dtRdr::Highlight->create(
    node => $toc->get_by_id('D'), range => [0, 3], id => 'baz'
));
is(scalar($anno_io->items_for($book)), 3, 'count');
$book->add_highlight( dtRdr::Highlight->create(
    node => $toc->get_by_id('A'), range => [0, 5], id => 'bat'
));
is(scalar($anno_io->items_for($book)), 4, 'count');

} # end big scope


########################################################################
my $mod_time_wibble;
{ # big scope here
# start again with on-disk checks
my $book = dtRdr::Book::ThoutBook_1_0->new();
ok($book, 'book');
isa_ok($book, 'dtRdr::Book');

$book->load_uri($book_uri);

my $anno_io = dtRdr::Annotation::IO->new(uri => $storage_dir);
ok($anno_io, 'constructor');
isa_ok($anno_io, 'dtRdr::Annotation::IO');
isa_ok($anno_io, 'dtRdr::Annotation::IO::YAML');
is(scalar($anno_io->items_for($book)), 4, 'got some files now');

eval { $anno_io->apply_to($book); };
ok(! $@, 'survived application') or die $@, ' ';

{ # count them all again
  my $toc = $book->toc;
  is(scalar($book->local_highlights($toc->get_by_id('A'))), 1);
  is(scalar($book->local_highlights($toc->get_by_id('B'))), 2);
  is(scalar($book->local_highlights($toc->get_by_id('D'))), 1);
}

{ # mod one and run update
  my $toc = $book->toc;
  my ($hl) = $book->local_highlights($toc->get_by_id('A'));
  $hl->set_title("wibble");
  is($hl->title, 'wibble');
  $mod_time_wibble = FREEZE_TIME(sub {$anno_io->update($hl)});
  is($hl->revision, 1, 'revision');
}

{ # and delete another
  my $toc = $book->toc;
  my ($hl) = $book->local_highlights($toc->get_by_id('B'));
  $book->delete_highlight($hl);
}

} # end big scope

# once more to check update
{ # big scope here
# start again with on-disk checks
my $book = dtRdr::Book::ThoutBook_1_0->new();
ok($book, 'book');
isa_ok($book, 'dtRdr::Book');

$book->load_uri($book_uri);

my $anno_io = dtRdr::Annotation::IO->new(uri => $storage_dir);
ok($anno_io, 'constructor');
isa_ok($anno_io, 'dtRdr::Annotation::IO');
isa_ok($anno_io, 'dtRdr::Annotation::IO::YAML');
is(scalar($anno_io->items_for($book)), 3, 'got three files now');

eval { $anno_io->apply_to($book); };
ok(! $@, 'survived application');

{ # count them all again
  my $toc = $book->toc;
  is(scalar($book->local_highlights($toc->get_by_id('A'))), 1);
  { # check this guy
    my ($hl) = $book->local_highlights($toc->get_by_id('A'));
    is($hl->title, 'wibble', 'title mod');
    is($hl->mod_time, $mod_time_wibble, 'mod_time');
    is($hl->revision, 1, 'revision');
  }
  is(scalar($book->local_highlights($toc->get_by_id('B'))), 1);
  is(scalar($book->local_highlights($toc->get_by_id('D'))), 1);

  # and check the public deserialize
  {
    my $hl = $book->find_highlight('foo');
    ok($hl, 'found it');
    is($hl->id, 'foo');
    my $p = $hl->public;
    ok($p, 'got public attrib');
    is_deeply({$p ? (%$p) : ()}, {%$pub_data}, 'match');
  }
}
} # end big scope

{ # check callbacks wrt internal updates
  my $book = dtRdr::Book::ThoutBook_1_0->new();
  ok($book, 'book');
  isa_ok($book, 'dtRdr::Book');

  $book->load_uri($book_uri);

  my $anno_io = dtRdr::Annotation::IO->new(uri => $storage_dir);
  ok($anno_io, 'constructor');
  isa_ok($anno_io, 'dtRdr::Annotation::IO');
  isa_ok($anno_io, 'dtRdr::Annotation::IO::YAML');
  my @items = $anno_io->items_for($book);
  is(scalar(@items), 3, 'three');

  eval { $anno_io->apply_to($book); };
  ok(! $@, 'survived application');

  # setup this bit
  my %hits;
  foreach my $event (qw(created changed deleted)) {
    $hits{$event} = 0;
    my $setter = 'set_annotation_' . $event . '_sub';
    dtRdr::Book->callback->$setter(sub {$hits{$event}++});
  }
  $anno_io->s_delete($items[0]->{id}, $book);
  is(scalar($anno_io->items_for($book)), 2);
  is($hits{deleted}, 1, "hit 'deleted' callback");

  { # make sure we don't get so far
    eval { $anno_io->s_delete($items[0]->{id}, $book)};
    my $err = $@;
    like($err, qr/cannot delete -- nothing/, 'complains');
    is($hits{deleted}, 1, "no more hits at 'deleted' callback");
  }

  $anno_io->s_update($items[1]->{id}, $items[1], $book);
  is($hits{changed}, 1, "hit 'changed' callback");
  $anno_io->s_update($items[1]->{id}, $items[1]);
  is($hits{changed}, 1, "no more hits to 'changed' callback");

  { # can't update what we don't have
    eval {$anno_io->s_update('thbbt', $items[1], $book)};
    my $err = $@;
    like($err, qr/cannot update -- nothing for thbbt/, 'complains');
    is($hits{changed}, 1, "no more hits to 'changed' callback");
  }

  $anno_io->s_insert($items[0]->{id}, $items[0], $book);
  is(scalar($anno_io->items_for($book)), 3);
  is($hits{created}, 1, "hit 'created' callback");

  { # can't insert what we do have
    eval {$anno_io->s_insert($items[1]->{id}, $items[1], $book)};
    my $err = $@;
    like($err, qr/duped/, 'complains');
    is($hits{created}, 1, "no more hits to 'created' callback");
  }
  is(scalar($anno_io->items_for($book)), 3);

} # end callback checks
# XXX no more tests unless you delete the callbacks

done;
# vim:ts=2:sw=2:et:sta:syntax=perl
