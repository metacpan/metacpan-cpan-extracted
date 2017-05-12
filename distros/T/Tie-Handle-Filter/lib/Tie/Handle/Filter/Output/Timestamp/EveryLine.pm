package Tie::Handle::Filter::Output::Timestamp::EveryLine;

# ABSTRACT: prepend every line of filehandle output with a timestamp

use 5.008;
use strict;
use warnings;
use base 'Tie::Handle::Filter';
use English '-no_match_vars';
use POSIX 'strftime';
our $VERSION = '0.011';

#pod =head1 SYNOPSIS
#pod
#pod     use Tie::Handle::Filter::Output::Timestamp::EveryLine;
#pod     tie *STDOUT, 'Tie::Handle::Filter::Output::Timestamp::EveryLine', *STDOUT;
#pod
#pod     print "Everything I print will be prepended with a timestamp.\n";
#pod     print <<'END_OUTPUT';
#pod     Even multi-line output will have every line prepended.
#pod     Including this one.
#pod     END_OUTPUT
#pod
#pod =cut

#pod =head1 DESCRIPTION
#pod
#pod This class may be used with Perl's L<tie|perlfunc/tie> function to
#pod prepend all output with a timestamp, optionally formatted according to
#pod the L<POSIX C<strftime>|POSIX/strftime> function. Unlike
#pod L<Tie::Handle::Filter::Output::Timestamp|Tie::Handle::Filter::Output::Timestamp>,
#pod I<every> line gets a timestamp, rather than just the beginning of
#pod strings given to L<C<print>|perlfunc/print>,
#pod L<C<printf>|perlfunc/printf>, L<C<syswrite>|perlfunc/syswrite>, and
#pod L<C<say>|perlfunc/say> (in Perl > v5.10).
#pod
#pod =head1 BUGS AND LIMITATIONS
#pod
#pod Because the date and time format is specified using
#pod L<C<strftime>|POSIX/strftime>, portable code should restrict itself to
#pod formats using ANSI C89 specifiers.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<PerlIO::via::Logger>, which offers a L<PerlIO|perlapio>-based logging
#pod layer and may be slightly faster.
#pod
#pod =cut

my $NEWLINE = $PERL_VERSION lt 'v5.10'
    ? '(?>\x0D\x0A|\n)'    ## no critic (RequireInterpolationOfMetachars)
    : '\R';

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
    return $class->SUPER::TIEHANDLE( $handle_glob,
        _filter_closure( $format || '%x %X ' ) );
}

sub _filter_closure {
    my $format           = shift;
    my $string_beginning = 1;
    return sub {
        my $string = join q() => @_;
        $string
            =~ s/ ($NEWLINE) (?=.) / $1 . strftime($format, localtime) /egmsx;
        if ($string_beginning) {
            $string =~ s/ \A / strftime($format, localtime) /emsx;
        }
        $string_beginning = $string =~ / $NEWLINE \z/msx
            || $OUTPUT_RECORD_SEPARATOR eq "\n";
        return $string;
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Handle::Filter::Output::Timestamp::EveryLine - prepend every line of filehandle output with a timestamp

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    use Tie::Handle::Filter::Output::Timestamp::EveryLine;
    tie *STDOUT, 'Tie::Handle::Filter::Output::Timestamp::EveryLine', *STDOUT;

    print "Everything I print will be prepended with a timestamp.\n";
    print <<'END_OUTPUT';
    Even multi-line output will have every line prepended.
    Including this one.
    END_OUTPUT

=head1 DESCRIPTION

This class may be used with Perl's L<tie|perlfunc/tie> function to
prepend all output with a timestamp, optionally formatted according to
the L<POSIX C<strftime>|POSIX/strftime> function. Unlike
L<Tie::Handle::Filter::Output::Timestamp|Tie::Handle::Filter::Output::Timestamp>,
I<every> line gets a timestamp, rather than just the beginning of
strings given to L<C<print>|perlfunc/print>,
L<C<printf>|perlfunc/printf>, L<C<syswrite>|perlfunc/syswrite>, and
L<C<say>|perlfunc/say> (in Perl > v5.10).

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

L<PerlIO::via::Logger>, which offers a L<PerlIO|perlapio>-based logging
layer and may be slightly faster.

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
