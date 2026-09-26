use strict;
use warnings;
use Test::More;
use Math::BigFloat;
use Math::BigInt;
use Scalar::Util qw(dualvar);
use Text::KDL::XS qw(parse_kdl emit_kdl);

sub emitted { my ($out) = emit_kdl({ n => $_[0] }) =~ /\An (.*)\n\z/; $out }
sub dies_like (&$$) {
    my ($code, $pattern, $name) = @_;
    my $lived = eval { $code->(); 1 };
    ok !$lived && $@ =~ $pattern, $name or diag $lived ? 'did not die' : $@;
}
sub numified { my ($text) = @_; no warnings 'numeric'; my $unused = $text + 0; return $text }

{
    package Local::Stringy;
    use overload '""' => sub { 'stringy' }, fallback => 1;
    sub new { bless {}, shift }
}

# A scalar is a number only when its string value, if it has one, is Perl's
# own rendering of the number.
is emitted(42),                 '42',     'an integer is a number';
is emitted(1.5),                '1.5',    'a float is a number';
is emitted('42'),               '"42"',   'a string of digits is a string';
is emitted('42' + 0),           '42',     'a string turned into a number is a number';
is emitted(numified('42')),     '42',     'a string used as a number, with canonical text, is a number';
is emitted(numified('007')),    '"007"',  'a string used as a number keeps leading zeros';
is emitted(numified('1.50')),   '"1.50"', 'a string used as a number keeps trailing zeros';
is emitted(numified('1e3')),    '"1e3"',  'a string used as a number keeps its exponent';
is emitted(numified(' 42 ')),   '" 42 "', 'a string used as a number keeps its spaces';
is emitted(dualvar(5, 'five')), 'five',   'a dualvar is its string';
is emitted(-0.0),               '-0.0',   'the sign of -0.0 is kept';
is emitted(!!0),                '""',     "perl's false value is the empty string";

# Objects.
is emitted(Math::BigInt->new('123456789012345678901234567890')), '123456789012345678901234567890',
    'a Math::BigInt is written as an exact number';
is emitted(Math::BigFloat->new('-1.25')), '-1.25', 'a Math::BigFloat is written as an exact number';
dies_like { emit_kdl({ n => Math::BigInt->bnan }) } qr/cannot write the Math::BigInt NaN as a KDL number/,
    'a Math::BigInt NaN dies';
is emitted(Local::Stringy->new), 'stringy', 'an object with string overloading is a string';
dies_like { emit_kdl({ n => bless {}, 'Local::Plain' }) } qr/cannot serialize Local::Plain object/,
    'any other object dies in data mode';
dies_like { emit_kdl({ n => \1 }) } qr/cannot serialize SCALAR ref/, 'a scalar reference dies in data mode';

{
    my $node = Text::KDL::XS::Node->new(name => 'n', args => [ Math::BigInt->new(7), Local::Stringy->new ]);
    is emit_kdl($node), "n 7 stringy\n", 'objects are converted the same way in tree mode';
    dies_like { emit_kdl(Text::KDL::XS::Node->new(name => 'n', args => [ bless {}, 'Local::Plain' ])) }
        qr/cannot serialize Local::Plain object/, 'any other object dies in tree mode';
}

# Subclasses of the tree classes are accepted wherever the class is.
{
    @Local::Document::ISA = ('Text::KDL::XS::Document');
    @Local::Node::ISA     = ('Text::KDL::XS::Node');
    @Local::Value::ISA    = ('Text::KDL::XS::Value');
    my $value = Local::Value->new(type => 'string', value => 'v');
    my $node  = Local::Node->new(name => 'n', args => [$value]);
    is emit_kdl(Local::Document->new(nodes => [$node])), "n v\n", 'Document subclass';
    is emit_kdl($node),                                  "n v\n", 'Node subclass';
    is emit_kdl({ n => $value }),                        "n v\n", 'Value subclass in data mode';
}

# Cycles die; shared substructures are written wherever they appear.
{
    my %cyclic = (name => 'x');
    $cyclic{self} = \%cyclic;
    dies_like { emit_kdl(\%cyclic) } qr/cyclic data structure/, 'a cyclic hash dies';

    my @cyclic_array = (1);
    push @cyclic_array, \@cyclic_array;
    dies_like { emit_kdl({ list => \@cyclic_array }) } qr/cyclic data structure/, 'a cyclic array dies';

    my $parent = Text::KDL::XS::Node->new(name => 'parent');
    push @{ $parent->children }, $parent;
    dies_like { emit_kdl($parent) } qr/cyclic data structure/, 'a node that is its own child dies';

    my $shared = { k => 1 };
    is emit_kdl({ a => $shared, b => $shared }), "a {\n    k 1\n}\nb {\n    k 1\n}\n", 'a shared hash is written twice';
    my $child = Text::KDL::XS::Node->new(name => 'c');
    is emit_kdl([ Text::KDL::XS::Node->new(name => 'a', children => [ $child, $child ]) ]),
        "a {\n    c\n    c\n}\n", 'a shared node is written twice';
}

done_testing;
