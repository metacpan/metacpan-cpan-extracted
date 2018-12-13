#!perl
# 09-mixed-skip-blocks: test n>1 where not all the tests are skipped.
# Tests both implicit- and explicit-config scenarios to reduce the
# repetition of boilerplate.

package t09;

use rlib 'lib';
use DTest;
use App::Prove;
use Capture::Tiny qw(capture);
use Data::Dumper;

our $RESULTS;   # Where the results will be stored

main();

# Main {{{1
sub main {
    my $test_fn = localpath('mixedskip.test');   # the test file to run

    # Tell `require` that the modules defined in this file are loaded.
    # That way when App::Prove calls `require` on them, it will succeed.
    $INC{'App/Prove/Plugin/t09p.pm'} = 1;
    $INC{'App/Prove/Plugin/t09p/Formatter.pm'} = 1;

    eval "require App::Prove::Plugin::t09p";
    ok(!$@, "can require t09p");

    eval "require App::Prove::Plugin::t09p::Formatter";
    ok(!$@, "can require t09p::Formatter");

    # Explicit config
    $RESULTS = undef;
    run_prove($test_fn);
    check_results($test_fn);

    # Implicit config
    $RESULTS = undef;
    run_prove($test_fn, 1);
    check_results($test_fn);

    done_testing();
} #main

sub run_prove {
    my $test_fn = shift;
    my $is_implicit = shift;

    diag "vvvvvvvvvvv Running tests in $test_fn under App::Prove";
    my $app = App::Prove->new;
    $app->process_args(
        qw(-Q --norc --state=all),  # Isolate us from the environment
        qw(-l),                     # DTest relies on Test::OnlySome::PathCapsule
        $test_fn,
        '-Pt09p',
        $is_implicit ? () : qw(:: explicit)
    );

    # prove(1) gets confused by the mixed output from this script and from
    # the inner App::Prove.  Therefore, capture it.
    my ($stdout, $stderr, @result) = capture {
        $app->run;
    };

    diag "  Result was ", join ", ", @result;
    diag "  STDOUT:";
    diag $stdout;
    diag "  STDERR";
    diag $stderr;
    diag "^^^^^^^^^^^ End of output from running tests in $test_fn under App::Prove";
} #run_prove()

sub check_results {
    my $test_fn = shift;

    ok(ref $RESULTS eq 'HASH', 'We got results');
    my $hr = $RESULTS->{$test_fn};
    ok($hr, "Result file has an entry for $test_fn");
    diag(Data::Dumper->Dump([$hr],[' Inner test results']));

    is_deeply($hr->{skipped}, [], 'No tests were skipped');
    is_deeply($hr->{todo}, [], 'No tests were marked TODO');
    is_deeply([sort @{ $hr->{failed} }], [1, 4], 'The tests we expected to fail did');
    is_deeply([sort @{ $hr->{passed} }], [2, 3], 'The tests we expected to pass did');
} #check_results()

# }}}1
# App::Prove plugin {{{1
package App::Prove::Plugin::t09p;

sub load {
    my ($class, $prove) = @_;
    $prove->{app_prove}->formatter('App::Prove::Plugin::t09p::Formatter');
} #load()

# }}}1
# Test formatter to capture results {{{1
package App::Prove::Plugin::t09p::Formatter;

use parent 'TAP::Formatter::Console';

sub summary {
    my $self = shift;
    my ($aggregate, $interrupted) = @_;
    my %results;

    #$self->SUPER::summary(@_);

    # Collect the results.  Can't use $parser->next, since App::Prove has
    # already iterated over the results.

    while( my ($fn, $parser) = each %{$aggregate->{parser_for}} ) {
        # Save the results for this test file
        $results{$fn} = {};
        $results{$fn}->{$_} = _ary($parser->$_)
            for qw(passed failed skipped actual_passed actual_failed todo todo_passed);
    } #foreach result file

    # Save the output
    $RESULTS = \%results;
} #summary()

# Wrap the arg(s) in an arrayref unless the first arg already is one.
sub _ary {
    return $_[0] if ref $_[0] eq 'ARRAY';
    return [@_];
}

# }}}1
# vi: set fdm=marker:
