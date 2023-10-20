use 5.010_001;
use strict;
use warnings;

use Test::More;

use Text::Table::Read::RelationOn::Tiny;

my @Set_Elems = ('this',  'that' , 'foo bar',  'baz' );
my %Elem_Ids  = (
                 'this'    => 0,
                 'that'    => 1,
                 'foo bar' => 2,
                 'baz'     => 3
                );

my $Input = <<'EOT';

      | x\y     | this | that | foo bar | baz   |
      |---------+------+------+---------+-------|
      | this    | X    |      | X       |       |
      |---------+------+------+---------+-------|
      | that    |      |      | X       |       |
      |---------+------+------+---------+-------|
      | foo bar |      | X    |         |       |
      |---------+------+------+---------+-------|
      | baz     |      |      |         |       |
      |---------+------+------+---------+-------|

EOT
#Don't append a semicolon to the line above!


my $Expected = [{
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
                [@Set_Elems],
                {%Elem_Ids}
               ];


{
  my $obj = Text::Table::Read::RelationOn::Tiny->new(set => \@Set_Elems, ext => 1
                                                    );
  note explain $obj->tab_elems;
  is($obj->elems, \@Set_Elems, "elems() references external array");
  is_deeply([$obj->get(src => $Input)],
            $Expected,
            'Return values of get() in list context'
           );
}

{
  my $obj = Text::Table::Read::RelationOn::Tiny->new(set => \@Set_Elems, ext => 1,
                                                     elem_ids => \%Elem_Ids
                                                    );
  is($obj->elems, \@Set_Elems,   "elems() references external array");
  is($obj->elem_ids, \%Elem_Ids, "elem_ids() references external hash");

  is_deeply([$obj->get(src => $Input)],
            $Expected,
            'Return values of get() in list context'
           );
}

#==================================================================================================
done_testing();

