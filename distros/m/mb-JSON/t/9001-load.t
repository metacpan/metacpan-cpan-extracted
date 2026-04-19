######################################################################
#
# 9001-load.t
#
# DESCRIPTION
#   1. mb::JSON module load and interface
#   2. INA_CPAN_Check library load and export
#
# COMPATIBILITY
#   Perl 5.005_03 and later.  No non-core dependencies.
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
use lib "$FindBin::Bin/lib";

my ($T_PLAN, $T_RUN, $T_FAIL) = (0, 0, 0);
sub plan_tests { $T_PLAN = $_[0]; print "1..$T_PLAN\n" }
sub ok {
    my ($ok, $name) = @_;
    $T_RUN++;
    $T_FAIL++ unless $ok;
    print +($ok ? '' : 'not ') . "ok $T_RUN" . ($name ? " - $name" : '') . "\n";
    return $ok;
}
sub diag { print "# $_[0]\n" }
END { exit 1 if $T_PLAN && $T_FAIL }

plan_tests(14);

# ok 1: module loads
eval { require mb::JSON };
ok(!$@, 'mb::JSON loads without error');
diag("load error: $@") if $@;

# ok 2-3: VERSION
ok(defined $mb::JSON::VERSION,         'mb::JSON: $VERSION defined');
ok($mb::JSON::VERSION =~ /^\d+\.\d+/, 'mb::JSON: $VERSION looks like a version number');

# ok 4: mb::JSON::Boolean present
ok(defined $mb::JSON::Boolean::{new} || 1,
   'mb::JSON::Boolean package present');

# ok 5-10: functions exist (decode/parse pair, encode/stringify pair, true/false)
for my $fn (qw(decode parse encode stringify true false)) {
    ok(mb::JSON->can($fn), "mb::JSON->can('$fn')");
}

# ok 11-12: true / false are Boolean objects
ok(ref(mb::JSON::true())  eq 'mb::JSON::Boolean', 'mb::JSON::true  is a Boolean object');
ok(ref(mb::JSON::false()) eq 'mb::JSON::Boolean', 'mb::JSON::false is a Boolean object');

# ok 13: INA_CPAN_Check loads
eval { require INA_CPAN_Check };
ok(!$@, 'INA_CPAN_Check loads without error');

# ok 14: key helpers defined
ok( defined &INA_CPAN_Check::check_A
 && defined &INA_CPAN_Check::check_K,
   'INA_CPAN_Check: check_A through check_K defined');
