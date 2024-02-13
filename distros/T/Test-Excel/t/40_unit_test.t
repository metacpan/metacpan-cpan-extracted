#!/usr/bin/env perl

use strict; use warnings;

use Test::More tests => 21;

use Test::Excel;
use File::Spec::Functions;

my ($got_col, $got_row);
my ($exp_col, $exp_row);
my ($got_cells, $exp_cells);
my ($got_number, $exp_number);
my ($got_letter, $exp_letter);
my ($cell, $range, $result, $error);

$cell = 'A23';
$exp_col = 'A'; $exp_row = 23;
($got_col, $got_row) = Test::Excel::_column_row($cell);
is($got_col, $exp_col);
is($got_row, $exp_row);

$range = 'A1:B3';
$exp_cells = [{row => 1, col => 0},
              {row => 1, col => 1},
              {row => 2, col => 0},
              {row => 2, col => 1},
              {row => 3, col => 0},
              {row => 3, col => 1}];
$got_cells = Test::Excel::_cells_within_range($range);
ok(eq_array($got_cells, $exp_cells));

$exp_number = 27;
$got_number = Test::Excel::_letter_to_number('AB');
is($got_number, $exp_number);

$exp_letter = 'AB';
$got_letter = Test::Excel::_number_to_letter(27);
is($got_letter, $exp_letter);

eval
{
    $result = cmp_excel('x.xls','y.xls');
};
$error = $@;
like($error, qr/ERROR: Unable to locate file/);

eval
{
    $result = cmp_excel(catfile('t','got-1.xls'),'y.xls');
};
$error = $@;
like($error, qr/ERROR: Unable to locate file/);

eval
{
    $result = compare_excel('x.xls','y.xls');
};
$error = $@;
like($error, qr/ERROR: Unable to locate file/);

eval
{
    $result = compare_excel(catfile('t','got-1.xls'),'y.xls');
};
$error = $@;
like($error, qr/ERROR: Unable to locate file/);

eval
{
    $result = cmp_excel(catfile('t','got-1.xls'),
                        catfile('t','exp-1.xls'),
                        'Test Message');
};
$error = $@;
like($error, qr/ERROR: Invalid RULE definitions. It has to be reference to a HASH./);

eval
{
    $result = compare_excel(catfile('t','got-1.xls'),
                            catfile('t','exp-1.xls'),
                            'Test Message');
};
$error = $@;
like($error, qr/ERROR: Invalid RULE definitions. It has to be reference to a HASH./);

eval
{
    $result = cmp_excel(catfile('t','got-1.xls'),
                        catfile('t','exp-1.xls'),
                        { name => 'Test Message'});
};
$error = $@;
like($error, qr/ERROR: Invalid key 'name' found in the rule definitions./);

eval
{
    $result = compare_excel(catfile('t','got-1.xls'),
                            catfile('t','exp-1.xls'),
                            { name => 'Test Message'});
};
$error = $@;
like($error, qr/ERROR: Invalid key 'name' found in the rule definitions./);

eval
{
    $result = cmp_excel(catfile('t','got-1.xls'),
                        catfile('t','exp-1.xls'),
                        { message         => 'Testing',
                          sheet           => 'Test Message',
                          sheet_tolerance => 0.2});
};
$error = $@;
like($error, qr/ERROR: Missing key tolerance in the rule definitions./);

eval
{
    $result = compare_excel(catfile('t','got-1.xls'),
                            catfile('t','exp-1.xls'),
                            { message         => 'Testing',
                              sheet           => 'Test Message',
                              sheet_tolerance => 0.2});
};
$error = $@;
like($error, qr/ERROR: Missing key tolerance in the rule definitions./);

eval
{
    $result = cmp_excel(catfile('t','got-1.xls'),
                        catfile('t','exp-1.xls'),
                        { message => 'Testing',
                          spec    => catfile('t','spec-1.txt')});
};
$error = $@;
like($error, qr/ERROR: Missing key sheet_tolerance in the rule definitions./);

eval
{
    $result = compare_excel(catfile('t','got-1.xls'),
                            catfile('t','exp-1.xls'),
                           { message => 'Testing',
                             spec    => catfile('t','spec-1.txt')});
};
$error = $@;
like($error, qr/ERROR: Missing key sheet_tolerance in the rule definitions./);

eval
{
    $result = cmp_excel(catfile('t','got-1.xls'),
                        catfile('t','exp-1.xls'),
                        { message         => 'Testing',
                          sheet_tolerance => 0.2,
                          spec            => catfile('t','spec-1.txt')});
};
$error = $@;
like($error, qr/ERROR: Missing key tolerance in the rule definitions./);

eval
{
    $result = compare_excel(catfile('t','got-1.xls'),
                            catfile('t','exp-1.xls'),
                           { message         => 'Testing',
                             sheet_tolerance => 0.2,
                             spec            => catfile('t','spec-1.txt')});
};
$error = $@;
like($error, qr/ERROR: Missing key tolerance in the rule definitions./);

eval { Test::Excel::_parse(catfile('t','spec-0.txt')); };
$error = $@;
like($error, qr/ERROR: Unable to locate spec file/);

eval
{
    $result = compare_excel(catfile('t','got-1.xls'),
                            catfile('t','exp-1.xls'),
                           { message         => 'Testing',
                             sheet_tolerance => 0.2,
                             spec            => catfile('t','spec-1.txt'),
                             a => 1,
                             b => 2,
                             c => 3,
                             d => 4,
                             e => 5,
                             f => 6,});
};
$error = $@;
like($error, qr/ERROR: Rule has more than 8 keys defined./);
