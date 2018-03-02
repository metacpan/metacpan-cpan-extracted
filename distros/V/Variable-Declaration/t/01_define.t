use strict;
use warnings;

use Test::More;
use B::Deparse;
use Variable::Declaration;

my @OK = (
    # expression     => deparsed text
    'let $foo'       => 'my $foo',
    'let ($foo)'     => 'my $foo', # equivalent to 'my ($foo)'
    'let $foo:Good'  => '\'attributes\'->import(\'main\', \$foo, \'Good\'), my $foo', # equivalent to 'my $foo:Good'
    'let $foo = 123' => 'my $foo = 123',
    'let $foo = 0'   => 'my $foo = 0',
    'let Str $foo'   => 'my $foo;croak(Str->get_message($foo)) unless Str->check($foo);ttie $foo, Str',

    'static $foo'       => 'state $foo',
    'static ($foo)'     => 'state $foo', # equivalent to 'state ($foo)'

    # https://rt.perl.org/Public/Bug/Display.html?id=68658
    $] =~ m{^5.012} ? (
        'static $foo:Good'  => '\'attributes\'->import(\'main\', \$foo, \'Good\'), my $foo', # equivalent to 'state $foo:Good'
    ) : (
        'static $foo:Good'  => '\'attributes\'->import(\'main\', \$foo, \'Good\'), state $foo', # equivalent to 'state $foo:Good'
    ),

    'static $foo = 123' => 'state $foo = 123',
    'static $foo = 0'   => 'state $foo = 0',
    'static Str $foo'   => 'state $foo;croak(Str->get_message($foo)) unless Str->check($foo);ttie $foo, Str',

    'const $foo = 123'           => 'my $foo = 123;dlock($foo)',
    'const $foo = 0'             => 'my $foo = 0;dlock($foo)',
    'const Str $foo = \'hello\'' => 'my $foo = \'hello\';croak(Str->get_message($foo)) unless Str->check($foo);ttie $foo, Str;dlock($foo)',
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
    my ($expression, $expected) = @_;
    my $deparse = B::Deparse->new();

    my $code = eval "sub { $expression }";
    my $text = $deparse->coderef2text($code);
    (my $got = $text) =~ s!^    !!mg;
    $got =~ s!\n!!g;

    note "'$expected'";
    note $text;
    my $e = quotemeta $expected;
    ok $got =~ m!$e!;
}

sub check_ng {
    my ($expression, $expected) = @_;

    my $code = eval "sub { $expression }";
    note "'$expected'";
    if ($@) {
        note $@;
    }
    else {
        my $deparse = B::Deparse->new();
        my $text = $deparse->coderef2text($code);
        note $text;
    }

    my $e = quotemeta $expected;
    ok $@ =~ m!$e!;
}

sub Str() { ;; }

subtest 'case ok' => sub {
    while (@OK) {
        check_ok(shift @OK, shift @OK)
    }
};

subtest 'case ng' => sub {
    while (@NG) {
        check_ng(shift @NG, shift @NG)
    }
};

subtest 'level 0' => sub {
    Variable::Declaration->import(level => 0);
    check_ok('let Str $foo', 'my $foo;');
};

subtest 'level 1' => sub {
    Variable::Declaration->import(level => 1);
    check_ok('let Str $foo', 'my $foo;croak(Str->get_message($foo)) unless Str->check($foo)');
    check_ok('let Str $foo = \'hello\'', 'my $foo = \'hello\';croak(Str->get_message($foo)) unless Str->check($foo)');
};

done_testing;
