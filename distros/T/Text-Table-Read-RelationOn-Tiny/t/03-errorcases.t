use 5.010_001;
use strict;
use warnings;

use Test::More;

use Text::Table::Read::RelationOn::Tiny;

use constant RELATION_ON => "Text::Table::Read::RelationOn::Tiny"; # to make calls shorter.

sub err_like(&$);
#use constant TEST_DIR => catdir(dirname(__FILE__), 'test-data');

{
  note("Constructor args");
  err_like {RELATION_ON->new(foo => 1)}                 qr/foo\b.*unexpected argument/;
  err_like {RELATION_ON->new(inc => [])}                qr/\binc: must be a scalar/;
  err_like {RELATION_ON->new(noinc => [])}              qr/\bnoinc: must be a scalar/;
  err_like {RELATION_ON->new(inc => 'x', noinc => 'x')} qr/\binc and noinc must be different/;

  err_like {RELATION_ON->new(set => {})}                qr/\bset: must be an array reference/;

  err_like {RELATION_ON->new(set => [1, undef, 3])}     qr/\bset: entry 1: invalid/;
  err_like {RELATION_ON->new(set => [{}, 2, 3])}        qr/\bset: entry 0: invalid/;

  err_like {RELATION_ON->new(set => [1, [{}, 27, 42], 3])}
    qr/\bset: subentry must be a defined scalar/;

  err_like {RELATION_ON->new(set => [1, [27, {}, 42], 3])}
    qr/\bset: subentry must be a defined scalar/;

  err_like {RELATION_ON->new(set => [1, [], 3])}
    qr/\bset: entry 1: array entry must not be empty/;
#
  err_like {RELATION_ON->new(set => [1, [2, 4, 5], [4, 3]])}
    qr/\bset: '4': duplicate element/;

  err_like {RELATION_ON->new(set => [1, [2, 4, 5], [3, 4]])}
    qr/\bset: '4': duplicate element/;

  err_like {RELATION_ON->new(set => [qw(a b c b)])}     qr/\bset: 'b': duplicate entry/;
}

{
  note("get() args");
  my $obj = RELATION_ON->new();
  err_like {$obj->get(1, 2)} qr/Wrong number of arguments/;
  err_like {$obj->get({})}   qr/Invalid argument/;

  note("Accessor args");
  err_like {$obj->inc(1)}        qr/Unexpected argument\(s\)/;
  err_like {$obj->noinc(1)}      qr/Unexpected argument\(s\)/;
  err_like {$obj->matrix(1)}     qr/Unexpected argument\(s\)/;
  err_like {$obj->elems(1)}      qr/Unexpected argument\(s\)/;
  err_like {$obj->elem_ids(1)}   qr/Unexpected argument\(s\)/;
  err_like {$obj->x_elem_ids(1)} qr/Unexpected argument\(s\)/;
  err_like {$obj->prespec(1)}    qr/Unexpected argument\(s\)/;
  err_like {$obj->n_elems(1)}    qr/Unexpected argument\(s\)/;
}

{
  note("Data error: wrong header");
  my $obj = RELATION_ON->new();
  err_like {$obj->get("foo|\n")}         qr/'foo\|': Wrong header format/;
  err_like {$obj->get("| |foo|foo|\n")}  qr/'foo': duplicate name in header/;
}

{
  note("Data error: other");
  my $obj = RELATION_ON->new();
  err_like {$obj->get("|.|foo|\nbar")}         qr/Wrong row format: 'bar'/;
  err_like {$obj->get("|.|foo|\n|bar|X|")}     qr/'bar': not in header/;
  err_like {$obj->get("|.|D|\n|D|X|\n|D|X|")}  qr/'D': duplicate element/;
  err_like {$obj->get("|.|foo|\n|foo|U|")}     qr/'U': unexpected entry/;
  err_like {$obj->get("|.|E|1|2|\n|E|X| |\n")} qr/'1', '2': no rows for this elements/;
}

{
  note("Table not match with data specified by new() arg 'set'");
  my $obj = RELATION_ON->new(set => [qw(a b c)]);
  my $tab1 = <<'FOT';
    | . | a | b |
    |---+---+---|
    | a |   |   |
    |---+---+---|
    | b |   | X |
    |---+---+---|
FOT
#Don't append a semicolon to the line above!

  err_like {$obj->get($tab1)}   qr/Wrong number of elements in table/;

  my $tab2 = <<'FOT';
    | . | a | b | x |
    |---+---+---+---|
    | a |   |   |   |
    |---+---+---+---|
    | b |   | X |   |
    |---+---+---+---|
    | x |   |   |   |
    |---+---+---+---|
FOT
#Don't append a semicolon to the line above!

  err_like {$obj->get($tab2)}   qr/'x': unknown element in table/;
}

#--------------------------------------------------------------------------------------------------

#
# err_like CODEREF, MSGREGEX
#
# Check if CODEREF fails with error message matching MSGREGEX.
#
sub err_like(&$) {
  my ($sub, $re) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  eval {$sub->()};
  if ($@) {
    (my $err = $@) =~ s/\n.*//s;  ## Important: cut off stacktrace
    like($err, $re, "Error message ok");
  } else {
    fail("Coded did not produce error");
    return "";
  }
}

#==================================================================================================
done_testing();
