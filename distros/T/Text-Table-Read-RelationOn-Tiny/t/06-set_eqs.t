use 5.010_001;
use strict;
use warnings;

use Test::More;

use Text::Table::Read::RelationOn::Tiny;

#use constant RELATION_ON => "Text::Table::Read::RelationOn::Tiny"; # to make calls shorter.

{
  my @set_elems = ('this',  'that' , 'foo bar',  'empty' );
  my %expected_ids;
  for (my $i = 0; $i < @set_elems; ++$i) {
    $expected_ids{$set_elems[$i]} = $i;
  }

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
                  [@set_elems],
                  {
                   'this'    => 0,
                   'that'    => 1,
                   'foo bar' => 2,
                   'empty'   => 3
                  }
                 ];

  my $obj = Text::Table::Read::RelationOn::Tiny->new(set => \@set_elems,
                                                     eqs => [['that'], ['empty']]);

  ok($obj->prespec, "prespec() returns true");

  is_deeply($obj->elems,      \@set_elems,    "elems()");
  is_deeply($obj->elem_ids,   \%expected_ids, "elem_ids()");
  is_deeply($obj->eq_ids,     {},             "eq_ids()");
  {
    note("Same order of elements");
    my $input = <<'EOT';

      | x\\y    | this | that | foo bar | empty |
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
    my $input_bak = $input;
    is_deeply([$obj->get(src => $input)],
              $expected,
              'Return values of get(STRING) in list context'
             );

    is($input, $input_bak, "Input string not changed");

    is_deeply($obj->elems,      \@set_elems,    "elems() unchanged");
    is_deeply($obj->elem_ids,   \%expected_ids, "elem_ids() unchanged");
    ok($obj->prespec, "prespec() still returns true");
  }
}


{
  my @set_elems = ( qw(a a1 a2 a3 b c c1 d) );
  my $elem_ids_expected = {'a'  => 0,
                           'a1' => 1,
                           'a2' => 2,
                           'a3' => 3,
                           'b'  => 4,
                           'c'  => 5,
                           'c1' => 6,
                           'd'  => 7
                          };
  my $tab_elems_expected = {a => 0,
                            b => 4,
                            c => 5,
                            d => 7
                           };
  my $obj = Text::Table::Read::RelationOn::Tiny->new(set => \@set_elems,
                                                     eqs => [[qw(a a1 a2 a3)],
                                                             [qw(c c1)]]);
  ok($obj->prespec, "prespec() returns true");
  is_deeply($obj->elems, \@set_elems, 'elems()');
  is_deeply($obj->elem_ids, $elem_ids_expected, 'elem_ids()');
  is_deeply($obj->eq_ids, {0 => [1, 2, 3],
                           5 => [6]},
            'eq_ids');

  is_deeply($obj->tab_elems, $tab_elems_expected, 'tab_elems()');


  my $input = <<'EOT';
      |     | a | b | c | d |
      |-----+---+---+---+---|
      | a   | X | X | X | X |
      |-----+---+---+---+---|
      | b   |   | X | X | X |
      |-----+---+---+---+---|
      | c   |   |   | X | X |
      |-----+---+---+---+---|
      | d   |   |   |   | X |
      |-----+---+---+---+---|
EOT

  $obj->get(src => $input);

  is_deeply($obj->elem_ids, $elem_ids_expected, 'elem_ids() not changed');
  is_deeply($obj->tab_elems, $tab_elems_expected, 'tab_elems() not changed');

  my $matrix_expected = {
                         0 => {
                               0 => undef, 1 => undef, 2 => undef, 3 => undef,
                               4 => undef,
                               5 => undef, 6 => undef,
                               7 => undef
                              },
                         4 => {
                               4 => undef,
                               5 => undef, 6 => undef,
                               7 => undef
                              },
                         5 => {
                               5 => undef, 6 => undef,
                               7 => undef
                              },
                         7 => {
                               7 => undef
                              }
                        };
  is_deeply($obj->matrix, $matrix_expected, 'matrix');

  {
    note("\tduplicates");
    my ($dup_elems, $elems) = ($obj->elems(1), $obj->elems());
    isnt($dup_elems, $elems, 'references: dup_elems != elems');
    is_deeply($dup_elems, $elems, 'content: dup_elems == elems');

    my ($dup_elem_ids, $elem_ids) = ($obj->elem_ids(1), $obj->elem_ids);
    isnt($dup_elem_ids, $elem_ids, 'references: dup_elem_ids != elem_ids');
    is_deeply($dup_elem_ids, $elem_ids, 'content: dup_elem_ids == elem_ids');

    my ($dup_tab_elems, $tab_elems) = ($obj->tab_elems(1), $obj->tab_elems);
    isnt($dup_tab_elems, $tab_elems, 'references: dup_tab_elems != tab_elems');
    is_deeply($dup_tab_elems, $tab_elems, 'content: dup_tab_elems == tab_elems');

    my ($dup_eq_ids, $eq_ids) = ($obj->eq_ids(1), $obj->eq_ids);
    isnt($dup_eq_ids, $elem_ids, 'references: dup_eq_ids != eq_ids');
    is_deeply($dup_eq_ids, $eq_ids, 'content: dup_eq_ids == eq_ids');
    foreach my $key (keys(%$eq_ids)) {
      isnt($dup_eq_ids->{$key}, $eq_ids->{$key}, "$key: refs are different");
    }

    my ($dup_matrix, $matrix) = ($obj->matrix(dup => 1), $obj->matrix);
    isnt($dup_matrix, $matrix, 'references: dup_matrix != matrix');
    is_deeply($dup_matrix, $matrix, 'content: dup_matrix == matrix');
    foreach my $key (keys(%{$matrix})) {
      isnt($dup_matrix->{$key}, $matrix->{$key}, "$key: refs are different");
    }

    note("\tEND duplicates");
  }

  note("allow_subset");
  $obj->get(src => ["|  *  | a |",
                    "| a   | X |"
                   ],
            allow_subset => 1
           );

  is_deeply($obj->elem_ids, $elem_ids_expected, 'elem_ids() not changed');
  is_deeply($obj->tab_elems, $tab_elems_expected, 'tab_elems() not changed');
  is_deeply($obj->matrix, {0 => {0 => undef,
                                 1 => undef,
                                 2 => undef,
                                 3 => undef
                                }}, 'matrix()');
}

{
  note("mixed eq elements");
  #               0 1 2 3 4 5 6 7 8 9
  my @elems = qw( A b c D e f G H i j );
  my %elem_ids = (
                  'A' => '0',
                  'b' => '1',
                  'c' => '2',
                  'D' => '3',
                  'e' => '4',
                  'f' => '5',
                  'G' => '6',
                  'H' => '7',
                  'i' => '8',
                  'j' => '9'
                  );

  my $obj = Text::Table::Read::RelationOn::Tiny->new(set => \@elems,
                                                     eqs => [[qw(A i)],
                                                             [qw(D b e j f)],
                                                             [qw(H c)]
                                                            ]);
  is_deeply($obj->elems,    \@elems,    'elems()');
  is_deeply($obj->elem_ids, \%elem_ids, 'elem_ids()');
  is_deeply($obj->eq_ids, { 0 => [ 8 ],
                            3 => [ 1, 4, 9, 5 ],
                            7 => [ 2 ]
                          },
            'eq_ids()'

           );
  $obj->get(src => ["|     | A | D | G | H |",
                    "|-----+---+---+---+---|",
                    "| A   | X | X | X | X |",
                    "|-----+---+---+---+---|",
                    "| D   |   | X | X | X |",
                    "|-----+---+---+---+---|",
                    "| G   |   |   | X | X |",
                    "|-----+---+---+---+---|",
                    "| H   |   |   |   | X |",
                    "|-----+---+---+---+---|"
                   ]);
  is_deeply($obj->matrix,{
                          0 => {
                                0 => undef,
                                1 => undef,
                                2 => undef,
                                3 => undef,
                                4 => undef,
                                5 => undef,
                                6 => undef,
                                7 => undef,
                                8 => undef,
                                9 => undef
                               },
                          3 => {
                                1 => undef,
                                2 => undef,
                                3 => undef,
                                4 => undef,
                                5 => undef,
                                6 => undef,
                                7 => undef,
                                9 => undef
                               },
                          6 => {
                                2 => undef,
                                6 => undef,
                                7 => undef
                               },
                          7 => {
                                2 => undef,
                                7 => undef
                               }
                         },
            'matrix()');
  is_deeply($obj->matrix_named, {
                                 'A' => {
                                         'A' => undef,
                                         'b' => undef,
                                         'c' => undef,
                                         'D' => undef,
                                         'e' => undef,
                                         'f' => undef,
                                         'G' => undef,
                                         'H' => undef,
                                         'i' => undef,
                                         'j' => undef
                                        },
                                 'D' => {
                                         'b' => undef,
                                         'c' => undef,
                                         'D' => undef,
                                         'e' => undef,
                                         'f' => undef,
                                         'G' => undef,
                                         'H' => undef,
                                         'j' => undef
                                        },
                                 'G' => {
                                         'c' => undef,
                                         'G' => undef,
                                         'H' => undef
                                        },
                                 'H' => {
                                         'c' => undef,
                                         'H' => undef
                                        }
                                },
            'matrix_named()'
           );
}


#==================================================================================================
done_testing();

