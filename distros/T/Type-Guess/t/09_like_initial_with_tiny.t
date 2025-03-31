use strict;
use warnings;
use Test::More;
use Type::Guess;
use Mojo::Util qw/dumper/;

my @list;
my $str;

# Test case 1: Strings
@list = qw/a b cd efg hijk/;
$str = Type::Guess->with_roles("+Tiny")->new(@list);

is($str->type, 'Str', 'Type is Str');
is($str->precision, 0, 'Precision is 0');
ok($str->length >= 4, 'Length is at least the longest Str length');
is($str->integer_chars, 0, 'Integer_Chars count is 0');
like($str->to_string, qr/%\-/, 'String format looks correct');

is_deeply([ map { $str->($_) } @list ], [ "a   ", "b   ", "cd  ", "efg ", "hijk" ], "formatting strings works");

# Test case 2: Integer_Chars and floats
@list = qw/1 23 456 12000 12.0/;
$str = Type::Guess->with_roles("+Tiny")->new(@list);

is($str->type, 'Int', 'Type is int');
is($str->precision, 0, 'Precision is 1');
ok($str->length >= 5, 'Length is correct');
ok($str->integer_chars >= 5, 'Integer size matches longest number');
is($str->to_string, '%5i', 'String format for Num is correct');
ok(!$str->signed, 'Strings are not signed');

is_deeply([ map { $str->($_) } @list ], [ "    1", "   23", "  456", 12000, "   12" ], "formatting strings works");

# Test case 3: Floats with precision
@list = qw/1.12345 23 456 12000 12.0/;
$str = Type::Guess->with_roles("+Tiny")->new(@list);

is($str->type, 'Num', 'Type is Num');
is($str->precision, 5, 'Precision is 5');
is($str->integer_chars, 5, 'Integer size is correct');
is($str->to_string, '%11.5f', 'String format for precision 5 is correct');
# is($str->sql, 'float', 'SQL type for Num is correct');

# Modify precision and validate
$str->precision(2);
is($str->to_string, '%8.2f', 'String format updated to precision 2');

# Change type to Str
$str->type("Str");
is($str->type, 'Str', 'Type changed to Str');
is($str->to_string, "%-7s", 'String format updated to Str');

# Test case 4: Percentages
@list = qw/-100% -13% 12.1%/;
$str = Type::Guess->with_roles("+Tiny")->new(@list);

is($str->type, 'Num', 'Type is Num with percentages');
ok($str->precision >= 1, 'Precision for percentages is correct');

ok($str->integer_chars == 4, 'Integer size matches');
like($str->to_string, qr/%/, 'String format includes percentage symbol');


is_deeply([ map { $str->($_) } @list ], [ "-100.0%", " -13.0%", "  12.1%" ], "Formatted percentages are correct");

# Test case 5: Mixed positive and negative integer_chars

@list = (23, +16, -100);

$str = Type::Guess->with_roles("+Tiny")->new(@list);

is($str->type, 'Int', 'Type is int');
is($str->precision, 0, 'Precision for integer_chars is 0');

ok($str->signed, 'Type is signed here');


ok($str->length >= 4, 'Length matches longest integer');
ok($str->integer_chars >= 4, 'Integer size is correct');
like($str->to_string, qr/%\-?\d+/, 'String format for integers is correct');
# is($str->sql, 'integer', 'SQL type is integer');


is_deeply([ map { $str->($_) } @list ], [ "  23", "  16", -100 ], "Formatted signed integers are correct");

done_testing();
