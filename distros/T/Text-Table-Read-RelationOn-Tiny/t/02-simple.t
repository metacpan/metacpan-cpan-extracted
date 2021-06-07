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
  is($obj->x_elem_ids, undef, 'elem_ids()');

  ok(!$obj->prespec, "prespec() returns false");

  is($obj->n_elems, undef, "n_elems()");

  {
    note('Empty input (array)');
    is($obj->get([]), $obj, 'get() returns object in scalar context');
    is_deeply($obj->matrix,   {}, 'matrix(): empty hash');
    is_deeply($obj->elems,    [], 'elems(): empty array');
    is_deeply($obj->elem_ids, {}, 'elem_ids(): empty hash');

    is($obj->n_elems,  0,  'n_elems(): empty set');
  }

  {
    note('Empty input (file)');
    is($obj->get(catfile(TEST_DIR, '002-empty.txt')),
       $obj, 'get() returns object in scalar context');
    is_deeply($obj->matrix,   {}, 'matrix(): empty hash');
    is_deeply($obj->elems,    [], 'elems(): empty array');
    is_deeply($obj->elem_ids, {}, 'elem_ids(): empty hash');

    is($obj->n_elems,  0,  'n_elems(): empty set');
  }
  {
    note('Empty input (string): spaces only');
    my ($o_m, $o_e, $o_i) = $obj->get("  \n    \n");
    my ($matrix, $elems, $elem_ids) = ($obj->matrix, $obj->elems, $obj->elem_ids);
    is($o_m, $matrix,   'get() in list context returns (matrix, elems, elem_ids)  [matrix]');
    is($o_e, $elems,    'get() in list context returns (matrix, elems, elem_ids)  [elems]');
    is($o_i, $elem_ids, 'get() in list context returns (matrix, elems, elem_ids)  [elem_ids]');

    is_deeply($matrix,   {}, 'matrix(): empty array');
    is_deeply($elems,    [], 'elems(): empty hash');
    is_deeply($elem_ids, {}, 'elem_ids(): empty hash');

    is($obj->n_elems,  0,  'n_elems(): empty set');
  }
  {
    note('Empty input (file): white spaces only');
    my ($o_m, $o_e, $o_i) = $obj->get(catfile(TEST_DIR, '002-spaces-only.txt'));
    my ($matrix, $elems, $elem_ids) = ($obj->matrix, $obj->elems, $obj->elem_ids);
    is($o_m, $matrix,   'get() in list context returns (matrix, elems, elem_ids)  [matrix]');
    is($o_e, $elems,    'get() in list context returns (matrix, elems, elem_ids)  [elems]');
    is($o_i, $elem_ids, 'get() in list context returns (matrix, elems, elem_ids)  [elem_ids]');

    is_deeply($matrix,   {}, 'matrix(): empty array');
    is_deeply($elems,    [], 'elems(): empty hash');
    is_deeply($elem_ids, {}, 'elem_ids(): empty hash');

    is($obj->n_elems,  0,  'n_elems(): empty set');
  }

  is($obj->get("\n"), $obj, 'get() returns object in scalar context');

  is_deeply([$obj->get("| *   |\n")],   [{}, [], {}],  "Relation on empty set");
}


{
  note('Simple / with constructor args');
  my $obj = new_ok('Text::Table::Read::RelationOn::Tiny' => [inc => 'x y', noinc => '-']);

  is($obj->inc,   'x y', 'inc()');
  is($obj->noinc, '-',   'noinc()');

  is($obj->matrix,   undef, 'matrix()');
  is($obj->elems,    undef, 'elems()');
  is($obj->elem_ids, undef, 'elem_ids()');
  is($obj->n_elems,  undef,  'n_elems()');

  {
    note("Single element input / non empty relation");
    my $input = <<'EOT';
      | *   | Foo |
      |-----+-----|
      | Foo | x y |
      |-----+-----|
EOT
    #Don't append a semicolon to the line above!

    my ($o_m, $o_e, $o_i) = $obj->get($input);
    my ($matrix, $elems, $elem_ids) = ($obj->matrix, $obj->elems, $obj->elem_ids);
    is($o_m, $matrix,   'get() in list context returns (matrix, elems, elem_ids)  [matrix]');
    is($o_e, $elems,    'get() in list context returns (matrix, elems, elem_ids)  [elems]');
    is($o_i, $elem_ids, 'get() in list context returns (matrix, elems, elem_ids)  [elem_ids]');

    is_deeply($matrix,   {0 => {0 => undef}}, 'matrix()');
    is_deeply($elems,    ['Foo'],             'elems()');
    is_deeply($elem_ids, {Foo => 0},          'elem_ids()');

    is($obj->n_elems, 1, 'n_elems()');
  }
  {
    note("Single element input / empty relation");
    my $input = <<'EOT';
      | *   | Foo |
      |-----+-----|
      | Foo |     |
      |-----+-----|
EOT
    #Don't append a semicolon to the line above!

    my ($o_m, $o_e, $o_i) = $obj->get($input);
    my ($matrix, $elems, $elem_ids) = ($obj->matrix, $obj->elems, $obj->elem_ids);
    is($o_m, $matrix,   'get() in list context returns (matrix, elems, elem_ids)  [matrix]');
    is($o_e, $elems,    'get() in list context returns (matrix, elems, elem_ids)  [elems]');
    is($o_i, $elem_ids, 'get() in list context returns (matrix, elems, elem_ids)  [elem_ids]');

    is_deeply($matrix,   {},         'matrix()');
    is_deeply($elems,    ['Foo'],    'elems()');
    is_deeply($elem_ids, {Foo => 0}, 'elem_ids()');

    is($obj->n_elems, 1, 'n_elems()');

    note("Same, but empty name");
    $input = <<'EOT';
      | *   |     |
      |-----+-----|
      |     | x y |
      |-----+-----|
EOT
    #Don't append a semicolon to the line above!

    is_deeply([$obj->get($input)], [{0 => {0 => undef}}, [''], {'' => 0}],
              "Result for one-element set with empty element namee");
    is($obj->n_elems, 1, 'n_elems()');
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
    is_deeply([$obj->get($input)],
              $expected,
              'Return values of get(STRING) in list context'
             );
    is($input, $input_bak, "Input string not changed");

    my @input_array = split(/\n/, $input);
    my @input_array_bak = @input_array;
    is_deeply([$obj->get(\@input_array)],
              $expected,
              'Return values of get(ARRAY) in list context'
             );
    is_deeply(\@input_array, \@input_array_bak, "Input array not changed");
    is($obj->n_elems, 4, 'n_elems()');
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
    $obj->get(catfile(TEST_DIR, '02-table.txt'));
    is_deeply($obj->matrix,   $expected{matrix},   'matrix()');
    is_deeply($obj->elems,    $expected{elems},    'elems()');
    is_deeply($obj->elem_ids, $expected{elem_ids}, 'elem_ids()');
    is($obj->n_elems, 4, 'n_elems()');

    note("Same input, but with 'weird' use of horitontal rules");
    $obj->get(catfile(TEST_DIR, '02-table-weird.txt'));
    is_deeply($obj->matrix,   $expected{matrix},   'matrix()');
    is_deeply($obj->elems,    $expected{elems},    'elems()');
    is_deeply($obj->elem_ids, $expected{elem_ids}, 'elem_ids()');
    is($obj->n_elems, 4, 'n_elems()');
  }
}

#==================================================================================================
done_testing();
