use strict;
use Data::Dumper;
use Test::More;
use Test::Deep;
use Test::Harness;
use Win32::ExcelSimple; 

my ($col, $row) = cell2cr('AB3');
is($col,  28, "convert AB3 to col 28");
is($row,  3, "convert AB3 to row 3");
is(cr2cell(2,34), 'B34', "convert (2,34) to B34");

done_testing;

