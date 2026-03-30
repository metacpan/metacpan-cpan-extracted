######################################################################
#
# 9001-load.t
#
# DESCRIPTION
#   1. mb module load and interface
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

my @pub_methods = qw(
    chop chr do dosglob eval getc
    index index_byte
    lc lcfirst length ord require reverse
    rindex rindex_byte
    substr tr uc ucfirst
    set_script_encoding get_script_encoding
    set_OSNAME get_OSNAME
);

plan_tests(4 + scalar(@pub_methods) + 4);

# Section 1: mb module
eval { require mb };
ok(!$@, 'mb loads without error');
diag("load error: $@") if $@;

ok(defined $mb::VERSION,         'mb: $VERSION defined');
ok($mb::VERSION =~ /^\d+\.\d+/, 'mb: $VERSION looks like a version number');
ok(mb->can('set_script_encoding'), 'mb->can(set_script_encoding)');

for my $m (@pub_methods) {
    ok(mb->can($m), "mb->can('$m')");
}

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
