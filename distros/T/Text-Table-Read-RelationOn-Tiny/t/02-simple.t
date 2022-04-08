use 5.010_001;
use strict;
use warnings;

use File::Basename;
use File::Spec::Functions;


use Test::More;

use Text::Table::Read::RelationOn::Tiny;

use constant TEST_DIR => catdir(dirname(__FILE__), 'test-data');


{
  note('Defaults / empty input');
  my $obj = new_ok('Text::Table::Read::RelationOn::Tiny');

  is($obj->inc,   'X', 'inc() - default');
  is($obj->noinc, '',  'noinc() - default');

  is($obj->matrix,     undef, 'matrix()');
  is($obj->elems,      undef, 'elems()');
  is($obj->elem_ids,   undef, 'elem_ids()');
  is($obj->tab_elems,  undef, 'tab_elems()');
  is($obj->eq_ids,     undef, 'eq_ids()');

  is($obj->matrix_named,             undef, 'matrix_named()');
  is($obj->matrix_named(bless => 1), undef, 'matrix_named(bless => 1)');

  ok(!$obj->prespec, "prespec() returns false");
  {
    note('Empty input (array)');
    is($obj->get(src => []), $obj, 'get() returns object in scalar context');
    is_deeply($obj->matrix,    {}, 'matrix(): empty hash');
    is_deeply($obj->elems,     [], 'elems(): empty array');
    is_deeply($obj->elem_ids,  {}, 'elem_ids(): empty hash');
    is_deeply($obj->tab_elems, {}, 'tab_elems(): empty hash');
    is_deeply($obj->eq_ids,    {}, 'eq_ids()');
    ok(!$obj->prespec, "prespec() still returns false");

    isnt($obj->elem_ids, $obj->tab_elems,
         "elem_ids() and tab_elems() do not reference the same hash");

    is_deeply($obj->matrix_named, {}, 'matrix_named()');
    my $matrix_named = $obj->matrix_named(bless => 1);
    is_deeply($matrix_named, {}, 'matrix_named()');
    isa_ok($matrix_named, 'Text::Table::Read::RelationOn::Tiny::_Relation_Matrix',
           '$matrix_named');
  }

  {
    note('Empty input (file)');
    is($obj->get(src => catfile(TEST_DIR, '002-empty.txt')),
       $obj, 'get() returns object in scalar context');
    is_deeply($obj->matrix,    {}, 'matrix(): empty hash');
    is_deeply($obj->elems,     [], 'elems(): empty array');
    is_deeply($obj->elem_ids,  {}, 'elem_ids(): empty hash');
    is_deeply($obj->tab_elems, {}, 'tab_elems(): empty hash');
  }
  {
    note('Empty input (string): spaces only');
    my ($o_m, $o_e, $o_i) = $obj->get(src => "  \n    \n");
    my ($matrix, $elems, $elem_ids) = ($obj->matrix, $obj->elems, $obj->elem_ids);
    is($o_m, $matrix,   'get() in list context returns (matrix, elems, elem_ids)  [matrix]');
    is($o_e, $elems,    'get() in list context returns (matrix, elems, elem_ids)  [elems]');
    is($o_i, $elem_ids, 'get() in list context returns (matrix, elems, elem_ids)  [elem_ids]');

    is_deeply($matrix,         {}, 'matrix(): empty array');
    is_deeply($elems,          [], 'elems(): empty hash');
    is_deeply($elem_ids,       {}, 'elem_ids(): empty hash');
    is_deeply($obj->tab_elems, {}, 'tab_elems(): empty hash');
  }
  {
    note('Empty input (file): white spaces only');
    my ($o_m, $o_e, $o_i) = $obj->get(src => catfile(TEST_DIR, '002-spaces-only.txt'));
    my ($matrix, $elems, $elem_ids) = ($obj->matrix, $obj->elems, $obj->elem_ids);
    is($o_m, $matrix,   'get() in list context returns (matrix, elems, elem_ids)  [matrix]');
    is($o_e, $elems,    'get() in list context returns (matrix, elems, elem_ids)  [elems]');
    is($o_i, $elem_ids, 'get() in list context returns (matrix, elems, elem_ids)  [elem_ids]');

    is_deeply($matrix,         {}, 'matrix(): empty array');
    is_deeply($elems,          [], 'elems(): empty hash');
    is_deeply($elem_ids,       {}, 'elem_ids(): empty hash');
    is_deeply($obj->tab_elems, {}, 'tab_elems(): empty hash');
  }

  is($obj->get(src => "\n"), $obj, 'get() returns object in scalar context');

  is_deeply([$obj->get(src => "| *   |\n")],   [{}, [], {}],  "Relation on empty set");
}


{
  note('Simple / with constructor args');
  my $obj = new_ok('Text::Table::Read::RelationOn::Tiny' => [inc => ' x y', noinc => ' -  ']);

  is($obj->inc,   'x y', 'inc()');
  is($obj->noinc, '-',   'noinc()');

  is($obj->matrix,    undef, 'matrix()');
  is($obj->elems,     undef, 'elems()');
  is($obj->elem_ids,  undef, 'elem_ids()');
  is($obj->tab_elems, undef, 'tab_elems()');
  is($obj->eq_ids,    undef, 'eq_ids()');
  ok(!$obj->prespec, "prespec() returns false");
  {
    note("Single element input / non empty relation");
    my $input = <<'EOT';
      | *   | Foo |
      |-----+-----|
      | Foo | x y |
      |-----+-----|
EOT
    #Don't append a semicolon to the line above!

    my ($o_m, $o_e, $o_i) = $obj->get(src => $input);
    my ($matrix, $elems, $elem_ids) = ($obj->matrix, $obj->elems, $obj->elem_ids);
    is($o_m, $matrix,   'get() in list context returns (matrix, elems, elem_ids)  [matrix]');
    is($o_e, $elems,    'get() in list context returns (matrix, elems, elem_ids)  [elems]');
    is($o_i, $elem_ids, 'get() in list context returns (matrix, elems, elem_ids)  [elem_ids]');

    is_deeply($matrix,         {0 => {0 => undef}}, 'matrix()');
    is_deeply($elems,          ['Foo'],             'elems()');
    is_deeply($elem_ids,       {Foo => 0},          'elem_ids()');
    is_deeply($obj->tab_elems, {Foo => 0},          'tab_elems()');
    is_deeply($obj->eq_ids,    {}, 'eq_ids()');

    note("Still the same with pedantic => 1");
    $obj->get(src => $input, pedantic => 1);
    is_deeply($obj->matrix, {0 => {0 => undef}}, 'matrix() / no change using pedantic');
  }
  {
    note("Single element input / empty relation");
    my $input = <<'EOT';
      | *   | Foo |
      |-----+-----|
      | Foo |  -  |
      |-----+-----|
EOT
    #Don't append a semicolon to the line above!

    my ($o_m, $o_e, $o_i) = $obj->get(src => $input);
    my ($matrix, $elems, $elem_ids) = ($obj->matrix, $obj->elems, $obj->elem_ids);
    is($o_m, $matrix,   'get() in list context returns (matrix, elems, elem_ids)  [matrix]');
    is($o_e, $elems,    'get() in list context returns (matrix, elems, elem_ids)  [elems]');
    is($o_i, $elem_ids, 'get() in list context returns (matrix, elems, elem_ids)  [elem_ids]');

    is_deeply($matrix,         {},         'matrix()');
    is_deeply($elems,          ['Foo'],    'elems()');
    is_deeply($elem_ids,       {Foo => 0}, 'elem_ids()');
    is_deeply($obj->tab_elems, {Foo => 0}, 'tab_elems()');
    is_deeply($obj->eq_ids,    {}, 'eq_ids()');

    note("Same, but empty name");
    $input = <<'EOT';
      | *   |     |
      |-----+-----|
      |     | x y |
      |-----+-----|
EOT
    #Don't append a semicolon to the line above!

    is_deeply([$obj->get(src => $input)], [{0 => {0 => undef}}, [''], {'' => 0}],
              "Result for one-element set with empty element namee");
  }
}

{
  note("Non trivial input");
  my $obj = Text::Table::Read::RelationOn::Tiny->new();
  {
    note("Input from string / from array");
    my $input = <<'EOT';

| x\y     | this | that | foo bar | empty |
|---------+------+------+---------+-------|
| this    | X    |      | X       |       |
|---------+------+------+---------+-------|
| that    |      |      | X       |       |
|---------+------+------+---------+-------|
| foo bar |      | X    |         |       |
|---------+------+------+---------+-------|
| empty   |      |      |         |       |
|---------+------+------+---------+-------|

EOT
#Don't append a semicolon to the line above!

    my $expected = [{
                     1 => {
                           2 => undef
                          },
                     0 => {
                           0 => undef,
                           2 => undef
                          },
                     2 => {
                           1 => undef
                          }
                    },
                    ['this', 'that', 'foo bar', 'empty'],
                    {
                     'this'    => 0,
                     'that'    => 1,
                     'foo bar' => 2,
                     'empty'   => 3
                    }
                   ];
    my $input_bak = $input;
    is_deeply([$obj->get(src => $input)],
              $expected,
              'Return values of get(STRING) in list context'
             );
    is($input, $input_bak, "Input string not changed");
    is_deeply($obj->eq_ids,    {}, 'eq_ids()');

    my @input_array = split(/\n/, $input);
    my @input_array_bak = @input_array;
    is_deeply([$obj->get(src => \@input_array)],
              $expected,
              'Return values of get(ARRAY) in list context'
             );
    is_deeply(\@input_array, \@input_array_bak, "Input array not changed");
    my $org_matrix = $obj->matrix;
    my $matrix     = $obj->matrix(bless => 1);
    is($matrix, $org_matrix, "bless_matrix() does not change matrix");
    isa_ok($matrix, 'Text::Table::Read::RelationOn::Tiny::_Relation_Matrix', '$matrix');
    ok($matrix->related(0, 2), "related(0, 2)");
    ok(!$matrix->related(1, 0), "NOT related(1, 0)");

    my $matrix_named = $obj->matrix_named;
    is_deeply($matrix_named, {
                              that      => {
                                            'foo bar' => undef
                                           },
                              this      => {
                                            this => undef,
                                            'foo bar' => undef
                                           },
                              'foo bar'  => {
                                             that => undef
                                            }
                             },
              'matrix_named()'
             );
    my $matrix_named_blessed = $obj->matrix_named(bless => 1);
    isa_ok($matrix_named_blessed, 'Text::Table::Read::RelationOn::Tiny::_Relation_Matrix',
           '$matrix_named');
    ok($matrix_named_blessed->related('this', 'foo bar'), "related(0, 2)");
    ok(!$matrix_named_blessed->related('that', 'this'), "NOT related(1, 0)");

  }
  {
    note("Same input, but from file + rows and columns reordered");
    my %expected = (
                    matrix => {
                               1 => {
                                     1 => undef,
                                     2 => undef
                                    },
                               3 => {
                                     2 => undef
                                    },
                               2 => {
                                     3 => undef
                                    }
                              },
                    elems =>  ['empty', 'this', 'foo bar', 'that'],
                    elem_ids => {
                                 'foo bar' => 2,
                                 'that'    => 3,
                                 'empty'   => 0,
                                 'this'    => 1
                                }
                    );
    $obj->get(src => catfile(TEST_DIR, '02-table.txt'));
    is_deeply($obj->matrix,    $expected{matrix},   'matrix()');
    is_deeply($obj->elems,     $expected{elems},    'elems()');
    is_deeply($obj->elem_ids,  $expected{elem_ids}, 'elem_ids()');
    is_deeply($obj->tab_elems, $expected{elem_ids}, 'tab_elems()');
    is_deeply($obj->eq_ids,    {},                  'eq_ids()');

    note("Same input, but with 'weird' use of horizontal rules");
    $obj->get(src => catfile(TEST_DIR, '02-table-weird.txt'));
    is_deeply($obj->matrix,    $expected{matrix},   'matrix()');
    is_deeply($obj->elems,     $expected{elems},    'elems()');
    is_deeply($obj->elem_ids,  $expected{elem_ids}, 'elem_ids()');
    is_deeply($obj->tab_elems, $expected{elem_ids}, 'tab_elems()');
    is_deeply($obj->eq_ids,    {},                  'eq_ids()');
  }
}

{
  note("allow_subset");
  note(" --- 1.");
  my $obj = Text::Table::Read::RelationOn::Tiny->new(inc => 'x y', noinc => '-');
  $obj->get(src => [
                    "| *   |     |",
                    "|-----+-----|",
                    "|     | x y |",
                    "|-----+-----|",
                    "|  a  | -   |",
                    "|-----+-----|",
                    "|  b  | x y |",
                    "|-----+-----|"
                   ],
            allow_subset => 1);
  is_deeply($obj->elems, ['', 'a', 'b'], 'elems');
  is_deeply($obj->elem_ids, {'' => 0, a => 1, b => 2}, 'elem_ids');
  is_deeply($obj->tab_elems, $obj->elem_ids, 'tab_elems');
  is_deeply($obj->matrix, {0 => {
                                 0 => undef
                                },
                           2 => {
                                 0 => undef
                                }
                          },
            'matrix');
  is_deeply($obj->eq_ids, {}, 'eq_ids()');

  note(" --- 2.");
  $obj->get(src => [
                    "| *   |  a  |  b  |",
                    "|-----+-----|-----|",
                    "|  a  | x y |  -  |"
                   ],
            allow_subset => 1);
  is_deeply($obj->elems, ['a', 'b'], 'elems');
  is_deeply($obj->elem_ids, {a => 0, b => 1}, 'elem_ids');
  is_deeply($obj->tab_elems, $obj->elem_ids, 'tab_elems');
  is_deeply($obj->matrix, {0 => {
                                 0 => undef
                                }
                          },
            'matrix');
  is_deeply($obj->eq_ids, {}, 'eq_ids()');

  note(" --- 3. - no rows");
  $obj->get(src => [
                    "| *   |  a  |  b  |",
                   ],
            allow_subset => 1);
  is_deeply($obj->elems, ['a', 'b'], 'elems');
  is_deeply($obj->elem_ids, {a => 0, b => 1}, 'elem_ids');
  is_deeply($obj->tab_elems, $obj->elem_ids, 'tab_elems');
  is_deeply($obj->matrix, {}, 'matrix');
  is_deeply($obj->eq_ids, {}, 'eq_ids()');

  note(" --- 4. - no columns");
  $obj->get(src => [
                    "| *   |",
                    "|-----+",
                    "|  a  |",
                    "|-----+",
                    "|  b  |",
                    "|-----+"
                   ],
            allow_subset => 1);
  is_deeply($obj->elems, ['a', 'b'], 'elems');
  is_deeply($obj->elem_ids, {a => 0, b => 1}, 'elem_ids');
  is_deeply($obj->tab_elems, $obj->elem_ids, 'tab_elems');
  is_deeply($obj->matrix, {}, 'matrix');
  is_deeply($obj->eq_ids, {}, 'eq_ids()');
}

#==================================================================================================
done_testing();
