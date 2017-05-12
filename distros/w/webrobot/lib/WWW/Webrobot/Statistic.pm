package WWW::Webrobot::Statistic;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG


use Carp;

use WWW::Webrobot::Attributes qw(extended elem sum_x sum_x2 n min max);


sub new {
    my ($class) = shift;
    my $self = bless({}, ref($class) || $class);
    my %parm = (@_);
    if (exists $parm{extended}) {
        $self->extended($parm{extended} ? 1 : 0);
        $self->elem([]);
    }
    $self->sum_x(0);
    $self->sum_x2(0);
    $self->n(0);
    return $self;
}

sub add {
    my $self = shift;
    foreach (@_) {
        push(@{$self->elem}, $_) if $self->extended;
        $self->sum_x($self->sum_x + $_);
        $self->sum_x2($self->sum_x2 + $_ * $_);
        $self->n($self->n + 1);
        $self->min($_) if !defined $self->min || $_ < $self->min;
        $self->max($_) if !defined $self->max || $_ > $self->max;
    }
}

sub mean {
    my $self = shift;
    return $self->sum_x / $self->n;
}

sub quad_mean {
    my $self = shift;
    return sqrt($self->sum_x2 / $self->n);
}

sub standard_deviation {
    my $self = shift;
    return 0 if $self->n <= 1;
    return sqrt(
        ($self->sum_x2 - $self->n * $self->mean * $self->mean) /
        ($self->n - 1)
    );
}

sub median {
    my $self = shift;
    croak("Method only available in extended mode ". __PACKAGE__ . "->new(extended=>1)")
        if ! $self->extended;
    my @tmp = sort { $a<=>$b } @{$self->elem};
    my $c = scalar @tmp;
    my $median = ($c%2 eq 1) ? $tmp[$c/2] : ($tmp[$c/2] + $tmp[$c/2-1]) / 2;
    return $median;
}

1;

=head1 NAME

WWW::Webrobot::Statistic - Plain simple statistic

=head1 SYNOPSIS

 use WWW::Webrobot::Statistic;
 my $s = WWW::Webrobot::Statistic -> new();
 $s -> add(3, 4, 5);
 $s -> add(6, 7);
 print "n: ",                  $s->n, "\n";
 print "min: ",                $s->min, "\n";
 print "max: ",                $s->max, "\n";
 print "mean: ",               $s->mean, "\n";
 print "median: ",             $s->median, "\n";
 print "standard deviation: ", $s->standard_deviation, "\n";
 print "quadratic mean: ",     $s->quad_mean, "\n";


=head1 DESCRIPTION

Does some plain statistics.
This module will store the complete data set on demand only.

=head1 METHODS

=over

=item $s->new(%options)

Constructor.
Options:

=over

=item extended

1  store complete data set (only if you want to call L<median>.

0  needn't store complete data set (L<median> not available).

=back

=item $s->n

Number of elements added.

=item $s->min

Smallest element.

=item $s->max

Largest element.

=item $s->mean

Arithmetic mean.

=item $s->quad_mean

Quadratic mean.

=item $s->standard_deviation

Standard deviation, base n-1

=item $s->median

Median.
Gives the arithmetic mean of the two "mean" elements
if the number of elements is even.

=back

=cut

__END__
