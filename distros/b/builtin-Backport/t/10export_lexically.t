#!/usr/bin/perl

use v5.18;
use warnings;

use builtin;
no warnings 'experimental::builtin';

use Test::More;

# Lexical export
{
    my $name;
    BEGIN {
        use builtin qw( export_lexically );

        $name = "message";
        export_lexically $name => sub { "Hello, world" };
    }

    is(message(), "Hello, world", 'Lexically exported sub is callable');
    ok(!__PACKAGE__->can("message"), 'Exported sub is not visible via ->can');

    is($name, "message", '$name argument was not modified by export_lexically');

    our ( $scalar, @array, %hash );
    BEGIN {
        use builtin qw( export_lexically );

        export_lexically
            '$SCALAR' => \$scalar,
            '@ARRAY'  => \@array,
            '%HASH'   => \%hash;
    }

    $::scalar = "value";
    is($SCALAR, "value", 'Lexically exported scalar is accessible');

    @::array = ('a' .. 'e');
    is(scalar @ARRAY, 5, 'Lexically exported array is accessible');

    %::hash = (key => "val");
    is($HASH{key}, "val", 'Lexically exported hash is accessible');
}

# imports are lexical; should not be visible here
{
    { use builtin 'true'; }

    my $ok = eval 'true()'; my $e = $@;
    ok(!$ok, 'true() not visible outside of lexical scope');
    like($e, qr/^Undefined subroutine &main::true called at /, 'failure from true() not visible');
}

# lexical imports work fine in a variety of situations
{
    use if $^V lt v5.26, feature  => "lexical_subs";
    no  if $^V lt v5.26, warnings => "experimental::lexical_subs";

    sub regularfunc {
        use builtin 'true';
        return true;
    }
    ok(regularfunc(), 'true in regular sub');

    my sub lexicalfunc {
        use builtin 'true';
        return true;
    }
    ok(lexicalfunc(), 'true in lexical sub');

    my $coderef = sub {
        use builtin 'true';
        return true;
    };
    ok($coderef->(), 'true in anon sub');

    sub recursefunc {
        use builtin 'true';
        return recursefunc() if @_;
        return true;
    }
    ok(recursefunc("rec"), 'true in self-recursive sub');

    my $recursecoderef = sub {
        use feature 'current_sub';
        use builtin 'true';
        return __SUB__->() if @_;
        return true;
    };
    ok($recursecoderef->("rec"), 'true in self-recursive anon sub');
}

done_testing;
