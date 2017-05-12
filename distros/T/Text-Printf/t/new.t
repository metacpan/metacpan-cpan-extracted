use strict;
use Test::More tests => 52;
use Text::Printf;

# Check that new() fails when it should.

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}

my ($template, $x);

eval
{
    $template = Text::Printf->new(<<END_TEMPLATE, 'burp');
Dear {{to}},
    Have a {{day_type}} day.
Your {{relation}},
{{from}}
END_TEMPLATE
};

$x = $@;
isnt $x, q{},   q{Bad second argument to 'new'};

ok (Text::Printf::X->caught(), q{Bad-arg exception caught});

ok (Text::Printf::X::ParameterError->caught(),  q{Bad-arg exception is of proper type});

begins_with $x,
    "Second argument to Text::Printf constructor must be hash ref, not scalar",
    "Bad-arg exception works as a string, too";


#----------------------------------------------------------------
eval
{
    $template = Text::Printf->new({a=>1}, 'burp');
};

$x = $@;
isnt $x, q{},   q{Out-of-order arguments to 'new'};

ok(Text::Printf::X->caught(), q{Out-of-order exception caught});

ok(Text::Printf::X::ParameterError->caught(),  q{Out-of-order exception is of proper type});

begins_with $x,
    'First argument to Text::Printf constructor should be a scalar, not HASH ref',
    'Out-of-order exception works as a string, too';


#----------------------------------------------------------------
eval
{
    $template = Text::Printf->new('whee', 'oops', 'burp');
};

$x = $@;
isnt $x, q{},   q{Too many arguments to 'new'};

ok(Text::Printf::X->caught(), q{Too many exception caught});

ok(Text::Printf::X::ParameterError->caught(),  q{Too-many exception is of proper type});

begins_with $x,
    'Too many parameters to Text::Printf constructor',
    'Too-many exception works as a string, too';


#----------------------------------------------------------------
eval
{
    $template = Text::Printf->new(q{}, {delimiters => q{}});
};

$x = $@;
isnt $x, q{},   q{Delimiter: bad type};

ok(Text::Printf::X->caught(), q{Bad delimiter option exception caught});

ok(Text::Printf::X::OptionError->caught(),  q{Bad delimiter exception is of proper type});

is +($x && $x->name), 'delimiter',  q{Bad option name specified (bad type)};

begins_with $x,
    "Bad option to Text::Printf constructor\ndelimiter value must be array reference",
    "Bad delimiter option exception works as a string, too";


#----------------------------------------------------------------
eval
{
    $template = Text::Printf->new(q{}, {delimiters => []});
};

$x = $@;
isnt $x, q{},   q{Wrong# delimiters};

ok(Text::Printf::X->caught(), q{Wrong# delimiters exception caught});

ok(Text::Printf::X::OptionError->caught(),  q{Wrong# delimiters exception is of proper type});

is $x->name(), 'delimiter',  q{Bad option name specified (wrong# delimiters)};

begins_with $x,
    "Bad option to Text::Printf constructor\ndelimiter arrayref must have exactly two values",
    "Wrong# delimiters exception works as a string, too";

#----------------------------------------------------------------
eval
{
    $template = Text::Printf->new(q{}, {delimiters => ['a', []]});
};

$x = $@;
isnt $x, q{},   q{Wrong type delimiters (sx)};

ok(Text::Printf::X->caught(), q{Wrong type delimiters (sx) exception caught});

ok(Text::Printf::X::OptionError->caught(),  q{Wrong type delimiters (sx) exception is of proper type});

is $x->name(), 'delimiter',  q{Bad option name specified (wrong type delimiters (sx))};

begins_with $x,
    "Bad option to Text::Printf constructor\ndelimiter values must be strings or regexes",
    "Wrong type delimiters (sx) exception works as a string, too";

#----------------------------------------------------------------
eval
{
    $template = Text::Printf->new(q{}, {delimiters => [qr/a/, []]});
};

$x = $@;
isnt $x, q{},   q{Wrong type delimiters (rx)};

ok(Text::Printf::X->caught(), q{Wrong type delimiters (rx) exception caught});

ok(Text::Printf::X::OptionError->caught(),  q{Wrong type delimiters (rx) exception is of proper type});

is $x->name(), 'delimiter',  q{Bad option name specified (wrong type delimiters (rx))};

begins_with $x,
    "Bad option to Text::Printf constructor\ndelimiter values must be strings or regexes",
    "Wrong type delimiters (rx) exception works as a string, too";

#----------------------------------------------------------------
eval
{
    $template = Text::Printf->new(q{}, {delimiters => [[], 'b']});
};

$x = $@;
isnt $x, q{},   q{Wrong type delimiters (xs)};

ok(Text::Printf::X->caught(), q{Wrong type delimiters (xs) exception caught});

ok(Text::Printf::X::OptionError->caught(),  q{Wrong type delimiters (xs) exception is of proper type});

is $x->name(), 'delimiter',  q{Bad option name specified (wrong type delimiters (xs))};

begins_with $x,
    "Bad option to Text::Printf constructor\ndelimiter values must be strings or regexes",
    "Wrong type delimiters (xs) exception works as a string, too";

#----------------------------------------------------------------
eval
{
    $template = Text::Printf->new(q{}, {delimiters => [[], qr/b/]});
};

$x = $@;
isnt $x, q{},   q{Wrong type delimiters (xr)};

ok(Text::Printf::X->caught(), q{Wrong type delimiters (xr) exception caught});

ok(Text::Printf::X::OptionError->caught(),  q{Wrong type delimiters (xr) exception is of proper type});

is $x->name(), 'delimiter',  q{Bad option name specified (wrong type delimiters (xr))};

begins_with $x,
    "Bad option to Text::Printf constructor\ndelimiter values must be strings or regexes",
    "Wrong type delimiters (xr) exception works as a string, too";

#----------------------------------------------------------------
eval
{
    $template = Text::Printf->new(q{}, {delimiters => [[], {}]});
};

$x = $@;
isnt $x, q{},   q{Wrong type delimiters (xx)};

ok(Text::Printf::X->caught(), q{Wrong type delimiters (xx) exception caught});

ok(Text::Printf::X::OptionError->caught(),  q{Wrong type delimiters (xx) exception is of proper type});

is $x->name(), 'delimiter',  q{Bad option name specified (wrong type delimiters (xx))};

begins_with $x,
    "Bad option to Text::Printf constructor\ndelimiter values must be strings or regexes",
    "Wrong type delimiters (xx) exception works as a string, too";


#----------------------------------------------------------------
# How about some non-exceptions, to brighten our day?

#----------------------------------------------------------------

eval
{
    $template = Text::Printf->new();
};

$x = $@;
is $x, q{},   q{'new' is now allowed to have zero parameters};


#----------------------------------------------------------------
eval
{
    $template = Text::Printf->new(q{}, {delimiters => ['a', 'b']});
};

is $@, q{},   q{Correct type delimiters (ss)};


#----------------------------------------------------------------
eval
{
    $template = Text::Printf->new({delimiters => ['a', 'b']});
};

is $@, q{},   q{Correct type delimiters (ss) (only arg)};


#----------------------------------------------------------------
eval
{
    $template = Text::Printf->new(q{}, {delimiters => [qr/a/, 'b']});
};

is $@, q{},   q{Correct type delimiters (rs)};


#----------------------------------------------------------------
eval
{
    $template = Text::Printf->new(q{}, {delimiters => [qr/a/, qr/b/]});
};

is $@, q{},   q{Correct type delimiters (rr)};
