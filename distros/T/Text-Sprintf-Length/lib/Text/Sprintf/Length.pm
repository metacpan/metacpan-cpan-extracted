package Text::Sprintf::Length;

our $DATE = '2018-03-17'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(sprintf_length);

# XXX BEGIN COPIED FROM Text::sprintfn

my  $re1   = qr/[^)]+/s;
my  $re2   = qr{(?<fmt>
                    %
                       (?<pi> \d+\$ | \((?<npi>$re1)\)\$?)?
                       (?<flags> [ +0#-]+)?
                       (?<vflag> \*?[v])?
                       (?<width> -?\d+ |
                           \*\d+\$? |
                           \((?<nwidth>$re1)\))?
                       (?<dot>\.?)
                       (?<prec>
                           (?: \d+ | \* |
                           \((?<nprec>$re1)\) ) ) ?
                       (?<conv> [%csduoxefgXEGbBpniDUOF])
                   )}x;
our $regex = qr{($re2|%|[^%]+)}s;

# faster version, without using named capture
if (1) {
    $regex = qr{( #all=1
                    ( #fmt=2
                        %
                        (#pi=3
                            \d+\$ | \(
                            (#npi=4
                                [^)]+)\)\$?)?
                        (#flags=5
                            [ +0#-]+)?
                        (#vflag=6
                            \*?[v])?
                        (#width=7
                            -?\d+ |
                            \*\d+\$? |
                            \((#nwidth=8
                                [^)]+)\))?
                        (#dot=9
                            \.?)
                        (#prec=10
                            (?: \d+ | \* |
                                \((#nprec=11
                                    [^)]+)\) ) ) ?
                        (#conv=12
                            [%csduoxefgXEGbBpniDUOF])
                    ) | % | [^%]+
                )}xs;
}

# XXX END COPIED FROM Text::sprintfn

sub sprintf_length {
    my $format = shift;

    my $sprintf_width = length($format);

    while ($format =~ /$regex/g) {
        my ($all, $fmt, $pi, $npi, $flags,
            $vflag, $width, $nwidth, $dot, $prec,
            $nprec, $conv) =
                ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12);

        if ($fmt && defined $sprintf_width) {

            if ($conv eq '%' || $conv eq 'c') {
                $width //= 1;
            } elsif ($conv eq 'p' || $conv eq 'c') {
                $width //= 1;
            } elsif ($conv eq 'n') {
                $width = 0;
            }

            if (defined $width) {
                $sprintf_width += $width - length($all);
            } else {
                $sprintf_width = undef;
            }

        }
    }

    $sprintf_width;
}

1;
# ABSTRACT: Calculate length of sprintf()-formatted string

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Sprintf::Length - Calculate length of sprintf()-formatted string

=head1 VERSION

This document describes version 0.001 of Text::Sprintf::Length (from Perl distribution Text-Sprintf-Length), released on 2018-03-17.

=head1 SYNOPSIS

 use Text::Sprintf::Length qw(sprintf_length);

 my $len;

 $len = sprintf_length("%s");        # => undef
 $len = sprintf_length("%8s") ;      # => 8
 $len = sprintf_length("%8s %% %c"); # => 12

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 sprintf_length

Usage:

 sprintf_length($fmt) => int|undef

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Sprintf-Length>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Sprintf-Length>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Sprintf-Length>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
