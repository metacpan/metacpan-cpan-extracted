use strict;
use Test::More tests => 25;
use Text::Printf;

# Check that text() works properly

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}

my ($template, $letter, $x, $text);


#----------------------------------------------------------------
eval
{
    $template = Text::Printf->new;
};

is $@, q{},   q{Created test template};

#----------------------------------------------------------------
eval
{
    $letter = $template->text('help', 'help');
};

$x = $@;
isnt $x, q{}, q{Too many parameters to text()};

ok(Text::Printf::X->caught(), q{Too-many parameters exception caught});

ok(Text::Printf::X::ParameterError->caught(),  q{Too-many parameters exception is of proper type});

begins_with $x,
    q{Too many parameters to text()},
    q{Too-many parameters exception works as a string, too};


#----------------------------------------------------------------
eval
{
    $letter = $template->text(undef);
};

$x = $@;
isnt $x, q{}, q{text(undef)};

ok(Text::Printf::X->caught(), q{text(undef) exception caught});

ok(Text::Printf::X::ParameterError->caught(),  q{text(undef) exception is of proper type});

begins_with $x,
    q{Text may not be set to an undefined value},
    q{text(undef) exception works as a string, too};


#----------------------------------------------------------------
eval
{
    $template = Text::Printf->new;
    $text     = $template->text;
};

$x = $@;
is $x, q{},         q{Empty constructor, no error};
ok !defined($text), q{Empty constructor, undefined text};


#----------------------------------------------------------------
eval
{
    $letter = $template->fill({to   => 'Lord Voldemort'},
                              {from => 'Harry'});
};

$x = $@;
isnt $x, q{},                 q{fill() with no text};
ok(Text::Printf::X->caught(), q{fill-no-text exception caught});
ok(Text::Printf::X::NoText->caught(),  q{fill-no-text exception is of proper type});
begins_with $x,
    q{Template text was never set},
    q{fill-no-text exception works as a string, too};


#----------------------------------------------------------------
eval
{
    $template = Text::Printf->new('Rowling');
    $text     = $template->text;
};

$x = $@;
is $x, q{} => q{Constructor one arg, no error};
is $text, q{Rowling}, q{Constructor one arg, correct value};


#----------------------------------------------------------------
eval
{
    # Empty string is pointless but legal
    $template = Text::Printf->new('');
    $text     = $template->text;
};

$x = $@;
is $x, q{} => q{text(''), no error};
is $text, q{}, q{text(''), correct value};


#----------------------------------------------------------------
eval
{
    $template->text('Hermione Granger');
    $text = $template->text;
};

$x = $@;
is $x, q{} => q{text() one arg, no error};
is $text, q{Hermione Granger}, q{text() one arg, correct value};


#----------------------------------------------------------------
eval
{
    $template->text(<<END_TEMPLATE);
Dear {{to}},
    Have a {{day_type}} day.
Your {{relation}},
{{from}}
END_TEMPLATE
    $text = $template->text;
};

$x = $@;
is $x, q{} => q{text() one arg, change, no error};
is $text, <<END_TEXT, q{text() one arg, change, correct value};
Dear {{to}},
    Have a {{day_type}} day.
Your {{relation}},
{{from}}
END_TEXT


#----------------------------------------------------------------
# make sure values are retained

eval
{
    $template->default({to       => 'Lord Voldemort'},
                       {from     => 'Harry'},
                       {relation => 'sworn enemy'});
    $letter = $template->fill({day_type => 'rotten'});
};

is $letter, <<END_LETTER, q{defaulted template returned correct result};
Dear Lord Voldemort,
    Have a rotten day.
Your sworn enemy,
Harry
END_LETTER

eval
{
    $template->text(<<END_TEMPLATE);
{{to}}:
    You are a {{person_type}} person, and
I am your {{relation}}.
-- {{from}}
END_TEMPLATE
    $letter = $template->fill({person_type => 'messed-up'});
};

is $letter, <<END_LETTER, q{defaulted template returned correct result};
Lord Voldemort:
    You are a messed-up person, and
I am your sworn enemy.
-- Harry
END_LETTER
#----------------------------------------------------------------
