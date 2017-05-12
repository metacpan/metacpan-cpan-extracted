package test_inc::anno_io_verify;

use warnings;
use strict;
use Carp;

BEGIN { require Exporter; *import = \&Exporter::import; }

our @EXPORT = qw(
  anno_io_verify
);

use dtRdr::Annotation::IO;
use Test::More;

sub anno_io_verify {
  my ($s_storage_dir, $io, $server, $books) = @_;

  # always a fresh load of this to do the checks
  my $s_io = dtRdr::Annotation::IO->new(uri => $s_storage_dir);
  my %s_items = map({$_->{id} => $_} $s_io->items);

  # verify that those all have public->server correct, etc
  my @items = do {
    my %book_ok = map({$_ => 1} @$books);
    grep({$book_ok{$_->{book}}} $io->items);
  };
  is(scalar(@items), scalar(keys(%s_items)), 'count');

  foreach my $item (@items) {
    my $id = $item->{id};
    my $s_item = $s_items{$id};
    my $p = $item->{public};
    is($p->{server}, $server->id, 'server') or diag("$id -- bad server");
    is($p->{rev}, $item->{revision}, 'rev eq revision');
    is($p->{rev}, $s_item->{revision}, 'rev eq given revision');
    my $owner = $s_item->{public}{owner};
    $owner = undef if($owner eq $server->username);
    is($p->{owner}, $owner, "owner '$id'");
    foreach my $key (qw(book node type)) {
      is($item->{$key}, $s_item->{$key}, "check $key ($id)");
    }
    like($item->{type}, qr/^dtRdr::/, 'type is sane');

    # if it has start defined, assume it is a range and check a bunch of
    # other stuff
    if(defined($s_item->{start})) {
      foreach my $key (qw(start end)) {
        is($item->{$key}, $s_item->{$key}, "check $key ($id)");
      }
      foreach my $key (qw(context selected)) {
        is_deeply($item->{$key}, $s_item->{$key}, "check $key ($id)");
      }
    }
  }
}

1;
# vim:ts=2:sw=2:et:sta
