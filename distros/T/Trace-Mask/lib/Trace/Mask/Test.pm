package Trace::Mask::Test;
use strict;
use warnings;

use Trace::Mask::Util qw/mask_frame mask_line mask_call/;
use Trace::Mask::Reference qw/trace/;

use Carp qw/croak/;
use Scalar::Util qw/reftype/;
use List::Util qw/min/;

use base 'Exporter';
our @EXPORT = qw{test_tracer NA};
our @EXPORT_OK = qw{
    test_stack_hide test_stack_shift test_stack_stop test_stack_no_start
    test_stack_alter test_stack_shift_and_hide test_stack_shift_short
    test_stack_hide_short test_stack_shift_and_alter test_stack_full_combo
    test_stack_restart test_stack_special test_stack_lock
};

sub NA() { \&NA }

sub test_tracer {
    my %params = @_;
    my $convert = delete $params{convert};
    my $trace   = delete $params{trace};
    my $name    = delete $params{name} || 'tracer test';
    my $type    = delete $params{type} || 'return';

    croak "your must provide a 'convert' callback coderef"
        unless $convert && ref($convert) && reftype($convert) eq 'CODE';

    croak "your must provide a 'trace' callback coderef"
        unless $trace && ref($trace) && reftype($trace) eq 'CODE';

    my %tests;
    if (keys %params) {
        my @bad;

        for my $test (keys %params) {
            my $sub;
            $sub = __PACKAGE__->can($test) if !ref($test) && $test =~ m/^test_/ && $test !~ m/test_tracer/;
            if($sub && ref($sub) && reftype($sub) eq 'CODE') {
                $tests{$test} = $sub;
            }
            else{
                push @bad => $test;
            }
        }

        croak "Invalid test(s): " . join(', ', map {"'$_'"} sort @bad)
            if @bad;
    }
    else {
        for my $sym (keys %Trace::Mask::Test::) {
            next unless $sym =~ m/^test_/;
            next if $sym =~ m/test_tracer/;
            my $sub = __PACKAGE__->can($sym) || next;
            $tests{$sym} = $sub;
        }
    }

    require Test2::Tools::Compare;
    require Test2::Tools::Subtest;
    require Test2::API;

    my $ctx = Test2::API::context();

    my $results = {};
    my $expects = {};
    my $ok;
    my $sig_die = $SIG{__DIE__};

    Test2::Tools::Subtest::subtest_buffered($name => sub {
        local $SIG{__DIE__} = $sig_die;
        my $sctx = Test2::API::context();
        $sctx->set_trace($ctx->trace);
        for my $test (sort keys %tests) {
            my $sub = $tests{$test};
            my $result;
            {
                my ($ok, $error, $out, $warning);
                {
                    local $@;
                    local $SIG{__WARN__} = $SIG{__WARN__};
                    local *STDERR = *STDERR;

                    if ($type eq 'warning') {
                        $SIG{__WARN__} = sub {
                            die "Got multiple warnings!\n$warning\n$_[0]\n" if $warning;
                            ($warning) = @_;
                        };
                    }
                    elsif($type eq 'sigwarn') {
                        local *Trace::Mask::Test::FAKE;
                        *STDERR = *Trace::Mask::Test::FAKE;
                        $warning = "";
                        open(STDERR, '>', \$warning) || do {
                            print "Could not open temp STDERR: $!\n";
                            die "Could not open temp STDERR: $!";
                        };
                    }

                    $ok = eval { $out = $sub->($trace); 1 };
                    $error = $@;
                }

                if ($type eq 'exception') {
                    die "Callback did not throw an exception!\n" if $ok;
                    $ok = 1;
                    $result = $error;
                }
                elsif ($type eq 'return') {
                    die "Callback did not return anything!\n" unless $out;
                    $result = $out;
                }
                elsif($type eq 'warning' || $type eq 'sigwarn') {
                    die "Callback did not issue any warnings!\n" unless $warning;
                    $result = $warning;
                }
                else {
                    die "Invalid type: '$type'\n";
                }

                die $error unless $ok;

                $result = $convert->($result);
            }
            my $expect = $sub->(\&trace);
            for my $frame (@$expect) {
                $frame->[1] = [ map { ref($_) ? "$_" : $_ } @{$frame->[1]} ];
            }

            $results->{$test} = $result;
            $expects->{$test} = $expect;

            my $size = min(scalar(@$result), scalar(@$expect));
            for(my $i = 0; $i < $size; $i++) { # Frame
                delete $expect->[$i]->[2]; # Remove the mask

                # Args may not be available
                unless ($result->[$i]->[1] && @{$result->[$i]->[1]}) {
                    delete $expect->[$i]->[1];
                    delete $result->[$i]->[1];
                }

                for (my $j = @{$expect->[$i]->[0]} - 1; $j >= 0; $j--) {
                    if (exists $result->[$i]->[0]->[$j]) {
                        $expect->[$i]->[0]->[$j] = sub { 1 } if ref($result->[$i]->[0]->[$j]) && $result->[$i]->[0]->[$j] == \&NA;
                    }
                    else {
                        pop @{$expect->[$i]->[0]};
                    }
                }
            }

            delete $_->[2] for @$expect;
            $ok = Test2::Tools::Compare::like($result, $expect, $test);
            local $Data::Dumper::Sortkeys = 1;
            local $Data::Dumper::Sparseseen = 1;
            use Data::Dumper;
            print Dumper($result, $expect) unless $ok;

        }
        $sctx->release;
    });

    $ctx->release;

    return $ok unless wantarray;
    return ($ok, $results, $expects);
}




#line 1 "mask_test_hide.pl"
sub test_stack_hide {                    # line 1
    my ($callback) = @_;                 # line 2
    mask_frame(stop => 1, hide => 1);    # line 3
    hide_1($callback, 'a');              # line 4
}                                        # line 5

sub hide_1 { my $code = shift; @_ = (@_); hide_2($code, 'b') }    # line 7
sub hide_2 { my $code = shift; @_ = (@_); hide_3($code, 'c') }    # line 8
sub hide_3 { my $code = shift; @_ = (@_); mask_frame(hide => 2); hide_4($code, 'd') }    # line 9
sub hide_4 { my $code = shift; @_ = (@_); hide_5($code, 'e') }    # line 10
sub hide_5 { my $code = shift; @_ = (@_); $code->() }             # line 11




#line 1 "mask_test_shift.pl"
sub test_stack_shift {                   # line 1
    my ($callback) = @_;                 # line 2
    mask_frame(stop => 1, hide => 1);    # line 3
    shift_1($callback, 'a');             # line 4
}                                        # line 5

sub shift_1 { my $code = shift; @_ = (@_); shift_2($code, 'b') }    # line 7
sub shift_2 { my $code = shift; @_ = (@_); shift_3($code, 'c') }    # line 8
sub shift_3 { my $code = shift; @_ = (@_); shift_4($code, 'd') }    # line 9
sub shift_4 { my $code = shift; @_ = (@_); mask_frame(shift => 2); shift_5($code, 'e') }    # line 10
sub shift_5 { my $code = shift; @_ = (@_); $code->() }              # line 11




#line 1 "mask_test_stop.pl"
sub test_stack_stop {                    # line 1
    my ($callback) = @_;                 # line 2
    mask_frame(stop => 1, hide => 1);    # line 3
    stop_1($callback, 'a');              # line 4
}                                        # line 5

sub stop_1 { my $code = shift; @_ = (@_); stop_2($code, 'b') }    # line 7
sub stop_2 { my $code = shift; @_ = (@_); mask_frame(stop => 1); stop_3($code, 'c') }    # line 8
sub stop_3 { my $code = shift; @_ = (@_); stop_4($code, 'd') }    # line 9
sub stop_4 { my $code = shift; @_ = (@_); stop_5($code, 'e') }    # line 10
sub stop_5 { my $code = shift; @_ = (@_); $code->() }             # line 11




#line 1 "mask_test_no_start.pl"
sub test_stack_no_start {                # line 1
    my ($callback) = @_;                 # line 2
    mask_frame(stop => 1, hide => 1);    # line 3
    no_start_1($callback, 'a');          # line 4
}                                        # line 5

sub no_start_1 { my $code = shift; @_ = (@_); no_start_2($code, 'b') }    # line 7
sub no_start_2 { my $code = shift; @_ = (@_); no_start_3($code, 'c') }    # line 8
sub no_start_3 { my $code = shift; @_ = (@_); no_start_4($code, 'd') }    # line 9
sub no_start_4 { my $code = shift; @_ = (@_); mask_frame(no_start => 1); no_start_5($code, 'e') }    # line 10
sub no_start_5 { my $code = shift; @_ = (@_); mask_frame(no_start => 1); mask_call({no_start => 1}, $code) }    # line 11




#line 1 "mask_test_alter.pl"
sub test_stack_alter {                   # line 1
    my ($callback) = @_;                 # line 2
    mask_frame(stop => 1, hide => 1);    # line 3
    alter_1($callback, 'a');             # line 4
}                                        # line 5

sub alter_1 { my $code = shift; @_ = (@_); alter_2($code, 'b') }    # line 7
sub alter_2 { my $code = shift; @_ = (@_); alter_3($code, 'c') }    # line 8
sub alter_3 { my $code = shift; @_ = (@_); alter_4($code, 'd') }    # line 9
sub alter_4 {                                                       # line 10
    my $code = shift;                                               # line 11
    @_ = (@_);                                                      # line 12
    mask_frame(                                                     # line 13
        0   => 'Foo::Bar',                                          # line 14
        1   => 'Foo/Bar.pm',                                        # line 15
        2   => '42',                                                # line 16
        3   => 'Foo::Bar::foobar',                                  # line 17
        999 => 'x'                                                  # line 18
    );                                                              # line 19
    alter_5($code, 'e')                                             # line 20
}                                                                   # line 21
sub alter_5 { my $code = shift; @_ = (@_); $code->() }              # line 22




#line 1 "mask_test_s_and_h.pl"
sub test_stack_shift_and_hide {          # line 1
    my ($callback) = @_;                 # line 2
    mask_frame(stop => 1, hide => 1);    # line 3
    s_and_h_1($callback, 'a');           # line 4
}                                        # line 5

sub s_and_h_1 { my $code = shift; @_ = (@_); s_and_h_2($code, 'b') }    # line 7
sub s_and_h_2 { my $code = shift; @_ = (@_); s_and_h_3($code, 'c') }    # line 8
sub s_and_h_3 { my $code = shift; @_ = (@_); mask_frame(hide  => 1); s_and_h_4($code, 'd') }   # line 9
sub s_and_h_4 { my $code = shift; @_ = (@_); mask_frame(shift => 1); s_and_h_5($code, 'e') }   # line 10
sub s_and_h_5 { my $code = shift; @_ = (@_); $code->() }                                  # line 11




#line 1 "mask_test_shift_short.pl"
sub test_stack_shift_short {             # line 1
    my ($callback) = @_;                 # line 2
    mask_frame(stop => 1, hide => 1);    # line 3
    shift_short_1($callback, 'a');       # line 4
}                                        # line 5

sub shift_short_1 { my $code = shift; @_ = (@_); shift_short_2($code, 'b') }    # line 7
sub shift_short_2 { my $code = shift; @_ = (@_); shift_short_3($code, 'c') }    # line 8
sub shift_short_3 { my $code = shift; @_ = (@_); shift_short_4($code, 'd') }    # line 9
sub shift_short_4 { my $code = shift; @_ = (@_); mask_frame(shift => 5); shift_short_5($code, 'e') }    # line 10
sub shift_short_5 { my $code = shift; @_ = (@_); $code->() }                                       # line 11




#line 1 "mask_test_hide_short.pl"
sub test_stack_hide_short {              # line 1
    my ($callback) = @_;                 # line 2
    mask_frame(stop => 1, hide => 1);    # line 3
    hide_short_1($callback, 'a');        # line 4
}                                        # line 5

sub hide_short_1 { my $code = shift; @_ = (@_); hide_short_2($code, 'b') }    # line 7
sub hide_short_2 { my $code = shift; @_ = (@_); hide_short_3($code, 'c') }    # line 8
sub hide_short_3 { my $code = shift; @_ = (@_); hide_short_4($code, 'd') }    # line 9
sub hide_short_4 { my $code = shift; @_ = (@_); mask_frame(hide => 5); hide_short_5($code, 'e') }    # line 10
sub hide_short_5 { my $code = shift; @_ = (@_); $code->() }                                     # line 11




#line 1 "mask_test_s_and_a.pl"
sub test_stack_shift_and_alter {         # line 1
    my ($callback) = @_;                 # line 2
    mask_frame(stop => 1, hide => 1);    # line 3
    s_and_a_1($callback, 'a');           # line 4
}                                        # line 5

sub s_and_a_1 { my $code = shift; @_ = (@_); s_and_a_2($code, 'b') }    # line 7
sub s_and_a_2 { my $code = shift; @_ = (@_); s_and_a_3($code, 'c') }    # line 8
sub s_and_a_3 {          # line 9
    my $code = shift;    # line 10
    @_ = (@_);           # line 11
    mask_frame(0 => 'x', 1 => 'x', 2 => '100', 3 => 'x', 4 => 'x');    # line 12
    s_and_a_4($code, 'd');                                           # line 13
}                        # line 14
sub s_and_a_4 {          # line 15
    my $code = shift;    # line 16
    @_ = (@_);           # line 17
    mask_frame(0 => 'y', 1 => 'y', 2 => '200', 3 => 'y', 4 => 'y', shift => 1);    # line 18
    s_and_a_5($code, 'e');                                                       # line 19
}                        # line 20
sub s_and_a_5 { my $code = shift; @_ = (@_); $code->() } # line 21




#line 1 "mask_test_full_combo.pl"
sub test_stack_full_combo {              # line 1
    my ($callback) = @_;                 # line 2
    mask_frame(stop => 1, hide => 1);    # line 3
    full_combo_1($callback, 'a');        # line 4
}                                        # line 5

sub full_combo_1 { my $code = shift; @_ = (@_); full_combo_2($code, 'b') }    # line 7
sub full_combo_2 { my $code = shift; @_ = (@_); mask_frame('pause' => 1, 'restart' => 1); full_combo_3($code, 'c') }    # line 8
sub full_combo_3 { my $code = shift; @_ = (@_); full_combo_4($code, 'd') }    # line 9
sub full_combo_4 { my $code = shift; @_ = (@_); mask_frame('pause' => 1); full_combo_5($code, 'e') }    # line 10
sub full_combo_5 { my $code = shift; @_ = (@_); full_combo_6($code, 'f') }                             # line 11
sub full_combo_6 { my $code = shift; @_ = (@_); full_combo_7($code, 'g') }                             # line 12
sub full_combo_7 { my $code = shift; @_ = (@_); full_combo_8($code, 'h') }                             # line 13
sub full_combo_8 { my $code = shift; @_ = (@_); full_combo_9($code, 'i') }                             # line 14
sub full_combo_9 { my $code = shift; @_ = (@_); mask_frame(0 => 'xxx'); full_combo_10($code, 'j') }    # line 15
sub full_combo_10 { my $code = shift; @_ = (@_); full_combo_11($code, 'k') }                           # line 16
sub full_combo_11 { my $code = shift; @_ = (@_); full_combo_12($code, 'l') }                           # line 17
sub full_combo_12 { my $code = shift; @_ = (@_); full_combo_13($code, 'm') }                           # line 18
sub full_combo_13 { my $code = shift; @_ = (@_); mask_frame(0 => 'foo', 5 => 'foo'); full_combo_14($code, 'n') }    # line 19
sub full_combo_14 { my $code = shift; @_ = (@_); mask_frame(hide => 1); full_combo_15($code, 'o') }                 # line 20
sub full_combo_15 { my $code = shift; @_ = (@_); full_combo_16($code, 'p') }                                        # line 21
sub full_combo_16 { my $code = shift; @_ = (@_); full_combo_17($code, 'q') }                                        # line 22
sub full_combo_17 { my $code = shift; @_ = (@_); mask_frame(shift => 3, 0 => 'bar', 5 => 'bar'); full_combo_18($code, 'r') }    # line 23
sub full_combo_18 { my $code = shift; @_ = (@_); full_combo_19($code, 's') }                                                    # line 24
sub full_combo_19 { my $code = shift; @_ = (@_); full_combo_20($code, 't') }                                                    # line 25
sub full_combo_20 { my $code = shift; @_ = (@_); mask_frame(no_start => 1); mask_call({no_start => 1}, $code) }                 # line 26




#line 1 "mask_test_restart.pl"
sub test_stack_restart {                 # line 1
    my ($callback) = @_;                 # line 2
    mask_frame(stop => 1, hide => 1);    # line 3
    restart_1($callback, 'a');           # line 4
}                                        # line 5

sub restart_1 { my $code = shift; @_ = (@_); restart_2($code, 'b') }                                # line 7
sub restart_2 { my $code = shift; @_ = (@_); mask_frame('restart' => 1); restart_3($code, 'c') }    # line 8
sub restart_3 { my $code = shift; @_ = (@_); restart_4($code, 'd') }                                # line 9
sub restart_4 { my $code = shift; @_ = (@_); mask_frame('pause' => 1); restart_5($code, 'e') }       # line 10
sub restart_5 { my $code = shift; @_ = (@_); restart_6($code, 'f') }                                # line 11
sub restart_6 { my $code = shift; @_ = (@_); mask_call({no_start => 1}, $code) }                    # line 12




#line 1 "mask_test_special.pl"
sub test_stack_special {                 # line 1
    my ($callback) = @_;                 # line 2
    mask_frame(stop => 1, hide => 1);    # line 3
    special_1($callback, 'a');           # line 4
}                                        # line 5

sub special_1 { my $code = shift; @_ = (@_); special_2($code, 'b') }
sub special_2 { my $code = shift; @_ = (@_); unimport($code, 'c') }
sub unimport {  my $code = shift; @_ = (@_); mask_frame(hide => 1); special_3($code, 'd') }
sub special_3 { my $code = shift; @_ = (@_); special_4($code, 'e') }
sub special_4 { my $code = shift; @_ = (@_); special_5($code, 'f') }
sub special_5 { my $code = shift; @_ = (@_); mask_frame(pause => 1); special_6($code, 'g') }
sub special_6 { my $code = shift; @_ = (@_); $code->() }




#line 1 "mask_test_lock.pl"
sub test_stack_lock {                    # line 1
    my ($callback) = @_;                 # line 2
    mask_frame(stop => 1, hide => 1);    # line 3
    lock_1($callback, 'a');              # line 4
}                                        # line 5

sub lock_1 { my $code = shift; @_ = (@_); lock_2($code, 'b') }
sub lock_2 { my $code = shift; @_ = (@_); lock_x($code, 'c') }
sub lock_x { my $code = shift; @_ = (@_); mask_frame(hide => 1, lock => 1); lock_3($code, 'd') }
sub lock_3 { my $code = shift; @_ = (@_); lock_4($code, 'e') }
sub lock_4 { my $code = shift; @_ = (@_); lock_5($code, 'f') }
sub lock_5 { my $code = shift; @_ = (@_); mask_frame(pause => 1); lock_6($code, 'g') }
sub lock_6 { my $code = shift; @_ = (@_); $code->() }


1;

=pod

=head1 NAME

Trace::Mask::Test - Tools for testing Trace::Mask compliance.

=head1 DESCRIPTION

This package provides tools for testing tracers. This allows you to check that
a tracer complies with the specifications.

=head1 SYNOPSIS

    use Trace::Mask::Test qw/test_tracer/;

    test_tracer(
        name => 'my tracer',
        trace => \&trace,
        type  => 'return',
        convert => sub {
            my $stack = shift;
            ...
            return $stack;
        },
    );

=head1 EXPORTS

=over 4

=item NA()

Placeholder value for use in test_tracer to represent fields the tracer does
not provide.

=item ($ok, $result, $expect) = test_tracer(trace => \&trace, convert => \&convert, name => "my test")

=item ($ok, $result, $expect) = test_tracer(trace => \&trace, convert => \&convert, name => "my test", %tests)

This will verify that a tracer follows the specification. This will run every
test in the test list below with both the specified tracer and the refewrence
tracer, it will then compare the results.

In scalar context the sub returns a true or false indicating if the test passed
or failed. In List context the sub will return the boolen $ok value, the
arrayref produced from your stack, and the arrayref produced by the reference
tracer. This behavior gives you the ability to debug the final structures, and
manually compare them.

=over 4

=item name => "..."

Specify a name for your test.

=item trace => \&trace

This should be your tracer, or a subroutine that calls it. This subroutine is
called in scalar context. This can return the trace in any form you want so
long as it is returned in a scalar.

=item convert => \&convert

This will be given the scalar your tracer returns as its only input argument.
This sub should convert the trace to a standard form for comparison.

    convert => sub {
        my ($trace) = @_;
        ...
        return [
            [[$package1, NA(), $line1, $subname1, ...], \@args]
            [[$package2, $file2, $line2, $subname2, ...], \@args]
        ]
    },

The standard return is an arrayref with an arrayref for each stack frame. Each
frame arrayref should itself contain 2 arrayrefs. The first arrayref should
contain the fields caller() would return for that level. The second arrayref
should contain arguments that the function was called with. You can use the ref
returned from C<NA()> in place of any value that cannot be obtained from your
stack trace results. In addition it only checks values you have specified, if
you only list the first 4 fields from caller then only the first 4 are checked.

=item type => 'return'

The trace function will return a trace in a scalar, use that as our trace.

=item type => 'exception'

The trace function will throw an exception, intercept it and use the exception
as the trace.

=item type => 'warning'

The trace function will issue a warning, intecept it using a C<$SIG{__WARN__}>
override, then use the warning as our trace.

B<Note:> If your tracer issues more than 1 warning and exception will be
thrown.

B<Note:> Since this uses a C<$SIG{__WARN__}>, it cannot be used to check traces
that require a custom C<$SIG{__WARN__} override. See the 'sigwarn' type below
if you are testing a tool that rewrites warnings.

=item type => 'sigwarn'

The trace function will issue a warning, but a custom $SIG{__WARN__} needs to
modify it before we see it. This will NOT override C<$SIG{__WARN__}>, instead
it will intercept all output to STDERR when it calls your tracer.

=item %tests

If you do not specify any tests then all will be run. If you only want to run a
subset of tests then you can list them with a true value.

    test_tracer(
        name    => "foo",
        type    => 'return',
        trace   => \&trace,
        convert => sub { ... },

        test_stack_hide            => 1,
        test_stack_shift           => 1,
        test_stack_stop            => 1,
        test_stack_no_start        => 1,
        test_stack_alter           => 1,
        test_stack_shift_and_hide  => 1,
        test_stack_shift_short     => 1,
        test_stack_hide_short      => 1,
        test_stack_shift_and_alter => 1,
        test_stack_full_combo      => 1,
    );

=back

=back

=head2 OPTIONAL EXPORTS / TESTS

=over 4

=item test_stack_hide(\&callback)

=item test_stack_shift(\&callback)

=item test_stack_stop(\&callback)

=item test_stack_no_start(\&callback)

=item test_stack_alter(\&callback)

=item test_stack_shift_and_hide(\&callback)

=item test_stack_shift_short(\&callback)

=item test_stack_hide_short(\&callback)

=item test_stack_shift_and_alter(\&callback)

=item test_stack_full_combo(\&callback)

=back

=head1 SOURCE

The source code repository for Trace-Mask can be found at
F<http://github.com/exodist/Trace-Mask>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2015 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut
