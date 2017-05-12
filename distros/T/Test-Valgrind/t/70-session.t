#!perl

use strict;
use warnings;

BEGIN { delete $ENV{PATH} }

use Test::Valgrind::Session;

use Test::More tests => 7;

use lib 't/lib';
use Test::Valgrind::FakeValgrind;

my $sess = eval { Test::Valgrind::Session->new(
 search_dirs => [ ],
) };
like $@, qr/^Empty valgrind candidates list/, 'no search_dirs';

$sess = eval { Test::Valgrind::Session->new(
 valgrind => 'wut',
) };
like $@, qr/^No appropriate valgrind executable/, 'nonexistant valgrind';

SKIP: {
 my $old_vg = Test::Valgrind::FakeValgrind->new(
  version => '3.0.0',
 );
 skip $old_vg => 5 unless ref $old_vg;

 my $sess = eval { Test::Valgrind::Session->new(
  valgrind    => $old_vg->path,
  min_version => '3.1.0',
 ) };
 like $@, qr/^No appropriate valgrind executable/, 'old valgrind';

 my $new_vg = Test::Valgrind::FakeValgrind->new(
  version => '3.4.0',
 );
 skip $new_vg => 4 unless ref $new_vg;

 $sess = eval { Test::Valgrind::Session->new(
  valgrind    => $new_vg->path,
  min_version => '3.1.0',
 ) };
 is     $@,    '',                        'new valgrind';
 isa_ok $sess, 'Test::Valgrind::Session', 'new valgrind isa Test::Valgrind::Session';

 $sess = eval { Test::Valgrind::Session->new(
  search_dirs => [ ],
  valgrind    => [ $old_vg->path, $new_vg->path ],
  min_version => '3.1.0',
 ) };
 is     $@,    '',                        'old and new valgrind';
 isa_ok $sess, 'Test::Valgrind::Session', 'old and new valgrind isa Test::Valgrind::Session';
}
