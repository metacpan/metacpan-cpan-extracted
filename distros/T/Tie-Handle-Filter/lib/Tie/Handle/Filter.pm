package Tie::Handle::Filter;

# ABSTRACT: [DEPRECATED] filters filehandle output through a coderef

#pod =head1 SYNOPSIS
#pod
#pod     use Tie::Handle::Filter;
#pod
#pod     # prefix output to STDERR with standard Greenwich time
#pod     BEGIN {
#pod         tie *STDERR, 'Tie::Handle::Filter', *STDERR,
#pod             sub { scalar(gmtime) . ': ', @_ };
#pod     }
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<DEPRECATION NOTICE:> This module distribution is deprecated in favor
#pod of L<Text::OutputFilter|Text::OutputFilter>, which is more robust while
#pod being functionally identical, or
#pod L<PerlIO::via::dynamic|PerlIO::via::dynamic>, which uses a different
#pod mechanism that may offer better performance.
#pod
#pod This is a small module for changing output when it is sent to a given
#pod file handle. By default it passes everything unchanged, but when
#pod provided a code reference, that reference is passed the string being
#pod sent to the tied file handle and may return a transformed result.
#pod
#pod =cut

use 5.008;
use strict;
use warnings;
use base 'Tie::Handle';
use Carp;
use English '-no_match_vars';
use FileHandle::Fmode ':all';
our $VERSION = '0.011';

#pod =head1 DIAGNOSTICS
#pod
#pod Wherever possible this module attempts to emulate the built-in functions
#pod it ties, so it will return values as expected from whatever function is
#pod called. Certain operations may also L<C<croak>|Carp> (throw a fatal
#pod exception) if they fail, such as aliasing the file handle during a
#pod L<C<tie>|perlfunc/tie> or attempting to perform an
#pod L<unsupported operation|/"BUGS AND LIMITATIONS"> on a tied file handle.
#pod
#pod =cut

sub TIEHANDLE {
    my ( $class, $handle_glob, $writer_ref ) = @_;

    ## no critic (InputOutput::RequireBriefOpen)
    open my $fh, _get_filehandle_open_mode($handle_glob) . q(&=), $handle_glob
        or croak $OS_ERROR;

    return bless {
        filehandle => $fh,
        writer     => (
            ( defined $writer_ref and 'CODE' eq ref $writer_ref )
            ? $writer_ref
            : sub { return @_ }
        ),
    }, $class;
}

sub _get_filehandle_open_mode {
    my $fh = shift;
    for ($fh) {
        return '>>'  if is_WO($_) and is_A($_);
        return '>'   if is_WO($_);
        return '<'   if is_RO($_);
        return '+>>' if is_RW($_) and is_A($_);
        return '+<'  if is_RW($_);
    }
    return '+>';
}

## no critic (Subroutines::RequireArgUnpacking)
## no critic (Subroutines::RequireFinalReturn)

#pod =method PRINT
#pod
#pod All arguments to L<C<print>|perlfunc/print> and L<C<say>|perlfunc/say>
#pod directed at the tied file handle are passed to the user-defined
#pod function, and the result is then passed to L<C<print>|perlfunc/print>.
#pod
#pod =cut

sub PRINT {
    my $self = shift;
    ## no critic (InputOutput::RequireCheckedSyscalls)
    print { $self->{filehandle} } $self->{writer}->(@_);
}

#pod =method PRINTF
#pod
#pod The second and subsequent arguments to L<C<printf>|perlfunc/printf>
#pod (i.e., everything but the format string) directed at the tied file
#pod handle are passed to the user-defined function, and the result is then
#pod passed preceded by the format string to L<C<printf>|perlfunc/printf>.
#pod
#pod Please note that this does not include calls to
#pod L<C<sprintf>|perlfunc/sprintf>.
#pod
#pod =cut

sub PRINTF {
    my ( $self, $format ) = splice @_, 0, 2;
    printf { $self->{filehandle} } $format, $self->{writer}->(@_);
}

#pod =method WRITE
#pod
#pod The first argument to L<C<syswrite>|perlfunc/syswrite> (i.e., the buffer
#pod scalar variable) directed at the tied file handle is passed to the
#pod user-defined function, and the result is then passed along with the
#pod optional second and third arguments (i.e., length of data in bytes and
#pod offset within the string) to L<C<syswrite>|perlfunc/syswrite>.
#pod
#pod Note that if you do not provide a length argument to
#pod L<C<syswrite>|perlfunc/syswrite>, it will be computed from the result of
#pod the user-defined function. However, if you do provide a length (and
#pod possibly offset), they will be relative to the results of the
#pod user-defined function, not the input.
#pod
#pod =cut

sub WRITE {
    my ( $self, $original ) = splice @_, 0, 2;
    my $buffer = ( $self->{writer}->($original) )[0];
    syswrite $self->{filehandle}, $buffer,
        ( defined $_[0] ? $_[0] : length $buffer ),
        ( defined $_[1] ? $_[1] : 0 );
}

sub CLOSE {
    my $self = shift;
    ## no critic (InputOutput::RequireCheckedSyscalls)
    ## no critic (InputOutput::RequireCheckedClose)
    close $self->{filehandle};
}

#pod =head1 BUGS AND LIMITATIONS
#pod
#pod If your function needs to know what operation was used to call it,
#pod consider using C<(caller 1)[3]> to determine the method used to call
#pod it, which will return C<Tie::Handle::Filter::PRINT>,
#pod C<Tie::Handle::Filter::PRINTF>, or C<Tie::Handle::Filter::WRITE> per
#pod L<perltie/"Tying FileHandles">.
#pod
#pod Currently this module is biased towards write-only file handles, such as
#pod C<STDOUT>, C<STDERR>, or ones used for logging. It does not (yet) define
#pod the following methods and their associated functions, so don't do them
#pod with file handles tied to this class.
#pod
#pod =head2 READ
#pod
#pod =over
#pod
#pod =item L<C<read>|perlfunc/read>
#pod
#pod =item L<C<sysread>|perlfunc/sysread>
#pod
#pod =back
#pod
#pod =head2 READLINE
#pod
#pod =over
#pod
#pod =item L<C<E<lt>HANDLEE<gt>>|perlop/"I/O Operators">
#pod
#pod =item L<C<readline>|perlfunc/readline>
#pod
#pod =back
#pod
#pod =head2 GETC
#pod
#pod =over
#pod
#pod =item L<C<getc>|perlfunc/getc>
#pod
#pod =back
#pod
#pod =head2 OPEN
#pod
#pod =over
#pod
#pod =item L<C<open>|perlfunc/open> (e.g., re-opening the file handle)
#pod
#pod =back
#pod
#pod =head2 BINMODE
#pod
#pod =over
#pod
#pod =item L<C<binmode>|perlfunc/binmode>
#pod
#pod =back
#pod
#pod =head2 EOF
#pod
#pod =over
#pod
#pod =item L<C<eof>|perlfunc/eof>
#pod
#pod =back
#pod
#pod =head2 TELL
#pod
#pod =over
#pod
#pod =item L<C<tell>|perlfunc/tell>
#pod
#pod =back
#pod
#pod =head2 SEEK
#pod
#pod =over
#pod
#pod =item L<C<seek>|perlfunc/seek>
#pod
#pod =back
#pod
#pod =cut

my $unimplemented_ref = sub {
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
    my $package = ( caller 0 )[0];
    my $method  = ( caller 1 )[3];
    $method =~ s/\A ${package} :: //xms;
    croak "$package doesn't define a $method method";
};

sub OPEN    { $unimplemented_ref->() }
sub BINMODE { $unimplemented_ref->() }
sub EOF     { $unimplemented_ref->() }
sub TELL    { $unimplemented_ref->() }
sub SEEK    { $unimplemented_ref->() }

#pod =head1 SEE ALSO
#pod
#pod =over
#pod
#pod =item L<Tie::Handle::Filter::Output::Timestamp|Tie::Handle::Filter::Output::Timestamp>
#pod
#pod Prepends filehandle output with a timestamp, optionally formatted via
#pod L<C<strftime>|POSIX/strftime>.
#pod
#pod =item L<Tie::Handle::Filter::Output::Timestamp::EveryLine|Tie::Handle::Filter::Output::Timestamp::EveryLine>
#pod
#pod Prepends every line of filehandle output with a timestamp, optionally
#pod formatted via L<C<strftime>|POSIX/strftime>.
#pod
#pod =back
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Handle::Filter - [DEPRECATED] filters filehandle output through a coderef

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    use Tie::Handle::Filter;

    # prefix output to STDERR with standard Greenwich time
    BEGIN {
        tie *STDERR, 'Tie::Handle::Filter', *STDERR,
            sub { scalar(gmtime) . ': ', @_ };
    }

=head1 DESCRIPTION

B<DEPRECATION NOTICE:> This module distribution is deprecated in favor
of L<Text::OutputFilter|Text::OutputFilter>, which is more robust while
being functionally identical, or
L<PerlIO::via::dynamic|PerlIO::via::dynamic>, which uses a different
mechanism that may offer better performance.

This is a small module for changing output when it is sent to a given
file handle. By default it passes everything unchanged, but when
provided a code reference, that reference is passed the string being
sent to the tied file handle and may return a transformed result.

=head1 METHODS

=head2 PRINT

All arguments to L<C<print>|perlfunc/print> and L<C<say>|perlfunc/say>
directed at the tied file handle are passed to the user-defined
function, and the result is then passed to L<C<print>|perlfunc/print>.

=head2 PRINTF

The second and subsequent arguments to L<C<printf>|perlfunc/printf>
(i.e., everything but the format string) directed at the tied file
handle are passed to the user-defined function, and the result is then
passed preceded by the format string to L<C<printf>|perlfunc/printf>.

Please note that this does not include calls to
L<C<sprintf>|perlfunc/sprintf>.

=head2 WRITE

The first argument to L<C<syswrite>|perlfunc/syswrite> (i.e., the buffer
scalar variable) directed at the tied file handle is passed to the
user-defined function, and the result is then passed along with the
optional second and third arguments (i.e., length of data in bytes and
offset within the string) to L<C<syswrite>|perlfunc/syswrite>.

Note that if you do not provide a length argument to
L<C<syswrite>|perlfunc/syswrite>, it will be computed from the result of
the user-defined function. However, if you do provide a length (and
possibly offset), they will be relative to the results of the
user-defined function, not the input.

=head1 EXTENDS

=over 4

=item * L<Tie::Handle>

=back

=head1 REQUIRES

=over 4

=item * L<FileHandle::Fmode|FileHandle::Fmode>

=back

=head1 DIAGNOSTICS

Wherever possible this module attempts to emulate the built-in functions
it ties, so it will return values as expected from whatever function is
called. Certain operations may also L<C<croak>|Carp> (throw a fatal
exception) if they fail, such as aliasing the file handle during a
L<C<tie>|perlfunc/tie> or attempting to perform an
L<unsupported operation|/"BUGS AND LIMITATIONS"> on a tied file handle.

=head1 BUGS AND LIMITATIONS

If your function needs to know what operation was used to call it,
consider using C<(caller 1)[3]> to determine the method used to call
it, which will return C<Tie::Handle::Filter::PRINT>,
C<Tie::Handle::Filter::PRINTF>, or C<Tie::Handle::Filter::WRITE> per
L<perltie/"Tying FileHandles">.

Currently this module is biased towards write-only file handles, such as
C<STDOUT>, C<STDERR>, or ones used for logging. It does not (yet) define
the following methods and their associated functions, so don't do them
with file handles tied to this class.

=head2 READ

=over

=item L<C<read>|perlfunc/read>

=item L<C<sysread>|perlfunc/sysread>

=back

=head2 READLINE

=over

=item L<C<E<lt>HANDLEE<gt>>|perlop/"I/O Operators">

=item L<C<readline>|perlfunc/readline>

=back

=head2 GETC

=over

=item L<C<getc>|perlfunc/getc>

=back

=head2 OPEN

=over

=item L<C<open>|perlfunc/open> (e.g., re-opening the file handle)

=back

=head2 BINMODE

=over

=item L<C<binmode>|perlfunc/binmode>

=back

=head2 EOF

=over

=item L<C<eof>|perlfunc/eof>

=back

=head2 TELL

=over

=item L<C<tell>|perlfunc/tell>

=back

=head2 SEEK

=over

=item L<C<seek>|perlfunc/seek>

=back

=head1 SEE ALSO

=over

=item L<Tie::Handle::Filter::Output::Timestamp|Tie::Handle::Filter::Output::Timestamp>

Prepends filehandle output with a timestamp, optionally formatted via
L<C<strftime>|POSIX/strftime>.

=item L<Tie::Handle::Filter::Output::Timestamp::EveryLine|Tie::Handle::Filter::Output::Timestamp::EveryLine>

Prepends every line of filehandle output with a timestamp, optionally
formatted via L<C<strftime>|POSIX/strftime>.

=back

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
