package Text::Sparkline;

use 5.10.1;
use strict;
use warnings;
use Scalar::Util;

=encoding utf8

=head1 NAME

Text::Sparkline - Creates text-based sparklines

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = 'v0.1.0';

=head1 SYNOPSIS

Creates sparklines, mini graphs for use in text programs.

    my @temperatures = ( 75, 78, 80, 74, 79, 77, 80 );
    print Text::Sparkline::sparkline( \@temperatures );

    ▂▅█▁▆▄█

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES

=head2 sparkline( \@values )

=cut

my @BARS= qw( ▁ ▂ ▃ ▄ ▅ ▆ ▇ █ );

sub sparkline {
    my $raw_values = shift;

    my ($values, $min, $max) = _stats($raw_values);

    my @bars;
    my $nbars = scalar(@BARS);
    for my $val ( @{$values} ) {
        if ( defined($val) ) {
            my $height = int($val * $nbars / $max);
            if ( $height == $nbars ) {
                --$height;
            }
            push @bars, $BARS[$height];
        }
        else {
            push @bars, ' ';
        }
    }

    return join( '', @bars );
}


sub sparkline_truncated {
    my $raw_values = shift;

    my ($values, $min, $max) = _stats($raw_values);

    my @bars;
    my $nbars = scalar(@BARS);
    my $span = $max - $min;
    for my $val ( @{$values} ) {
        if ( defined($val) ) {
            if ( $span ) {
                my $height = int(($val-$min) * $nbars / $span);
                if ( $height == $nbars ) {
                    --$height;
                }
                push @bars, $BARS[$height];
            }
            else {
                push @bars, $BARS[$nbars-1];
            }
        }
        else {
            push @bars, ' ';
        }
    }

    return join( '', @bars );
}


sub _stats {
    my $raw_values = shift;

    my @values;
    my $min;
    my $max;
    for my $val ( @{$raw_values} ) {
        if ( Scalar::Util::looks_like_number($val) && ($val>=0) ) {
            push @values, $val;
            if ( !defined($min) ) {
                $min = $max = $val;
            }
            else {
                $min = $val if $val < $min;
                $max = $val if $val > $max;
            }
        }
        else {
            push @values, undef;
        }
    }

    return ( \@values, $min, $max );
}


=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
L<http://github.com/petdance/text-sparkline/issues>.

Note that Text::Sparline does NOT use L<http://rt.cpan.org> for bug tracking.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Sparkline

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/pod/Text::Sparkline>

=item * Text::Sparkline's bug queue

L<http://github.com/petdance/text-sparkline/issues>

=item * Project repository at GitHub

L<http://github.com/petdance/text-sparkline>

=back

=head1 ACKNOWLEDGEMENTS

This code is adapted from
L<Term::Spark|https://metacpan.org/pod/Term::Spark>,
based on Zach Holman's original L<spark|https://github.com/holman/spark> program.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Andy Lester.

This is free software, licensed under: The Artistic License 2.0 (GPL Compatible)

=cut


1;
