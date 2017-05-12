#!perl

use strict;
use warnings;

use Test::More tests => 7;

use Util::Underscore;

BEGIN {

    package Local::Ref::Scalar;
    use overload '${}' => sub { die "Unimplemented" };

    package Local::Ref::Array;
    use overload '@{}' => sub { die "Unimplemented" };

    package Local::Ref::Hash;
    use overload '%{}' => sub { die "Unimplemented" };

    package Local::Ref::Code;
    use overload '&{}' => sub { die "Unimplemented" };

    package Local::Ref::Glob;
    use overload '*{}' => sub { die "Unimplemented" };

    package Local::Ref::Regex;
    use overload 'qr' => sub { die "Unimplemented" };
}

{
    # to avoid "used only once" warnings
    our $test_object;
    our $test_ref
}

my %overloaded_objects = (
    scalar => (bless [] => 'Local::Ref::Scalar'),
    array => (bless {} => 'Local::Ref::Array'),
    hash  => (bless [] => 'Local::Ref::Hash'),
    code  => (bless [] => 'Local::Ref::Code'),
    glob  => (bless [] => 'Local::Ref::Glob'),
    regex => (bless [] => 'Local::Ref::Regex'),
);

my %objects = (
    scalar => (
        bless \do { my $o }
            => 'Local::Foo'
    ),
    array => (bless [] => 'Local::Foo'),
    hash => (bless               {}                      => 'Local::Foo'),
    code => (bless sub           { die "Unimplemented" } => 'Local::Foo'),
    glob => (bless \*test_object => 'Local::Foo'),
);

my %refs = (
    scalar => \1,
    array  => [],
    hash   => {},
    code   => sub { die "Unimplemented" },
    glob   => \*test_ref,

    # !!! regex   => qr//, regexes are special, as they are blessed objects!
);

subtest '_::is_ref' => sub {
    plan tests => 7 + (keys %refs) + (keys %overloaded_objects);

    for (keys %refs) {
        ok _::is_ref $refs{$_}, "positive $_";
    }
    ok !_::is_ref qr//, "negative regex";

    ok !_::is_ref undef, "negative undef";
    ok !_::is_ref 'Foo', "negative string";
    ok !_::is_ref 42,    "negative number";
    ok !_::is_ref $objects{scalar}, "negative object";

    for (keys %overloaded_objects) {
        ok !_::is_ref $overloaded_objects{$_}, "negative overloaded object $_";
    }

    ok _::is_ref,  "positive default argument" for \1;
    ok !_::is_ref, "negative default argument" for undef;
};

subtest '_::is_scalar_ref' => sub {
    plan tests => 9 + (keys %refs) - 1;

    ok _::is_scalar_ref $refs{scalar}, "positive plain ref";
    ok _::is_scalar_ref $overloaded_objects{scalar},
        "positive overloaded object";

    ok !_::is_scalar_ref undef, "negative undef";
    ok !_::is_scalar_ref 'Foo', "negative string";
    ok !_::is_scalar_ref 42,    "negative number";
    ok !_::is_scalar_ref $objects{scalar}, "negative object";
    for (grep { $_ ne 'scalar' } keys %refs) {
        ok !_::is_scalar_ref $refs{$_}, "negative ref $_";
    }

    ok _::is_scalar_ref,  "positive default argument" for $refs{scalar};
    ok !_::is_scalar_ref, "negative default argument" for undef;

    # additionally, test that references to references are also handled:
    ok _::is_scalar_ref \\1, "positive ref ref";
};

subtest '_::is_array_ref' => sub {
    plan tests => 8 + (keys %refs) - 1;

    ok _::is_array_ref $refs{array},               "positive plain ref";
    ok _::is_array_ref $overloaded_objects{array}, "positive overloaded object";

    ok !_::is_array_ref undef, "negative undef";
    ok !_::is_array_ref 'Foo', "negative string";
    ok !_::is_array_ref 42,    "negative number";
    ok !_::is_array_ref $objects{array}, "negative object";
    for (grep { $_ ne 'array' } keys %refs) {
        ok !_::is_array_ref $refs{$_}, "negative ref $_";
    }

    ok _::is_array_ref,  "positive default argument" for $refs{array};
    ok !_::is_array_ref, "negative default argument" for undef;
};

subtest '_::is_hash_ref' => sub {
    plan tests => 8 + (keys %refs) - 1;

    ok _::is_hash_ref $refs{hash},               "positive plain ref";
    ok _::is_hash_ref $overloaded_objects{hash}, "positive overloaded object";

    ok !_::is_hash_ref undef, "negative undef";
    ok !_::is_hash_ref 'Foo', "negative string";
    ok !_::is_hash_ref 42,    "negative number";
    ok !_::is_hash_ref $objects{hash}, "negative object";
    for (grep { $_ ne 'hash' } keys %refs) {
        ok !_::is_hash_ref $refs{$_}, "negative ref $_";
    }

    ok _::is_hash_ref,  "positive default argument" for $refs{hash};
    ok !_::is_hash_ref, "negative default argument" for undef;
};

subtest '_::is_code_ref' => sub {
    plan tests => 8 + (keys %refs) - 1;

    ok _::is_code_ref $refs{code},               "positive plain ref";
    ok _::is_code_ref $overloaded_objects{code}, "positive overloaded object";

    ok !_::is_code_ref undef, "negative undef";
    ok !_::is_code_ref 'Foo', "negative string";
    ok !_::is_code_ref 42,    "negative number";
    ok !_::is_code_ref $objects{code}, "negative object";
    for (grep { $_ ne 'code' } keys %refs) {
        ok !_::is_code_ref $refs{$_}, "negative ref $_";
    }

    ok _::is_code_ref,  "positive default argument" for $refs{code};
    ok !_::is_code_ref, "negative default argument" for undef;
};

subtest '_::is_glob_ref' => sub {
    plan tests => 8 + (keys %refs) - 1;

    ok _::is_glob_ref $refs{glob},               "positive plain ref";
    ok _::is_glob_ref $overloaded_objects{glob}, "positive overloaded object";

    ok !_::is_glob_ref undef, "negative undef";
    ok !_::is_glob_ref 'Foo', "negative string";
    ok !_::is_glob_ref 42,    "negative number";
    ok !_::is_glob_ref $objects{glob}, "negative object";
    for (grep { $_ ne 'glob' } keys %refs) {
        ok !_::is_glob_ref $refs{$_}, "negative ref $_";
    }

    ok _::is_glob_ref,  "positive default argument" for $refs{glob};
    ok !_::is_glob_ref, "negative default argument" for undef;
};

subtest '_::is_regex' => sub {
    plan tests => 7 + (keys %refs);

    ok _::is_regex qr//, "positive plain ref";
    ok _::is_regex $overloaded_objects{regex}, "positive overloaded object";

    ok !_::is_regex undef, "negative undef";
    ok !_::is_regex 'Foo', "negative string";
    ok !_::is_regex 42,    "negative number";
    for (keys %refs) {
        ok !_::is_regex $refs{$_}, "negative ref $_";
    }

    ok _::is_regex,  "positive default argument" for qr//;
    ok !_::is_regex, "negative default argument" for undef;
};
