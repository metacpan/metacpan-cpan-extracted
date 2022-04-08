use 5.010_001;
use strict;
use warnings;

use Test::More;

use Text::Table::Read::RelationOn::Tiny;

use constant RELATION_ON => "Text::Table::Read::RelationOn::Tiny"; # to make calls shorter.

sub err_like(&$);
sub no_err(&);

{
  note("Constructor args");
  err_like {RELATION_ON->new(1)}                        qr/^Odd number of arguments/;
  err_like {RELATION_ON->new(foo => 1)}                 qr/^foo\b.*unexpected argument/;
  err_like {RELATION_ON->new(inc => [])}                qr/^inc: must be a scalar/;
  err_like {RELATION_ON->new(noinc => [])}              qr/^noinc: must be a scalar/;
  err_like {RELATION_ON->new(inc => 'x', noinc => 'x')} qr/^inc and noinc must be different/;
  err_like {RELATION_ON->new(inc => '|', noinc => 'x')} qr/^'\|' is not allowed for inc or noinc/;
  err_like {RELATION_ON->new(noinc => ' |  ')}          qr/^'\|' is not allowed for inc or noinc/;

  err_like {RELATION_ON->new(set => {})}                qr/^set: must be an array reference/;

 err_like {RELATION_ON->new(set => [1, undef, 3])}     qr/^set: entry 2: invalid/;
  err_like {RELATION_ON->new(set => [{}, 2, 3])}        qr/^set: entry 1: invalid/;

  err_like {RELATION_ON->new(set => [1, [], 3])}
    qr/^set: entry 2: array entry must not be empty/;

  err_like {RELATION_ON->new(set => [1, [2, 4, 5], [4, 3]])}
    qr/^set: '4': duplicate element/;

  err_like {RELATION_ON->new(set => [1, [2, 4, 5], [3, 4]])}
    qr/^set: '4': duplicate element/;

  err_like {RELATION_ON->new(set => [1, [2, 4, 5], -1, [3, 4, 27], 42])}
    qr/^set: '4': duplicate element/;

  err_like {RELATION_ON->new(set => [1, [2, 5], -1, [3, 4, 27, 4, 'xx'], 42])}
    qr/^set: '4': duplicate element/;

  err_like {RELATION_ON->new(set => [qw(a b c b)])}     qr/^set: 'b': duplicate element/;

  err_like {RELATION_ON->new(set => [1, [2, 3]], eqs => [])}
    qr/^set: entry 2: array not allowed if eqs is specified/;

  err_like {RELATION_ON->new(set => [1, [], 2])}
    qr/^set: entry 2: array entry must not be empty/;

  err_like {RELATION_ON->new(set => [1, [{}, 2, 3]])}
    qr/^set: entry 2: subarray contains invalid entry/;

  err_like {RELATION_ON->new(set => [1, [2, {}, 3]])}
    qr/^set: entry 2: subarray contains invalid entry/;

  err_like {RELATION_ON->new(set => [1, [2, undef, 3]])}
    qr/^set: entry 2: subarray contains invalid entry/;

  err_like {RELATION_ON->new(set => [1, 2], eqs => {})} qr/^eqs: must be an array ref/;

  err_like {RELATION_ON->new(set => [1, 2], eqs => [{}])}
    qr/^eqs: each entry must be an array ref/;

  err_like {RELATION_ON->new(set => [1, 2], eqs => [[], [1, {}, 2]])}
    qr/^eqs: subentry contains a non-scalar/;

  err_like {RELATION_ON->new(set => [1, 2], eqs => [[], [1, undef, 2]])}
    qr/^eqs: subentry undefined/;

  err_like {RELATION_ON->new(set => [1, 2, 3], eqs => [[3], [27, 42]])}
    qr/^eqs: '27': unknown element/;

  err_like {RELATION_ON->new(set => [1, 2, 3], eqs => [[3], [1, 42]])}
    qr/^eqs: '42': unknown element/;

  err_like {RELATION_ON->new(set => [1, 2, 3], eqs => [[2, 3], [1, 3]])}
    qr/^eqs: '3': duplicate element/;

  err_like {RELATION_ON->new(set => [1, 2, 3], eqs => [[3], [1, 3]])}
    qr/^eqs: '3': duplicate element/;

  err_like {RELATION_ON->new(eqs => [[0], [1, undef, 2]])}
    qr/^eqs: not allowed without argument 'set'/;

  err_like {RELATION_ON->new(elem_ids => {a => 0})}
    qr/^elem_ids: not allowed without arguments 'set' and 'ext'/;

  err_like {RELATION_ON->new(elem_ids => {a => 0}, set => ['a'])}
    qr/^elem_ids: not allowed without arguments 'set' and 'ext'/;

  err_like {RELATION_ON->new(elem_ids => {a => 0}, ext => 1)}
    qr/^elem_ids: not allowed without arguments 'set' and 'ext'/;

  err_like {RELATION_ON->new(elem_ids => [], ext => 1, set => ['a'])}
    qr/^elem_ids: must be a hash ref/;

  err_like {RELATION_ON->new(ext => 1)}
    qr/^ext: not allowed without argument 'set'/;

  err_like {RELATION_ON->new(elem_ids => {a => 0}, ext => 1, set => ['a', ['b']])}
    qr/^set: no subarray allowed if 'ext' is specified/;

  err_like {RELATION_ON->new(elem_ids => {a => 0}, ext => 1, set => [qw(a b)])}
    qr/^elem_ids: wrong number of entries/;

  err_like {RELATION_ON->new(elem_ids => {a => 0, c => 27}, ext => 1, set => [qw(a b)])}
    qr/^elem_ids: 'b': missing value/;

  err_like {RELATION_ON->new(elem_ids => {a => 0, b => undef}, ext => 1, set => [qw(a b)])}
    qr/^elem_ids: 'b': missing value/;

  err_like {RELATION_ON->new(elem_ids => {a => 0, b => 'abc'}, ext => 1, set => [qw(a b)])}
    qr/^elem_ids: 'b': entry has wrong value/;

  err_like {RELATION_ON->new(elem_ids => {a => 0, b => 0}, ext => 1, set => [qw(a b)])}
    qr/^elem_ids: 'b': entry has wrong value/;

  err_like {RELATION_ON->new(elem_ids => {a => 0, b => '3'}, ext => 1, set => [qw(a b)])}
    qr/^elem_ids: 'b': entry has wrong value/;
}

{
  note("get() args");
  my $obj = RELATION_ON->new();
  err_like {$obj->get()}               qr/^Missing argument 'src'/;
  err_like {$obj->get(1, 2, 3)}        qr/^Odd number of arguments/;
  err_like {$obj->get(src => "",
                      FOO => 22)}      qr/^FOO: unexpected argument/;
  err_like {$obj->get(src => "",
                      FOO => 27,
                      BAR => 42)}      qr/^BAR, FOO: unexpected argument/;
  err_like {$obj->get(src => undef)}   qr/^Invalid value argument for 'src'/;
  err_like {$obj->get(src => {})}      qr/^Invalid value argument for 'src'/;
  err_like {$obj->get(src => ["",
                              {}])}    qr/^src: each entry must be a defined scalar/;

  note("Accessor args");
  err_like {$obj->inc(1)}               qr/^Unexpected argument\(s\)/;
  err_like {$obj->noinc(1)}             qr/^Unexpected argument\(s\)/;
  err_like {$obj->prespec(1)}           qr/^Unexpected argument\(s\)/;
  err_like {$obj->elems(1)}             qr/^Unexpected argument\(s\)/;
  err_like {$obj->elem_ids(1)}          qr/^Unexpected argument\(s\)/;

  note("matrix() and matrix_named()");
  err_like {$obj->matrix(1, 2, 3)}      qr/^Odd number of arguments/;
  err_like {$obj->matrix(a => 1)}       qr/^Unexpected argument\(s\)/;
  err_like {$obj->matrix_named(1)}      qr/^Odd number of arguments/;
  err_like {$obj->matrix_named(a => 1)} qr/^Unexpected argument\(s\)/;
}

{
  note("Data error: wrong header");
  my $obj = RELATION_ON->new();
  err_like {$obj->get(src => "foo|\n")}         qr/^'foo\|': Wrong header format/;
  err_like {$obj->get(src => "| |foo|foo|\n")}  qr/^'foo': duplicate name in header/;
  err_like {$obj->get(src => "|.|a|foo|a|\n")}  qr/^'a': duplicate name in header/;
}

{
  note("Data error: other, without predefined set");
  my $obj = RELATION_ON->new(noinc => '-');
  err_like {$obj->get(src => "|.|foo|\nbar")}        qr/^Wrong row format: 'bar'/;
  err_like {$obj->get(src => "|.|foo|\n|foo|U|")}    qr/^'U': unexpected entry/;
  err_like {$obj->get(src => "|.|foo|\n|foo| |")}    qr/^'': unexpected entry/;
  err_like {$obj->get(src => ["|.|D|",
                              "|D|X|",
                              "|D|X|"])}             qr/^'D': duplicate element in first column/;
  err_like {$obj->get(src => ["|.|E|a|b|",
                              "|E|-|X|-|"])}         qr/^Number\ of\ elements\ in\ header\ does
                                                        \ not\ match\ number\ of\ elemens\ in
                                                        \ row/x;
  err_like {$obj->get(src => ["|.|a|b|c|",
                              "|b|-|-|-|",
                              "|a|-|X|-|",
                              "|c|-|-|-|",
                              "|E|-|-|X|"])}         qr/^Number\ of\ elements\ in\ header\ does
                                                        \ not\ match\ number\ of\ elemens\ in
                                                        \ row/x;
  err_like {$obj->get(src => ["|.|a|M|c|",
                              "|c|-|-|-|",
                              "|b|-|-|-|",
                              "|a|-|-|X|"])}         qr/^'M': row missing for element/;
}

{
  note("Data error: other, with predefined set");
  my $obj = RELATION_ON->new(set => [qw(a b c)]);
  err_like {$obj->get(src => "|.|a|b|c|\na")}        qr/^Wrong row format: 'a'/;
  err_like {$obj->get(src => ["|.|a|U|c|",
                              "|c| | | |",
                              "|b| | | |",
                              "|a| | |X|"])}         qr/^'U': unknown element in table/;

  err_like {$obj->get(src => ["|.|a|b|c|",
                              "|c| | | |",
                              "|U| | | |",
                              "|a| | |X|"])}         qr/^'U': unknown element in table/;

  err_like {$obj->get(src => ["|.|a|c|",
                              "|c| | |",
                              "|b| | |",
                              "|a| |X|"])}           qr/^'b': column missing for element/;

  err_like {$obj->get(src => ["|.|a|b|c|",
                              "|c| | | |",
                              "|a| | |X|"])}         qr/^'b': row missing for element/;
}

{
  note("Data error: other, with predefined set and allow_subset");
  my $obj = RELATION_ON->new(set => [qw(a b c)]);
  err_like {$obj->get(src => "|.|a|b|c|\na",
                      allow_subset => 1)}            qr/^Wrong row format: 'a'/;
  err_like {$obj->get(src => ["|.|a|U|c|",
                              "|c| | | |",
                              "|b| | | |",
                              "|a| | |X|"],
                      allow_subset => 1)}            qr/^'U': unknown element in table/;

  err_like {$obj->get(src => ["|.|a|b|c|",
                              "|c| | | |",
                              "|U| | | |",
                              "|a| | |X|"],
                      allow_subset => 1)}            qr/^'U': unknown element in table/;

}

{
  note("Pedantic: header");
  my @src = ("|.|a|b|c",
             "|c| | | |",
             "|b| | | |",
             "|a| | |X|");
  my $obj = RELATION_ON->new(set => [qw(a b c)]);
  no_err {$obj->get(  src      => \@src)};
  err_like {$obj->get(src      => \@src,
                      pedantic => 1)}   qr/Wrong header format/;
}


{
  note("Pedantic: row 1");
  my @src = ("|.|a|b|c|",
             "|c| |   | |",
             "|b| | | |",
             "|a| | |X|");
  my $obj = RELATION_ON->new(set => [qw(a b c)]);
  no_err {$obj->get(  src      => \@src)};
  err_like {$obj->get(src      => \@src,
                      pedantic => 1)}   qr/Wrong row format at line 2\b/;
}

{
  note("Pedantic: row 2");
  my @src = ("  |.|a|b|c|",
             "|c| | | |",
             "  |b| | | |",
             "  |a| | |X|");
  my $obj = RELATION_ON->new(set => [qw(a b c)]);
  no_err {$obj->get(  src      => \@src)};
  err_like {$obj->get(src      => \@src,
                      pedantic => 1)}   qr/Wrong row format at line 2\b/;
}


{
  note("Pedantic: row 3");
  my @src = ("|.|a|b|c|",
             "|c| | |  ",
             "|b| | | |",
             "|a| | |X|");
  my $obj = RELATION_ON->new(set => [qw(a b c)]);
  no_err {$obj->get(  src      => \@src)};
  err_like {$obj->get(src      => \@src,
                      pedantic => 1)}   qr/Wrong row format at line 2\b/;
}



{
  note("Pedantic: row sep 1");
  my @src = ("|.|a|b|c|",
             "|-----",
             "|c| | | | ",
             "|b| | | |",
             "|a| | |X|");
  my $obj = RELATION_ON->new(set => [qw(a b c)]);
  no_err {$obj->get(  src      => \@src)};
  err_like {$obj->get(src      => \@src,
                      pedantic => 1)}   qr/Invalid row separator at line 2\b/;
}

{
  note("Pedantic: row sep 2");
  my @src = ("|.|a|b|c|",
             " |-+-+-+-|",
             "|c| | | | ",
             "|b| | | |",
             "|a| | |X|");
  my $obj = RELATION_ON->new(set => [qw(a b c)]);
  no_err {$obj->get(  src      => \@src)};
  err_like {$obj->get(src      => \@src,
                      pedantic => 1)}   qr/Invalid row separator at line 2\b/;
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
    fail("Code did not produce error");
    return "";
  }
}

sub no_err(&) {
  my ($sub) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  eval {$sub->()};
  ok(!$@, "Code did not produce an error $@");
}

#==================================================================================================
done_testing();
