use strict;
use Test::More tests => 18;
use Text::Printf;

# Check that printf-style formats work.

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}

my ($template, $str, $x);
my $opts = {howmany => 15, price => 0.80, total => 15 * 0.80};

eval
{
    $template = Text::Printf->new(
    'Yes, we have {{howmany}} bananas, at {{price}} each, for a total of {{total}}');
};
is $@, q{},   q{Created plain test template};

eval
{
    $str = $template->fill($opts);
};
is ($@, q{}, 'Filled out the plain string fine');
is ($str, 'Yes, we have 15 bananas, at 0.8 each, for a total of 12', 'Correct plain string result');

eval
{
    $template = Text::Printf->new(
    'Yes, we have {{howmany:%5d}} bananas, at {{price:.2f}} each, for a total of {{total:%.2f}}');
};
is $@, q{},   q{Created formatted test template};

eval
{
    $str = $template->fill($opts);
};
is ($@, q{}, 'Filled out the formatted string fine');
is ($str, 'Yes, we have    15 bananas, at 0.80 each, for a total of 12.00', 'Correct formatted string result');


# Extended formatting (commas, dollar signs)
$opts = {howmany => 1575, price => 0.82, total => 1575 * 0.82};

eval
{
    $template = Text::Printf->new(
    'Yes, we have {{howmany:%6d:,}} bananas, at {{price:.2f:,$}} each, for a total of {{total:%12.2f:$,}}');
};
is $@, q{},   q{Created doubly formatted test template};

eval
{
    $str = $template->fill($opts);
};
is ($@, q{}, 'Filled out the doubly formatted string fine');
is ($str, 'Yes, we have  1,575 bananas, at $0.82 each, for a total of    $1,291.50', 'Correct doubly formatted string result');

eval
{
    $template = Text::Printf->new(
    'Yes, we have {{howmany:%-6d:,}} bananas, at {{price:6.2f:$}} each, for a total of {{total:%-12.2f:$,}}');
};
is $@, q{},   q{Created doubly formatted test template};

eval
{
    $str = $template->fill($opts);
};
is ($@, q{}, 'Filled out the doubly formatted string fine');
is ($str, 'Yes, we have 1,575  bananas, at  $0.82 each, for a total of $1,291.50   ', 'Correct doubly formatted string result');

# Left-and-right justification with < and >
$opts = {howmany => 15, price => 0.80, total => 15 * 0.80};
eval
{
    $template = Text::Printf->new(
    'Yes, we have {{howmany:<5d}} bananas, at {{price:<6.2f}} each, for a total of {{total:>6d}}');
};
is $@, q{},   q{Created plain test template};

eval
{
    $str = $template->fill($opts);
};
is ($@, q{}, 'Filled out the < > format string fine');
is ($str, 'Yes, we have 15    bananas, at 0.80   each, for a total of     12', 'Correct < > format string result');

eval
{
    $template = Text::Printf->new(
    'Yes, we have {{howmany:%+-5d}} bananas, at {{price:.2f}} each, for a total of {{total:%+>6d}}');
};
is $@, q{},   q{Created < > formatted test 2 template};

eval
{
    $str = $template->fill($opts);
};
is ($@, q{}, 'Filled out the < > formatted 2 string fine');
is ($str, 'Yes, we have +15   bananas, at 0.80 each, for a total of    +12', 'Correct < > formatted string 2 result');

