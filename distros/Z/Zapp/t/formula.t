
=head1 DESCRIPTION

This tests the Zapp::Formula class.

=cut

use Mojo::Base -strict, -signatures;
use Test::Mojo;
use Test::More;
use Zapp::Formula;

my $f = Zapp::Formula->new;

subtest 'parse' => sub {
    my $tree = $f->parse( q{"string"} );
    is_deeply $tree, [ string => q{"string"} ], 'string parsed correctly';

    $tree = $f->parse( q{ "string" } );
    is_deeply $tree, [ string => q{"string"} ], 'whitespace around string literals stripped';

    $tree = $f->parse( q{foo.bar} );
    is_deeply $tree, [ var => qw{foo bar} ], 'var parsed correctly';

    $tree = $f->parse( q{ foo . bar } );
    is_deeply $tree, [ var => qw{foo bar} ], 'whitespace around vars stripped';

    $tree = $f->parse( q{TRUE()} );
    is_deeply $tree, [ call => [ var => 'TRUE' ] ],
        'function call without args parsed correctly'
            or diag explain $tree;

    $tree = $f->parse( q{UPPER("string")} );
    is_deeply $tree, [ call => [ var => 'UPPER' ] => [ string => q{"string"} ] ],
        'function call with args parsed correctly'
            or diag explain $tree;

    $tree = $f->parse( q{ UPPER ( "string" ) } );
    is_deeply $tree, [ call => [ var => 'UPPER' ] => [ string => q{"string"} ] ],
        'whitespace around function call stripped';

    $tree = $f->parse( q{LEFT(LOWER(Foo),2)} );
    is_deeply $tree,
        [
            call => [ var => 'LEFT' ],
            [
                call => [ var => 'LOWER' ],
                [
                    var => 'Foo',
                ],
            ],
            [
                number => 2,
            ],
        ],
        'function call with function call as argument parsed correctly';

    $tree = $f->parse( q{ LEFT ( LOWER ( Foo ) , 2 ) } );
    is_deeply $tree,
        [
            call => [ var => 'LEFT' ],
            [
                call => [ var => 'LOWER' ],
                [
                    var => 'Foo',
                ],
            ],
            [
                number => 2,
            ],
        ],
        'whitespace around nested calls stripped';

    $tree = $f->parse( q{[Foo,"bar",2]} );
    is_deeply $tree,
        [
            array =>
            [ var => 'Foo' ],
            [ string => q{"bar"} ],
            [ number => 2 ],
        ],
        'array literal parsed correctly'
            or diag explain $tree;

    $tree = $f->parse( q{ [ Foo , "bar" , 2 ] } );
    is_deeply $tree,
        [
            array =>
            [ var => 'Foo' ],
            [ string => q{"bar"} ],
            [ number => 2 ],
        ],
        'whitespace around array literal stripped'
            or diag explain $tree;

    $tree = $f->parse( q{[[Foo],["bar"],2]} );
    is_deeply $tree,
        [
            array =>
            [ array => [ var => 'Foo' ] ],
            [ array => [ string => q{"bar"} ] ],
            [ number => 2 ],
        ],
        'nested array literal parsed correctly'
            or diag explain $tree;

    $tree = $f->parse( q[{"foo":Foo,"bar":"bar","2":2}] );
    is_deeply $tree,
        [
            hash =>
            [ q{"foo"}, [ var => 'Foo' ] ],
            [ q{"bar"}, [ string => q{"bar"} ] ],
            [ q{"2"}, [ number => 2 ] ],
        ],
        'hash literal parsed correctly'
            or diag explain $tree;

    $tree = $f->parse( q[{"foo":[Foo],"bar":{"bar":"bar"},"2":2}] );
    is_deeply $tree,
        [
            hash =>
            [ q{"foo"}, [ array => [ var => 'Foo' ] ] ],
            [ q{"bar"}, [ hash => [ q{"bar"} => [ string => q{"bar"} ] ] ] ],
            [ q{"2"}, [ number => 2 ] ],
        ],
        'nested hash literal parsed correctly'
            or diag explain $tree;

    $tree = $f->parse( q[ { "foo" : [ Foo ] , "bar" : { "bar" : "bar" } , "2" : 2 } ] );
    is_deeply $tree,
        [
            hash =>
            [ q{"foo"}, [ array => [ var => 'Foo' ] ] ],
            [ q{"bar"}, [ hash => [ q{"bar"} => [ string => q{"bar"} ] ] ] ],
            [ q{"2"}, [ number => 2 ] ],
        ],
        'whitespace in nested hash literal stripped'
            or diag explain $tree;

    $tree = $f->parse( q[ "foo" & "bar" & "baz" ] );
    is_deeply $tree,
        [
            binop => '&',
            [ string => q{"foo"} ],
            [
                binop => '&',
                [ string => q{"bar"} ],
                [ string => q{"baz"} ],
            ],
        ],
        'multiple binops parsed correctly'
            or diag explain $tree;

    $tree = $f->parse( qq[{\n"foo": "bar",\r\n"baz": 1,\n}] );
    is_deeply $tree,
        [
            hash => [
                q{"foo"} => [
                    string => q{"bar"},
                ],
            ],
            [
                q{"baz"} => [
                    number => 1,
                ],
            ],
        ],
        'formula with newlines is parsed correctly'
            or diag explain $tree;

    subtest 'unclosed string literal' => sub {
        my $tree;
        eval { $tree = $f->parse( q{UPPER(Foo&"Bar)} ) };
        ok $@, 'parse dies for syntax error';
        # The end parenthesis is considered part of the string, so
        # this error is found at the end of input.
        # XXX: "Might be an unclosed string starting at ..."
        like $@, qr{Could not find closing quote for string at end of input},
            'error message is correct';
        ok !$tree, 'nothing returned' or diag explain $tree;
    };

    subtest 'binop missing right-hand side' => sub {
        my $tree;
        eval { $tree = $f->parse( q{UPPER(LOWER(Foo)&)} ) };
        ok $@, 'parse dies for syntax error';
        like $@, qr{Expected expression at 17},
            'error message is correct';
        ok !$tree, 'nothing returned' or diag explain $tree;
    };

    subtest 'illegal character in variable' => sub {
        my $tree;
        eval { $tree = $f->parse( q{Bar:baz} ) };
        ok $@, 'parse dies for syntax error';
        like $@, qr{Expected operator at 3},
            'error message is correct';
        ok !$tree, 'nothing returned' or diag explain $tree;
    };

    subtest 'function missing close parens' => sub {
        my $tree;
        eval { $tree = $f->parse( q{UPPER(bar} ) };
        ok $@, 'parse dies for syntax error';
        like $@, qr{Could not find end parenthesis at end of input},
            'error message is correct';
        ok !$tree, 'nothing returned' or diag explain $tree;
    };

};

subtest 'eval' => sub {
    my $context = {
        Hash => {
            Key => 'success',
        },
        Str => 'string',
    };

    my $result = $f->eval( q{"string"}, $context );
    is $result, 'string', 'string literal';

    $result = $f->eval( q{"hello, \"doug\""}, $context );
    is $result, 'hello, "doug"', 'string literal with escaped quotes';

    $result = $f->eval( q{Hash.Key}, $context );
    is $result, 'success', 'variable lookup from context';

    $result = $f->eval( q{UPPER("foo")}, $context );
    is $result, 'FOO', 'function call';

    $result = $f->eval( q{Str&"Bar"}, $context );
    is $result, 'stringBar', 'binary operator';

    $result = $f->eval( q{Str&"Bar"&Hash.Key}, $context );
    is $result, 'stringBarsuccess', 'series of binary operators';

    $result = $f->eval( q{UPPER("foo"&Str)}, $context );
    is $result, 'FOOSTRING', 'function call takes binary operator expr as argument';

    $result = $f->eval( q{LEFT("foo",2)}, $context );
    is $result, 'fo', 'function call with multiple arguments';

    $result = $f->eval( q{LEFT(UPPER(Str),2)}, $context );
    is $result, 'ST', 'function call with function call as argument';

    $result = $f->eval( q{LOWER("FOO")&UPPER(Str)}, $context );
    is $result, "fooSTRING", 'binary operator with function call as operands';
};

subtest 'resolve' => sub {
    my $context = {
        Hash => {
            Key => 'success',
        },
        Str => 'string',
    };

    my $result = $f->resolve( q{="string"}, $context );
    is $result, 'string', 'scalar with string literal';

    $result = $f->resolve( q{=="string"}, $context );
    is $result, '="string"', 'two =s escapes formula';

    $result = $f->resolve( [ q{="string"}, q{=Hash.Key} ], $context );
    is_deeply $result, [ 'string', 'success' ], 'array is resolved';

    $result = $f->resolve( { foo => [ q{="string"}, q{=Hash.Key} ] }, $context );
    is_deeply $result, { foo => [ 'string', 'success' ] }, 'hash of arrays is resolved';
};

subtest 'built-in functions' => sub {
    subtest 'logic' => sub {
        subtest 'TRUE()' => sub {
            my $result = $f->eval( q{TRUE()} );
            is $result, Mojo::JSON->true, 'true value is returned';
        };

        subtest 'FALSE()' => sub {
            my $result = $f->eval( q{FALSE()} );
            is $result, Mojo::JSON->false, 'false value is returned';
        };

        subtest 'IF( <expression>, <true_result>, <false_result> )' => sub {
            my $result = $f->eval( q{IF(TRUE(),"true","false")} );
            is $result, "true", "<true_result> value is returned when <expression> is true";

            $result = $f->eval( q{IF(FALSE(),"true","false")} );
            is $result, "false", "<false_result> value is returned when <expression> is false";
        };

        subtest 'IFS( <expression>, <result>, ..., <default_result> )' => sub {
            my $result = $f->eval( q{IFS(TRUE(),"true","false")} );
            is $result, "true", "<result> value is returned when <expression> is true (first position)";

            $result = $f->eval( q{IFS(FALSE(),"false",TRUE(),"true","false")} );
            is $result, "true", "<result> value is returned when <expression> is true (second position)";

            $result = $f->eval( q{IFS(FALSE(),"false",FALSE(),"false","true")} );
            is $result, "true", "<default_result> value is returned when all <expression> are false";
        };

        subtest 'AND( <expression>, <...> )' => sub {
            my $result = $f->eval( q{AND(TRUE(),TRUE())} );
            is $result, Mojo::JSON->true, "true value is returned when all <expression> are true";

            $result = $f->eval( q{AND(TRUE(),FALSE())} );
            is $result, Mojo::JSON->false, "false value is returned when one <expression> is false";
        };

        subtest 'OR( <expression>, <...> )' => sub {
            my $result = $f->eval( q{OR(TRUE(),FALSE())} );
            is $result, Mojo::JSON->true, "true value is returned when one <expression> is true";

            $result = $f->eval( q{OR(TRUE(),TRUE())} );
            is $result, Mojo::JSON->true, "true value is returned when all <expression> are true";

            $result = $f->eval( q{OR(FALSE(),FALSE())} );
            is $result, Mojo::JSON->false, "false value is returned when all <expression> are false";
        };

        subtest 'XOR( <expression>, <...> )' => sub {
            my $result = $f->eval( q{XOR(TRUE(),FALSE())} );
            is $result, Mojo::JSON->true, "true value is returned when one <expression> is true";

            $result = $f->eval( q{XOR(TRUE(),TRUE())} );
            is $result, Mojo::JSON->false, "false value is returned when more than one <expression> are true";

            $result = $f->eval( q{OR(FALSE(),FALSE())} );
            is $result, Mojo::JSON->false, "false value is returned when all <expression> are false";
        };

        subtest 'NOT( <expression> )' => sub {
            my $result = $f->eval( q{NOT(TRUE())} );
            is $result, Mojo::JSON->false, "not true is false";

            $result = $f->eval( q{NOT(FALSE())} );
            is $result, Mojo::JSON->true, "not false is true";
        };

        subtest 'EVAL( <string> )' => sub {
            my $result = $f->eval( q{EVAL("TRUE()")} );
            is $result, Mojo::JSON->true, "evaling true is true";

            $result = $f->eval( q{EVAL("TR" & "UE()")} );
            is $result, Mojo::JSON->true, "evaling true is true";
        };

        # - [ ] SWITCH function
        # - [ ] CHOOSE function
    };

    #subtest 'text functions' => sub {
        # - [ ] CONCAT function
        # - [ ] FIXED function
        # - [ ] TRIM function
        # - [ ] TEXTJOIN function
    #};

    #subtest 'date/time' => sub {
        # - [ ] DATE function
        # - [ ] TIME function
        # - [ ] DATEVALUE function
        # - [ ] NOW function
        # - [ ] TODAY function
        # - [ ] YEAR function
        # - [ ] MONTH function
        # - [ ] DAY function
        # - [ ] HOUR function
        # - [ ] MINUTE function
        # - [ ] SECOND function
        # - [ ] WEEKDAY function
        # - [ ] WEEKNUM function
    #};

};

done_testing;

