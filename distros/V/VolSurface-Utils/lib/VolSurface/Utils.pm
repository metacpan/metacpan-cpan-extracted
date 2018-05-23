package VolSurface::Utils;

use 5.006;
use strict;
use warnings;

=head1 NAME

VolSurface::Utils - A class that handles several volatility related methods

=cut

our $VERSION = '1.04';

use Carp;
use List::Util qw(notall);
use Math::CDF qw(pnorm qnorm);
use Math::Business::BlackScholesMerton::NonBinaries;
use Math::Business::BlackScholes::Binaries::Greeks::Delta;
use base qw( Exporter );

=head1 SYNOPSIS

A class that handles several volatility related methods such as gets strikes from a certain delta point, gets delta from a certain vol point etc.

    use VolSurface::Utils;

    my ($strike, $atm_vol, $t, $spot, $r_rate, $q_rate, $premium_adjusted) = (); ## initialize args
    my $delta = get_delta_for_strike({
        strike           => $strike,
        atm_vol          => $atm_vol,
        t                => $t,
        spot             => $spot,
        r_rate           => $r_rate,
        q_rate           => $q_rate,
        premium_adjusted => $premium_adjusted
    });


=head1 EXPORT

get_delta_for_strike

get_strike_for_spot_delta

get_ATM_strike_for_spot_delta

get_moneyness_for_strike

get_strike_for_moneyness

get_1vol_butterfly

get_2vol_butterfly

=cut

our @EXPORT_OK =
    qw( get_delta_for_strike get_strike_for_spot_delta get_ATM_strike_for_spot_delta get_moneyness_for_strike get_strike_for_moneyness get_1vol_butterfly get_2vol_butterfly);

=head1 METHODS

=head2 get_delta_for_strike

Returns the delta (spot delta or premium adjusted spot delta) correspond to a particular strike with set of parameters such as atm volatility, time in year, spot level, rates

    my $delta = get_delta_for_strike({
        strike           => $strike,
        atm_vol          => $atm_vol,
        t                => $t,
        spot             => $spot,
        r_rate           => $r_rate,
        q_rate           => $q_rate,
        premium_adjusted => $premium_adjusted
    });

Spot delta of an option is the percentage of the foreign notional one must buy when selling the option to hold a hedged position in the spot markets.

Premium adjusted spot delta is the spot delta which adjusted to take care of the correction induced by payment of the premium in foreign currency, which is the amount by which the delta hedge in foreign currency has to be corrected.

=cut

sub get_delta_for_strike {
    my $args = shift;

    my %new_args = %$args;
    my @required = qw(strike atm_vol t spot r_rate q_rate premium_adjusted);
    for (@required) {
        croak "Arg $_ is undef at get_delta_for_strike" unless defined $args->{$_};
    }

    my ($K, $sigma, $t, $S, $r, $q, $premium_adjusted) =
        ($new_args{strike}, $new_args{atm_vol}, $new_args{t}, $new_args{spot}, $new_args{r_rate}, $new_args{q_rate}, $new_args{premium_adjusted});

    my $delta;
    if ($premium_adjusted) {
        my $d2 = (log($S / $K) + ($r - $q - ($sigma**2) / 2) * $t) / ($sigma * sqrt($t));
        $delta = ($K / $S) * exp(-1 * $r * $t) * pnorm($d2);
    } else {
        my $d1 = (log($S / $K) + ($r - $q + ($sigma**2) / 2) * $t) / ($sigma * sqrt($t));
        $delta = exp(-1 * $q * $t) * pnorm($d1);
    }

    return $delta;
}

=head2 get_strike_for_spot_delta

Returns the strike corresponds to a particular delta (spot delta or premium adjusted spot delta) with a set of parameters such as option type, atm vol, time in year, rates and spot level.

    my $strike = get_strike_for_spot_delta({
        delta            => $delta,
        option_type      => $option_type,
        atm_vol          => $atm_vol,
        t                => $t,
        r_rate           => $r_rate,
        q_rate           => $q_rate,
        spot             => $spot,
        premium_adjusted => $premium_adjusted
    });

Calculation of strike depends on which type of delta we have. Delta provided must be on [0,1].

=cut

sub get_strike_for_spot_delta {
    my $args = shift;

    my %new_args = %$args;
    my @required = qw(delta option_type atm_vol t r_rate q_rate spot premium_adjusted);
    for (@required) {
        croak "Arg $_ is undef at get_strike_for_spot_delta" unless defined $args->{$_};
    }

    if (!grep { $new_args{option_type} eq $_ } qw(VANILLA_CALL VANILLA_PUT)) {
        croak 'Wrong option type [' . $new_args{option_type} . ']';
    }

    if ($new_args{delta} < 0 or $new_args{delta} > 1) {
        croak 'Provided delta [' . $new_args{delta} . '] must be on [0,1]';
    }

    $new_args{normalInv} = qnorm($new_args{delta} / exp(-$new_args{q_rate} * $new_args{t}));
    my $k;
    if ($new_args{normalInv}) {
        $k =
            ($new_args{option_type} eq 'VANILLA_CALL')
            ? _calculate_strike_for_vanilla_call(\%new_args)
            : _calculate_strike_for_vanilla_put(\%new_args);
    }

    return $k;
}

sub _calculate_strike_for_vanilla_put {
    my $args = shift;

    my ($normalInv, $delta, $sigma, $time_in_years, $r, $d, $S, $premium_adjusted) =
        ($args->{normalInv}, $args->{delta}, $args->{atm_vol}, $args->{t},
        $args->{r_rate}, $args->{q_rate}, $args->{spot}, $args->{premium_adjusted});

    #Step 1: Set initial k level with corresponding to spot delta without premium_adjusted
    my $k = $S * exp(($normalInv * $sigma * sqrt($time_in_years)) + ($r - $d + ($sigma * $sigma / 2)) * $time_in_years);

    for (my $i = 1; $i <= 5 * $premium_adjusted; $i++) {
        my $k1 = $k;

        # Step 2: Calculate option price and the corresponding delta
        my $option_price_1 = Math::Business::BlackScholesMerton::NonBinaries::vanilla_put($S, $k1, $time_in_years, $r, $r - $d, $sigma);
        my $delta_1 = Math::Business::BlackScholes::Binaries::Greeks::Delta::vanilla_put($S, $k1, $time_in_years, $r, $r - $d, $sigma);

        # Step 3: Numerically evaluate option at slightly different strike and calculate its corresponding delta
        my $option_price_2 = Math::Business::BlackScholesMerton::NonBinaries::vanilla_put($S, $k1 * 1.000001, $time_in_years, $r, $r - $d, $sigma);
        my $delta_2 = Math::Business::BlackScholes::Binaries::Greeks::Delta::vanilla_put($S, $k1 * 1.000001, $time_in_years, $r, $r - $d, $sigma);
        # Option's premium adjusted delta derivatives with respect to strike
        my $d_delta = ($delta_2 - $option_price_2 / $S - $delta_1 + $option_price_1 / $S) / ($k1 * 0.000001);

        # Step 4: Calcuate strike, k for i+1
        $k = $k1 - (($delta_1 + $delta) - $option_price_1 / $S) / $d_delta;

        # This is because we cant take log of negative in BS pricer.
        if ($k <= 0) {
            $k = 0;
            last;
        }

        last if (abs($k - $k1) <= 0.0000000000000000000001);
    }

    return $k;
}

sub _calculate_strike_for_vanilla_call {
    my $args = shift;

    my ($normalInv, $delta, $sigma, $time_in_years, $r, $d, $S, $premium_adjusted) =
        ($args->{normalInv}, $args->{delta}, $args->{atm_vol}, $args->{t},
        $args->{r_rate}, $args->{q_rate}, $args->{spot}, $args->{premium_adjusted});

    #Step 1: Set initial k level with corresponding to spot delta without premium_adjusted.
    my $k = $S * exp(-($normalInv * $sigma * sqrt($time_in_years)) + ($r - $d + ($sigma * $sigma / 2)) * $time_in_years);

    for (my $i = 1; $i <= 5 * $premium_adjusted; $i++) {
        my $k1 = $k;

        # Step 2: Calculate option price and the corresponding delta
        my $option_price_1 = Math::Business::BlackScholesMerton::NonBinaries::vanilla_call($S, $k1, $time_in_years, $r, $r - $d, $sigma);
        my $delta_1 = Math::Business::BlackScholes::Binaries::Greeks::Delta::vanilla_call($S, $k1, $time_in_years, $r, $r - $d, $sigma);

        # Step 3: Numerically evaluate option at slightly different strike and calculate its corresponding delta
        my $option_price_2 = Math::Business::BlackScholesMerton::NonBinaries::vanilla_call($S, $k1 * 1.000001, $time_in_years, $r, $r - $d, $sigma);
        my $delta_2 = Math::Business::BlackScholes::Binaries::Greeks::Delta::vanilla_call($S, $k1 * 1.000001, $time_in_years, $r, $r - $d, $sigma);

        # Option's premium adjusted delta derivatives with respect to strike
        my $d_delta = ($delta_2 - $option_price_2 / $S - $delta_1 + $option_price_1 / $S) / ($k1 * 0.000001);

        # Step 4: Calcuate strike, k for i+1. If $d_delta is zero, then $k will be a negative infinity number
        # Instead of giving it a negative infinity number, we'll assign zero to it
        $k = ($d_delta) ? $k1 - (($delta_1 - $delta) - $option_price_1 / $S) / $d_delta : 0;

        # This is because we cant take log of negative in BS pricer.
        if ($k <= 0) {
            $k = 0;
            last;
        }

        last if (abs($k - $k1) <= 0.0000000000000000000001);
    }

    return $k;
}

=head2 get_ATM_strike_for_spot_delta

Returns the ATM strike that satisifies straddle Delta neutral.

    my $atm_strike = get_ATM_strike_for_spot_delta({
        atm_vol => $atm_vol,
        t => $t,
        r_rate => $r_rate,
        q_rate => $q_rate,
        spot => $spot,
        premium_adjusted => $premium_adjusted,
    });

The ATM volatility quoted in the market is that of a zero delta
straddle, whose strike, for each given expiry, is chosen so that
a put and a call have the SAME delta but with different signs.
No delta hedge is needed when trading this straddle.

The ATM volatility for the expiry T is the volatility where the ATM strike K must satisfy the following condition:
Delta Call =  - Delta Put

The ATM strike is the strike correspond to this ATM volatility.

=cut

sub get_ATM_strike_for_spot_delta {
    my $args = shift;

    my %new_args = %$args;
    my @required = qw(atm_vol t r_rate q_rate spot premium_adjusted);
    for (@required) {
        croak "Arg $_ is undef at get_ATM_strike_for_spot_delta" unless defined $args->{$_};
    }

    my ($sigma, $time_in_years, $r, $d, $S, $premium_adjusted) =
        ($new_args{atm_vol}, $new_args{t}, $new_args{r_rate}, $new_args{q_rate}, $new_args{spot}, $new_args{premium_adjusted});

    my $constant = ($premium_adjusted) ? -0.5 : 0.5;
    my $strike = $S * exp(($r - $d + $constant * $sigma * $sigma) * $time_in_years);

    return $strike;
}

=head2 get_moneyness_for_strike

Returns the corresponding moneyness point for a given strike.

    my $moneyness = get_moneyness_for_strike({
        strike => $strike,
        spot => $spot,
    });

=cut

sub get_moneyness_for_strike {
    my $args = shift;

    for (qw(spot strike)) {
        croak "$_ is undef when you convert strike to moneyness" unless defined $args->{$_};
    }

    return $args->{strike} / $args->{spot} * 100;
}

=head2 get_strike_for_moneyness

Returns the corresponding strike value for a given moneyness point.


 my $strike = get_strike_for_moneyness({
        spot => $spot,
        moneyness => $moneyness
    });

=cut

sub get_strike_for_moneyness {
    my $args = shift;

    for (qw(spot moneyness)) {
        croak "$_ is not defined at get_strike_for_moneyness" unless defined $args->{$_};
    }

    my $moneyness = $args->{moneyness};
    $moneyness = $args->{moneyness} / 100 if $moneyness > 3;

    return $moneyness * $args->{spot};
}

=head2 get_2vol_butterfly

Returns the two vol butterfly that satisfy the abitrage free constraint.

 my $bf = get_2vol_butterfly($spot, $tiy,$delta, $atm, $rr, $bf, $r, $d, $premium_adjusted, $bf_style);

DESCRIPTION:
There are two different butterfly vol:

-The first one is 2 vol butterfly which is the quoted butterfly that appear in interbank market (vwb= 0.5(Sigma(call)+SigmaP(Put))- Sigma(ATM)).

-The second one is 1 vol butterfly which is the butterfly volatility that consistent with market standard conventions of trading the butterfly  strategies (some paper called it market strnagle volatility).

The market standard conventions for trading the butterfly is price the strangle with one unique volatility whereas with the first butterfly convention(ie the quoted butterfly vol), we will price the strangle with two volatility.

There is possible arbitrage opportunities that might result from the inconsistency caused by the above quoting mechanism.

Hence, in practice, we need to build a volatility smile so that the price of the two options strangle based on the volatility surface that we build will have same price as the one from the market conventional butterfly trading(ie with one unique volatility).

The consistent constraint that need to hold in building surface is as shown as follow :
C(K_25C, Vol_K_25C) + P(K_25P, Vol_K_25P) = C(K_25C, Vol_market_conventional_bf) + P(K_25P, Vol_market_conventional_bf)

The first step in building the abitrage free volatility smile is to determine an equivalent butterfly which will combines with all the ATM and RR vol to yields a volatility smile that satisfies the above constraint .

This equivalent butterfly which is also named as two vol butterfly or smiled butterfly can be found numerically.

This is only needed if the butterfly is the 1 vol butterfly from the market without any adjustment yet. If vol smile is abitrage free, hence their BF is already adjusted accordingly to fullfill the abitrage free constraints, hence no adjustment needed on the BF.

As this process gone through a numerical procedures, hence the result might be slightly different when compare with other vendor as they might used different approach to get the relevant result.

=cut

sub get_2vol_butterfly {
    my ($S, $tiy, $delta, $atm, $rr, $bf, $r, $d, $premium_adjusted, $bf_style) = @_;

    # If the bf is not 1 vol butterfly, no need to do adjustment.
    if ($bf_style ne '1_vol') {
        return $bf;
    }

    my $strike_atm = get_ATM_strike_for_spot_delta({
        atm_vol          => $atm,
        t                => $tiy,
        r_rate           => $r,
        q_rate           => $d,
        spot             => $S,
        premium_adjusted => $premium_adjusted
    });

    #  Step 1: Obtain the market conventional volatility of butterfly (ie the unique butterfly volatility used in price strangle)
    my $market_conventional_bf = $atm + $bf;

    # Step 2 to 5 is mainly to obtain the difference between the two strangles (one valued with market quoted volatility and one with market conventional butterfly volatility)
    my $strangle_difference = _strangle_difference($S, $tiy, $delta, $atm, $rr, $bf, $market_conventional_bf, $r, $d, $strike_atm, $premium_adjusted);

    # Step 6.1 : just return the quoted butterfly if the difference is too small
    return $bf if (abs($strangle_difference) < 0.0000001 * $S);

    # 6.2 : Increase the bf by one basic point of 0.0001 and go through iteration to perform the same calculation from step 1 to 5 with new incremented bf
    $bf = $bf + 0.0001;
    my $diff_bf = 0.0001;

    while (abs($strangle_difference) > 0.0000001 * $S) {
        my $new_strangle_difference =
            _strangle_difference($S, $tiy, $delta, $atm, $rr, $bf, $market_conventional_bf, $r, $d, $strike_atm, $premium_adjusted);
        # Step 7: Calculate the numerical derivatives of the strangle diffrences with respect to the new bf
        my $D_strangle_difference = ($new_strangle_difference - $strangle_difference) / $diff_bf;
        # Step 8: Calculate the new bf and the
        $bf                  = $bf - $new_strangle_difference / $D_strangle_difference;
        $diff_bf             = -$new_strangle_difference / $D_strangle_difference;
        $strangle_difference = $new_strangle_difference;
    }
    return $bf;
}

=head2 get_1vol_butterfly

Returns the 1 vol butterfly which is the butterfly volatility that consistent with market standard conventions of trading the butterfly strategies (some paper called it market strnagle volatility)

    my $bf_1vol = get_1vol_butterfly({
        spot             => $volsurface->underlying->spot,
        tiy              => $tiy,
        delta            => 0.25,
        call_vol         => $smile->{25},
        put_vol          => $smile->{75},
        atm_vol          => $smile->{50},
        bf_1vol          => 0,
        r                => $volsurface->underlying->interest_rate_for($tiy),
        q                => $volsurface->underlying->dividend_rate_for($tiy),
        premium_adjusted => $volsurface->underlying->{market_convention}->{delta_premium_adjusted},
        bf_style         => '2_vol',
    });

=cut

sub get_1vol_butterfly {
    my $args = shift;
    my ($S, $tiy, $delta, $call_vol, $put_vol, $atm_vol, $bf_1vol, $r, $d, $premium_adjusted, $bf_style) =
        @{$args}{'spot', 'tiy', 'delta', 'call_vol', 'put_vol', 'atm_vol', 'bf_1vol', 'r', 'q', 'premium_adjusted', 'bf_style'};

    if ($bf_style ne '2_vol') {
        return $bf_1vol;
    }

    my $smile_rr = $call_vol - $put_vol;
    my $smile_bf = ($call_vol + $put_vol) / 2 - $atm_vol;
    # set initial guess for 1 vol
    if (not $bf_1vol) {
        $bf_1vol = $smile_bf - 0.0001;
    }

    my $bf_2vol = get_2vol_butterfly($S, $tiy, $delta, $atm_vol, $smile_rr, $bf_1vol, $r, $d, $premium_adjusted, '1_vol');

    my $differences_between_two_bf = $smile_bf - $bf_2vol;

    return $bf_1vol if ($differences_between_two_bf > 0.0001);

    while ($differences_between_two_bf < 0.0001) {
        $bf_1vol = $bf_1vol - 0.0001;
        $bf_2vol = get_2vol_butterfly($S, $tiy, $delta, $atm_vol, $smile_rr, $bf_1vol, $r, $d, $premium_adjusted, '1_vol');

        $differences_between_two_bf = $smile_bf - $bf_2vol;

    }
    return $bf_1vol;
}

sub _strangle_difference {

    my ($S, $tiy, $delta, $atm, $rr, $bf, $market_conventional_bf, $r, $d, $strike_atm, $premium_adjusted) = @_;

    #Step 2: Retrieve the two call and put volatility in a "consistent" way which means from the market quoted ATM, BF and RR volatility.
    my $put_sigma  = $atm + $bf - $rr / 2;
    my $call_sigma = $atm + $bf + $rr / 2;

    #Step 3: Calculate the two call and put strikes with the "consistent" volatilities obtained from step 2
    my $consistent_call_strike = get_strike_for_spot_delta({
        delta            => $delta,
        option_type      => 'VANILLA_CALL',
        atm_vol          => $call_sigma,
        t                => $tiy,
        r_rate           => $r,
        q_rate           => $d,
        spot             => $S,
        premium_adjusted => $premium_adjusted
    });
    my $consistent_put_strike = get_strike_for_spot_delta({
        delta            => $delta,
        option_type      => 'VANILLA_PUT',
        atm_vol          => $put_sigma,
        t                => $tiy,
        r_rate           => $r,
        q_rate           => $d,
        spot             => $S,
        premium_adjusted => $premium_adjusted
    });

    #Step 4: Calculate the two call and put strikes for the market traded butterfly (ie with market conventional volatility of butterfly obtain on step 1.)
    my $market_conventional_call_strike = get_strike_for_spot_delta({
        delta            => $delta,
        option_type      => 'VANILLA_CALL',
        atm_vol          => $market_conventional_bf,
        t                => $tiy,
        r_rate           => $r,
        q_rate           => $d,
        spot             => $S,
        premium_adjusted => $premium_adjusted
    });
    my $market_conventional_put_strike = get_strike_for_spot_delta({
        delta            => $delta,
        option_type      => 'VANILLA_PUT',
        atm_vol          => $market_conventional_bf,
        t                => $tiy,
        r_rate           => $r,
        q_rate           => $d,
        spot             => $S,
        premium_adjusted => $premium_adjusted
    });

    #Step 5: Calculate the difference between the strangle struck at the market traded butterfly strikes(those obtained on step 4) valued with the smile volatility( ie the one build with market quoted volatilities), and the same strangle struck at same market traded butterfly strikes but valued with market conventional volatility of butterfly(ie. the one obtained on step 1).

    # 5.1:To obtain the corresponding volatilities for market traded butterfly strikes (ie those obtained on step 4.)
    my $market_conventional_call_sigma = _smile_approximation($S, $tiy, 2, $market_conventional_call_strike,
        $consistent_put_strike, $strike_atm, $consistent_call_strike, $put_sigma, $atm, $call_sigma, $d, $r);

    my $market_conventional_put_sigma = _smile_approximation($S, $tiy, 2, $market_conventional_put_strike,
        $consistent_put_strike, $strike_atm, $consistent_call_strike, $put_sigma, $atm, $call_sigma, $d, $r);

    # 5.2: Strangle struck at market traded butterfly strikes (ie those obtained on step 4) with smile volatility builds with market quoted volatilities
    my $call_with_consistent_vol = Math::Business::BlackScholesMerton::NonBinaries::vanilla_call($S, $market_conventional_call_strike,
        $tiy, $r, $r - $d, $market_conventional_call_sigma);

    my $put_with_consistent_vol = Math::Business::BlackScholesMerton::NonBinaries::vanilla_put($S, $market_conventional_put_strike,
        $tiy, $r, $r - $d, $market_conventional_put_sigma);
    my $strangle_with_consistent_vol = $call_with_consistent_vol + $put_with_consistent_vol;
    # 5.3: Strangle struck at market traded butterfly strikes (ie those obtained on step 4) with market coventional volatility of butterfly.
    my $call_with_market_conventional_bf = Math::Business::BlackScholesMerton::NonBinaries::vanilla_call($S, $market_conventional_call_strike,
        $tiy, $r, $r - $d, $market_conventional_bf);
    my $put_with_market_conventional_bf =
        Math::Business::BlackScholesMerton::NonBinaries::vanilla_put($S, $market_conventional_put_strike, $tiy, $r, $r - $d, $market_conventional_bf);
    my $strangle_with_market_conventional_bf = $call_with_market_conventional_bf + $put_with_market_conventional_bf;

    # 5.4: Calculate differences between strangle from 5.2 and 5.3

    my $strangle_difference = $strangle_with_consistent_vol - $strangle_with_market_conventional_bf;
    return $strangle_difference;

}

sub _smile_approximation {
    my ($S, $tiy, $order_approx, $k, $k1, $k2, $k3, $vol_k1, $vol_k2, $vol_k3, $d, $r) = @_;

    if ($order_approx < 1 or $order_approx > 2) {
        croak "$0: Supported order 1 and 2. Not supported order [$order_approx].";
    }
    my $vol;
    my $F = $S * exp(($r - $d) * $tiy);
    my $Y_1 = (log($k2 / $k) * log($k3 / $k)) / (log($k2 / $k1) * log($k3 / $k1));
    # At grid points k3 or k1, this is zero.
    my $Y_2 = (log($k3 / $k) * log($k / $k1)) / (log($k3 / $k2) * log($k2 / $k1));
    # At grid points k1 or k2, this is zero.
    my $Y_3 = (log($k / $k1) * log($k / $k2)) / (log($k3 / $k1) * log($k3 / $k2));

    my $d1_k = ((0.5 * $vol_k2 * $vol_k2 * $tiy) + log($F / $k)) / ($vol_k2 * sqrt($tiy));
    my $d2_k = $d1_k - ($vol_k2 * sqrt($tiy));

    my $d1_k1 = ((0.5 * $vol_k2 * $vol_k2 * $tiy) + log($F / $k1)) / ($vol_k2 * sqrt($tiy));
    my $d2_k1 = $d1_k1 - ($vol_k2 * sqrt($tiy));

    my $d1_k3 = ((0.5 * $vol_k2 * $vol_k2 * $tiy) + log($F / $k3)) / ($vol_k2 * sqrt($tiy));
    my $d2_k3 = $d1_k3 - ($vol_k2 * sqrt($tiy));

    # For the 1st order approximation, what happens at market grid points is that it
    # will be equal to the grid point volatility.
    my $vol_1st_order = ($Y_1 * $vol_k1) + ($Y_2 * $vol_k2) + ($Y_3 * $vol_k3);

    return $vol_1st_order if ($order_approx == 1);

    # 2nd order approximation
    my $D1_k  = $vol_1st_order - $vol_k2;
    my $D2_k  = $Y_1 * $d1_k1 * $d2_k1 * (($vol_k1 - $vol_k2)**2) + $Y_3 * $d1_k3 * $d2_k3 * (($vol_k3 - $vol_k2)**2);
    my $temp1 = ($vol_k2 * $vol_k2) + ($d1_k * $d2_k * (2 * $vol_k2 * $D1_k + $D2_k));

    # default to first-order approximation, if 2nd order would lead to imaginary numbers
    if ($temp1 < 0) {
        my $implied_vol_method = ($k > $k2) ? 'VANILLA_CALL' : 'VANILLA_PUT';
        $vol = _implied_vol($S, $tiy, $k, $S * 0.00001, $r, $d, $implied_vol_method);
    } else {
        $temp1 = sqrt($temp1);
        $vol = $vol_k2 + ((-$vol_k2 + $temp1) / ($d1_k * $d2_k));
    }

    return $vol;
}

sub _implied_vol {
    my ($S, $tiy, $k, $price, $r, $d, $type) = @_;

    return 0 if ($price < 0);
    my $F = $S * exp(($r - $d) * $tiy);

    # The starting point setting
    my $vol = sqrt(2 / $tiy * $F / $k);

    $vol = 0.15 if ($vol == 0);
    my $esc = 1;
    my $i   = 1;
    my $option_price;
    my $vega;

    while (abs($esc) > 0.000001) {
        return 0 if ($i > 35);
        if ($type eq 'VANILLA_CALL') {
            $option_price = Math::Business::BlackScholesMerton::NonBinaries::vanilla_call($S, $k, $tiy, $r, $r - $d, $vol);
            $vega = Math::Business::BlackScholes::Binaries::Greeks::Vega::vanilla_call($S, $k, $tiy, $r, $r - $d, $vol);
        } else {
            $option_price = Math::Business::BlackScholesMerton::NonBinaries::vanilla_put($S, $k, $tiy, $r, $r - $d, $vol);
            $vega = Math::Business::BlackScholes::Binaries::Greeks::Vega::vanilla_put($S, $k, $tiy, $r, $r - $d, $vol);
        }

        return 0 if ($vega <= 0.00000001);
        $esc = $option_price - $price;
        $vol = $vol - $esc / $vega;
        $i++;
    }

    return $vol;
}

=head1 AUTHOR

Binary.com, C<< <support at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-volsurface-utils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=VolSurface-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VolSurface::Utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=VolSurface-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/VolSurface-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/VolSurface-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/VolSurface-Utils/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Binary.com.

=cut

1;    # End of VolSurface::Utils
