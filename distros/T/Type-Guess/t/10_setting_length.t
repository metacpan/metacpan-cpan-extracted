use strict;
use warnings;
use Test::More;
use Type::Guess;

$\ = "\n"; $, = "\t";

my @list = qw/a b cd efg hijk/;
my $str = Type::Guess->new(@list);

ok($str->length == 4);
ok($str->to_string eq '%-4s');

$str->length(9);
ok($str->length == 9);
ok($str->to_string eq '%-9s');

@list = qw/1 23 456 12000 12.0/;
$str = Type::Guess->new(@list);

ok($str->length == 5, "Length correct");

$str->length(4);
ok($str->integer_chars == 5, "Length unchanged on int");

$str->integer_chars(7);
ok($str->integer_chars == 7, "Length changed on int");


@list = qw/1.12345 23 456 12000 12.0/;
$str = Type::Guess->new(@list);

ok(length $str->(112345.12345) == 12, "Length is correct");
ok($str->length(16) == 16, "Length changed on float");
ok(length $str->(112345.12345) == 16, "Changed length is correct");

$str->integer_chars_ro(12);
ok($str->integer_chars_ro == 5, "Integer chars read-only stay put");

done_testing()
