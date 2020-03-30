use strict;
use warnings;
use lib 't/lib';
use Test::More qw(no_plan);
use new;

our ($O, $E);

new->import('ExampleClass');

is ref($O), 'ExampleClass', 'object exists';

is $O->foo, 'foo', 'method works';

is $O->bar, 'bar', 'method works';

new->import('ExampleClass', bars => 3);

is $O->bar, 'bar bar bar', 'method w/constructor args works';

new->import('ExampleClass', '$E');

is $E->foo, 'foo', 'export with name works';

new->import('ExampleClass', '$E', bars => 2);

is $E->bar, 'bar bar', 'export with name and constructor args works';
