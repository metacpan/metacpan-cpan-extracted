package Tie::Handle::Filter::Output::Timestamp;

# ABSTRACT: prepend filehandle output with a timestamp

use 5.008;
use strict;
use warnings;
use base 'Tie::Handle::Filter';
use POSIX 'strftime';
our $VERSION = '0.011';

#pod =head1 SYNOPSIS
#pod
#pod     use Tie::Handle::Filter::Output::Timestamp;
#pod     tie *STDOUT, 'Tie::Handle::Filter::Output::Timestamp', *STDOUT;
#pod
#pod     print "Everything I print will be prepended with a timestamp.\n";
#pod     print <<'END_OUTPUT';
#pod     The first line of a multi-line string will be prepended.
#pod     Subsequent lines will not.
#pod     END_OUTPUT
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class may be used with Perl's L<tie|perlfunc/tie> function to
#pod prepend all output with a timestamp, optionally formatted according to
#pod the L<POSIX C<strftime>|POSIX/strftime> function. Only the beginning of
#pod strings given to L<C<print>|perlfunc/print>,
#pod L<C<printf>|perlfunc/printf>, L<C<syswrite>|perlfunc/syswrite>, and
#pod L<C<say>|perlfunc/say> (in Perl > v5.10) get timestamps.
#pod
#pod =head1 BUGS AND LIMITATIONS
#pod
#pod Because the date and time format is specified using
#pod L<C<strftime>|POSIX/strftime>, portable code should restrict itself to
#pod formats using ANSI C89 specifiers.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Tie::Handle::Filter::Output::Timestamp::EveryLine|Tie::Handle::Filter::Output::Timestamp::EveryLine>,
#pod which prefixes every line.
#pod
#pod =method TIEHANDLE
#pod
#pod Invoked by the command
#pod C<tie *glob, 'Tie::Handle::Filter::Output::Timestamp', *glob>.
#pod You may also specify a L<C<strftime>|POSIX/strftime> string as an
#pod additional parameter to format the timestamp; by default the format is
#pod C<%x %X >, which is the local representation of the date and time
#pod followed by a space.
#pod
#pod =cut

sub TIEHANDLE {
    my ( $class, $handle_glob, $format ) = @_;
    $format ||= '%x %X ';
    return $class->SUPER::TIEHANDLE( $handle_glob,
        sub { ( strftime( $format, localtime ), @_ ) } );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Handle::Filter::Output::Timestamp - prepend filehandle output with a timestamp

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    use Tie::Handle::Filter::Output::Timestamp;
    tie *STDOUT, 'Tie::Handle::Filter::Output::Timestamp', *STDOUT;

    print "Everything I print will be prepended with a timestamp.\n";
    print <<'END_OUTPUT';
    The first line of a multi-line string will be prepended.
    Subsequent lines will not.
    END_OUTPUT

=head1 DESCRIPTION

This class may be used with Perl's L<tie|perlfunc/tie> function to
prepend all output with a timestamp, optionally formatted according to
the L<POSIX C<strftime>|POSIX/strftime> function. Only the beginning of
strings given to L<C<print>|perlfunc/print>,
L<C<printf>|perlfunc/printf>, L<C<syswrite>|perlfunc/syswrite>, and
L<C<say>|perlfunc/say> (in Perl > v5.10) get timestamps.

=head1 METHODS

=head2 TIEHANDLE

Invoked by the command
C<tie *glob, 'Tie::Handle::Filter::Output::Timestamp', *glob>.
You may also specify a L<C<strftime>|POSIX/strftime> string as an
additional parameter to format the timestamp; by default the format is
C<%x %X >, which is the local representation of the date and time
followed by a space.

=head1 EXTENDS

=over 4

=item * L<Tie::Handle::Filter>

=back

=head1 REQUIRES

=over 4

=item * L<POSIX|POSIX>

=back

=head1 BUGS AND LIMITATIONS

Because the date and time format is specified using
L<C<strftime>|POSIX/strftime>, portable code should restrict itself to
formats using ANSI C89 specifiers.

=head1 SEE ALSO

L<Tie::Handle::Filter::Output::Timestamp::EveryLine|Tie::Handle::Filter::Output::Timestamp::EveryLine>,
which prefixes every line.

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
