use strict;
use warnings;

use Test::More;
use B::Deparse;
use Variable::Declaration;

my @OK = (
    # expression => deparsed text
    'let $foo' => [
        q!my $foo;!,
        q!Variable::Declaration::register_info(\$foo, {'declaration', 'let', 'attributes', undef, 'type', undef});!,
    ],
    'let ($foo)' => [
        q!my $foo;!, # equivalent to 'my ($foo)'
        q!Variable::Declaration::register_info(\$foo, {'declaration', 'let', 'attributes', undef, 'type', undef});!,
    ],
    'let $foo:Good' => [
        $] > 5.026003 ? (
            q!my $foo :Good;!,
        ) : (
            q!'attributes'->import('main', \$foo, 'Good'), my $foo;!,
        ),
        q!Variable::Declaration::register_info(\$foo, {'declaration', 'let', 'attributes', ':Good', 'type', undef});!,
    ],
    'let $foo = 123' => [
        q!my $foo = 123;!,
        q!Variable::Declaration::register_info(\$foo, {'declaration', 'let', 'attributes', undef, 'type', undef});!,
    ],
    'let $foo = 0' => [
        q!my $foo = 0;!,
        q!Variable::Declaration::register_info(\$foo, {'declaration', 'let', 'attributes', undef, 'type', undef});!,
    ],
    'let Str $foo' => [
        q!my $foo;!,
        q!Variable::Declaration::register_info(\$foo, {'declaration', 'let', 'attributes', undef, 'type', Str});!,
        q!Variable::Declaration::croak(Str->get_message($foo)) unless Str->check($foo);!,
        q!&Variable::Declaration::type_tie(\$foo, Str, $foo);!,
    ],
    'static $foo' => [
        q!state $foo;!,
        q!Variable::Declaration::register_info(\$foo, {'declaration', 'static', 'attributes', undef, 'type', undef});!,
    ],
    'static ($foo)' => [
        q!state $foo;!, # equivalent to 'state ($foo)'
        q!Variable::Declaration::register_info(\$foo, {'declaration', 'static', 'attributes', undef, 'type', undef});!,
    ],
    'static $foo:Good'  => [
        $] =~ m{^5.012} ? (
            # https://rt.perl.org/Public/Bug/Display.html?id=68658
            q!'attributes'->import('main', \$foo, 'Good'), my $foo;!,
        ) : $] > 5.026003 ? (
            q!state $foo :Good;!,
        ) : (
            q!'attributes'->import('main', \$foo, 'Good'), state $foo;!,
        ),
        q!Variable::Declaration::register_info(\$foo, {'declaration', 'static', 'attributes', ':Good', 'type', undef});!,
    ],
    
    'static $foo = 123' => [
        q!state $foo = 123;!,
        q!Variable::Declaration::register_info(\$foo, {'declaration', 'static', 'attributes', undef, 'type', undef});!,
    ],
    'static $foo = 0' => [
        q!state $foo = 0;!,
        q!Variable::Declaration::register_info(\$foo, {'declaration', 'static', 'attributes', undef, 'type', undef});!,
    ],
    'static Str $foo' => [
        q!state $foo;!,
        q!Variable::Declaration::register_info(\$foo, {'declaration', 'static', 'attributes', undef, 'type', Str});!,
        q!Variable::Declaration::croak(Str->get_message($foo)) unless Str->check($foo);!,
        q!&Variable::Declaration::type_tie(\$foo, Str, $foo);!,
    ],
    'const $foo = 123' => [
        q!my $foo = 123;!,
        q!Variable::Declaration::register_info(\$foo, {'declaration', 'const', 'attributes', undef, 'type', undef});!,
        q!Variable::Declaration::data_lock($foo);!,
    ],
    'const $foo = 0' => [
        q!my $foo = 0;!,
        q!Variable::Declaration::register_info(\$foo, {'declaration', 'const', 'attributes', undef, 'type', undef});!,
        q!Variable::Declaration::data_lock($foo);!,
    ],
    'const Str $foo = "hello"' => [
        q!my $foo = 'hello';!,
        q!Variable::Declaration::register_info(\$foo, {'declaration', 'const', 'attributes', undef, 'type', Str});!,
        q!Variable::Declaration::croak(Str->get_message($foo)) unless Str->check($foo);!,
        q!&Variable::Declaration::type_tie(\$foo, Str, $foo);!,
        q!Variable::Declaration::data_lock($foo);!,
    ],
);

my @TODO = (
    'issue #2' =>
        ['(let $foo)' => [
            q!(my $foo);!,
            q!Variable::Declaration::register_info(\$foo, {'declaration', 'let', 'attributes', undef, 'type', undef});!,
        ]],
);

my @NG = (
    # expression   => error message
    'let'          => 'variable declaration is required',
    'let foo'      => 'variable declaration is required',
    'let = 123'    => 'variable declaration is required',
    'let $foo ='   => 'illegal expression',
    'let $foo 123' => 'illegal expression',
    'let $foo!'    => 'syntax error',

    'static'          => 'variable declaration is required',
    'static foo'      => 'variable declaration is required',
    'static = 123'    => 'variable declaration is required',
    'static $foo ='   => 'illegal expression',
    'static $foo 123' => 'illegal expression',
    'static $foo!'    => 'syntax error',

    'const'           => 'variable declaration is required',
    'const foo'       => 'variable declaration is required',
    'const = 123'     => 'variable declaration is required',
    'const $foo'      => '\'const\' declaration must be assigned',
    'const ($foo)'    => '\'const\' declaration must be assigned',
    'const $foo:Good' => '\'const\' declaration must be assigned',
    'const Str $foo'  => '\'const\' declaration must be assigned',
    'const $foo ='    => '\'const\' declaration must be assigned',
    'const $foo 123'  => '\'const\' declaration must be assigned',
    'const $foo!'     => '\'const\' declaration must be assigned',
);

sub check_ok {
    my ($expression, $expected_arrayref) = @_;

    my $expected = join '', @$expected_arrayref;
    note "EXPRESSION: $expression";
    note "EXPECTED:";
    note join "", map { "\t$_\n" } @$expected_arrayref;
    local $@;
    my $code = eval "sub { $expression }";
    if ($@) {
        note 'EVAL FAILED';
        note $@;
        fail;
    }
    else {
        my $deparse = B::Deparse->new();
        my $text = $deparse->coderef2text($code);
        (my $got = $text) =~ s!^    !!mg;
        $got =~ s!\n!!g;
        $got =~ s!}\z!!;

        note "GOT:$text";
        my $e = quotemeta $expected;
        ok $got =~ m/$e\z/;
    }
}

sub check_todo {
    my ($message, $data) = @_;
    TODO: {
        local $TODO = $message;
        check_ok(@$data);
    };
}

sub check_ng {
    my ($expression, $expected) = @_;

    note "'$expected'";
    local $@;
    my $code = eval "sub { $expression }";
    if ($@) {
        note $@;
        my $e = quotemeta $expected;
        ok $@ =~ m!$e!;
    }
    else {
        my $deparse = B::Deparse->new();
        my $text = $deparse->coderef2text($code);
        note $text;
        fail;
    }
}

sub Str() { ;; }

subtest 'case ok' => sub {
    while (@OK) {
        check_ok(shift @OK, shift @OK)
    }
};

subtest 'case todo' => sub {
    while (@TODO) {
        check_todo(shift @TODO, shift @TODO)
    }
};

subtest 'case ng' => sub {
    while (@NG) {
        check_ng(shift @NG, shift @NG)
    }
};

subtest 'level 0' => sub {
    Variable::Declaration->import(level => 0);
    check_ok('let Str $foo', [
        q!my $foo;!,
        q!Variable::Declaration::register_info(\$foo, {'declaration', 'let', 'attributes', undef, 'type', Str});!,
    ]);
};

subtest 'level 1' => sub {
    Variable::Declaration->import(level => 1);
    check_ok('let Str $foo' => [
        q!my $foo;!,
        q!Variable::Declaration::register_info(\$foo, {'declaration', 'let', 'attributes', undef, 'type', Str});!,
        q!Variable::Declaration::croak(Str->get_message($foo)) unless Str->check($foo);!,
    ]);

    check_ok('let Str $foo = "hello"', [
        q!my $foo = 'hello';!,
        q!Variable::Declaration::register_info(\$foo, {'declaration', 'let', 'attributes', undef, 'type', Str});!,
        q!Variable::Declaration::croak(Str->get_message($foo)) unless Str->check($foo);!,
    ]);
};

done_testing;
