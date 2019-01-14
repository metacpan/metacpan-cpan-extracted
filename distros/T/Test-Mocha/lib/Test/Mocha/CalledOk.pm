package Test::Mocha::CalledOk;
# ABSTRACT: Abstract base class for verifying method calls
# Abstract class methods required of sub-classes: 'is' and 'stringify'
$Test::Mocha::CalledOk::VERSION = '0.65';
use strict;
use warnings;

use Test::Builder;

my $TB = Test::Builder->new;

sub test {
    # uncoverable pod
    my ( $class, $method_call, $exp, $test_name ) = @_;

    my $calls   = $method_call->invocant->__calls;
    my $got     = grep { $method_call->__satisfied_by($_) } @{$calls};
    my $test_ok = $class->is( $got, $exp );

    my $exp_times = $class->stringify($exp);
    $test_name = "$method_call was called $exp_times" if !defined $test_name;

    # Test failure report should not trace back to Mocha modules
    {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $TB->ok( $test_ok, $test_name );
    }

    # output diagnostics to aid with debugging
    unless ( $test_ok || $TB->in_todo ) {
        my $call_history;
        if ( @{$calls} ) {
            $call_history .= "\n    " . $_->stringify_long foreach @{$calls};
        }
        else {
            $call_history = "\n    (No methods were called)";
        }

        $TB->diag(<<"END");
Error: unexpected number of calls to '$method_call'
         got: $got time(s)
    expected: $exp_times
Complete method call history (most recent call last):$call_history
END
    }
    return;
}

1;
