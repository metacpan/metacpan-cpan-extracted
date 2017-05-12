use strict;
use Test::More tests => 28;
use Text::Printf;

# Check that fill() fails when it should.

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}

my ($template, $letter, $x);

eval
{
    $template = Text::Printf->new(<<END_TEMPLATE);
Dear {{to}},
    Have a {{day_type}} day.
Your {{relation}},
{{from}}
END_TEMPLATE
};

is $@, q{},   q{Created test template};

eval
{
    $letter = $template->fill(qw/bad arguments/);
};

$x = $@;
isnt $x, q{},   q{No hashref args to fill};

ok(Text::Printf::X->caught(), q{Not-hashref exception caught});

ok(Text::Printf::X::ParameterError->caught(),  q{Not-hashref exception is of proper type});

begins_with $x,
    q{Argument to fill() is not a hashref},
    q{Not-hashref exception works as a string, too};

eval
{
    $letter = $template->fill({foo => 'bar'}, 'burp');
};

$x = $@;
isnt $x, q{},   q{Not all args are hashref};

ok(Text::Printf::X->caught(), q{Not-all-hashrefs exception caught});

ok(Text::Printf::X::ParameterError->caught(),  q{Not-all-hashrefs exception is of proper type});

begins_with $x,
    q{Argument to fill() is not a hashref},
    q{Not-all-hashrefs exception works as a string, too};

eval
{
    $letter = $template->fill({to   => 'Lord Voldemort'},
                              {from => 'Harry'});
};

$x = $@;
isnt $x, q{},   q{Not all symbols resolved};

ok(Text::Printf::X->caught(), q{Not-all-symbols exception caught});

ok(Text::Printf::X::KeyNotFound->caught(),  q{Not-all-symbols exception is of proper type});

begins_with $x,
    q{Could not resolve the following symbols: day_type, relation},
    q{Not-all-symbols exception works as a string, too};

eval
{
    $letter = $template->fill({to       => 'Lord Voldemort'},
                              {from     => 'Harry'},
                              {day_type => 'supercalifragilisticexpialidocious'});
};

$x = $@;
isnt $x, q{},   q{One symbol unresolved};

ok(Text::Printf::X->caught(), q{One-unresolved exception caught});

ok(Text::Printf::X::KeyNotFound->caught(),  q{One-unresolved exception is of proper type});

begins_with $x,
    q{Could not resolve the following symbol: relation},
    q{Not-all-symbols exception works as a string, too};

# Finally, let's get a couple right.

undef $letter;
eval
{
    $letter = $template->fill({to       => 'Lord Voldemort'},
                              {from     => 'Harry'},
                              {day_type => 'supercalifragilisticexpialidocious'},
                              {relation => 'sworn enemy'});
};

$x = $@;
is $x, q{},   q{Normal (multiple hashrefs)};

is $letter, <<END_LETTER, q{Multiple hashrefs reurned correct result};
Dear Lord Voldemort,
    Have a supercalifragilisticexpialidocious day.
Your sworn enemy,
Harry
END_LETTER

undef $letter;
eval
{
    $letter = $template->fill({to       => 'Lord Voldemort',
                               from     => 'Harry',
                               day_type => 'supercalifragilisticexpialidocious',
                               relation => 'sworn enemy'});
};

$x = $@;
is $x, q{},   q{Normal (one hashrefs)};

is $letter, <<END_LETTER, q{One-hashref returned correct result};
Dear Lord Voldemort,
    Have a supercalifragilisticexpialidocious day.
Your sworn enemy,
Harry
END_LETTER

# test DONTSET

undef $letter;
eval
{
    $letter = $template->fill({to       => 'Lord Voldemort',
                               from     => $DONTSET,
                               day_type => 'supercalifragilisticexpialidocious',
                               relation => 'sworn enemy'});
};

$x = $@;
is $x, q{},   q{No exception on DONTSET};

is $letter, <<END_LETTER, q{DONTSET worked};
Dear Lord Voldemort,
    Have a supercalifragilisticexpialidocious day.
Your sworn enemy,
{{from}}
END_LETTER

# test first-come-first-served
undef $letter;
eval
{
    $letter = $template->fill({to       => 'Lord Voldemort',
                               from     => $DONTSET,
                               day_type => 'supercalifragilisticexpialidocious',
                               relation => 'sworn enemy'},
                              {from     => 'Harry'});
};

$x = $@;
is $x, q{},   q{No exception on first come first served (DONTSET)};

is $letter, <<END_LETTER, q{Correct result with first come, first served (DONTSET)};
Dear Lord Voldemort,
    Have a supercalifragilisticexpialidocious day.
Your sworn enemy,
{{from}}
END_LETTER

undef $letter;
eval
{
    $letter = $template->fill({to       => 'Lord Voldemort',
                               from     => 'Harry',
                               day_type => 'supercalifragilisticexpialidocious',
                               relation => 'sworn enemy'},
                              {from     => 'Hermione'});
};

$x = $@;
is $x, q{},   q{No exception on first come first served};

is $letter, <<END_LETTER, q{Correct result with first come, first served};
Dear Lord Voldemort,
    Have a supercalifragilisticexpialidocious day.
Your sworn enemy,
Harry
END_LETTER


undef $template;
eval
{
    $template = Text::Printf->new(<<END_TEMPLATE);
Dear {{ to}},
    Have a {{day_type }} day.
Your {{ relation }},
{{from}}
END_TEMPLATE
};


undef $letter;
eval
{
    $letter = $template->fill({to       => 'Lord Voldemort',
                               from     => 'Harry',
                               day_type => 'rotten',
                               relation => 'sworn enemy'});
};

is ($letter, <<END_LETTER, 'Poorly-formatted keywords not substituted');
Dear {{ to}},
    Have a {{day_type }} day.
Your {{ relation }},
Harry
END_LETTER

