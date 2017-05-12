use strict;
use warnings;

use Test::More tests => 3;

use Text::Trac2GFM qw( trac2gfm );

my ($give, $expect);

$give = <<EOG;
A simple table:
||=Header 1=||=Header 2=||
||Cell 1||Cell 2||
EOG
$expect = <<EOE;
A simple table:

| Header 1 | Header 2 |
| :------: | :------: |
|  Cell 1  |  Cell 2  |
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'simple table');

$give = <<EOG;
Some mixed alignment.

||=Left Aligned =||= Right Aligned=||=Centered=||= More Centering =||
||Left||Right||Center||Center||
EOG
$expect = <<EOE;
Some mixed alignment.

| Left Aligned | Right Aligned | Centered | More Centering |
| :----------- | ------------: | :------: | :------------: |
| Left         |         Right |  Center  |     Center     |
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'mixed alignment tables');

$give = <<EOG;
Large cells.

||Foo ||Bar||
||This cell has a moderate length sentence in it.||       Baz||
EOG
$expect = <<EOE;
Large cells.

| Foo                                             |  Bar  |
| :---------------------------------------------- | :---: |
| This cell has a moderate length sentence in it. |  Baz  |
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'large cell');

