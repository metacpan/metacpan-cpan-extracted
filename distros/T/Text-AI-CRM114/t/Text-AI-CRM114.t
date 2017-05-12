use strict;
use warnings;

use File::Temp qw/ tmpnam /;

use Test::More tests => 62;
BEGIN { use_ok('Text::AI::CRM114') };
use lib 't';
BEGIN { use_ok('SampleText') };

can_ok('Text::AI::CRM114', qw(new readfile));
my $db = Text::AI::CRM114->new();
isa_ok($db, 'Text::AI::CRM114');
can_ok($db, qw(learn classify writefile));

$db = Text::AI::CRM114->new();
isa_ok($db, 'Text::AI::CRM114');
$db = Text::AI::CRM114->new(classes => ["Alice", "Macbeth"]);
isa_ok($db, 'Text::AI::CRM114');

$db = Text::AI::CRM114->new(flags => Text::AI::CRM114::OSB, datasize => 8000000, classes => ["Alice", "Macbeth"]);
isa_ok($db, 'Text::AI::CRM114');

$db->learn("Alice", SampleText::Alice());
$db->learn("Macbeth", SampleText::Macbeth());

my ($fh, $filename) = tmpnam();
my $rc = $db->writefile($filename);
is($rc, Text::AI::CRM114::OK, "writefile");
undef $db;

# read anew from file 
$db = Text::AI::CRM114->readfile($filename);
isa_ok($db, 'Text::AI::CRM114');

my %classes = %{$db->getclasses()};
isa_ok(\%classes, 'HASH', "getclasses()");
ok(defined($classes{"Alice"}));
ok(defined($classes{"Macbeth"}));
is($classes{"Alice"}, 0);
is($classes{"Macbeth"}, 1);
is(scalar(keys(%classes)), 2);

# result values from simple_demo.c

# "normal mode" -- adjusted values
my($err, $class, $prob, $pR) = $db->classify(SampleText::Alice_frag());
is($err, Text::AI::CRM114::OK);
is($class, "Alice");
is(sprintf("%.1f", $prob), "1.0");
is(sprintf("%.6f", $pR), "19.779991");

($err, $class, $prob, $pR) = $db->classify(SampleText::Macbeth_frag());
is($err, Text::AI::CRM114::OK);
is($class, "Macbeth");
is(sprintf("%.1f", $prob), "1.0");
is(sprintf("%.6f", $pR), "20.351904");

($err, $class, $prob, $pR) = $db->classify(SampleText::Hound_frag());
is($err, Text::AI::CRM114::OK);
is($class, "Macbeth");
is(sprintf("%.3f", $prob), "0.596");
is(sprintf("%.6f", $pR), "0.169050");

($err, $class, $prob, $pR) = $db->classify(SampleText::Willows_frag());
is($err, Text::AI::CRM114::OK);
is($class, "Alice");
is(sprintf("%.3f", $prob), "0.897");
is(sprintf("%.6f", $pR), "0.938232");

# "verbatim mode"
($err, $class, $prob, $pR) = $db->classify(SampleText::Alice_frag(), 1);
is($err, Text::AI::CRM114::OK);
is($class, "Alice");
is(sprintf("%.1f", $prob), "1.0");
is(sprintf("%.6f", $pR), "19.779991");

($err, $class, $prob, $pR) = $db->classify(SampleText::Macbeth_frag(), 1);
is($err, Text::AI::CRM114::OK);
is($class, "Macbeth");
is(sprintf("%.1f", $prob), "0.0");
is(sprintf("%.6f", $pR), "-20.351904");

($err, $class, $prob, $pR) = $db->classify(SampleText::Hound_frag(), 1);
is($err, Text::AI::CRM114::OK);
is($class, "Macbeth");
is(sprintf("%.3f", $prob), "0.404");
is(sprintf("%.6f", $pR), "-0.169050");

($err, $class, $prob, $pR) = $db->classify(SampleText::Willows_frag(), 1);
is($err, Text::AI::CRM114::OK);
is($class, "Alice");
is(sprintf("%.3f", $prob), "0.897");
is(sprintf("%.6f", $pR), "0.938232");

# set up with more classes
# NB: using an empty string is obviously a bad idea, don't try this at home
$db = Text::AI::CRM114->new(classes => ["Alice", "Macbeth", "Something", "Else", ""]);
isa_ok($db, 'Text::AI::CRM114');
%classes = %{$db->getclasses()};
isa_ok(\%classes, 'HASH', "getclasses()");
ok(defined($classes{"Alice"}));
ok(defined($classes{"Macbeth"}));
ok(defined($classes{"Something"}));
ok(defined($classes{"Else"}));
ok(defined($classes{""}));
is($classes{"Alice"},     0);
is($classes{"Macbeth"},   1);
is($classes{"Something"}, 2);
is($classes{"Else"},      3);
is($classes{""},          4);
is(scalar(keys(%classes)), 5);

$db->learn("Alice", SampleText::Alice());
$db->learn("Macbeth", SampleText::Macbeth());
($err, $class, $prob, $pR) = $db->classify(SampleText::Willows_frag());
is($err, Text::AI::CRM114::OK);

