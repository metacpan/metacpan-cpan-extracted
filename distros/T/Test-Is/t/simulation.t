use strict;
use warnings;

use Test::More;

eval { require TAP::Harness } or plan skip_all => 'TAP::Harness not available';


my %ENV_NAMES = map { ($_ => undef) } qw(
    AUTOMATED_TESTING
    NONINTERACTIVE_TESTING
    EXTENDED_TESTING
);


# Cleanup environment of testing variables that we will test
delete $ENV{$_} for keys %ENV_NAMES;

# Cleanup environment to avoid side effects of prove
delete $ENV{$_} for grep /^PERL_TEST_HARNESS_/, keys %ENV;

my $output = '';
open my $out, '>', \$output or die;
my $runner = TAP::Harness->new({
    lib => [ -d 'blib' ? 'blib/lib' : 'lib' ],
    formatter_class => 'TAP::Formatter::File',
    stdout => $out,
    verbosity => 1,
    errors => 1, # We want to know about TAP output errors
    jobs => 2,
});



sub check_tests
{
    my $title = shift;
    my $env = shift;
    my $checks = pop;

    note $title;

    # Prepare the environment
    local %ENV;
    while (my ($k, $v) = each %$env) {
	# sanity check
	die "invalid env: $k" unless exists $ENV_NAMES{$k};

	if (defined $v) {
	    $ENV{$k} = $v
	} else {
	    delete $ENV{$k}
	}
    }

    # Run the tests
    $output = '';

    # Returns a TAP::Parser::Aggregator
    my $result = $runner->runtests(@_);

    # Check the result
    CHECKS: while (@$checks) {
	my $prop = shift @$checks;
	my $expected = shift @$checks;
	my $name = shift @$checks;
	is($result->$prop, $expected, "$title: $name")
	    or do {
		(my $formatted_output = $output) =~ s/^/### /gm;
		diag($formatted_output);
		last CHECKS	
	    };
    }
}




check_tests(
'non-interactive',
{
    NONINTERACTIVE_TESTING => 1,
}, qw(t/pass.t t/interactive.t),
[
    all_passed => 1, 'all passed',
    total => 1, 'test completely skipped',
]);

check_tests(
'interactive',
{
}, qw(t/pass.t t/interactive.t),
[
    all_passed => 1, 'all passed',
    total => 2, 'all ran',
]);

check_tests(
'extended',
{
    EXTENDED_TESTING => 1,
}, qw(t/pass.t t/extended.t),
[
    all_passed => 1, 'all passed',
    total => 2, 'all ran',
]);

check_tests(
'no extended',
{
}, qw(t/pass.t t/extended.t),
[
    all_passed => 1, 'all passed',
    total => 1, 'extended test skipped',
]);


check_tests(
'interactive, extended (both.t)',
{
    EXTENDED_TESTING => 1,
}, qw(t/pass.t t/both.t),
[
    all_passed => 1, 'all passed',
    total => 2, 'all ran',
]);

check_tests(
'non-interactive, extended (both.t)',
{
    NONINTERACTIVE_TESTING => 1,
    EXTENDED_TESTING => 1,
}, qw(t/pass.t t/both.t),
[
    all_passed => 1, 'all passed',
    total => 1, 'test completely skipped',
]);

check_tests(
'no extended (both.t)',
{
}, qw(t/pass.t t/both.t),
[
    all_passed => 1, 'all passed',
    total => 1, 'test completely skipped',
]);

check_tests(
'non-interactive, no extended (both.t)',
{
    NONINTERACTIVE_TESTING => 1,
}, qw(t/pass.t t/both.t),
[
    all_passed => 1, 'all passed',
    total => 1, 'test completely skipped',
]);

done_testing;

