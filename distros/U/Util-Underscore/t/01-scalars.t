#!perl -T

use strict;
use warnings;

use Test::More tests => 14;
use Test::Exception;

use Util::Underscore;

subtest 'identity tests' => sub {
    plan tests => 1;
    is \&_::new_dual, \&Scalar::Util::dualvar, "_::new_dual";
};

subtest 'dualvar' => sub {
    plan tests => 7;

    my $dual = _::new_dual - 42, "foo bar";
    ok defined $dual, "construction successful";

    ok _::is_dual $dual, "_::is_dual positive";
    ok !_::is_dual - 42, "_::is_dual negative";
    ok _::is_dual,  "_::is_dual positive default argument" for $dual;
    ok !_::is_dual, "_::is_dual negative default argument" for -42;

    is "$dual", "foo bar", "stringification";
    is 0 + $dual, "-42", "numification";
};

subtest '_::is_vstring' => sub {
    plan tests => 7;

    ok _::is_vstring v1.2.3, "positive";

    ok !_::is_vstring undef,          "negative undef";
    ok !_::is_vstring "v1.2.3",       "negative string";
    ok !_::is_vstring 1.2,            "negative float";
    ok !_::is_vstring "\x01\x02\x03", "negative binary string";

    ok _::is_vstring,  "positive default argument" for v1.2.3;
    ok !_::is_vstring, "negative default argument" for undef;
};

subtest '_::is_readonly' => sub {
    plan tests => 4;
    my $var = 42;
    ok _::is_readonly 42, "positive";
    ok !_::is_readonly $var, "negative";
    ok _::is_readonly,  "positive default argument" for 42;
    ok !_::is_readonly, "negative default argument" for $var;
};

subtest '_::const' => sub {
    plan tests => 4;

    subtest "mutation during constification" => sub {
        plan tests => 3;

        my $var = 42;
        ok !_::is_readonly $var, "fixture: variable is variable";
        _::const $var => do { my $x = "foo" };
        ok _::is_readonly $var, "variable made readonly";
        is $var, "foo", "variable reassigned by _::const";
    };

    subtest "scalars" => sub {
        plan tests => 4;

        _::const my $const => \do { my $x = my $y = "foo" };
        ok _::is_readonly $const, "constant is readonly";
        is ref $const, 'SCALAR', "constant has correct type";
        ok _::is_readonly $$const, "constant is deeply immutable";
        is $$const, "foo", "data structure is deeply as expected";
    };

    subtest "arrays" => sub {
        plan tests => 5;

        _::const my @const => (1, 2, 3);
        is_deeply \@const, [ 1, 2, 3 ], "created correct data structure";
        dies_ok { push @const, 4 } "constness resents additions";
        dies_ok { pop @const } "constness resents removal";
        dies_ok { @const = () } "constness resents clearing";
        dies_ok { $const[1] = "foo" } "constness resents member reassignment";
    };

    subtest "hashes" => sub {
        plan tests => 5;

        _::const my %const => (a => 1, b => 2);
        is_deeply \%const, { a => 1, b => 2 }, "created correct data structure";
        dies_ok { $const{c} = 3 } "constness resents additions";
        dies_ok { delete $const{a} } "constness resents removal";
        dies_ok { %const = () } "constness resents clearing";
        dies_ok { $const{a} = "foo" } "constness resents member reassignment";
    };
};

sub _find_tainted_hash_entries {
    my ($tainted, $untainted, $hash) = @_;
    for my $key (sort keys %$hash) {
        if (_::is_tainted $hash->{$key}) {
            push @$tainted, $key;
        }
        else {
            push @$untainted, $key;
        }
    }
}

subtest '_::is_tainted' => sub {
    plan tests => 5;

    my $untainted   = 42;
    ok !_::is_tainted $untainted, "untainted variable is untainted";
    ok !_::is_tainted, "untainted implicit variable is untainted";

    _find_tainted_hash_entries(
        \my @tainted_env_keys,
        \my @untainted_env_keys,
        \%ENV,
    );

    ok 0+@tainted_env_keys, "environment variables are tainted"
        or do {
            diag("Tainted   ENV variables: [@tainted_env_keys]");
            diag("Untainted ENV variables: [@untainted_env_keys]");
        };

    my ($taint_key) = @tainted_env_keys;
    my $tainted     = $ENV{$taint_key};

    ok _::is_tainted $tainted, "tainted variable is tainted";
    ok _::is_tainted, "tainted implicit variable is tainted" for $tainted;
};

subtest '_::alias' => sub {
    ## no critic (ProhibitStringyEval)
    if (not eval q{ require Data::Alias; 1 }) {
        plan skip_all => q(Data::Alias not installed);
    }

    # In case Data::Alias doesn't exist, the below calls to _::alias will fail
    # to compile. Therefore, optionally inject this stand-in.
    BEGIN {
        *_::alias = sub { die "_::alias not available" } if not *_::alias{CODE};
    }

    plan tests => 4;

    my $orig = 42;
    _::alias my $alias = $orig;
    my $copy = $orig;

    is $alias, $orig, "positive alias value comparison";
    is $copy,  $orig, "positive copy value comparison";
    is \$alias,  \$orig, "positive alias reference comparison";
    isnt \$copy, \$orig, "negative copy reference comparison";
};

BEGIN {

    package Local::Stringy;

    use overload '""' => sub {
        my ($self) = @_;
        return $$self;
    };

    sub new {
        my ($class, $val) = @_;
        return bless \$val => $class;
    }
}

my $stringy = Local::Stringy->new("foo");

subtest '_::is_plain' => sub {
    plan tests => 7;
    ok _::is_plain 42,    "positive number";
    ok _::is_plain "foo", "positive string";
    ok !_::is_plain [], "negative ref";
    ok !_::is_plain undef, "negative undef";
    ok !_::is_plain $stringy, "negative stringy object";
    ok _::is_plain,  "positive implicit argument" for "foo";
    ok !_::is_plain, "negative implicit argument" for undef;
};

subtest '_::is_string' => sub {
    plan tests => 7;
    ok _::is_string 42,    "positive number";
    ok _::is_string "foo", "positive string";
    ok !_::is_string [], "negative ref";
    ok !_::is_string undef, "negative undef";
    ok _::is_string $stringy, "positive stringy object";
    ok _::is_string,  "positive implicit argument" for "foo";
    ok !_::is_string, "negative implicit argument" for undef;
};

{

    package Local::IsBool;
    use overload bool => sub { 1 };
}

{

    package Local::IsString;
    use overload q[""] => sub { "foo" };

    # While a "bool" method is autogenerated, this doesn't show the intent
    # to overload "bool". Therefore, a Local::IsString instance won't be
    # considered to be a boolean by "_::is_bool".
    # Also, overload::Method doesn't return autogenerated methods.
}

{

    package Local::OrdinaryObject;
    1;
}

subtest '_::is_bool' => sub {
    plan tests => 10;
    ok _::is_bool undef, "positive undef";
    ok _::is_bool 1,     "positive number 1";
    ok _::is_bool 0,     "positive number 0";
    ok _::is_bool "foo", "positive string";
    ok !_::is_bool [], "negative reference";

    my $booly   = bless [] => 'Local::IsBool';
    my $stringy = bless [] => 'Local::IsString';
    my $objy    = bless [] => 'Local::OrdinaryObject';
    ok _::is_bool $booly,    "positive bool-overloaded object";
    ok !_::is_bool $stringy, "positive string-overloaded object";
    ok !_::is_bool $objy,    "negative non-overloaded object";

    ok _::is_bool,  "positive implicit argument" for 1;
    ok !_::is_bool, "negative implicit argument" for [];
};

subtest '_::is_identifier' => sub {
    plan tests => 11;
    ok _::is_identifier 'foo_bar',   "positive plain";
    ok _::is_identifier 'a',         "positive single letter";
    ok _::is_identifier 'a3',        "positive letter and digit";
    ok _::is_identifier '_',         "positive underscore";
    ok _::is_identifier 'Foo',       "positive plain uppercase";
    ok !_::is_identifier '3',        "negative digit";
    ok !_::is_identifier undef,      "negative undef";
    ok !_::is_identifier '',         "negative empty string";
    ok !_::is_identifier 'Foo::Bar', "negative package name";
    ok _::is_identifier,  "positive implicit argument" for 'foo';
    ok !_::is_identifier, "negative implicit argument" for undef;
};

subtest '_::is_package' => sub {
    plan tests => 13;
    ok _::is_package 'FooBar',     "positive plain";
    ok _::is_package 'a',          "positive single letter";
    ok _::is_package 'a3',         "positive letter and digit";
    ok _::is_package '_',          "positive underscore";
    ok _::is_package 'Foo::Bar',   "positive composite name";
    ok _::is_package 'Foo::3',     "positive composite name digits";
    ok _::is_package 'A::B::C::D', "positive composite name long";
    ok !_::is_package undef,       "negative undef";
    ok !_::is_package '',          "negative empty string";
    ok !_::is_package 'Foo::',     "negative trailing colon";
    ok !_::is_package q(Foo'Bar),  "negative single quote separator";
    ok _::is_package,  "positive implicit argument" for 'foo';
    ok !_::is_package, "negative implicit argument" for undef;
};

subtest '_::chomp' => sub {
    plan tests => 8;
    my $end = 'bar';
    my $str  = 'foobarbar';
    my $expected_str  = 'foobar';
    my @strs = qw/ foobarbar wunderbar /;
    my @expected_strs = qw/ foobar wunder /;

    my $before = $str;
    _::chomp $str, $end;
    is $str, $before, "scalar arguments remain unchanged";

    $before = \@strs;
    _::chomp \@strs, $end;
    is_deeply \@strs, $before, "array arguments remain unchanged";

    is +(_::chomp $str, $end), $expected_str, "positive scalar with explicit \$end";
    is_deeply +(_::chomp \@strs, $end), \@expected_strs, "positive array with explicit \$end";

    local $/ = $end;
    is +(_::chomp $str), $expected_str, "positive scalar with implicit \$end";
    is_deeply +(_::chomp \@strs), \@expected_strs, "positive array with implicit \$end";

    is _::chomp, $expected_str, "positive implicit scalar" for $str;
    is_deeply _::chomp, \@expected_strs, "positive implicit array" for \@strs;
};

subtest '_::index' => sub {
    plan tests => 7;
    my $haystack = 'foobar';
    my ($needle_start,  $pos_start)  = ('foo', 0);
    my ($needle_middle, $pos_middle) = ('bar', 3);
    my ($needle_nether, $pos_nether) = ('baz', undef);

    is +(_::index $haystack, $needle_start),  $pos_start, "positive start with implicit \$start";
    is +(_::index $haystack, $needle_middle), $pos_middle, "positive middle with implicit \$start";

    is +(_::index $haystack, $needle_start,  $pos_start),  $pos_start,  "positive start with explicit \$start=start";
    is +(_::index $haystack, $needle_middle, $pos_start),  $pos_middle, "positive middle with explicit \$start=start";
    is +(_::index $haystack, $needle_middle, $pos_middle), $pos_middle, "positive middle with explicit \$start=middle";

    is +(_::index $haystack, $needle_nether), $pos_nether, "negative nether with implicit \$start";
    is +(_::index $haystack, $needle_start, $pos_middle), $pos_nether, "negative start with explicit \$start=middle";
};
