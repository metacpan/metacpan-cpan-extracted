package WWW::Webrobot::Histogram;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG

use WWW::Webrobot::Attributes qw(logarithm base hist_pos hist_neg);


sub new {
    my ($class) = shift;
    my $self = bless({}, ref($class) || $class);
    $self->hist_pos([]);
    $self->hist_neg([]);
    my %parm = (@_);
    $self->base($parm{base} || 2);
    $self->logarithm(make_logarithm($self->base));
    return $self;
}

sub add {
    my $self = shift;
    foreach (@_) {
        my $log = $self->logarithm->($_);
        my $intlog = $log >= 0 ? int($log) : int($log-1);
        if ($intlog >= 0) {
            $self->hist_pos->[$intlog] ++;
        }
        else {
            $self->hist_neg->[-$intlog] ++;
        }
    }
}

sub histogram {
    my $self = shift;
    $_ ||= 0 foreach (@{$self->hist_pos});
    $_ ||= 0 foreach (@{$self->hist_neg});
    return ($self->hist_neg, $self->hist_pos);
}

sub make_logarithm {
    my ($b) = @_;
    my $log_b = log($b);
    return sub {
        my $n = shift;
        my $result = eval {
            log($n) / $log_b;
        };
        $result = undef if $@;
        return $result;
    }
    # Berechnung des Zweierlogarithmus:
    # perl -lne 'my $i=0; while ($_ = $_ >> 1) {$i++; } print $i'
}

1;

=head1 NAME

WWW::Webrobot::Histogram - Plain simple histograms

=head1 SYNOPSIS

 use WWW::Webrobot::Histogram;
 my $hist = WWW::Webrobot::Histogram -> new(base => 1.4142135623731);
 $hist -> add(3, 4, 5);
 $hist -> add(6, 7);
 my ($hist_neg, $hist_pos) = $hist->histogram;


=head1 DESCRIPTION

This module is used to calculate a logarithmic histogram
from a set of data.

=head1 METHODS

=over

=item my $histo = WWW::Webrobot::Histogram -> new

Constructor. Parameters are given as C<key=>value>. keys are

 base
        [default: 2] base of the logarithmic scale (x-axis)

=item $histo->add(...)

Add values.

=item $histo->histogram()

 return ($hist_neg, $hist_pos)

$hist_pos is an array reference.

 $hist_pos->[$i]
        (i>=0): shows the number of elements between $base**$i and $base**($i+1).
 $hist_neg->[$i]
        (i<0): shows the number of elements between $base**(-$i) and $base**(-$i+1).
               $hist_neg->[0] is defined but invalid.

=item $histo->base

Get base attribute, see constructor new.
NO SET METHOD!

=back

=cut

__END__
