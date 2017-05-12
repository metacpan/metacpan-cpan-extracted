package Finance::BDT;

use strict;
use warnings;

use Data::Dumper;
use constant EPSILON => 0.00001;

our $VERSION = '0.01';
our $DEBUG;

my (@P, @y, $vol, @r, @d, @A, $epsilon);

sub clear { @P = @y = @r = @d = @A = (); $vol = $epsilon = undef }
sub bdt {
    my (%params) = @_;
    @y = @{$params{-yields}};
    $epsilon = $params{-epsilon} || EPSILON;
    $vol = $params{-volatility};  ## constant volatility

    ## @P: the set of discount prices
    for (0..$#y) { $P[$_] = [] }                       ## initialize @P as a 2-D array
    for (0..$#y) { $P[0][$_] = exp( -$y[$_] * $_) }    ## derive bond prices from the yields

    if ($DEBUG) {
      print "Bond Price: ";
      for (0..$#y) { printf "%.5f  ", $P[0][$_] }
      print "\n";
    }

    ## @r: the rates at each period
    for (0..$#y) { $r[$_] = [] }   ## initialize @r as a 2-D array
    $r[0] = [$y[1]];               ## we start knowing this

    ## @d: the discount rates
    for (0..$#y) { $d[$_] = [] }   ## initialize @r as a 2-D array

    ## @A: the state asset prices
    for (0..$#y) { $A[$_] = [] }    ## initialize @A as a 2-D array
    $A[1][0] = $P[0][1] * 0.5;
    $A[1][1] = $P[0][1] * 0.5;


    #### Now the real work starts
    for (1..$#y-1) {
	$r[$_] = iterator($_, $r[$_-1][0]);
	&gen_discount_function($_);
	print Dumper $d[$_] if $DEBUG;
	&gen_state_prices($_+1);
	print Dumper $A[$_] if $DEBUG;
    }

    return(\@r, \@d, \@A);
}

sub gen_discount_function {
    my ($period) = @_;
    for (0..$period) {
	$d[$period][$_] = exp(- $r[$period][$_] );
    }
}


sub gen_state_prices {
    my ($period) = @_;
    $A[$period][0]       = $A[$period - 1][0] * .5 * $d[$period - 1][0];                      ## the bottom lattice
    $A[$period][$period] = $A[$period - 1][$period - 1] * .5 * $d[$period - 1][$period - 1];  ## the top lattice

    ## the middle lattices:
    for (1 .. $period - 1) {
	$A[$period][$_] = ($A[$period - 1][$_-1] * .5 * $d[$period - 1][$_ - 1] + 
			   $A[$period - 1][$_] * .5 * $d[$period - 1][$_] );
    }
}


sub bond {
    my ($period, $r, $vol) = @_;
    my $u1 = exp(2 * $vol);
    my $bond = $P[0][$period - 1] * (.5 * exp(-$r) + .5 * exp(-$r * $u1) );
    printf("bond(%i, %.7f, %.7f, %.7f)\n", $period, $r, $u1, $vol) if $DEBUG;
    return ($bond, [$r, $r * $u1]);
}

sub bond2 {
    my ($period, $r, $vol) = @_;
#    print "period: $period, $r, $vol\n";
    my $bond = 0;
    my @r;
    my $u = exp( 2 * $vol);

#    $bond = $A[2][0] * exp(-$r) + $A[2][1] * exp(-$r * $u) + $A[2][2] * exp(-$r * $u**2);
#    @r = ($r, $r * $u, $r * $u**2);

    $r[$_] = $r * $u ** $_ for (0..$period-1);
    for (0..$period-1) {
	$bond += $A[$period - 1][$_] * exp( - $r[$_] );
    }
    return ($bond, \@r);
}

sub iterator {
    my ($period, $guess) = @_;

    ## try the first guess
    ## uses a binary search to find the correct rates
    my $diff = 1; ## for starters
    my ($low, $high) = ($guess / 2, $guess * 2);
    my ($bond, $r);     ## the calculated bond price, and the respective rates

    while (abs($diff) > $epsilon) {
	## till we reach a certain limit ...

	($bond, $r) = $period == 1 ? bond($period + 1, $guess, $vol) : bond2($period + 1, $guess, $vol);
	$diff = $bond - $P[0][$period + 1];
	print "[$high, $low, $guess, $bond]  " if $DEBUG;

	if ($diff < 0) {
	    $high = $guess;
	}
	else {
	    $low = $guess;
	}
	$guess = ($low + $high) / 2;


    }

    print "\nSuccess: P:$period, B:$bond, B:$P[0][$period + 1], R:@$r\n" if $DEBUG;

    return $r;
}


1;
__END__

=head1 NAME

Finance::BDT - Implements BDT yield curve model

=head1 SYNOPSIS

  use Finance::BDT;
  use Data::Dumper
  my @y = (0, 0.0283, 0.029, 0.0322, 0.0401, 0.0435, 0.0464, 0.0508, 0.0512);        ## YTM on strips
  my $vol = 0.20;  ## constant volatility
  my $epsilon = 0.01;
  my ($r, $d, $A) = Finance::BDT::bdt( -yields => \@y, -epsilon => $epsilon, -volatility => $vol );
  print "Short Rates: \n", Dumper $r;
  print "Discount Prices: \n", Dumper $d;
  print "Asset State Prices: \n", Dumper $A;


=head1 ABSTRACT

  Sample implementation of Black-Derman-Toy model.

=head1 DESCRIPTION

Finance::BDT implements a constant volatility Black-Derman-Toy model in Perl.  Not that you should be building your curves in perl, but now you can.  The current implementation works with constant volatility but I am testing a version which allows you to pass in a term structure of volatilities.  The input is the zero curve (as observed yields), a constant volatility, and a limit for the numerical solution.
The function returns the interest rate tree as a list of lists (first index being the time period, and second being the position with the lowest rate having index 0).  Three trees are returned: the short rates at each period, the discount prices and most importantly the state prices.

The examples directory has an untested sample implementation in C for the brave.

=head2 TODO

- Use a term structure of volatilies
- Be able to price an interest rate derivative based on the asset prices
- Be able to perturb and re-price the instrument
- Implement the actual calculation in C (maybe using Inline::C)

=head2 EXPORT

None by default.


=head1 SEE ALSO

Black, F., Derman, E., and Toy, W. "A one-factor model of interest rates and its application to treasury bond options," Financial Analysts Journal, 46 (1990), 33-39.

Hull, J. and White, A., "One-Factor interest Rate Models and the Valuation of Interest Rate Derivative Securities," Journal of Financial and Quantitive Analysis, 28 (1993), 235-254.

Klose, Chrisoph and Yuan, Li Chang. Implementation of the Black, Derman and Toy Model. http://www.lcy.net/files/BDT_Seminar_Paper.pdf

=head1 AUTHOR

Sidharth Malhotra, sidharth dot malhotra at gmail dot com

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Sidharth Malhotra

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
