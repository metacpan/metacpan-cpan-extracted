use Test2::Plugin::Cover ();
use Test2::V0 -target => 'Test2::Plugin::Cover';
use Path::Tiny qw/path/;

$CLASS->enable;
$CLASS->full_reset;

is($CLASS->get_from, '*', "default from is '*'");
ok(!$CLASS->was_from_modified, "not modified after full_reset");

$CLASS->set_from('foo');
is($CLASS->get_from, 'foo', "set_from stored the value");
ok($CLASS->was_from_modified, "modified flag set");

$CLASS->clear_from;
is($CLASS->get_from, '*', "clear_from resets the value");
ok($CLASS->was_from_modified, "clear_from does not clear the modified flag");

$CLASS->reset_from;
ok(!$CLASS->was_from_modified, "reset_from clears the modified flag");

$CLASS->set_from_manager('My::Manager');
ok($CLASS->was_from_modified, "set_from_manager sets the modified flag");
$CLASS->reset_from;

# Values that cannot be serialized into the report warn and are ignored.
# They must never die: enabling coverage should not introduce new exceptions
# into the code being observed.
$CLASS->set_from('good');
like(warning { $CLASS->set_from(sub { 1 }) },                  qr/must be serializable/, "plain coderef warns");
like(warning { $CLASS->set_from({list => [{cb => sub { 1 }}]}) }, qr/must be serializable/, "nested coderef warns");
is($CLASS->get_from, 'good', "rejected values are ignored, previous from kept");

$CLASS->reset_from;
like(warning { $CLASS->set_from(\*STDOUT) }, qr/must be serializable/, "glob ref warns");
is($CLASS->get_from, '*', "from still default after rejected value");
ok(!$CLASS->was_from_modified, "rejected value does not mark from as modified");

ok(lives { $CLASS->set_from({a => [1, "x", {b => \"str"}]}) }, "plain structures accepted");

my $cycle = {};
$cycle->{self} = $cycle;
ok(lives { $CLASS->set_from($cycle) }, "cyclic structure validated without infinite loop");

# Dedup is by content, not reference, and ordering is deterministic.
$CLASS->full_reset;
$CLASS->set_from(['yyy']);
$CLASS->touch_source_file('from_test.pl', 'subA');
$CLASS->set_from(['yyy']);    # different ref, same content
$CLASS->touch_source_file('from_test.pl', 'subA');
$CLASS->set_from('aaa');
$CLASS->touch_source_file('from_test.pl', 'subA');

my $data = $CLASS->data(root => path('.'));
is(
    $data->{'from_test.pl'}->{subA},
    [['yyy'], 'aaa'],
    "identical from structures deduplicated by content, deterministic order"
);

# A bad value smuggled directly into the report (bypassing set_from) must not
# kill the report generated at test exit.
$CLASS->reset_coverage;
{
    my $cb = sub { 1 };
    $Test2::Plugin::Cover::REPORT{'direct.pl'}{'subX'}{"$cb"} = $cb;
}
ok(lives { $CLASS->data(root => path('.')) }, "data() survives unserializable from values");

$CLASS->full_reset;

done_testing;
