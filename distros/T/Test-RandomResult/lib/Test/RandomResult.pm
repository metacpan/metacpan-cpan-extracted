## no critic: Modules::ProhibitAutomaticExportation
package Test::RandomResult;

our $DATE = '2019-07-17'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;
use Test2::API 'context';

use Exporter 'import';
our @EXPORT = qw(
    results_look_random
);

sub results_look_random(&@) {
    my $code = shift;
    my $opts = {};
    while (@_ > 1) {
        my ($k, $v) = splice @_, 0, 2;
        $opts->{$k} = $v;
    };
    my $name = @_ ? shift : undef;

    my $runs = $opts->{runs} || 30;
    $runs >= 2 or die "Please set runs > 1";
    my @res;
    for (1..$runs) {
        push @res, $code->();
    }

    my $ctx = context();
    #use Data::Dump; $ctx->diag(Data::Dump::dump($opts));
    my $is_ok = 0;

    {
        # XXX check actual distribution
        my %vals;
        for (@res) { $vals{$_}++ }
        if (%vals < 2) {
            $ctx->diag("Results do not look random (constant value)");
            last;
        }

        if ($opts->{between} ||
                defined $opts->{min} || defined $opts->{xmin} ||
                defined $opts->{max} || defined $opts->{xmax}
            ) {
            my ($min, $max);
            for (@res) {
                $min = $_ if !defined($min) || $min > $_;
                $max = $_ if !defined($max) || $max < $_;
            }
            if ($opts->{between} && $min < $opts->{between}[0]) {
                $ctx->diag("There are results that are less than the specified minimum ($opts->{between}[0]): $min");
                last;
            }
            if ($opts->{between} && $max > $opts->{between}[1]) {
                $ctx->diag("There are results that are greater than the specified minimum ($opts->{between}[1]): $max");
                last;
            }
            if (defined $opts->{min} && $min < $opts->{min}) {
                $ctx->diag("There are results that are less than the specified minimum ($opts->{min}): $min");
                last;
            }
            if (defined $opts->{xmin} && $min <= $opts->{xmin}) {
                $ctx->diag("There are results that are less than or equal to the specified minimum ($opts->{xmin}): $min");
                last;
            }
            if (defined $opts->{max} && $max > $opts->{max}) {
                $ctx->diag("There are results that are greater than the specified maximum ($opts->{max}): $max");
                last;
            }
            if (defined $opts->{xmax} && $max >= $opts->{xmax}) {
                $ctx->diag("There are results that are greater than or equal to the specified maximum ($opts->{xmax}): $max");
                last;
            }
        }

        # everything's good
        $is_ok = 1;
    }

    $ctx->ok($is_ok, $name);
    $ctx->release;
    $is_ok;
}

1;
# ABSTRACT: Test that results of a running code look random

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::RandomResult - Test that results of a running code look random

=head1 VERSION

This document describes version 0.001 of Test::RandomResult (from Perl distribution Test-RandomResult), released on 2019-07-17.

=head1 SYNOPSIS

 use Test::More;
 use Test::RandomResult; # exports results_look_random

 results_look_random { your_func($arg) } 'your_func returns random result';
 results_look_random { your_func($arg) } between=>[1,10], 'your_func returns random between 1-10';
 ...
 done_testing;

=head1 DESCRIPTION

B<EARLY RELEASE. CURRENTLY HAS NOT CHECKED THE DISTRIBUTION OF RANDOM RESULTS.>

=head1 FUNCTIONS

=head2 results_look_random

Usage:

 results_look_random { CODE... }, 'TEST NAME';
 results_look_random { CODE... }, OPT1=>VAL, OPT2=>VAL, ..., 'TEST NAME';

Run code multiple times (by default 30 or more, see the C<runs> option) and
check if the results look random.

Known options:

=over

=item * runs

Integer. Default 30 or more. Number of times to run CODE.

=item * between

2-element array of numbers (C<< [$min, $max] >>). Check that results are between
C<$min> and C<$max>.

=item * min

Number. Specify minimum value (inclusive).

=item * xmin

Number. Specify minimum value (exclusive).

=item * max

Number. Specify maximum value (inclusive).

=item * xmax

Number. Specify maximum value (exclusive).

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Test-RandomResult>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Test-RandomResult>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-RandomResult>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Test::RandomResults>

L<Test::Stochastic>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
