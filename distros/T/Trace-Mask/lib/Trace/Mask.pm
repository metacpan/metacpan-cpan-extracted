package Trace::Mask;
use strict;
use warnings;

our $VERSION = "0.000008";

sub masks() { no warnings 'once'; \%Trace::Mask::MASKS }

1;

__END__

=pod

=head1 NAME

Trace::Mask - Standard for masking frames in stack traces.

=head1 DESCRIPTION

This is a specification packages can follow to define behaviors stack tracers
may choose to honor. If a module implements this specification than any
compliant stack tracer will render the stack trace as desired. Implementing the
spec will have no effect on non-complient stack tracers. This specification
does not effect C<caller()> in any way.

=head1 PRACTICAL APPLICATIONS

Masking stack traces is not something you want to do every day, but there are
situations where it can be helpful, if not essential.

=over 4

=item Emulate existing language structures

    sub foo {
        if ($cond) { trace() }
    }

In the example above a stack trace is produced, the call to C<foo()> will show
up, but the C<if> block will not. This is useful as the conditional is part of
the sub, and should not be listed.

Emulating this behavior would be a useful feature for exception tools that
provide try/catch/finally or similar control structures.

    try   { ... }
    catch { ... };

In perl the above would be emulated with 2 subs that take codeblocks in their
prototype. In a stack trace you see a call to try, and a call to an anonymous
block. In a stack trace this is distracting at best. Further it is hard to
distinguish which anonymous block you are in, though tools like L<Sub::Name>
mitigate this some.

=item Testing Tools

Tools like L<Test::Exception> use L<Sub::Uplevel> to achieve a similar effect.
This is done by globally overriding C<caller()>, which can have some
unfortunate side effects. Using Trace::Mask instead would avoid the nasty side
effects, would be much faster than overriding C<caller()>, and give more
control over what makes it into the trace.

=item One interface to many tools

Currently L<Carp> provides several configuration variables such as C<@CARP_NOT>
to give you control over where a trace starts. Other modules that provide stack
traces all provide their own variables. If you want to control stack traces you
need to account for all the possible tracing tools that could be used. Many
tracing tools do not provide enough control, including C<Carp> itself.

=back

=head1 SPECIFICATION

No module (including this one) is required when implementing the spec. Though
it is a good idea to list the version of the spec you have implemented in the
runtime recommendations for your module. There are no undesired side effects as
the specification is completely opt-in, both for modules that want to effect
stack traces, and for the stack tracers themselves.

=head2 %Trace::Mask::MASKS

Packages that wish to mask stack frames may do so by altering the
C<%Trace::Mask::MASKS> package variable. Packages may change this variable at
any time, so consumers should not cache the contents, however they may cache
the reference to the hash itself.

This is an overview of the MASKS structure:

    %Trace::Mask::MASKS = (
        FILE => {
            LINE => {
                SUBNAME => {
                    # Behaviors
                    no_start => BOOL,     # Do not start a trace on this frame
                    stop     => BOOL,     # Stop tracing at this frame
                    pause    => BOOL,     # Stop tracing at this frame until you see a restart
                    restart  => BOOL,     # Start tracing again at this frame
                    hide     => COUNT,    # Hide the frames completely
                    shift    => COUNT,    # Pretend this frame started X frames before it did
                    lock     => BOOL,     # Prevent the frame from being hidden or modified

                    # Replacements
                    0 => PACKAGE,         # Replace the package listed in the frame
                    1 => FILE,            # Replace the filename listed in the frame
                    2 => LINE,            # Replace the linenum listed in the frame
                    3 => NAME,            # Replace the subname listen in the frame
                    ...,                  # Replace any index listed in the frame
                }
            }
        }
    );

No package should ever reset/erase the C<%Trace::Mask::MASKS> variable. They
should only ever remove entries they added, even that is not recommended.

You CAN add entries for files+lines that are not under your control. This is an
important allowance as it allows a function to hide the call to itself.

A stack frame is defined based on the return from C<caller()> which returns the
C<($package, $file, $line, $subname)> data of a call in the stack. To
manipulate a call you define the C<< $MASKS{$file}->{$line}->{$subname} >> path
in the hash that matches the call itself.

'FILE', 'LINE', and 'SUBNAME' can all be replaced with the wildcard C<'*'>
string to apply to all:

    # Effect all calls to Foo::foo in any file
    ('*' => { '*' => { Foo::foo => { ... }}})

    # Effect all sub calls in Foo.pm
    ('Foo.pm' => { '*' => { '*' => { ... }}});

You cannot use 3 wildcards to effect all subs. The 3 wildcard entry will be
ignored by a compliant tracer.

    # This is not allowed, the entry will be ignored
    ('*' => { '*' => { '*' => { ... }}});

=head2 CALL MASK HASHES

Numeric keys in the behavior structures are replacement values. If you want to
replace the package listed in the frame then you specify a value for field '0'.
If you want to replace the filename you would put a value for field '1'.
Numeric fields always correspond to the same index in the list returned from
C<caller()>.

   {
       # Behaviors
       no_start => BOOL,     # Do not start a trace on this frame
       stop     => BOOL,     # Stop tracing at this frame
       pause    => BOOL,     # Stop tracing at this frame until you see a restart
       restart  => BOOL,     # Start tracing again at this frame
       hide     => COUNT,    # Hide the frames completely
       shift    => COUNT,    # Pretend this frame started X frames before it did
       lock     => BOOL,     # Prevent the frame from being hidden or modified

       # Replacements
       0 => PACKAGE,         # Replace the package listed in the frame
       1 => FILE,            # Replace the filename listed in the frame
       2 => LINE,            # Replace the linenum listed in the frame
       3 => NAME,            # Replace the subname listen in the frame
       ...,                  # Replace any index listed in the frame
   }

The following additional behaviors may be specified:

=over 4

=item no_start => $BOOL

This prevents a stack trace from starting at the given call. This is similar to
L<Carp>'s C<@CARP_NOT> variable. These frames will still appear in the stack
trace if they are not the start.

=item stop => $BOOL

This tells the stack tracer to stop tracing at this frame. The frame itself
will be listed in the trace, unless this is combined with the 'hide' option.

Usually you want pause.

=item pause => $BOOL

Same as stop, except that things can restart it.

=item restart => $BOOL

This tells the stack tracer to start again after a pause, effectively skipping
all the frames between the pause and this restart. This may be combined with
'pause' in order to show a single frame.

=item hide => $COUNT

This completely hides the frame from a stack trace. This does not modify the
values of any surrounding frames, the frame is simply dropped from the trace.
If C<$COUNT> is greater than 1, then additional frames below the hidden one
will also be dropped.

This has the same effect on a stack trace as L<Sub::Uplevel>.

=item shift => $COUNT

This is like hide with one important difference, all components of the shifted
call, except for package, file, and line, will replace the values of the next
frame to be kept in the trace. If C<$COUNT> is large than 1, the shift will
hide frames between the shifted frame and the new frame. If C<$COUNT> is larger
than the remaining stack, the lowest unhidden/unshifted stack frame will be the
recipient of the shift operation, even if the shift frame itself is the lowest.

This has the same effect on a stack trace as C<goto &sub>.

=item lock => $BOOL

Locking a frame means that it must be displayed, and cannot be modified. If it
is lower than a stop, or in the middle of a hide/shift span it must be shown
anyway. No replacements will have any effect, and it cannot be modified by a
shift.

=back

=head2 MASK RESOLUTION

Multiple masks in the C<%Trace::Mask::MASKS> structure may apply to any given
stack frame, a compliant tracer will account for all of them. A simple hash
merge is sufficient so long as they are merged in the correct order. Here is an
example:

    my $masks_ref = \%Trace::Mask::MASKS;

    my @all = grep { defined $_ } (
        $masks_ref->{$file}->{'*'}->{'*'},
        $masks_ref->{$file}->{$line}->{'*'},
        $masks_ref->{'*'}->{'*'}->{$name},
        $masks_ref->{$file}->{'*'}->{$name},
        $masks_ref->{$file}->{$line}->{$name},
    );

    my %final = map { %{$_} } @all;

The most specific path should win out (override others). Rightmost path
component is considered the most important. More wildcards means less specific.
Paths may never have wildcards for all 3 components.

=head2 $ENV{'NO_TRACE_MASK'}

If this environment variable is set to true then all masking rules should be
ignored, tracers should produce full and complete stack traces.

=head2 TRACES STARTING AT $LEVEL

If a tracing tool starts at the call to the tool (such as C<Carp::confess()>)
then it should account for all the masks starting with the call to confess
itself going all the way until the bottom of the stack, or until a mask with
'stop' is found. If a tracing tool allows you to start tracing from a specific
level, the tracer should still account for the masks of the frames at the top
of the stack on which it is not reporting.

=head2 MASK NUMERIC KEYS

Numeric keys in a mask represent items in the list returned from C<caller()>.
If you provide numeric keys their values will replace the corresponding value
in the caller list before it is used in the trace. You can use this to replace
the package, file, etc. This will work for any VALID index into the list. This
cannot be used to extend the list. Numeric keys outside the bounds of the list
are simply ignored, this is for compatability as different perl versions may
have a different size list.

=head2 SPECIAL/MAGIC subs

Traces must NEVER hide or alter the following special/magic subs, they should
be considered the same as any C<lock> frame.

=over 4

=item BEGIN

=item UNITCHECK

=item CHECK

=item INIT

=item END

=item DESTROY

=item import

=item unimport

=back

These subs are all special in one way or another, hiding them would be hiding
critical information.

=head1 CLASS METHODS

The C<masks()> method is defined in L<Trace::Mask>, it returns a reference to
the C<%Trace::Mask::MASKS> hash for easy access. It is fine to cache this
reference, but not the data it contains.

=head1 REFERENCE

L<Trace::Mask::Reference> is included in this distribution. The Reference
module contains example tracers, and example tools that benefit from masking
stack traces. The examples in this module should NOT be used in production
code.

=head1 UTILS

L<Trace::Mask::Util> is included in this distribution. The util module provides
utilities for adding stack trace masking behavior. The utilities provided by
this module are considered usable in production code.

=head1 TEST

L<Trace::Mask::Test> is included in this distribution. This module provides
test cases and tools useful for verifying your tracing tools are compliant with
the spec.

=head1 PLUGINS

=head2 Carp

L<Trace::Mask::Carp> is included in this distribution. This module can make
L<Carp> compliant with L<Trace::Mask>.

=head2 Try::Tiny

L<Trace::Mask::TryTiny> is included in this ditribution. Simply loading theis
module will cause L<Try::Tiny> framework to be hidden in compliant stack
traces.

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
