# PODNAME: Textoola::PatternStatComparator
# ABSTRACT: Class to compare 2 counting-hashes with pattern-tokenlines and return the rate of change.

use strict;
use warnings;
use v5.14;

package Textoola::PatternStatComparator;
$Textoola::PatternStatComparator::VERSION = '0.003';
sub new {
    my $class = shift;
    my %args  = @_;

    my $self={
	patternstats1  => $args{patternstats1},
	patternstats2  => $args{patternstats2},
	threshhold     => $args{threshhold} || 0.05, # 5%
    };

    bless $self, $class;
    return $self;
}

sub compare {
    my $self       = shift;
    my $patstats1  = $self->{patternstats1};
    my %patstats2  = %{$self->{patternstats2}};

    my $threshhold = $self->{threshhold};
    my $upperlimit = $threshhold;
    my $lowerlimit = -$threshhold;

    my %result;

    for my $pat (keys %$patstats1) {
	if (exists $patstats2{$pat}) {
	    my $base   = $patstats1->{$pat};
	    my $new    = $patstats2{$pat};
	    my $change = ($new - $base) / $base;
	    if ($change <= $lowerlimit) {
		$result{$pat} = $change;
	    } elsif ($change >= $upperlimit) {
		$result{$pat} = $change;
	    }
	    
	    delete $patstats2{$pat};
	} else {
	    # only on left side
	    $result{$pat} = -1;
	}
    }
    # for the rest of right side had an indefinite change
    for my $pat (keys %patstats2) {
	$result{$pat} = '*';
    }

    return wantarray ? %result : \%result;
}

sub compare_reduce {
    my $self = shift;
    my $result = $self->compare(@_);

    # reduce partial patterns with same change-rate
    my @patterns = sort keys %$result;
    while (scalar(@patterns)-1) {
	my $cur_pattern  = shift @patterns;
	my $size         = length($cur_pattern);
	my $next_pattern = substr($patterns[0],0,$size);

	if ($cur_pattern eq $next_pattern) {
	    if (($result->{$cur_pattern} ne '*') and ($result->{$next_pattern} ne '*')) {
		if ($result->{$cur_pattern} == $result->{$next_pattern}) {
		    delete $result->{$cur_pattern};
		}
	    } elsif (($result->{$cur_pattern} eq '*') and ($result->{$next_pattern} eq '*')) {
		delete $result->{$cur_pattern};
	    }
	} 
    }

    return wantarray ? %$result : $result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Textoola::PatternStatComparator - Class to compare 2 counting-hashes with pattern-tokenlines and return the rate of change.

=head1 VERSION

version 0.003

=head1 AUTHOR

Sascha Dibbern <sacha@dibbern.info>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Sascha Dibbern.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
