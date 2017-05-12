# test with readonly values in T::B::ok()'s @_

use strict;
use warnings;

use Test::Builder;
use Test::Builder::Tester tests => 1;

use Test::NameNote;

test_out(
  "ok 1 - true (note)",
  "ok 2 - note",
  "ok 3 - bare",
);

my $note = Test::NameNote->new('note');

my $T = Test::Builder->new;

$T->ok(1, "true");
$T->ok(1);

undef $note;

$T->ok(1, "bare");

test_test();

