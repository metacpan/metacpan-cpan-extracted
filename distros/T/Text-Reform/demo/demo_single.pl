use Text::Reform;

@graph = split "\n", <<EOGRAPH;
|*
| *
|  *
|   *
|      *
|          *
|                *
|
EOGRAPH

print form {squeeze=>0},
            '~ [[[[[[[[[[[[[[[[[[[[[[[[[[[[',
            "Activity", \@graph,
            '  +---------------------------',
            '  ||||||||||||||||||||||||||||',
              'Time';
