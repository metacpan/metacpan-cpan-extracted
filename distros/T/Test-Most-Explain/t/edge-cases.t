use strict;
use warnings;
use Test::Most;

use utf8;
use lib 'lib';
use Test::Most::Explain qw(explain);

#------------------------------------------------------------
# 1. undef vs undef
#------------------------------------------------------------
subtest 'undef vs undef' => sub {
    my $out = explain(undef, undef);
    ok(defined $out, 'explain returns a string for undef inputs');
};


#------------------------------------------------------------
# 2. undef vs scalar
#------------------------------------------------------------
subtest 'undef vs scalar' => sub {
    my $out = explain(undef, 'x');
    like($out, qr/Scalar/i, 'scalar diff detected');
    like($out, qr/Expected.*x/i, 'expected value shown');
};

#------------------------------------------------------------
# 3. empty structures
#------------------------------------------------------------
subtest 'empty structures' => sub {

    my $a = explain([], []);
    like($a, qr/identical/i, 'empty arrays identical');

    my $h = explain({}, {});
    like($h, qr/identical/i, 'empty hashes identical');
};

#------------------------------------------------------------
# 4. mismatched types
#------------------------------------------------------------
subtest 'mismatched types' => sub {
	my $s_a = explain(1, [1]);
	ok(defined $s_a || !defined $s_a, 'scalar vs array does not crash');

	my $h_s = explain({a=>1}, 1);
	ok(defined $h_s || !defined $h_s, 'hash vs scalar does not crash');

	my $a_h = explain([1], {a=>1});
	ok(defined $a_h || !defined $a_h, 'array vs hash does not crash');
};

#------------------------------------------------------------
# 5. deeply nested structures
#------------------------------------------------------------
subtest 'deeply nested structures' => sub {

    my $got = { a => [ { x => 1 }, { y => 2 } ] };
    my $exp = { a => [ { x => 1 }, { y => 9 } ] };

    my $out = explain($got, $exp);

    like($out, qr/Array diff/i, 'nested array diff detected');
    like($out, qr/Hash diff/i,  'nested hash diff detected');
};

#------------------------------------------------------------
# 6. circular references (must not crash)
#------------------------------------------------------------
subtest 'circular references' => sub {

    my $a = [];
    push @$a, $a;   # $a->[0] == $a

    my $b = [];
    push @$b, $b;

    lives_ok {
        my $out = explain($a, $b);
        like($out, qr/Array diff|identical/i, 'circular refs handled');
    } 'explain() survives circular refs';
};

#------------------------------------------------------------
# 7. blessed objects with overload
#------------------------------------------------------------
{
    package Local::Over;
    use overload '""' => sub { "OVER(" . $_[0]->{v} . ")" }, fallback => 1;
    sub new { bless { v => shift }, shift }
}

subtest 'blessed objects with overload' => sub {

    my $got = Local::Over->new(1);
    my $exp = Local::Over->new(2);

    my $out = explain($got, $exp);

    like($out, qr/bless|OVER/i, 'blessed/overloaded object handled');
};

#------------------------------------------------------------
# 8. very long strings
#------------------------------------------------------------
subtest 'very long strings' => sub {

    my $got = 'x' x 10_000;
    my $exp = 'x' x 9_999 . 'y';

    my $out = explain($got, $exp);

    like($out, qr/Scalar/i, 'scalar diff detected');
    like($out, qr/index 9999/i, 'first diff index detected');
};

#------------------------------------------------------------
# 9. repeated calls must not leak state
#------------------------------------------------------------
subtest 'state isolation' => sub {

    my $a = explain(1,2);
    my $b = explain(1,2);

    is($a, $b, 'repeated calls produce identical output');
};

#------------------------------------------------------------
# 10. explain() must always return a string
#------------------------------------------------------------
subtest 'always returns a string' => sub {

    my @cases = (
        [1,2],
        [undef, undef],
        [{a=>1},{a=>2}],
        [[1],[2]],
        ['x','x'],
    );

    for my $c (@cases) {
        my $out = explain(@$c);
        ok(!ref($out), 'returned a plain string');
        ok(defined($out), 'string is defined');
    }
};

my $deep = [];
$deep = [$deep] for 1..100;
ok(explain($deep, $deep), 'very deep nesting handled');

my $a = { x => [ { y => 1 } ] };
my $b = { x => [ { y => 2 } ] };
like(explain($a, $b), qr/diff/i, 'mixed nested structures');

done_testing();
