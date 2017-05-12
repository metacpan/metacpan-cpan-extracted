use Test::More tests => 21;

use TestML::Compiler::Pegex;

my $testml = '
# A comment
%TestML 0.1.0

Plan = 2;
Title = "O HAI TEST";

*input.uppercase() == *output;

=== Test mixed case string
--- input: I Like Pie
--- output: I LIKE PIE

=== Test lower case string
--- input: i love lucy
--- output: I LOVE LUCY
';

my $func = TestML::Compiler::Pegex->new->compile($testml);
ok $func, 'TestML string matches against TestML grammar';
is $func->namespace->{TestML}->value, '0.1.0', 'Version parses';
is $func->statements->[0]->expr->value, 2, 'Plan parses';
is $func->statements->[1]->expr->value, 'O HAI TEST', 'Title parses';
is $func->statements->[1]->expr->value, 'O HAI TEST', 'Title parses';

is scalar(@{$func->statements}), 3, 'Three test statements';
my $statement = $func->statements->[2];
is join('-', @{$statement->points}), 'input-output',
    'Point list is correct';

is scalar(@{$statement->expr->calls}), 2, 'Expression has two calls';
my $expr = $statement->expr;
ok $expr->calls->[0]->isa('TestML::Point'), 'First sub is a Point';
is $expr->calls->[0]->name, 'input', 'Point name is "input"';
is $expr->calls->[1]->name, 'uppercase', 'Second sub is "uppercase"';

is $statement->assert->name, 'EQ', 'Assertion is "EQ"';

$expr = $statement->assert->expr;
ok $expr->isa('TestML::Point'), 'First sub is a Point';
is $expr->name, 'output', 'Point name is "output"';

is scalar(@{$func->data}), 2, 'Two data blocks';
my ($block1, $block2) = @{$func->data};
is $block1->label, 'Test mixed case string', 'Block 1 label ok';
is $block1->points->{input}, 'I Like Pie', 'Block 1, input point';
is $block1->points->{output}, 'I LIKE PIE', 'Block 1, output point';
is $block2->label, 'Test lower case string', 'Block 2 label ok';
is $block2->points->{input}, 'i love lucy', 'Block 2, input point';
is $block2->points->{output}, 'I LOVE LUCY', 'Block 2, output point';
