use strict;
use Test::More tests => 9;
use Text::Printf;

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

# Passing no arguments to pre_fill is useless, but why not allow it.

eval
{
    $template->pre_fill();
};

is $@, q{},  q{zero args to pre_fill};

# give it some bad parameters

eval
{
    $template->pre_fill({to => 'Professor Dumbledore'},
                        'bass guitarist for the Weird Sisters');
};

$x = $@;
isnt $x, q{},  q{Exception for bad args to pre_fill};

ok (Text::Printf::X->caught(), q{bad-args exception is proper type});
ok (Text::Printf::X::ParameterError->caught(), q{bad-args exception is proper specific type});

# give it some good parameters

my $ret;
eval
{
    $ret = $template->pre_fill({to       => 'Lord Voldemort'},
                               {from     => 'Harry'},
                               {relation => 'sworn enemy'});
};

is $@, q{},  q{No exception when pre-filling some arrays};

ok (!defined $ret, q{pre_fill returned undef});

eval
{
    $letter = $template->fill({day_type => 'rotten'},
                             );
};


$x = $@;
is ($x, q{},   q{No exception for fill()});

is $letter, <<END_LETTER, q{prefilled template returned correct result};
Dear Lord Voldemort,
    Have a rotten day.
Your sworn enemy,
Harry
END_LETTER

