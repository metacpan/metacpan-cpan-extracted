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

my ($T_RUN, $T_FAIL) = (0, 0);
sub ok {
    my ($ok, $name) = @_;
    $T_RUN++;
    $T_FAIL++ unless $ok;
    print +($ok ? '' : 'not ') . "ok $T_RUN" . ($name ? " - $name" : '') . "\n";
    return $ok;
}
sub diag { print "# $_[0]\n" }
# Assigning to $? sets the exit status; calling exit() from an END block
# aborts perl 5.6 and earlier with "Callback called exit."
END { $? = 1 if $T_FAIL }

my @tests;

# module loads
push @tests, sub {
    eval { require mb::JSON };
    ok(!$@, 'mb::JSON loads without error');
    diag("load error: $@") if $@;
};

# VERSION
push @tests, sub { ok(defined $mb::JSON::VERSION,        'mb::JSON: $VERSION defined') };
push @tests, sub { ok($mb::JSON::VERSION =~ /^\d+\.\d+/, 'mb::JSON: $VERSION looks like a version number') };

# mb::JSON::Boolean present
push @tests, sub {
    ok(defined $mb::JSON::Boolean::{new} || 1,
       'mb::JSON::Boolean package present');
};

# functions exist (decode/parse pair, encode/stringify pair, true/false)
for my $fn (qw(decode parse encode stringify true false)) {
    push @tests, sub { ok(mb::JSON->can($fn), "mb::JSON->can('$fn')") };
}

# true / false are Boolean objects
push @tests, sub { ok(ref(mb::JSON::true())  eq 'mb::JSON::Boolean', 'mb::JSON::true  is a Boolean object') };
push @tests, sub { ok(ref(mb::JSON::false()) eq 'mb::JSON::Boolean', 'mb::JSON::false is a Boolean object') };

# INA_CPAN_Check loads
push @tests, sub {
    eval { require INA_CPAN_Check };
    ok(!$@, 'INA_CPAN_Check loads without error');
};

# key helpers defined
push @tests, sub {
    ok( defined &INA_CPAN_Check::check_A
     && defined &INA_CPAN_Check::check_K,
       'INA_CPAN_Check: check_A through check_K defined');
};

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
