use Test::More tests => 12;

package MyVal;

use Validation::Class;

package main;

my $v1 = MyVal->new(
    fields => {foobar => {min_length => 5}},
    params => {foobar => [join('', 1 .. 4), join('', 1 .. 5),]}
);

# check that an array parameters is handled properly on-the-fly
ok !$v1->validate('foobar'), 'validation does not pass';
ok $v1->error_count == 1,
  '1 errors set, 1 wrong element of the param array value';
ok $v1->errors_to_string =~ /multiple/,
  'error message identifies no array handling specified';

my $v2 = MyVal->new(
    fields => {
        'foobar.barbaz' => {
            min_length => 5,
            multiples  => 1
        }
    },
    params => {'foobar.barbaz' => [join('', 1 .. 4), join('', 1 .. 5),]}
);

ok !$v2->validate('foobar.barbaz'), 'validation does not pass';
ok $v2->error_count == 1,
  '1 errors set, 1 wrong element of the param array value';
ok $v2->errors_to_string =~ /#/,
  'error message identifies the problem param array element';

my $v3 = MyVal->new(
    fields => {'foobar.barbaz:0' => {min_length => 5}},
    params => {
        'foobar.barbaz:0' => join('', 1 .. 4),
        'foobar.barbaz:1' => join('', 1 .. 5)
    }
);

ok !$v3->validate('foobar.barbaz:0'), 'validation does not pass';
ok $v3->error_count == 1,
  '1 errors set, 1 wrong element of the param array value';
ok $v3->errors_to_string =~ /less than 5/,
  'error message identifies the problem param array element';

my $v4 = MyVal->new(
    fields => {'foobar.barbaz' => {min_length => 5}},
    params => {'foobar.barbaz' => join('', 1 .. 4)}
);

ok !$v4->validate('foobar.barbaz'), 'validation does not pass';
ok $v4->error_count == 1,
  '1 errors set, 1 wrong element of the param array value';
ok $v4->errors_to_string !~ /#/,
  'error message identifies the problem param in not an array element';
