#!perl

use strict;
use warnings;

use Test::More tests => 11;

use Util::Underscore;

BEGIN {

    package Local::Parent;
    sub meth   { $_[1] }
    sub marker { }

    package Local::Child;
    push our @ISA, 'Local::Parent';

    package Local::Mock;
    sub meth { $_[1] }

    sub DOES {
        my ($self, $what) = @_;
        return 1 if $what eq 'Local::Parent';
        return $self->SUPER::DOES($what);
    }

    package Local::Unrelated;
    sub meth { $_[1] }
}

my %class = (
    parent    => 'Local::Parent',
    child     => 'Local::Child',
    mock      => 'Local::Mock',
    unrelated => 'Local::Unrelated',
);

my %object;
$object{$_} = bless [] => $class{$_} for keys %class;

my $zero_object = bless [] => '0';

subtest 'fixtures' => sub {
    plan tests => 6;

    for (keys %object) {
        is ref $object{$_}, $class{$_}, "instantiation for $_ successful";
    }

    is ref $zero_object, '0', "zero object has correct ref type";
    ok !ref $zero_object, "zero object class appears to be false";
};

subtest 'identity tests' => sub {
    plan tests => 2;

    is \&_::class,       \&_::blessed, "_::class";
    is \&_::is_instance, \&_::does,    "_::is_instance";
};

subtest '_::blessed' => sub {
    plan tests => 2;

    subtest 'boolean usage' => sub {
        plan tests => 11;

        ok _::blessed $object{parent}, "positive object";
        ok _::blessed qr//, "positive regex object";
        ok defined _::blessed $zero_object, "zero object correct return value";

        ok !_::blessed undef, "negative undef";
        ok !_::blessed 42,    "negative number";
        ok !_::blessed "foo", "negative string";
        ok !_::blessed [], "negative array reference";
        ok !_::blessed {}, "negative hash reference";
        ok !_::blessed $class{parent}, "negative class";

        ok _::blessed,  "positive implicit argument" for $object{parent};
        ok !_::blessed, "negative implicit argument" for undef;

    };

    subtest 'return values' => sub {
        plan tests => 8 + (keys %class);

        for (keys %class) {
            is _::blessed $object{$_}, $class{$_}, "positive return value $_";
        }

        is _::blessed $zero_object, '0', "positive return value zero object";
        is _::blessed qr//, 'Regexp', "positive return value Regexp";

        ok !defined _::blessed undef, "negative undef";
        ok !defined _::blessed 42,    "negative number";
        ok !defined _::blessed "foo", "negative string";
        ok !defined _::blessed [], "negative array reference";
        ok !defined _::blessed {}, "negative hash reference";
        ok !defined _::blessed $class{parent}, "negative class";
    };
};

subtest '_::is_object' => sub {
    plan tests => 11;

    ok _::is_object $object{parent}, "positive object";
    ok _::is_object qr//, "positive regex object";
    ok _::is_object $zero_object, "positive zero object";

    ok !_::is_object undef, "negative undef";
    ok !_::is_object 42,    "negative number";
    ok !_::is_object "foo", "negative string";
    ok !_::is_object [], "negative array reference";
    ok !_::is_object {}, "negative hash reference";
    ok !_::is_object $class{parent}, "negative class";

    ok _::is_object,  "positive implicit argument" for $object{parent};
    ok !_::is_object, "negative implicit argument" for undef;
};

subtest '_::class_isa' => sub {
    plan tests => 4;

    ok _::class_isa($class{parent}, $class{parent}), "positive parent";
    ok _::class_isa($class{child},  $class{parent}), "positive child";
    ok !_::class_isa($class{mock},      $class{parent}), "negative mock";
    ok !_::class_isa($class{unrelated}, $class{parent}), "negative unrelated";
};

subtest '_::class_does' => sub {
    plan tests => 4;

    ok _::class_does($class{parent}, $class{parent}), "positive parent";
    ok _::class_does($class{child},  $class{parent}), "positive child";
    ok _::class_does($class{mock},   $class{parent}), "positive mock";
    ok !_::class_does($class{unrelated}, $class{parent}), "negative unrelated";
};

subtest '_::class_can' => sub {
    plan tests => 4;

    ok _::class_can($class{parent}, 'marker'), "positive parent";
    ok _::class_can($class{child},  'marker'), "positive child";
    ok !_::class_can($class{mock},      'marker'), "negative mock";
    ok !_::class_can($class{unrelated}, 'marker'), "negative unrelated";
};

subtest '_::isa' => sub {
    plan tests => 4;

    ok _::isa($object{parent}, $class{parent}), "positive parent";
    ok _::isa($object{child},  $class{parent}), "positive child";
    ok !_::isa($object{mock},      $class{parent}), "negative mock";
    ok !_::isa($object{unrelated}, $class{parent}), "negative unrelated";
};

subtest '_::does' => sub {
    plan tests => 4;

    ok _::does($object{parent}, $class{parent}), "positive parent";
    ok _::does($object{child},  $class{parent}), "positive child";
    ok _::does($object{mock},   $class{parent}), "positive mock";
    ok !_::does($object{unrelated}, $class{parent}), "negative unrelated";
};

subtest '_::can' => sub {
    plan tests => 4;

    ok _::can($object{parent}, 'marker'), "positive parent";
    ok _::can($object{child},  'marker'), "positive child";
    ok !_::can($object{mock},      'marker'), "negative mock";
    ok !_::can($object{unrelated}, 'marker'), "negative unrelated";
};

subtest '_::safecall' => sub {
    plan tests => 8 + (keys %object);

    for (keys %object) {
        is _::safecall($object{$_}, meth => "foo"), "foo", "positive $_";
    }

    ok !defined _::safecall(undef, meth => "foo"), "negative undef";
    ok !defined _::safecall("bar", meth => "foo"), "negative string";
    ok !defined _::safecall(42,    meth => "foo"), "negative number";
    ok !defined _::safecall([],    meth => "foo"), "negative reference";

    my @ret = _::safecall(undef, meth => "foo");
    ok @ret == 0, "negative response in list context";

    # However, safecall only asserts that the invocant is an object
    #  * It does not allow packages, and
    #  * it does not check that the invocant will respond to the method
    ok !defined _::safecall($class{parent}, meth => "bar", "foo"),
        "negative package";
    {
        local $@;
        my $result = eval { _::safecall $object{mock}, marker => "foo" };
        my $error = $@;
        ok !defined $result, "negative nonexistent method";
        like $error, qr/^Can't locate object method "marker" via package/;
    }
};
