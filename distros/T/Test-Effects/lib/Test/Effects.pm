package Test::Effects;

use warnings;
no if $] >= 5.018, 'warnings', "experimental::smartmatch";
use strict;
use 5.014;

our $VERSION = '0.001005';

use Test::More;
use Test::Trap;
use base 'Test::Builder::Module';

# Export the modules interface (and that of Test::More)...
our @EXPORT = (
    qw( effects_ok ),
    qw( ONLY VERBOSE TIME ),
    @Test::More::EXPORT,
);

our @EXPORT_OK = (
    @Test::More::Export_OK,
);

our %EXPORT_TAGS = (
    'minimal' => [ 'effects_ok' ],
    'more'    => [ 'effects_ok', @Test::More::EXPORT],
);

# Magic number tells Test::More how many stack levels to go up when reporting errors
# (Unfortunately, this depends on the internals of Test::More)
# [TODO: Send a patch for Test::More that autoskips a named class when reporting]
my $LEVEL_OFFSET = 6;
my $LEVEL_OFFSET_NESTED = 2 * $LEVEL_OFFSET + 1;


# Adjust tests used in the module to account for nesting...
sub _subtest {
    my ($desc) = @_;

    # Report problems as being in the appropriate place...
    local $Test::Builder::Level = $Test::Builder::Level + $LEVEL_OFFSET;

    &subtest(@_);
}

sub _fail {
    # Report problems as being in the appropriate place...
    local $Test::Builder::Level = $Test::Builder::Level + $LEVEL_OFFSET_NESTED;

    &fail(@_);
}

use Scalar::Util 'looks_like_number';

sub is_num { Test::Effects->builder->is_num(@_) }

sub _is_or_like {
    my ($got, $expected, $desc) = @_;

    # Report problems as being in the appropriate place...
    local $Test::Builder::Level = $Test::Builder::Level + $LEVEL_OFFSET_NESTED;

    given (ref $expected) {
        when ('CODE')   {
            no warnings;
            my $ok = \&Test::Builder::ok;
            local *Test::Builder::ok = sub { $_[2] = $desc unless defined $_[2]; $ok->(@_); };
            ok($expected->($got, $desc), $desc);
        }
        when ('Regexp')                     { &like(@_);   }
        when (looks_like_number($expected)) { &is_num(@_); }
        default                             { &is(@_);     }
    }
}

sub _is_deeply {
    my ($got, $expected, $desc) = @_;

    # Report problems as being in the appropriate place...
    local $Test::Builder::Level = $Test::Builder::Level + $LEVEL_OFFSET_NESTED;

    given (ref $expected) {
        when ('CODE')   {
            no warnings;
            my $ok = \&Test::Builder::ok;
            local *Test::Builder::ok = sub { $_[2] = $desc unless defined $_[2]; $ok->(@_); };
            ok($expected->($got, $desc), $desc);
        }
        default { &is_deeply(@_) }
    }
}

sub _is_like_or_deeply {
    my ($got, $expected, $desc) = @_;

    # Report problems as being in the appropriate place...
    local $Test::Builder::Level = $Test::Builder::Level + $LEVEL_OFFSET_NESTED;

    given (ref $expected) {
        when ('CODE')   {
            no warnings;
            my $ok = \&Test::Builder::ok;
            local *Test::Builder::ok = sub { $_[2] = $desc unless defined $_[2]; $ok->(@_); };
            ok($expected->($got, $desc), $desc);
        }
        when ('Regexp') { my $got_val = ref($got) eq 'ARRAY' && @{$got} == 1
                                        ? $got->[0]
                                        : $got;
                          like($got_val, $expected, $desc);
                        }
        when (q{}) {
            if (looks_like_number($expected)) { &is_num(@_) }
            else                              {     &is(@_) }
        }
        default { &is_deeply(@_) }
    }
}

sub _is_like_or_list {
    my ($got, $expected, $desc) = @_;

    # Report problems as being in the appropriate place...
    local $Test::Builder::Level = $Test::Builder::Level + $LEVEL_OFFSET_NESTED;

    given (ref $expected) {
        when ('CODE')   {
            no warnings;
            my $ok = \&Test::Builder::ok;
            local *Test::Builder::ok = sub { $_[2] = $desc unless defined $_[2]; $ok->(@_); };
            ok($expected->($got, $desc), $desc);
        }
        when ('Regexp') { my $got_val = ref($got) eq 'ARRAY' && @{$got} == 1
                                        ? $got->[0]
                                        : $got;
                          like($got_val, $expected, $desc);
                        }
        when (q{} && looks_like_number($expected)) { &is_num(@_); }
        when (q{})                                 { &is(@_);   }
        when (q{ARRAY}) {
            for my $n (0..$#{$expected}) {
                _is_or_like($got->[$n], $expected->[$n], "$desc [warning $n]");
            }
        }
        default { &is_deeply(@_) }
    }
}


# Utility sub: dump values...

sub _explain {
    use Data::Dumper 'Dumper';
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    return Dumper(shift) =~ s/\s+/ /gr
                         =~ s/\s+$//gr;
}


# Utility subs: build subs that append the right verb, when requested....

sub _was_were_sub {
    my ($desc) = @_;

    return sub {
        my (undef, $was_were) = @_;

        return $desc if !$was_were;
        return "$desc was";
    };
}

sub _was_were_warn_sub {
    return sub {
        my ($expected, $was_were) = @_;

        my $count = eval{ @{$expected} } // 1;

        return $count == 1 ? 'warning'  . ($was_were ? ' was'  : q{})
                           : 'warnings' . ($was_were ? ' were' : q{});
    }
}


# Utility sub: load carp() and croak() only on demand...
sub _croak {
    if (eval{ require Carp }) { Carp::croak(@_); }
    else                      { die @_; }
}


# Module is largely table-driven (from these tables)...

my (%TEST_FOR, %NULL_VALUE_FOR, %BAD_NULL_VALUE_FOR, %DESCRIBE);

BEGIN {
    %TEST_FOR = (
        'stdout' => \&_is_or_like,
        'stderr' => \&_is_or_like,
        'warn'   => \&_is_like_or_list,
        'die'    => \&_is_or_like,
        'exit'   => \&_is_or_like,
    );

    %NULL_VALUE_FOR = (
        'stdout' => q{},
        'stderr' => q{},
        'warn'   => [],
        'die'    => undef,
        'exit'   => undef,
    );

    %BAD_NULL_VALUE_FOR = (
        'stdout' => undef,
        'stderr' => undef,
        'warn'   => undef,
        'die'    => q{},
        'exit'   => q{},
    );

    %DESCRIBE = (
        'stdout' => _was_were_sub( 'output to STDOUT' ),
        'stderr' => _was_were_sub( 'output to STDERR' ),
        'warn'   => _was_were_warn_sub(),
        'die'    => _was_were_sub( 'exception' ),
        'exit'   => _was_were_sub( 'call to exit()' ),
    );
}


# Make a copy of a hash with an appropriate flag added...
sub ONLY    (+)  { return { ONLY    => 1, %{shift()} } }
sub VERBOSE (+)  { return { VERBOSE => 1, %{shift()} } }
sub TIME    (+)  { return { TIME    => 1, %{shift()} } }

my $MS_THRESHHOLD = 0.1; # seconds (anything less reported in ms)

# Test all trapped info, as requested...
sub effects_ok (&;+$) {
    my ($block, $expected, $desc) = @_;
    my $expected_ref = ref $expected;

    # Handle case where hash is missing, but description isn't...
    if (@_ == 2 && !$expected_ref) {
        $desc     = "$expected";
        $expected = undef;
    }

    # Expectations are passed in a hash...
    $expected //= {};
    if (ref($expected) ne 'HASH') {
        _croak 'Second argument to effects_ok() must be hash or hash reference, not '
             . lc(ref($expected) || 'scalar value');
    }

    # If there's a timing request, the value has to make sense...
    my $timing;
    if (exists $expected->{'timing'}) {
        my $spec = $expected->{'timing'};
        my $valid_time =  ref($spec) =~ m{ \A (?: HASH | ARRAY ) \Z}xms
                      || !ref($spec) && looks_like_number($spec);
        if (!$valid_time) {
            _croak("Invalid timing specification: timing => '$spec'");
        }
    }

    # Get lexical hints...
    my %lexical_hint = %{ (caller 0)[10] // {} };

    # Fill in default tests, unless requested not to...
    my $is_only
        = exists $expected->{'ONLY'} ? $expected->{'ONLY'}
        :                              $lexical_hint{'Test::Effects::ONLY'};

    # Time the test, if requested
    my $timed_test
        = exists $expected->{'TIME'} ? $expected->{'TIME'}
        :                              $lexical_hint{'Test::Effects::TIME'};

    if (!$is_only) {
        my $warn = $expected->{'warn'};
        $expected = {
            %NULL_VALUE_FOR,
            'stderr' => (ref $warn eq 'ARRAY' ? join(q{}, @{$warn}) : $warn),
            %{$expected},
        };
    }

    # Correct common mispecifications...
    for my $option (keys %BAD_NULL_VALUE_FOR) {
        next if !exists $expected->{$option};
        if ($expected->{$option} ~~ $BAD_NULL_VALUE_FOR{$option}) {
            $expected->{$option} = $NULL_VALUE_FOR{$option};
        }
    }

    # Ensure there's a description...
    $desc //= sprintf "Testing effects_ok() at %s line %d", (caller)[1,2];

    # Are we echoing this test???
    my $is_terse
        = exists $expected->{'VERBOSE'} ? !$expected->{'VERBOSE'}
        :                                 !$lexical_hint{'Test::Effects::VERBOSE'};

    # Show the description...
    my $preview_desc = !$is_terse || exists $expected->{'timing'};
    if ($preview_desc) {
        note '_' x (3 + length $desc);
        note exists $expected->{'timing'}
                ? "$desc (being timed)..."
                : "$desc...";
    }

    # Redirect test output, so we can retrospectively de-terse on errors...
    my $tests_output;
    given (Test::Builder->new()) {
        $_->output(\$tests_output);
        $_->failure_output(\$tests_output);
        $_->todo_output(\$tests_output);
    }

    # Preview description under terse too, in case of failures...
    if (!$preview_desc) {
        note '_' x (3 + length $desc);
        note "$desc...";
    }

    # Are we WITHOUT any modules in this test???
    my @real_INC = @INC;
    local @INC = @INC;
    local %INC = %INC;
    if (exists $expected->{'WITHOUT'}) {
        my $without_list = $expected->{'WITHOUT'};

        # Normalize list...
        if (ref $without_list ne 'ARRAY') {
            $without_list = [ $without_list ];
        }

        # Translate list to filepaths...
        for my $module_name ( @{$without_list} ) {
            # Classify the argument...
            my $is_pattern = ref $module_name eq 'Regexp';
            my $is_libpath = $module_name =~ m{/};

            # Modules get translated to paths...
            if (!$is_libpath) {
                if (not $module_name =~ s{::}{/}gxms) {
                    diag "WARNING: ambiguous WITHOUT => "
                       . ($is_pattern ? "qr{$module_name}" : "'$module_name'")
                       . "\ntreated as module name (not library path)"
                       . "\n(use "
                       . ($is_pattern ? "qr{::$module_name}" : "'::$module_name'")
                       . " or "
                       . ($is_pattern ? "qr{$module_name/}" : "'$module_name/'")
                       . " to silence this warning)";
                }
                if (!$is_pattern) {
                    $module_name .= '.pm';
                }
                else {
                    $module_name = qr{$module_name};
                }
            }
            # Libpaths winnow @INC directly...
            elsif (!$is_pattern && $is_libpath) {
                $module_name =~ s{/\Z}{}xms;
                if ($module_name =~ m{\A /}x) {
                    @INC = grep { !m{\A $module_name /? \Z}x } @INC;
                }
                else {
                    @INC = grep { !m{\A (?: [.]/ )? $module_name /? \Z}x } @INC;
                }
            }
            else { # Pattern spec for libpath
                @INC = grep { !m{$module_name} } @INC;
            }

            # Libpaths then don't need to be checked with @INC...
            if ($is_libpath) {
                $module_name = undef;
            }
        }

        # Put an interceptor sub at the start of @INC...
        unshift @INC, sub {
            my ($self, $target) = @_;

            # If what you're looking for is WITHOUT'd, pretend to fail...
            if ($target ~~ $without_list || "/$target" ~~ $without_list) {
                _croak "Can't locate $target in \@INC (\@INC contains: @real_INC)";
            }
            return;
        };
    }

    # Test in a subtest...
    my $failed = _subtest $desc => sub {
        # Find the specified return value (if any)...
        my @return_specs = grep /return/, keys %{$expected};
        if (@return_specs > 1) {
            _fail "Ambiguous specification for testing of return value.";
            diag "ERROR: Found request for " . scalar(@return_specs),
                 " mutually exclusive tests:\n",
                 "       {\n",
                 (map { "          '$_' => " . _explain($expected->{$_}) . ",\n" } @return_specs),
                 "       }\n",
                 "       Call to effects_ok() terminated without testing anything.";
            return;
        }

        # Infer context, if necessary...
        if (exists $expected->{'return'}) {
            given (ref $expected->{'return'}) {
                when ('ARRAY') { $expected->{'list_return'}   = delete $expected->{'return'} }
                default        { $expected->{'scalar_return'} = delete $expected->{'return'} }
            }
        }

        # Call the block and test the return value in the appropriate context...
        # 1. Explicit void context...
        if (exists $expected->{'void_return'}) {
            if (defined $expected->{'void_return'}) {
                note "WARNING: Meaningless option {void_return => '$expected->{void_return}'} ignored.\n"
                   . "         To silence this warning, either remove the option entirely\n"
                   . "         or replace it with: {void_return => undef})";
            }
            if ($timed_test) {
                _time_calls_to($block, $timed_test => $timing);
            }
            else {
                trap { $block->() };
            }
            pass 'Tested in void context, so ignored return value'
        }
        # 2. Explicit scalar context...
        elsif (exists $expected->{'scalar_return'}) {
            my $return_val = do {
                if ($timed_test) {
                    _time_calls_to($block, $timed_test => $timing);
                }
                else {
                    trap { $block->() };
                }
            };
            _is_like_or_deeply $return_val, $expected->{'scalar_return'}
                            => 'Scalar context return value was as expected';
        }
        # 3. Explicit list context...
        elsif (exists $expected->{'list_return'}) {
            my @return_vals = do {
                if ($timed_test) {
                    _time_calls_to($block, $timed_test => $timing);
                }
                else {
                    trap { $block->() };
                }
            };
            _is_deeply \@return_vals, $expected->{'list_return'}
                    => 'List context return value was as expected';
        }
        # 4. Implied void context...
        else {
            if ($timed_test) {
                _time_calls_to($block, $timed_test => $timing);
            }
            else {
                trap { $block->() };
            }
            pass 'No return value specified, so tested in void context';
        }

        # Test side-effects...
        for my $info (qw< stdout stderr warn die exit>) {
            if (exists $expected->{$info}) {
                no strict 'refs';
                my $desc = $expected->{$info} ~~ $NULL_VALUE_FOR{$info}
                           ? 'No ' . $DESCRIBE{$info}->($expected->{$info}) . ' (as expected)'
                           : ucfirst $DESCRIBE{$info}->($expected->{$info},'was') . ' as expected';

                $TEST_FOR{$info}->($trap->$info, $expected->{$info}, $desc);
            }
        }

        # Do timing, if requested...

        if (exists $expected->{'timing'}) {

            # Work out the parameters...
            my $time_spec = $expected->{'timing'};
            my $spec_type = ref $time_spec;

            my $min = $spec_type eq 'HASH'  ? $time_spec->{'min'} // 0
                    : $spec_type eq 'ARRAY' ? $time_spec->[0]     // 0
                    :                         0;

            state $INF = 0 + 'inf';
            my $max = $spec_type eq 'HASH'          ? $time_spec->{'max'} // $INF
                    : $spec_type eq 'ARRAY'         ? $time_spec->[-1]    // $INF
                    :                                 0+$time_spec;

            # Run the test...
            my $duration = _time_calls_to($block);

            # Compute a handy alternate measure of performance...
            my $speed = $duration ? 1/$duration : 0;
               $speed = $speed > 1 ? sprintf('(%1.0lf/sec)', $speed)
                      : $speed > 0 ? sprintf('(%0.4g/sec)', $speed)
                      :              '(unmeasurably fast)';

            # Was the result acceptable???
            my $in_range = $min <= $duration && $duration <= $max;

            # Report outcome...
            ok $in_range => $duration > $MS_THRESHHOLD
                ? sprintf('Ran in %0.3f sec %s', $duration, $speed)
                : sprintf('Ran in %dms %s', 1000*$duration, $speed);

            # Clean up report...
            if (!$in_range) {
                $tests_output =~ s{\N*\n\N*\n\z}{}xms;
            }

            # Report any problems (as being in the appropriate place)...
            local $Test::Builder::Level = $Test::Builder::Level + $LEVEL_OFFSET_NESTED - 1;
            if (!$in_range) {
                diag sprintf "         Expected to run in: $min to $max sec", $min, $max;
            }
        }

    };

    # Clean up...
    my $builder = Test::Builder->new;
    $builder->reset_outputs;

    # Report outcomes...
    my $passed = ($builder->summary)[-1];
    # If passed in terse mode, just print the summary (i.e. last line)...
    if ( $is_terse && $passed ) {
        $tests_output =~ s{ .* \n (?= .*\n )}{}xms;
    }
    # Otherwise print the probems...
    elsif ( $is_terse ) {
        $tests_output =~ s{^ \s*+ (?! not | [#] ) [^\n]* \n}{}gxms;
    }

    # Add the timing info, if requested...
    if ($timed_test) {
        $tests_output =~ s{^ ( (?:not|ok) \s \N*) }{$1\t$timing}xms;
    }

    print {$builder->output} $tests_output;

    return $passed;
}


BEGIN { eval{ require Time::HiRes and Time::HiRes->import('time') } }

sub _time_calls_to {
    my ($block, $time_one_call) = @_;

    state $MAX_CPU_TIME              = 1;
    state $MIN_CREDIBLE_UTILIZATION  = 0.1;

    my ($cpu_time, $wall_time) = (0,0);
    my $count = 0;

    my (@start, @end);
    my $wantarray = wantarray;
    my (@result, $result);

    while (1) {
        if ($time_one_call && $wantarray) {
            @start = (time, times);
            @result = trap { $block->() };
            @end   = (time, times);
        }
        elsif ($time_one_call && defined $wantarray) {
            @start = (time, times);
            $result = trap { $block->() };
            @end   = (time, times);
        }
        else {
            @start = (time, times);
            trap { $block->() };
            @end   = (time, times);
        }

        $wall_time += $end[0] - $start[0];
        $cpu_time  += $end[$_] - $start[$_] for 1..4;

        $count++;

        last if $cpu_time  > $MAX_CPU_TIME
             || $wall_time > 2 * $MAX_CPU_TIME
             || $time_one_call;
    }

    my $utilization = $cpu_time / ($wall_time||1);
    my $timing = !$cpu_time || $utilization < $MIN_CREDIBLE_UTILIZATION
                    ? $wall_time / $count
                    : $cpu_time  / $count;

    if ($time_one_call) {
        if ($timing < $MS_THRESHHOLD) {
            $_[2] = '[' . int($timing * 1000) . 'ms]';
        }
        else {
            $_[2] = sprintf '[%0.2lf sec]', $timing;
        }
        return $wantarray ? @result : $result;
    }
    else {
        return $timing;
    }
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Test::Effects - Test all effects at once (return value, I/O, warnings, exceptions, etc.)


=head1 VERSION

This document describes Test::Effects version 0.001005


=head1 SYNOPSIS

=for test-synopsis
my $expected_scalar_context_return_value;
my @expected_list_context_return_values;

    use Test::Effects;

    # Test all possible detectable side-effects of some code...
    effects_ok { your_code_here() }
           {
               return => $expected_scalar_context_return_value,
               warn   => qr/match expected warning text/,
               stdout => '',  # i.e. Doesn't print anything.
           }
           => 'Description of test';


    # Test only specifically requested side-effects of some code...
    effects_ok { your_code_here() }
           ONLY {
               return => \@expected_list_context_return_values,
               stderr => 'Expected output to STDERR',
               die    => undef,  # i.e. Doesn't die.
               exit   => undef,  # i.e. Doesn't exit either.
           }
           => 'Description of test';


    # Test that some code has no detectable side-effects...
    effects_ok { your_code_here() };


=head1 DESCRIPTION

Test::Effects provides a single exported subroutine: C<effects_ok>

This sub expects a block of code (or sub ref) as its first argument,
followed by an optional hash ref as its second, and an optional string
as its third.

The first argument specifies some code to be tested. This code is run in
void context by default, but may instead be called in either list or
scalar context, depending on the test specification provided by the
second argument. The block is run within a call to C<Test::Trap::trap()>,
so all warnings, exceptions, output, and exit attempts are trapped.
The block may contain calls to other Test::Builder-based testing
modules; these are handled correctly within the overall test.

The second argument is a hash reference, whose entries specify the
expected side-effects of executing the block. You specify the name of
the side-effect you're interested in as the key, and the "effect" you
expected as the value. Side-effects that are not explicitly specified
are automatically tested for default behaviour (e.g. no warnings,
no exceptions, no output, not call to C<exit()>, etc. If the entire
hash is omitted, all possible side-effects are tested for default
behaviour (in other words, did the block of code have I<no> side-effects
whatsoever?)

The third argument is the overall description of the test (i.e. the
usual final argument for Perl tests). If omitted, C<effects_ok()>
generates a description based on the line number at which it was called.


=head1 INTERFACE

=head2 C<use Test::Effects;>

Loads the module, and exports the C<effects_ok()>, C<VERBOSE()>,
C<ONLY()>, and C<TIME()> subroutines (see below). Also exports the
standard interface from the Test::More module.

=head2 C<< use Test::Effects tests => $N; >>

Exactly the same as:

    use Test::More tests => $N;

In fact, S<C<use Test::Effects>> can take all the same arguments as
S<C<use Test::More>>.


=head2 C<< use Test::Effects import => [':minimal']; >>

Only export the C<effects_ok()> subroutine.

Do not export C<VERBOSE()>, C<ONLY()>, C<TIME()>,
or any of the Test::More interface.


=head2 C<< use Test::Effects import => [':more']; >>

Only export the C<effects_ok()> subroutine and the Test::More interface

Do not export C<VERBOSE()>, C<ONLY()>, or C<TIME()>.


=head2 C<< effects_ok {BLOCK} {EFFECTS_HASH} => 'TEST_DESCRIPTION'; >>

Test the code in the block, ensuring that the side-effects named by the
keys of the hash match the corresponding hash values. Both the hash
and the description arguments are optional.

The effects that can be specified as key/value pairs
in the hash are:

=over

=item C<< void_return => undef >>

Call the block in void context.


=item C<< return      => $ARRAY_REFERENCE >>

=item C<< list_return => $ANY_SCALAR_VALUE >>

Call the block in list context. The final value evaluated in the
block should (deeply) match the specified array ref or scalar value
of the option.


=item C<< return        => $NON_ARRAYREF >>

=item C<< scalar_return => $ANY_SCALAR_VALUE >>

Call the block in scalar context. The final value evaluated in block
should match the specified scalar value of the option.


=item C<< stdout => $STRING >>

What the block wrote to C<STDOUT> should be C<eq> to $STRING.

=item C<< stdout => $REGEX >>

What the block wrote to C<STDOUT> should be match $REGEX.

=item C<< stdout => $CODE_REF >>

The subroutine specified by the code ref should return true when passed
what the block wrote to C<STDOUT>.

The subroutine can call nested tests (such as Test::More's C<is>) or
Test::Tolerant's C<is_tol>) and these will be correctly handled.


=item C<< stderr => $STRING >>

=item C<< stderr => $REGEX >>

=item C<< stderr => $CODE_REF >>

What the block writes to C<STDERR> should "match" the specified value
(either C<eq>, or C<=~>, or return true when passed as an argument).

Note that, if this option is not specified, but the C<'warn'> option
(see below) I<is> specified, then this option defaults to the value of
the C<'warn'> option.


=item C<< warn => $STRING >>

=item C<< warn => $REGEX >>

=item C<< warn => $CODE_REF >>

=item C<< warn => [ $STRING1, $REGEX2, $CODE_REF3, $ETC ] >>

The block should issue the specified number of warnings, and each
of these warnings should match the corresponding value specified,
in the order specified.


=item C<< die => $STRING >>

=item C<< die => $REGEX >>

=item C<< die => $CODE_REF >>

The block should raise an exception, which should match the value
specified.

Note: when using OO exceptions, use a code ref to test them:

    die => sub { shift->isa('X::BadData') }

You can also use Test::More-ish tests, if you prefer:

    die => sub { isa_ok(shift, 'X::BadData') }


=item C<< exit => $NUMBER >>

=item C<< exit => $REGEX >>

=item C<< exit => $CODE_REF >>

The block should call C<exit()> and the exit code should match the
value specified.


=item C<< timing => { min => $MIN_SEC, max => $MAX_SEC }  >>

=item C<< timing => [$MIN_SEC, $MAX_SEC] >>

=item C<< timing => $MAX_SEC >>

This option performs a separate timing measurment for the block, by
running it multiple times over at least 1 cpu-second and averaging the
times required for each run (i.e. like the Benchmark module does).

When passed a hash reference, the C<'min'> and C<'max'> entries
specify the range of allowable timings (in seconds) for the block.
For example:

    # Test our new snooze() function...
    effects_ok { snooze(1.5, plus_or_minus=>0.2); }
               {
                    timing => { min => 1.3, max => 1.7 },
               }
               => 'snooze() slept about the right amount of time';

The default for C<'min'> is zero seconds;
the default for C<'max'> is eternity.

If you use an array reference instead of a hash reference, the first
value in the array is taken as the minimum time, and the final value is
taken as the maximum allowed time. Hence the above time specification
could also be written:

    timing => [ 1.3, 1.7 ],

But don't write:

    timing => [ 1.3 .. 1.7 ],

(unless your limits are integers),
because Perl truncates the bounds of a range,
so it treats C<[1.3 .. 1.7]> as C<[1 .. 1]>.

If you use a number instead of a reference, then
number is taken as the maximum time allowed:

    timing => 3.2,    # Same as: timing => { min => 0, max => 3.2 }

If you do not specify either time limit:

    timing => {},

or:

    timing => [],

then the "zero-to-eternity" defaults are used and C<effects_ok()> simply
times the block and reports the timing (as a success).

Note that the timings measured using this option are considerably more
accurate than those produced by the C<< TIME => 1 >> option (see below),
but also take significantly longer to measure.

=back


Other configuration options that can be specified as key/value pairs in
the hash are:

=over

=item C<< VERBOSE => $BOOLEAN >>

If the value is true, all side-effect tests are reported individually
(running them in a subtest).

When this option is false (or omitted) only the overall result, plus any
individual failures, are reported.


=item C<< ONLY => $BOOLEAN >>

If the value is true, only the effects explicitly requested by the other
keys of this hash are tested for. In other words, this option causes
C<effects_ok()> to omit the "default" tests for unnamed side-effects.

When this option is false (or omitted) unspecified options are tested
for their expected default behaviour.


=item C<< TIME => $BOOLEAN >>

If the value is true, the block is timed as it is executed.
The timing is reported in the final TAP line.

Note that this option is entirely independent of the C<'timing'> option
(which times the block repeatedly and then tests it against specified
limits).

In contrast, the C<'TIME'> option merely times the block once, while it
is being evaluated for the other tests. This is much less accurate, but
also much faster and much less intrusive, when you merely want an rough
indication of performance.


=item C<< WITHOUT => 'Module::Name' >>

=item C<< WITHOUT => qr/Module::.*/ >>

Execute the block as if the specified module (or all modules matching
the specified pattern) were not installed.


=item C<< WITHOUT => 'lib/path/' >>

=item C<< WITHOUT => qr{lib/*} >>

Execute the block as if the specified library directory (or all
directories matching the specified pattern) were not accessible.

The specified patch I<must> include at least one slash (C</>), otherwise
it will be interpreted as a module name (see above). You can always add
a redundant slash at the end of the path, if necessary:

    WITHOUT => 'lib',     # Test without the C<lib.pm> module

    WITHOUT => 'lib/',    # Test without the C<lib> directory

=back

=head2 C<< VERBOSE I<$HASH_REF> >>

A call to:

    effects_ok { BLOCK }
               VERBOSE { return => 0, stdout => 'ok' }

is just a shorthand for:

    effects_ok { BLOCK }
               { return => 0, stdout => 'ok', VERBOSE => 1 }


=head2 C<< ONLY I<$HASH_REF> >>

A call such as:

    effects_ok { BLOCK }
               ONLY { return => 0, stdout => 'ok' }

is just a shorthand for:

    effects_ok { BLOCK }
               { return => 0, stdout => 'ok', ONLY => 1 }


=head2 C<< TIME I<$HASH_REF> >>

A call such as:

    effects_ok { BLOCK }
               TIME { return => 0, stdout => 'ok' }

is just a shorthand for:

    effects_ok { BLOCK }
               { return => 0, stdout => 'ok', TIME => 1 }

Note that the C<VERBOSE>, C<ONLY>, and C<TIME> subs can be "stacked"
(in any combination and order):

    effects_ok { BLOCK }
               TIME ONLY VERBOSE { return => 0, stdout => 'ok' }

    effects_ok { BLOCK }
               VERBOSE ONLY { return => 0, stdout => 'ok' }


=head2 C<< use Test::Effects::VERBOSE; >>

This causes every subsequent call to C<effects_ok()>
in the current lexical scope to act as if it had a
S<< C<< VERBOSE => 1 >> >> option set.

Note, however, that an explicit S<< C<< VERBOSE => 0 >> >> in
any call in the scope overrides this default.

=head2 C<< no Test::Effects::VERBOSE; >>

This causes every subsequent call to C<effects_ok()>
in the current lexical scope to act as if it had a
S<< C<< VERBOSE => 0 >> >> option set. Again, however,
an explicit S<< C<< VERBOSE => 1 >> >> in
any call in the scope overrides this default.


=head2 C<< use Test::Effects::ONLY; >>

This causes every subsequent call to C<effects_ok()>
in the current lexical scope to act as if it had a
S<< C<< ONLY => 1 >> >> option set.

Note, however, that an explicit S<< C<< ONLY => 0 >> >> in
any call in the scope overrides this default.

=head2 C<< no Test::Effects::ONLY; >>

This causes every subsequent call to C<effects_ok()>
in the current lexical scope to act as if it had a
S<< C<< ONLY => 0 >> >> option set. Again, however,
an explicit S<< C<< ONLY => 1 >> >> in
any call in the scope overrides this default.


=head2 C<< use Test::Effects::TIME; >>

This causes every subsequent call to C<effects_ok()>
in the current lexical scope to act as if it had a
S<< C<< TIME => 1 >> >> option set.

Note, however, that an explicit S<< C<< TIME => 0 >> >> in
any call in the scope overrides this default.

=head2 C<< no Test::Effects::TIME; >>

This causes every subsequent call to C<effects_ok()>
in the current lexical scope to act as if it had I<no>
S<< C<< TIME => 0 >> >> option set. Again, however,
an explicit S<< C<< TIME => 1 >> >> in
any call in the scope overrides this default.


=head1 DIAGNOSTICS

=over

=item C<< Second argument to effects_ok() must be hash or hash reference, not %s >>

C<effects_ok()> expects a hash as its second argument, but you passed
something else. This can happen if you forget to put braces around a
single option, such as:

    effects_ok { test_code() }
               warn => qr/Missing arg/;

That needs to be:

    effects_ok { test_code() }
               { warn => qr/Missing arg };

Or you may have accidentally used an array instead of a hash:

    effects_ok { test_code() }
               [ warn => qr/Missing arg ];

That is not supported, as it is being reserved for a
future feature.

=item C<< "Invalid timing specification: timing => %s" >>

The C<'timing'> option expects a hash reference, array reference,
or a single number as its value. You specified some value that
was something else (and which C<effects_ok()> therefore didn't
understand).

=back


=head1 CONFIGURATION AND ENVIRONMENT

Test::Effects requires no configuration files or environment variables.


=head1 DEPENDENCIES

Requires Perl 5.14 (or better).

Requires the Test::Trap module, v0.2.1 (or better).


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

Ironically, the test suite for this module is as yet unsatisfactory.
(T.D.D. Barbie says: "Testing test modules is B<I<HARD!>>")

No other bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-effects@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
