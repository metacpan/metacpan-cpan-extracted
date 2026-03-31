######################################################################
#
# 9001-load.t
#
# DESCRIPTION
#   1. UTF8::R2 module load and interface
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
    $T_RUN++; $T_FAIL++ unless $ok;
    print +($ok ? '' : 'not ') . "ok $T_RUN" . ($name ? " - $name" : '') . "\n";
    return $ok;
}
sub diag { print "# $_[0]\n" }
END { exit 1 if $T_PLAN && $T_FAIL }

plan_tests(8);

# Section 1: UTF8::R2 module
eval { require UTF8::R2 };
ok(!$@, 'UTF8::R2 loads without error');
diag("load error: $@") if $@;

ok(defined $UTF8::R2::VERSION,          'UTF8::R2: $VERSION defined');
ok($UTF8::R2::VERSION =~ /^\d+\.\d+/,   'UTF8::R2: $VERSION looks like a version number');
ok($UTF8::R2::VERSION eq '0.29',        'UTF8::R2: $VERSION is 0.29');

# Section 2: INA_CPAN_Check
eval { require INA_CPAN_Check };
ok(!$@, 'INA_CPAN_Check loads without error');
diag("load error: $@") if $@;

ok( defined &INA_CPAN_Check::ok
 && defined &INA_CPAN_Check::_slurp
 && defined &INA_CPAN_Check::_scan_code,
   'INA_CPAN_Check: key helpers defined');

ok( defined &INA_CPAN_Check::check_A && defined &INA_CPAN_Check::check_K,
   'INA_CPAN_Check: check_A through check_K defined');

ok( defined &INA_CPAN_Check::count_A && defined &INA_CPAN_Check::count_K,
   'INA_CPAN_Check: count_A through count_K defined');
