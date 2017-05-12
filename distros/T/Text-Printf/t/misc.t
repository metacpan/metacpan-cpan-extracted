use strict;
use Test::More tests => 7;
use Text::Printf;

# This unit tests miscellaneous conditions throughout the system;
# these tests didn't really fit anywhere else.

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}


my ($x, $template, $letter);

# Check that undef gets interpolated as empty string,
# and that an array ref gets stringified (not treated like $DONTSET).
eval
{
    $template = Text::Printf->new('Undef? {{u}}; aref? {{aref}}.');
};
is $@, q{},   q{Simple template creation didn't die};

$letter = $template->fill( {u => undef, aref => []} );
like $letter, qr/\AUndef\? ; aref\? ARRAY\(0x[0-9A-Fa0-f]+\)\.\z/, 'Misc: undef, aref';

# Check that clear_values works
$template->default({u => 'The Letter U'});
$template->pre_fill({aref => 'A Reference'});
$template->clear_values;
eval
{
    $template->fill({aref => 'foo'});
};
$x = $@;
isnt $x, q{},   q{clear: Not all symbols resolved};
ok(Text::Printf::X->caught(), q{clear: exception caught});
ok(Text::Printf::X::KeyNotFound->caught(),  q{clear: exception is of proper type});
begins_with $x,
    q{Could not resolve the following symbol: u},
    q{clear: exception works as a string, too};


$letter = $template->fill({u => 'ubuntu', aref => 'FOO'});
is $letter, 'Undef? ubuntu; aref? FOO.', 'clear: did clear pre-fill';

