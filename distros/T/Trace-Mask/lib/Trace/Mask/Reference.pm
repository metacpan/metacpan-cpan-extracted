package Trace::Mask::Reference;
use strict;
use warnings;

use Carp qw/croak/;

use Scalar::Util qw/reftype looks_like_number refaddr blessed/;

use Trace::Mask::Util qw/mask_frame mask_line get_mask/;

use base 'Exporter';
our @EXPORT_OK = qw{
    trace
    trace_string
    trace_mask_caller
    try_example
};

sub try_example(&) {
    my $code = shift;
    local $@;
    my $ok = eval {
        # Hides the call, the eval, and the call to try_example
        # This also has the added benefit that if there was an exception inside
        # try_example itself, the trace would not hide anything. The hide only
        # effects traces from inside the anonymous sub.
        BEGIN { mask_line({hide => 3}, 1) }
        $code->();
        1;
    };
    return if $ok;
    return $@ || "error was smashed!";
}

sub _call_details {
    my ($level) = @_;
    $level += 1;

    my (@call, @args);
    {
        package DB;
        @call = caller($level);
        @args = @DB::args;
    }

    return unless @call && defined $call[0];
    return (\@call, \@args);
}

sub _do_shift {
    my ($shift, $frame) = @_;

    # Args are a direct move
    $frame->[1] = $shift->[1];

    # Merge the masks numeric keys, shift wins
    for my $key (keys %{$shift->[2]}) {
        next unless $key =~ m/^\d+$/;
        $frame->[2]->{$key} = $shift->[2]->{$key};
    }

    # Copy all caller values from shift except 0-2
    for(my $i = 3; $i < @{$shift->[0]}; $i++) {
        $frame->[0]->[$i] = $shift->[0]->[$i];
    }
}

sub trace {
    my @stack;

    # Always have to start at 0 since frames can hide frames that come after them.
    my $level = 0;

    # Shortcut
    if ($ENV{NO_TRACE_MASK}) {
        while (my ($call, $args) = _call_details($level++)) {
            push @stack => [$call, $args];
        }
        return \@stack;
    }

    my ($shift, $last);
    my $skip = 0;
    my $stopped = 0;
    my $paused  = 0;
    while (my ($call, $args) = _call_details($level++)) {
        my $mask = get_mask(@{$call}[1,2,3]);
        my $frame = [$call, $args, $mask];

        my $lock = $mask->{lock};

        next if $paused && !($mask->{restart} || $lock);
        $paused = 0 if $mask->{restart};

        next if $stopped && !$lock;

        $last = $frame unless $mask->{hide} || $mask->{shift} || $lock;

        unless($lock) {
            # Need to do this even if the frame is not pushed now, it may be pushed
            # later depending on shift.
            for my $idx (keys %$mask) {
                next unless $idx =~ m/^\d+$/;
                next if $idx >= @$call;    # Do not create new call indexes
                $call->[$idx] = $mask->{$idx};
            }
        }

        if ($mask->{shift}) {
            $shift ||= $frame;
            $skip  = ($skip || $lock) ? $skip + $mask->{shift} - 1 : $mask->{shift};
        }
        elsif ($mask->{hide}) {
            $skip  = ($skip || $lock) ? $skip + $mask->{hide} - 1 : $mask->{hide};
        }
        elsif($skip && !(--$skip) && $shift) {
            _do_shift($shift, $frame) unless $lock;
            $shift = undef;
        }

        my $push = !($skip || ($mask->{no_start} && !@stack));

        push @stack => $frame if $push || $lock;

        $stopped = 1 if $mask->{stop};
        $paused  = 1 if $mask->{pause};
    }

    if ($shift) {
        _do_shift($shift, $last) unless $last->[2]->{lock};
        push @stack => $last unless @stack && $stack[-1] == $last;
    }

    return \@stack;
}

sub trace_mask_caller {
    my ($level) = @_;
    $level = 0 unless defined($level);

    my $trace = trace();
    return unless $trace && @$trace;

    my $frame = $trace->[$level + 2];
    return unless $frame;

    return @{$frame->[0]}[0, 1, 2] unless @_;
    return @{$frame->[0]};
}

sub trace_string {
    my ($level) = @_;
    $level = 0 unless defined($level);

    BEGIN { mask_line({hide => 1}, 1) };
    my $trace = trace();

    shift @$trace while @$trace && $level--;
    my $string = "";
    for my $frame (@$trace) {
        my ($call, $args) = @$frame;
        my $args_str = join ", " => map { render_arg($_) } @$args;
        $args_str ||= '';
        if ($call->[3] eq '(eval)') {
            $string .= "eval { ... } called at $call->[1] line $call->[2]\n";
        }
        else {
            $string .= "$call->[3]($args_str) called at $call->[1] line $call->[2]\n";
        }
    }

    return $string;
}

sub render_arg {
    my $arg = shift;
    return 'undef' unless defined($arg);

    if (ref($arg)) {
        my $type = reftype($arg);

        # Look past overloading
        my $class = blessed($arg) || '';
        my $it = sprintf('0x%x', refaddr($arg));
        my $ref = "$type($it)";

        return $ref unless $class;
        return "$class=$ref";
    }

    return $arg if looks_like_number($arg);
    $arg =~ s/'/\\'/g;
    return "'$arg'";
}

1;

__END__

=pod

=head1 NAME

Trace::Mask::Reference - Reference implemtnations of tools and tracers

=head1 DESCRIPTION

This module provides a reference implementation of an L<Stack::Mask> compliant
stack tracer. It also provides reference examples of tools that benefit from
masking stack traces. These tools should B<NOT> be used in production code, but
may be useful in unit tests that verify compliance.

=head1 SYNOPSIS

    use Trace::Mask::Reference qw/try_example trace_string/;

    sub foo {
        print trace_string;
    }

    sub bar {
        my $error = try_example { foo() };
        ...
    }

    sub baz {
        bar();
    }

    baz();

This produces the following stack trace:

    main::foo() called at test.pl line 8
    main::bar() called at test.pl line 13
    main::baz() called at test.pl line 16

Notice that the call to try, the eval it uses inside, and the call to the
anonymous codeblock are all hidden. This effectively removes noise from the
stack trace. It makes 'try' look just like an 'if' or 'while' block. There is a
downside however if anything inside the C<try> implementation itself is broken.

=head2 EXPORTS

B<Note:> All exports are optional, you must request them if you want them.

=over 4

=item $frames_ref = trace()

This produces an array reference containing stack frames of a trace. Each frame
is an arrayref that matches the return from C<caller()>, with the additon that
the last index contains the arguments used in the call. Never rely on the index
number of the arguments, always pop them off if you need them, different
versions of perl may have a different number of values in a stack frame.

Index 0 of the C<$frames_ref> will be the topmost call of the trace, the rest
will be in descending order.

See C<trace_string()> for a tool to provide a carp-like stack trace.

C<$level> may be specified to start the stack at a deeper level.

=item $trace = trace_string()

=item $trace = trace_string($level)

This provides a stack trace string similar to C<longmess()> from L<Carp>.
Though it does not indent the trace, and it does not take the form of an error
report.

C<$level> may be specified to start the stack at a deeper level.

=item ($pkg, $file, $line) = trace_mask_caller()

=item ($pkg, $file, $line, $name, ...) = trace_mask_caller($level)

This is a C<caller()> emulator that honors the stack tracing specifications.
Please do not override C<caller()> with this. This implementation take a FULL
stack trace on each call, and returns just the desired frame from that trace.

=item $error = try_example { ... }

A reference implementation of C<try { ... }> that demonstrates the trace
masking behavior. Please do not use this in production code, it is a very dumb,
and not-very-useful implementation of C<try> that serves as a demo.

=back

=head1 SEE ALSO

L<Sub::Uplevel> - Tool for hiding stack frames from all callers, not just stack
traces.

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
