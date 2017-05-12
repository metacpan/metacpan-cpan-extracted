package Trace::Mask::Carp;
use strict;
use warnings;

use Carp 1.03 ();
$Carp::Internal{'Trace::Mask'} = 1;
$Carp::Internal{'Trace::Mask::Carp'} = 1;
$Carp::Internal{'Trace::Mask::Util'} = 1;
$Carp::Internal{'Trace::Mask::Reference'} = 1;
use Trace::Mask::Util qw/get_mask mask_line/;

BEGIN {
    *carp_longmess = Carp->can('longmess') or die "Could not find Carp::longmess";
}

sub longmess {      mask_trace(scalar(carp_longmess(@_)), 'Trace::Mask::Carp::longmess') }
sub confess  { die  mask_trace(scalar(carp_longmess(@_)), 'Trace::Mask::Carp::confess') }
sub cluck    { warn mask_trace(scalar(carp_longmess(@_)), 'Trace::Mask::Carp::cluck') }

sub _my_croak {
    my $msg = shift;
    my @caller = caller(1);
    die "$msg at $caller[1] line $caller[2].\n";
}

sub import {
    my $class = shift;

    my $caller = caller;

    my %flags;

    for my $arg (@_) {
        if ($arg =~ m/^-(.+)$/) {
            $flags{$1} = 1;
        }
        elsif ($arg =~ m/^_/) {
            _my_croak "'$arg' is not exported by $class"
        }
        else {
            my $sub = $class->can($arg) || _my_croak "'$arg' is not exported by $class";
            no strict 'refs';
            *{"$caller\::$arg"} = $sub;
        }
    }

    $class->_global_override if delete $flags{'global'};
    $class->_wrap_carp       if delete $flags{'wrap'};

    my @bad = sort keys %flags;
    return unless @bad;
    _my_croak "bad flag(s): " . join (", ", map { "-$_" } @bad);
}

sub _global_override {
    my $die  = $SIG{__DIE__}  || sub { CORE::die(@_) };
    my $warn = $SIG{__WARN__} || sub { CORE::warn(@_) };

    $SIG{__DIE__} = sub {
        my $error = shift;
        my @caller = caller(1);
        $error = mask_trace($error, $caller[3]) if $caller[3] =~ m/^Carp::(confess|longmess|cluck)$/;
        return $die->($error)
    };

    $SIG{__WARN__} = sub {
        my $msg = shift;
        my @caller = caller(1);
        $msg = mask_trace($msg, $caller[3]) if $caller[3] =~ m/^Carp::(confess|longmess|cluck)$/;
        $warn->($msg);
    };
}

sub _wrap_carp {
    no warnings 'redefine';
    *Carp::confess  = \&confess;
    *Carp::longmess = \&longmess;
    *Carp::cluck    = \&cluck;
}

sub mask(&) {
    my ($code) = @_;
    my $sigwarn = $SIG{__WARN__};
    my $sigdie  = $SIG{__DIE__};

    local $SIG{__WARN__};
    local $SIG{__DIE__};

    $SIG{__WARN__} = $sigwarn if $sigwarn;
    $SIG{__DIE__}  = $sigdie  if $sigdie;

    _global_override();

    BEGIN { mask_line({hide => 2}, 1) }
    $code->();
}

sub parse_carp_line {
    my ($line) = @_;
    my %out = (orig => $line);

    if ($line =~ m/^(\s*)([^\(]+)\((.*)\) called at (.+) line (\d+)\.?$/) { # Long
        @out{qw/indent sub args file line/} = ($1, $2, $3, $4, $5);
    }
    elsif ($line =~ m/^(\s*)eval \Q{...}\E called at (.+) line (\d+)\.?$/) { # eval
        @out{qw/sub indent file line/} = ('eval', $1, $2, $3);
    }
    elsif ($line =~ m/^(\s*)(.*) at (.+) line (\d+)\.?$/) { # Short
        @out{qw/indent msg file line/} = ($1, $2, $3, $4);
    }

    return \%out if keys(%out) > 1;
    return undef;
}

sub _write_carp_line{
    my ($fields) = @_;
    my ($indent, $file, $line, $sub, $msg, $args) = @{$fields}{qw/indent file line sub msg args/};
    $indent ||= "";

    if ($msg || !$sub) {
        $msg ||= "";
        return "$indent$msg at $file line $line.\n";
    }

    if ($sub eq 'eval') {
        return "$indent$sub {...} called at $file line $line\n";
    }
    else {
        $args ||= "";
        return "$indent$sub\($args) called at $file line $line\n";
    }
}

sub mask_trace {
    my ($msg, $sub) = @_;
    return $msg if $ENV{NO_TRACE_MASK};
    my @lines = split /[\n\r]+/, $msg;
    return $msg unless @lines > 1;

    my $out = "";
    my ($shift, $last);
    my $skip = 0;

    my $num = 0;
    my $error;
    my $stopped = 0;
    my $paused  = 0;
    for my $line (@lines) {
        my $fields = parse_carp_line($line);

        unless($fields) {
            $out .= "$line\n";
            next;
        }

        $fields->{sub} ||= $sub unless $num;
        $error = $fields if exists $fields->{msg};
        $num++;

        my $mask = get_mask(@{$fields}{qw/file line/}, $fields->{sub} || '*');

        next if $paused && !($mask->{restart} || $mask->{lock});
        $paused = 0 if $mask->{restart};

        next if $stopped && !$mask->{lock};

        $last = $fields unless $mask->{hide} || $mask->{shift} || $mask->{lock};

        unless ($mask->{lock}) {
            $fields->{file} = $mask->{1} if $mask->{1};
            $fields->{line} = $mask->{2} if $mask->{2};
            $fields->{sub}  = $mask->{3} if $mask->{3};
        }

        if ($mask->{shift}) {
            $shift ||= $fields;
            $skip  = ($skip || $mask->{lock}) ? $skip + $mask->{shift} - 1 : $mask->{shift};
        }
        elsif ($mask->{hide}) {
            $skip  = ($skip || $mask->{lock}) ? $skip + $mask->{hide} - 1 : $mask->{hide};
        }
        elsif($skip && !(--$skip) && $shift) {
            unless ($mask->{lock}) {
                $fields->{msg}    = $shift->{msg};
                $fields->{indent} = $shift->{indent};
                $fields->{sub}    = $shift->{sub};
                $fields->{args}   = $shift->{args};
            }
            $shift = undef;
        }

        unless ($skip || ($mask->{no_start} && !$out)) {
            if ($error) {
                $fields->{msg} = $error->{msg};
                $fields->{indent} = $error->{indent};
                delete $fields->{sub};
                $error = undef;
            }
            $out .= _write_carp_line($fields)
        }

        $stopped = 1 if $mask->{stop};
        $paused  = 1 if $mask->{pause};
    }

    if ($shift) {
        $last->{msg}    = $shift->{msg};
        $last->{indent} = $shift->{indent};
        $last->{sub}    = $shift->{sub};
        $last->{args}   = $shift->{args};
        $out .= _write_carp_line($last) unless $out && $out =~ m/at \Q$last->{file}\E line $last->{line}/;
    }

    return $out;
}

1;

__END__

=pod

=head1 NAME

Trace::Mask::Carp - Trace::Mask tools for masking Carp traces

=head1 DESCRIPTION

This module can be used to apply L<Trace::Mask> behavior to traces from the
L<Carp> module.

=head1 SYNOPSIS

=head2 LEXICAL

You can import C<confess()>, C<cluck()>, and C<longmess()> from this module,
this will mask traces produced from these functions in your module, but will
not effect any other modules traces. This is the safest way to use this module.

    use Trace::Mask::Carp qw/confess cluck longmess mask/;

    ...

    confess "XXX"; # throws an exception with a masked trace

    # Any traces produced inside the block below, regardless of what module
    # calls confess/cluck/longmess, will be masked.
    mask {
        ...
    };

=head2 HANDLERS

B<THIS HAS GLOBAL CONSEQUENCES!!!>

This will put handlers into C<$SIG{__WARN__}> and C<$SIG{__DIE__}> that will
mask Carp traces no matter where they are generated.

    use Trace::Mask::Carp '-global'

B<Note:> This is useful in a test, script, app, psgi file, etc, but should
NEVER be used by a cpan module or library.

=head2 OVERRIDE

B<THIS HAS GLOBAL CONSEQUENCES!!!>

This will redefine C<confess()>, C<cluck()>, and C<longmess()> in L<Carp>
itself. This will make it so that any modules that import these functions from
Carp will get the masked versions. This will not effect already loaded modules!

    use Trace::Mask::Carp '-wrap'

B<Note:> This is useful in a test, script, app, psgi file, etc, but should
NEVER be used by a cpan module or library.

=head1 IMPORT OPTIONS

=head2 FLAGS

=over 4

=item -global

Add global handlers to C<$SIG{__WARN__}> and C<$SIG{__DIE__}> that mask traces
coming from carp.

=item -wrap

Modify C<longmess()>, C<confess()>, and C<cluck()> in L<Carp> itself so that
any modules that load carp will get the mask versions. This will nto effect any
modules that have already loaded carp.

=back

=head2 EXPORTS

B<Note:> All exports are optional, you must request them if you want them.

=over 4

=item $trace_string = longmess($message)

=item confess($error)

=item cluck($warning)

These are basically wrappers around the L<Carp> functions of the same name.
These will get the trace from Carp, then mask it.

=item mask { ... }

This will set C<$SIG{__WARN__}> and C<$SIG{__DIE__}> for the code in the block.
This means that traces generated inside the mask block will be masked, but
traces outside the block will not be effected.

=item $hr = parse_carp_line($line)

Returns a hashref with information that can be gathered from the line of carp
output. This typically includes the file and line number. It may also include
an error message or a subroutine name, and any arguments that were passed into
the sub when it was called.

=item $masked_trace = mask_trace($trace)

=item $masked_trace = mask_trace($trace, $subname)

C<$subname> should be 'confess', 'longmess', or 'cluck' typically, but is also
optional.

This takes a trace from Carp (string form) and returns the masked form.

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
