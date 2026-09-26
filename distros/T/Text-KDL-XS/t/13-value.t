use strict;
use warnings;
use Test::More;
use Text::KDL::XS qw(parse_kdl);

sub Value { Text::KDL::XS::Value->new(@_) }
sub parsed { parse_kdl("n $_[0]\n")->nodes->[0]->args->[0] }
sub dies_like (&$$) {
    my ($code, $pattern, $name) = @_;
    my $lived = eval { $code->(); 1 };
    ok !$lived && $@ =~ $pattern, $name or diag $lived ? 'did not die' : $@;
}

my $inf = 9**9**9;

# Constructor validation.
dies_like { Value(type => 'Number', value => 1) } qr/unknown type 'Number'/, 'unknown type dies';
dies_like { Value(type => 'string', kind => 'float', value => 'x') } qr/'kind' is only allowed for numbers/,
    'kind on a string dies';
dies_like { Value(type => 'string') } qr/a string needs a defined value/, 'string without a value dies';
dies_like { Value(type => 'number', kind => 'float') } qr/a number needs a defined value/, 'number without a value dies';
dies_like { Value(type => 'number', kind => 'Integer', value => 1) } qr/unknown kind 'Integer'/, 'unknown kind dies';
for my $not_integer (1.9, 'abc', 1e20, '18446744073709551616', '-9223372036854775809', ' 42') {
    dies_like { Value(type => 'number', kind => 'integer', value => $not_integer) } qr/is not an integer/,
        "kind integer rejects '$not_integer'";
}
dies_like { Value(type => 'number', kind => 'float', value => 'abc') } qr/'abc' is not a number/,
    'kind float rejects non-numeric text';
for my $not_literal ('hello world', "1\nevil 2", '1e', '', '.5', '0x', '1._5', '#INF') {
    dies_like { Value(type => 'number', kind => 'string', value => $not_literal) } qr/is not a KDL number/,
        "kind string rejects '$not_literal'";
}
for my $literal ('1e400', '0x10', '0o17', '0b101', '-1_000', '+1.5E-3', '#inf', '#-inf', '#nan') {
    is Value(type => 'number', kind => 'string', value => $literal)->value, $literal,
        "kind string accepts '$literal'";
}

# Kind inference and normalisation.
is Value(type => 'number', value => 42)->kind,     'integer', 'a Perl integer is kind integer';
is Value(type => 'number', value => 1.5)->kind,    'float',   'a Perl float is kind float';
is Value(type => 'number', value => '0x1F')->kind, 'string',  'KDL number text is kind string';
dies_like { Value(type => 'number', value => 'abc') } qr/'abc' is not a number/, 'other text is not a number';
is Value(type => 'bool', value => 'yes')->value, 1, 'a true bool is stored as 1';
is Value(type => 'bool', value => 0)->value,     0, 'a false bool is stored as 0';
is Value(type => 'null', value => 5)->value, undef, 'null never has a value';

# as_number always returns a native number.
is parsed('12345678901234567890123')->as_number, 1.2345678901234567e22, 'as_number of a big integer is a float';
is Value(type => 'number', kind => 'string', value => '0x1_0')->as_number,  16,  'as_number reads radix text';
is Value(type => 'number', kind => 'string', value => '-0o17')->as_number, -15,  'as_number reads signed octal';
is Value(type => 'number', kind => 'string', value => '#-inf')->as_number, -$inf, 'as_number of #-inf is -Inf';
my $nan = Value(type => 'number', kind => 'string', value => '#nan')->as_number;
ok $nan != $nan, 'as_number of #nan is NaN';
is sprintf('%g', Value(type => 'number', kind => 'float', value => -0.0)->as_number), '-0',
    'as_number keeps the sign of -0.0';
is Value(type => 'bool', value => 1)->as_number, 1, 'as_number of a bool is 1 or 0';
is Value(type => 'null')->as_number, undef, 'as_number of null is undef';

# as_bignum returns exact Math::BigInt / Math::BigFloat objects.
{
    my $big = parsed('123456789012345678901234567890')->as_bignum;
    isa_ok $big, 'Math::BigInt';
    is "$big", '123456789012345678901234567890', 'as_bignum is exact for big integers';
    my $decimal = parsed('3.141592653589793238462643383279')->as_bignum;
    isa_ok $decimal, 'Math::BigFloat';
    is "$decimal", '3.141592653589793238462643383279', 'as_bignum is exact for long decimals';
    is Value(type => 'number', kind => 'float', value => 0.1)->as_bignum, '0.1', 'as_bignum of a float uses its KDL text';
    is Value(type => 'number', kind => 'string', value => '-0x1F')->as_bignum, '-31', 'as_bignum reads signed hex';
    is Value(type => 'number', kind => 'string', value => '0o777')->as_bignum, '511', 'as_bignum reads octal';
    ok Value(type => 'number', kind => 'string', value => '#inf')->as_bignum->is_inf('+'), 'as_bignum of #inf is +inf';
    is Value(type => 'bool', value => 0)->as_bignum, 0, 'as_bignum of a bool is 1 or 0';
    is Value(type => 'null')->as_bignum, undef, 'as_bignum of null is undef';
    dies_like { Value(type => 'string', value => '1')->as_bignum } qr/is a string, not a number/,
        'as_bignum of a string dies';
}

# as_string spells floats as KDL does.
is parsed('1.0')->as_string,                 '1.0',                 'as_string keeps the decimal point';
is parsed('1e3')->as_string,                 '1000.0',              'as_string of 1e3';
is Value(type => 'number', value => 0.1 + 0.2)->as_string, '0.30000000000000004', 'as_string round-trips';
is parsed('#inf')->as_string,                '#inf',                'as_string of #inf';
is parsed('#-inf')->as_string,               '#-inf',               'as_string of #-inf';
is parsed('#nan')->as_string,                '#nan',                'as_string of #nan';
is parsed('1e400')->as_string,               '1e400',               'as_string of kind string is verbatim';
is parsed('18446744073709551615')->as_string, '18446744073709551615', 'as_string of a UV';

done_testing;
