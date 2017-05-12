#!perl -T

use strict;
use warnings;
use Test::More;
use Text::SpanningTable;

my $t = Text::SpanningTable->new(6, 6, 10);
ok($t, 'Got a proper Text::SpanningTable object');

my $output = '';
$t->exec(sub { my ($output, $string) = @_; $$output .= $string; }, \$output);
$t->newlines(1);
$t->decoration(0);
ok(!$t->{decorate}, 'decoration disabled');

is($t->row('#1', '#2', '#3'), "#1    #2    #3       \n", 'row with no decoration');
is($t->hr('top'), '', 'horizontal rule just returns empty char');
is($t->dhr, '-'x22 . "\n", 'double horizontal rule returns dashed rule');
$t->row('My', 'Chemical', 'Romance');

is($output, "#1    #2    #3       
----------------------
My    Chem- Romance  
      ical            \n", 'table with no decoration');

my $t2 = Text::SpanningTable->new(10, 10, 6);
$output = '';
$t2->exec(sub { my ($output, $string) = @_; $$output .= $string; }, \$output);
$t2->newlines(1);
$t2->decoration(0);
$t2->row('A', 'B', 'C');
$t2->dhr;
$t2->row('012345678', '876543210', '1'x5);
$t2->row([2, '01234567890987654321090101010101010101010101010101'], 2);
$t2->row([2, 'x'x19], 2);
is($output, "A         B         C    
--------------------------
012345678 876543210 11111
012345678909876543- 2    
210901010101010101-       
01010101010101           
xxxxxxxxxxxxxxxxxxx 2    \n", 'table with no decoration and spanning columns');

done_testing();
