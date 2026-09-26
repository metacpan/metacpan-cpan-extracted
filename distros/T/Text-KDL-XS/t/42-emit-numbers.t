use strict;
use warnings;
use Test::More;
use Text::KDL::XS qw(parse_kdl emit_kdl);

sub emitted_text { my ($out) = emit_kdl({ n => $_[0] }, @_[1 .. $#_]) =~ /\An (.*)\n\z/; $out }
sub parsed { parse_kdl("n $_[0]\n")->nodes->[0]->args->[0] }
sub dies_like (&$$) {
    my ($code, $pattern, $name) = @_;
    my $lived = eval { $code->(); 1 };
    ok !$lived && $@ =~ $pattern, $name or diag $lived ? 'did not die' : $@;
}
# A number payload that bypasses Value->new, to test the XS layer's own checks.
sub raw_number { bless { type => 'number', kind => $_[0], value => $_[1] }, 'Text::KDL::XS::Value' }

my $inf = 9**9**9;
my $nan = $inf - $inf;

# Floats are written with the shortest text that reads back as the same double.
my %float_text = (
    '1908124443056.387'  => 1908124443056.387,
    '123456789012345.0'  => 123456789012345.0,
    '0.30000000000000004' => 0.1 + 0.2,
    '9007199254740992.0' => 2**53,
    '123456789.0'        => 123456789.0,
    '2.2250738585072014e-308' => 2.2250738585072014e-308,
    '2.3e-308'           => 2.3e-308,
    '4.94065645841247e-324' => 5e-324,
    '-0.0'               => -0.0,
    '1e+21'              => 1e21,
    '0.5'                => 0.5,
);
for my $text (sort keys %float_text) {
    is emitted_text($float_text{$text}), $text, "float $text";
}
for my $float (2.2250738585072014e-308, 2.3e-308, 1.5e-308, 3.5771699383255836e-303, 1e-320, 1e23) {
    is parsed(emitted_text($float))->as_number, $float, sprintf('%.17g round-trips', $float);
}
is sprintf('%g', parse_kdl(emit_kdl({ n => -0.0 }))->nodes->[0]->args->[0]->as_number), '-0',
    '-0.0 keeps its sign through a round trip';

{
    srand 20260926;
    my @doubles;
    while (@doubles < 10_000) {
        my $double = unpack 'd<', pack 'V2', int rand 2**32, int rand 2**32;
        my $probe  = $double;    # comparing would give $double an integer value too
        push @doubles, $double if $probe == $probe && abs($probe) != $inf;
    }
    my $kdl = emit_kdl({ n => \@doubles });
    my @texts = split / /, ($kdl =~ /\An (.*)\n\z/)[0];
    is scalar(grep { !/[.e]/ } @texts), 0, 'every emitted float has a decimal point or an exponent';
    my @read_back = map { $_->as_number } @{ parse_kdl($kdl)->nodes->[0]->args };
    my @different = grep { $read_back[$_] != $doubles[$_] } 0 .. $#doubles;
    is scalar @different, 0, '10000 random doubles read back unchanged'
        or diag sprintf '%.17g', $doubles[ $different[0] ];
}

# Non-finite values have no KDL v1 spelling.
is emitted_text([ $inf, -$inf, $nan ]), '#inf #-inf #nan', 'non-finite floats in KDL v2';
dies_like { emit_kdl({ n => $inf }, version => 1) } qr/KDL v1 has no representation for inf\/nan/,
    'a non-finite float dies in KDL v1';
dies_like { emit_kdl({ n => raw_number(string => '#nan') }, version => 1) } qr/KDL v1 has no representation/,
    'a #nan literal dies in KDL v1';

# Integers are written exactly over the whole native range.
is emitted_text([ 9223372036854775807, -9223372036854775808, 9223372036854775808, 18446744073709551615 ]),
    '9223372036854775807 -9223372036854775808 9223372036854775808 18446744073709551615',
    'IV_MAX, IV_MIN, 2**63 and UV_MAX are written exactly';

# Parsed integers that fit IV or UV are kind integer; larger ones stay text.
for my $integer (qw(2147483648 4294967295 -2147483648 -9223372036854775808 9223372036854775808 18446744073709551615)) {
    my $value = parsed($integer);
    ok $value->kind eq 'integer' && $value->value eq $integer, "$integer parses as an integer";
}
is parsed('0xFFFFFFFF')->value, 4294967295, '0xFFFFFFFF parses as the integer 4294967295';
for my $big (qw(18446744073709551616 -9223372036854775809)) {
    is parsed($big)->kind, 'string', "$big stays kind string";
}

# Parsed floats are correctly rounded.
for my $literal (qw(1e23 -9.28967186747759e-78 4.48989800528767e-247 0.1)) {
    is parsed($literal)->value, 0 + $literal, "$literal parses to the nearest double";
}

# String-encoded numbers are written verbatim, but only valid KDL numbers.
for my $literal ('0x1F', '1_000', '1e285', '-9223372036854775808', '+1.5E-3') {
    is emitted_text(raw_number(string => $literal)), $literal, "number text $literal is written verbatim";
}
for my $bad ('1 evil=#true', '', "1\n2", '0x', 'abc', "1\xFF") {
    (my $shown = $bad) =~ s/\n/\\n/g;
    dies_like { emit_kdl({ n => raw_number(string => $bad) }) } qr/is not a KDL number/, "number text '$shown' dies";
}
dies_like { emit_kdl({ n => raw_number(Integer => 5) }) } qr/unknown number kind 'Integer'/, 'an unknown kind dies';
dies_like { emit_kdl({ n => raw_number(undef, 5) }) } qr/number has no kind/, 'a missing kind dies';
dies_like { emit_kdl({ n => raw_number(integer => 1e20) }) } qr/is not an integer/, 'kind integer with 1e20 dies';
dies_like { emit_kdl({ n => raw_number(integer => '12abc') }) } qr/is not an integer/, "kind integer with '12abc' dies";
dies_like { emit_kdl({ n => raw_number(float => 'abc') }) } qr/is not a number/, "kind float with 'abc' dies";

done_testing;
