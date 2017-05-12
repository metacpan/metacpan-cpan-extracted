use strict;
use warnings;
use Test::More;
use Text::MarkdownTable;

my $out = '';
my $table = Text::MarkdownTable->new( file => \$out );
$table->add({one=>"a",two=>"table"});
$table->add({one=>"is",two=>"nice"});
$table->done;
is $out, <<TABLE;
| one | two   |
|-----|-------|
| a   | table |
| is  | nice  |
TABLE

$out = '';
Text::MarkdownTable->new( 
    columns => ['X','Y','Z'],
    edges => 0, 
    file => \$out,
)->add({a=>1,b=>2,c=>3})->done;

is $out, <<TABLE;
X | Y | Z
--|---|--
1 | 2 | 3
TABLE

done_testing;
