######################################################################
#
# 1003-boolean.t - mb::JSON::Boolean object tests
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

use mb::JSON;

my ($T_PLAN, $T_RUN, $T_FAIL) = (0, 0, 0);
sub plan_tests { $T_PLAN = $_[0]; print "1..$T_PLAN\n" }
sub ok   {
    my ($ok,$n) = @_;
    $T_RUN++; $T_FAIL++ unless $ok;
    print +($ok?'':'not ') . "ok $T_RUN" . ($n?" - $n":'') . "\n"; $ok
}
sub is   {
    my ($got,$exp,$n) = @_;
    my $ok = defined $got && defined $exp && "$got" eq "$exp";
    ok($ok, $n) or print "# got: '$got'  expected: '$exp'\n";
}
END { exit 1 if $T_PLAN && $T_FAIL }

plan_tests(22);

# ok 1-2: type check
ok(ref(mb::JSON::true)  eq 'mb::JSON::Boolean', 'true is mb::JSON::Boolean');
ok(ref(mb::JSON::false) eq 'mb::JSON::Boolean', 'false is mb::JSON::Boolean');

# ok 3-4: singleton identity
ok(mb::JSON::true  == mb::JSON::true,  'true is singleton');
ok(mb::JSON::false == mb::JSON::false, 'false is singleton');

# ok 5-6: numification
ok(mb::JSON::true  == 1, 'true numifies to 1');
ok(mb::JSON::false == 0, 'false numifies to 0');

# ok 7-8: stringification
is("" . mb::JSON::true,  'true',  'true stringifies to "true"');
is("" . mb::JSON::false, 'false', 'false stringifies to "false"');

# ok 9-10: boolean context
ok(mb::JSON::true  == 1, 'true  is true  in boolean context');
ok(mb::JSON::false == 0, 'false is false in boolean context');

# ok 11-12: encode produces true/false (not 1/0)
is( mb::JSON::encode(mb::JSON::true),  'true',  'encode(true)  -> "true"');
is( mb::JSON::encode(mb::JSON::false), 'false', 'encode(false) -> "false"');

# ok 13-14: plain 1/0 are NOT boolean
is( mb::JSON::encode(1), '1', 'encode(1) -> "1" not "true"');
is( mb::JSON::encode(0), '0', 'encode(0) -> "0" not "false"');

# ok 15-16: decode returns Boolean objects
my $t = mb::JSON::decode('true');
my $f = mb::JSON::decode('false');
ok(ref($t) eq 'mb::JSON::Boolean', 'decode true  -> Boolean object');
ok(ref($f) eq 'mb::JSON::Boolean', 'decode false -> Boolean object');

# ok 17-18: decoded booleans re-encode correctly
is( mb::JSON::encode($t), 'true',  'decoded true  re-encodes as true');
is( mb::JSON::encode($f), 'false', 'decoded false re-encodes as false');

# ok 19: $VERSION defined
ok(defined $mb::JSON::Boolean::VERSION, 'mb::JSON::Boolean has VERSION');

# ok 20-21: stringify() also encodes booleans correctly
is( mb::JSON::stringify(mb::JSON::true),  'true',  'stringify(true)  -> "true"');
is( mb::JSON::stringify(mb::JSON::false), 'false', 'stringify(false) -> "false"');

# ok 22: true != false
ok(mb::JSON::true != mb::JSON::false, 'true != false');
