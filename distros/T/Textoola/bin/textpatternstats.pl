#!/usr/bin/perl

# PODNAME: textpatternstats.pl
# ABSTRACT: Analyse which line based text pattern exists and return some statistics.

use strict;
use warnings;
use v5.14;

use Getopt::Long;
use Textoola::PatternStatParser;


my $order;
my @filepaths;

GetOptions (
    "order:s"       => \$order,
    "file=s"        => \@filepaths,
    );

my @parsers = map { 
    Textoola::PatternStatParser->new(path=>$_);
} @filepaths;

my @pattern_countings = map {
    $_->parse();
    $_->patternstats()
} @parsers;

# Get all patterns
my %patterns_set = map { (%{$_}) } @pattern_countings;
my @patterns = sort keys %patterns_set;

# Nullify undefined patterns
for my $pattern_count (@pattern_countings) {
    for my $pattern (@patterns) {
	$pattern_count->{$pattern} = 0
	    unless (defined $pattern_count->{$pattern});
    }
}

# Summarize all patterns
my %pattern_sum;
for my $pattern_count (@pattern_countings) {
    for my $pattern (@patterns) {
	$pattern_sum{$pattern}+=$pattern_count->{$pattern};
    }
}

my $pattern_sets_amount = scalar(@pattern_countings);

# Average for patterns
my %pattern_avg = map {
    my $div = $pattern_sum{$_}/$pattern_sets_amount;
    $_ => $div
} @patterns;

# Calculate the variance-sigma for each pattern
my %pattern_var_sigma = map {
    my $pattern = $_;
    my $sigma = 0;
    my $pattern_sum = $pattern_sum{$pattern};
    for my $pattern_count (@pattern_countings) {
	my $diff = $pattern_count->{$pattern}-$pattern_sum;
	$sigma += ($diff*$diff)
    }
    $pattern => $sigma
} @patterns;

# Calculate variance for each pattern
my %pattern_var = map {
    my $var = $pattern_var_sigma{$_} / $pattern_sets_amount;
    $_ => $var
} @patterns;

# Remove subpatterns
my %reduced_patterns=map { $_ => 1 } @patterns;

for (my $i=scalar(@patterns)-1;$i>=1;$i--) {
    my $cur_pattern         = $patterns[$i];
    my $next_pattern        = $patterns[$i-1];
    my $size                = length($next_pattern);
    my $cur_pattern_substr  = substr($cur_pattern,0,$size);

    if ($next_pattern eq $cur_pattern_substr) {
	if ($pattern_avg{$cur_pattern} == $pattern_avg{$next_pattern}) {
	    if ($pattern_var{$cur_pattern} == $pattern_var{$next_pattern}) {
		delete $reduced_patterns{$next_pattern};
	    }
	}
    }
}

say "Average   |Deviation |Pattern";
for my $pattern (sort keys %reduced_patterns) {
    my $avg=sprintf("%10.2f",$pattern_avg{$pattern});
    my $var=sprintf("%10.2f",sqrt($pattern_var{$pattern}));
    say "$avg|$var|$pattern";
}

__END__

=pod

=encoding UTF-8

=head1 NAME

textpatternstats.pl - Analyse which line based text pattern exists and return some statistics.

=head1 VERSION

version 0.003

=head1 SYNOPSIS

textpatternstats.pl --file FILE1 --file FILE2 ...

=head1 DESCRIPTION

Generate statistics for count difference of text pattern lines between text files. 

=head1 NAME

textpatternstats.pl - Analyse which line based text pattern exists and return some statistics

=head1 OUTPUT

=head2 Average column

The average count of the pattern in the given input files.

=head2 Deviation column

The deviation to the count of the pattern in the given input files.

=head2 Pattern column

The most aggregated pattern (most broad text-piece) for the given average and deviation.

=head1 Project

L<Textoola on github.com|https://github.com/sascha-dibbern/Textoola/>

=head1 Authors 

L<Sascha Dibbern|http://sascha.dibbern.info/> (sascha@dibbern.info) 

=head1 AUTHOR

Sascha Dibbern <sacha@dibbern.info>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Sascha Dibbern.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
