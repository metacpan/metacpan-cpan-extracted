use 5.010_001;
use strict;
use warnings;

use Test::More;

use Text::Table::Read::RelationOn::Tiny;

#               0 1 2 3 4 5 6 7 8 9
my @Elems = qw( A b c D e f G H i j );
my %Elem_Ids = (
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

my $Input = [
             "|     | A | D | G | H |",
             "|-----+---+---+---+---|",
             "| A   | X | X | X | X |",
             "|-----+---+---+---+---|",
             "| D   |   | X | X | X |",
             "|-----+---+---+---+---|",
             "| G   |   |   | X | X |",
             "|-----+---+---+---+---|",
             "| H   |   |   |   | X |",
             "|-----+---+---+---+---|"
            ];

my $Eqs = [[qw(A i)],
           [qw(D b e j f)],
           [qw(H c)]
          ];

my $Expected_EqIds = { 0 => [ 8 ],
                       3 => [ 1, 4, 9, 5 ],
                       7 => [ 2 ]
                     };

my $Expected_Matrix = {
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
                      };

my $Expected_MatrixNamed = {
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
                           };



{
  note("mixed eq elements");

  my $obj = Text::Table::Read::RelationOn::Tiny->new(ext => 1,
                                                     set => \@Elems,
                                                     eqs => $Eqs);
  is($obj->elems, \@Elems, 'elems() references external array');
  is_deeply($obj->eq_ids, $Expected_EqIds, 'eq_ids()'

           );
  $obj->get(src => $Input);
  is_deeply($obj->matrix, $Expected_Matrix, 'matrix()');
  is_deeply($obj->matrix_named, $Expected_MatrixNamed, 'matrix_named()');
}

{
  note("mixed eq elements / with elem_ids => ...");

  my $obj = Text::Table::Read::RelationOn::Tiny->new(ext => 1,
                                                     set => \@Elems,
                                                     elem_ids => \%Elem_Ids,
                                                     eqs => $Eqs);
  is($obj->elems,    \@Elems,    'elems() references external array');
  is($obj->elem_ids, \%Elem_Ids, 'elem_ids() references external hash');
  is_deeply($obj->eq_ids, $Expected_EqIds, 'eq_ids()'

           );
  $obj->get(src => $Input);
  is_deeply($obj->matrix, $Expected_Matrix, 'matrix()');
  is_deeply($obj->matrix_named, $Expected_MatrixNamed, 'matrix_named()');
}



#==================================================================================================
done_testing();

