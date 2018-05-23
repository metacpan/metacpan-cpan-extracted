#!/usr/bin/perl
use strict;
use warnings;

use POSIX;
use Test::Exception;
use Test::MockTime qw( set_absolute_time restore_time );
use Test::More (tests => 11);
use Test::NoWarnings;
use Test::MockModule;

use File::Spec;

use VolSurface::Utils qw(
    get_delta_for_strike
    get_strike_for_spot_delta
    get_ATM_strike_for_spot_delta
    get_moneyness_for_strike
    get_strike_for_moneyness
    get_2vol_butterfly
    get_1vol_butterfly
);

subtest get_delta_for_strike => sub {
    plan tests => 3;
    my %args = (
        strike           => 100,
        atm_vol          => 0.11,
        t                => 0.9,
        spot             => 99,
        r_rate           => 0.1,
        q_rate           => 0.2,
        premium_adjusted => undef
    );
    throws_ok { get_delta_for_strike(\%args) } qr/is undef at /, 'throws exception when args is undef';
    $args{premium_adjusted} = 1;
    lives_ok { get_delta_for_strike(\%args) } "can calculate premium_adjusted delta";
    $args{premium_adjusted} = 0;
    lives_ok { get_delta_for_strike(\%args) } "can calculate non-premium_adjusted delta";
};

subtest get_strike_for_spot_delta => sub {
    plan tests => 7;
    my %args = (
        delta            => 0.50,
        option_type      => 'VANILLA_CALL',
        atm_vol          => 0.11,
        t                => 0.9,
        spot             => 99,
        r_rate           => 0.1,
        q_rate           => 0.2,
        premium_adjusted => undef
    );
    throws_ok { get_strike_for_spot_delta(\%args) } qr/ is undef/, 'throws exception when args is undef';
    $args{premium_adjusted} = 1;
    lives_ok { get_strike_for_spot_delta(\%args) } 'can calculate strike for a premium adjusted delta for CALL';
    $args{delta} = 50;
    throws_ok { get_strike_for_spot_delta(\%args) } qr/^Provided delta.*must be on \[0,1\]/, 'Throws exception for deltas out of [0,1]';
    $args{delta}            = 0.50;
    $args{premium_adjusted} = 0;
    lives_ok { get_strike_for_spot_delta(\%args) } 'can calculate strike for a non premium adjusted delta for CALL';
    $args{option_type}      = 'VANILLA_PUT';
    $args{premium_adjusted} = 1;
    lives_ok { get_strike_for_spot_delta(\%args) } 'can calculate strike for a premium adjusted delta for PUT';
    $args{premium_adjusted} = 0;
    lives_ok { get_strike_for_spot_delta(\%args) } 'can calculate strike for a non premium adjusted delta for PUT';
    $args{option_type} = 'WHATEVER';
    throws_ok { get_strike_for_spot_delta(\%args) } qr/type/,
        'throws exception if you try to calculate strike for anything except for VANILLA_CALL & VANILLA_PUT';
};

subtest get_ATM_strike_for_spot_delta => sub {
    plan tests => 3;
    my %args = (
        atm_vol          => 0.11,
        t                => 0.9,
        spot             => 99,
        r_rate           => 0.1,
        q_rate           => 0.2,
        premium_adjusted => undef
    );
    throws_ok { get_ATM_strike_for_spot_delta(\%args) } qr/ is undef/, 'throws exception when args is undef';
    $args{premium_adjusted} = 1;
    lives_ok { get_ATM_strike_for_spot_delta(\%args) } 'can calculate ATM strike for premium adjusted delta';
    $args{premium_adjusted} = 0;
    lives_ok { get_ATM_strike_for_spot_delta(\%args) } 'can calculate ATM strike for non premium adjusted delta';
};

subtest get_moneyness_for_strike => sub {
    plan tests => 3;
    my %args = (
        strike => 100,
        spot   => undef
    );
    throws_ok { get_moneyness_for_strike(\%args) } qr/spot is undef/, 'throws exception when args is undef';
    $args{spot} = 99;
    my $moneyness;
    lives_ok { $moneyness = get_moneyness_for_strike(\%args) } 'can calculate moneyness point for a given strike and spot';
    is(floor($moneyness), 101, 'correct moneyness calculation');
};

subtest get_strike_for_moneyness => sub {
    plan tests => 3;
    my %args = (
        moneyness => 100,
        spot      => undef
    );
    throws_ok { get_strike_for_moneyness(\%args) } qr/spot is not defined/, 'throws exception when args is undef';
    $args{spot} = 99;
    my $strike;
    lives_ok { $strike = get_strike_for_moneyness(\%args) } 'can calculate strike for a given spot and moneyness';
    is($strike, 99, 'correct strike calculation');
};

subtest get_2vol_butterfly => sub {
    plan tests => 5;

    my $nonconverted = get_2vol_butterfly(undef, undef, undef, undef, undef, 25, undef, undef, undef, 'anything but 1_vol');
    cmp_ok($nonconverted, '==', 25, "Didn't ask to convert to 1_vol.");

    my $expected_butterfly = {
        'premium_adjusted'     => 0.00255,
        'non_premium_adjusted' => 0.00253,
    };
    my $data = {
        interest_rate => 0.035,
        dividend_rate => 0.02,
        ATM           => 0.14,
        RR            => -0.01,
        BF            => 0.0024,
    };
    my $S   = 104.7;
    my $tiy = 1 / 365;
    my $premium_adjusted_bf;
    lives_ok {
        $premium_adjusted_bf = sprintf(
            "%.5f",
            get_2vol_butterfly(
                $S, $tiy, 0.25, $data->{'ATM'}, $data->{'RR'}, $data->{'BF'},
                $data->{interest_rate},
                $data->{dividend_rate},
                1, '1_vol'
            ));
    }
    'Can get equivalent butterfly from premiumd adjused delta';
    is($premium_adjusted_bf, $expected_butterfly->{premium_adjusted}, 'correct premium_adjusted butterfly');

    my $non_premium_adjusted_bf;
    lives_ok {
        $non_premium_adjusted_bf = sprintf(
            "%.5f",
            get_2vol_butterfly(
                $S, $tiy, 0.25, $data->{'ATM'}, $data->{'RR'}, $data->{'BF'},
                $data->{interest_rate},
                $data->{dividend_rate},
                0, '1_vol'
            ));
    }
    'Can get equivalent butterfly from premiumd adjused delta';

    is($non_premium_adjusted_bf, $expected_butterfly->{non_premium_adjusted}, 'correct non_premium_adjusted butterfly');
};

subtest 'get_2vol_butterfly castagna' => sub {
    plan tests => 2;

    my $spot          = 102.65;
    my $time_in_years = 183 / 365;
    my $r             = (1 - 0.9949767) / (0.9949767 * $time_in_years);
    my $d             = (1 - 0.98356851) / (0.98356851 * $time_in_years);
    my $vol_atm       = 0.1195;
    my $vol_rr        = -0.047;
    my $vol_vwb       = 0.0012;

    my $equivalent_vwb_expected = 0.5116;

    my $equivalent_bf_non_premium_adjusted;
    lives_ok {
        $equivalent_bf_non_premium_adjusted = get_2vol_butterfly($spot, $time_in_years, 0.25, $vol_atm, $vol_rr, $vol_vwb, $r, $d, 1, '1_vol');
    }
    'can calculate non_premium_adjusted butterfly';

    is(sprintf("%.4f", $equivalent_bf_non_premium_adjusted * 100),
        $equivalent_vwb_expected, "Equivalent vega-weighted butterfly is $equivalent_vwb_expected %.");
};

subtest get_1vol_butterfly => sub {
    plan tests => 4;

    my $nonconverted = get_1vol_butterfly({
        bf_1vol  => 25,
        bf_style => 'anything but 1_vol'
    });
    cmp_ok($nonconverted, '==', 25, "Didn't ask to convert to 1_vol.");

    my %args = (
        spot             => 100,
        tiy              => 1,
        delta            => 0.5,
        call_vol         => 0.11,
        put_vol          => 0.101,
        atm_vol          => 0.10,
        r                => 0.1,
        q                => 0.1,
        premium_adjusted => 1,
        bf_style         => '2_vol'
    );
    my $onevol_butterfly;
    lives_ok { $onevol_butterfly = get_1vol_butterfly(\%args) } 'can calculate 1vol butterfly with bf_style = 2vol';
    is($onevol_butterfly, 0.0046, 'correct value of 1vol butterfly');
    $args{bf_style} = '1vol';
    lives_ok { get_1vol_butterfly(\%args) } 'can calculate 1vol butterfly with bf_style = 1vol';
};

# The following sets of tests need time to be mocked.
set_absolute_time('2011-08-15T00:00:00Z');

# We are going to test 2 surfaces, defined in
# _sample_surface at the bottom of this script.

# Market sample data
my $expected_strike_delta = {
    1 => {
        premium_adjusted => {
            K_25P => 104.23,
            K_ATM => 104.77,
            K_25C => 105.28
        },
        non_premium_adjusted => {
            K_25P => 104.23,
            K_ATM => 104.78,
            K_25C => 105.29
        },
        interest_rate => 0.035,
        dividend_rate => 0.02,
    },
    7 => {
        premium_adjusted => {
            K_25P => 103.59,
            K_ATM => 104.79,
            K_25C => 105.89
        },
        non_premium_adjusted => {
            K_25P => 103.60,
            K_ATM => 104.81,
            K_25C => 105.90
        },
        interest_rate => 0.0355,
        dividend_rate => 0.021,
    },
    14 => {
        premium_adjusted => {
            K_25P => 103.15,
            K_ATM => 104.80,
            K_25C => 106.30
        },
        non_premium_adjusted => {
            K_25P => 103.18,
            K_ATM => 104.85,
            K_25C => 106.32
        },
        interest_rate => 0.036,
        dividend_rate => 0.0215,
    },
    30 => {
        premium_adjusted => {
            K_25P => 102.37,
            K_ATM => 104.84,
            K_25C => 107.00
        },
        non_premium_adjusted => {
            K_25P => 102.43,
            K_ATM => 104.95,
            K_25C => 107.04
        },
        interest_rate => 0.0365,
        dividend_rate => 0.022,
    },
    60 => {
        premium_adjusted => {
            K_25P => 101.44,
            K_ATM => 104.91,
            K_25C => 107.96
        },
        non_premium_adjusted => {
            K_25P => 101.57,
            K_ATM => 105.12,
            K_25C => 108.04
        },
        interest_rate => 0.037,
        dividend_rate => 0.023,
    },
    91 => {
        premium_adjusted => {
            K_25P => 100.75,
            K_ATM => 104.98,
            K_25C => 108.69
        },
        non_premium_adjusted => {
            K_25P => 100.95,
            K_ATM => 105.29,
            K_25C => 108.81
        },
        interest_rate => 0.038,
        dividend_rate => 0.024,
    },
    182 => {
        premium_adjusted => {
            K_25P => 99.29,
            K_ATM => 105.20,
            K_25C => 110.42
        },
        non_premium_adjusted => {
            K_25P => 99.71,
            K_ATM => 105.81,
            K_25C => 110.63
        },
        interest_rate => 0.039,
        dividend_rate => 0.025,
    },
    273 => {
        premium_adjusted => {
            K_25P => 98.41,
            K_ATM => 105.45,
            K_25C => 111.63
        },
        non_premium_adjusted => {
            K_25P => 99.02,
            K_ATM => 106.30,
            K_25C => 111.93
        },
        interest_rate => 0.04,
        dividend_rate => 0.026,
    },
    365 => {
        premium_adjusted => {
            K_25P => 97.73,
            K_ATM => 105.74,
            K_25C => 112.78
        },
        non_premium_adjusted => {
            K_25P => 98.55,
            K_ATM => 106.86,
            K_25C => 113.16
        },
        interest_rate => 0.0415,
        dividend_rate => 0.027,
    },

};

subtest 'Premium adjusted delta.' => sub {
    my @expiries = keys %{$expected_strike_delta};

    plan tests => scalar(@expiries) * 14;

    my $market_data = {
        1 => {
            interest_rate => 0.035,
            dividend_rate => 0.02,
        },
        7 => {
            interest_rate => 0.0355,
            dividend_rate => 0.021,
        },
        14 => {
            interest_rate => 0.036,
            dividend_rate => 0.0215,
        },
        30 => {
            interest_rate => 0.0365,
            dividend_rate => 0.022,
        },
        60 => {
            interest_rate => 0.037,
            dividend_rate => 0.023,
        },
        91 => {
            interest_rate => 0.038,
            dividend_rate => 0.024,
        },
        182 => {
            interest_rate => 0.039,
            dividend_rate => 0.025,
        },
        273 => {
            interest_rate => 0.04,
            dividend_rate => 0.026,
        },
        365 => {
            interest_rate => 0.0415,
            dividend_rate => 0.027,
        },
    };

    my $S = 104.77;

    foreach my $days_to_expiry (@expiries) {

        my $term = ($days_to_expiry eq 'ON') ? 1 : $days_to_expiry;
        my $time_in_years = $term / 365;

        my $r = $market_data->{$days_to_expiry}->{interest_rate};
        my $d = $market_data->{$days_to_expiry}->{dividend_rate};

        # Test if we are getting the correct strike for spot delta with premium adjusted
        my $vol_surface_delta_premium_adjusted = _sample_surface('premium_adjusted');

        my ($call_vol_premium_adjusted, $atm_vol_premium_adjusted, $put_vol_premium_adjusted);
        lives_ok {
            $call_vol_premium_adjusted = $vol_surface_delta_premium_adjusted->{$days_to_expiry}->{smile}->{25};
            $atm_vol_premium_adjusted  = $vol_surface_delta_premium_adjusted->{$days_to_expiry}->{smile}->{50};
            $put_vol_premium_adjusted  = $vol_surface_delta_premium_adjusted->{$days_to_expiry}->{smile}->{75};
        }
        'Can get call,put and ATM vol from the premium adjusted surface';

        my ($ATM_strike_premium_adjusted, $call_strike_premium_adjusted, $put_strike_premium_adjusted);
        lives_ok {
            $ATM_strike_premium_adjusted = sprintf(
                "%.2f",
                get_ATM_strike_for_spot_delta({
                        atm_vol          => $atm_vol_premium_adjusted,
                        t                => $time_in_years,
                        r_rate           => $r,
                        q_rate           => $d,
                        spot             => $S,
                        premium_adjusted => 1
                    }));
        }
        'Can get ATM strike from premium adjusted delta';

        lives_ok {
            $call_strike_premium_adjusted = sprintf(
                "%.2f",
                get_strike_for_spot_delta({
                        delta            => 0.25,
                        option_type      => 'VANILLA_CALL',
                        atm_vol          => $call_vol_premium_adjusted,
                        t                => $time_in_years,
                        r_rate           => $r,
                        q_rate           => $d,
                        spot             => $S,
                        premium_adjusted => 1
                    }));
        }
        'Can get call strike from premium adjusted delta ';

        lives_ok {
            $put_strike_premium_adjusted = sprintf(
                "%.2f",
                get_strike_for_spot_delta({
                        delta            => 0.25,
                        option_type      => 'VANILLA_PUT',
                        atm_vol          => $put_vol_premium_adjusted,
                        t                => $time_in_years,
                        r_rate           => $r,
                        q_rate           => $d,
                        spot             => $S,
                        premium_adjusted => 1
                    }));
        }
        'Can get put strike from premium adjusted delta';

        # test for the strike
        cmp_ok($ATM_strike_premium_adjusted, '==', $expected_strike_delta->{$days_to_expiry}->{premium_adjusted}->{K_ATM},
            "For $days_to_expiry days , the ATM strike from premium adjusted delta is $expected_strike_delta->{$days_to_expiry}->{premium_adjusted}->{K_ATM} and we are getting $ATM_strike_premium_adjusted"
        );

        cmp_ok($call_strike_premium_adjusted, '==', $expected_strike_delta->{$days_to_expiry}->{premium_adjusted}->{K_25C},
            "For $days_to_expiry days , the call strike from premium adjusted delta is $expected_strike_delta->{$days_to_expiry}->{premium_adjusted}->{K_25C} and we are getting $call_strike_premium_adjusted"
        );

        cmp_ok($put_strike_premium_adjusted, '==', $expected_strike_delta->{$days_to_expiry}->{premium_adjusted}->{K_25P},
            "For $days_to_expiry days , the put strike from premium adjusted delta is $expected_strike_delta->{$days_to_expiry}->{premium_adjusted}->{K_25P} and we are getting $put_strike_premium_adjusted"
        );

        # Test if we are getting the correct strike for spot delta with non premium adjusted
        my $vol_surface_delta_non_premium_adjusted = _sample_surface('non_premium_adjusted');

        my ($call_vol_non_premium_adjusted, $atm_vol_non_premium_adjusted, $put_vol_non_premium_adjusted);
        lives_ok {
            $call_vol_non_premium_adjusted = $vol_surface_delta_non_premium_adjusted->{$days_to_expiry}->{smile}->{25};
            $atm_vol_non_premium_adjusted  = $vol_surface_delta_non_premium_adjusted->{$days_to_expiry}->{smile}->{50};
            $put_vol_non_premium_adjusted  = $vol_surface_delta_non_premium_adjusted->{$days_to_expiry}->{smile}->{75};
        }
        'Can get call,put and ATM vol from the non premium adjusted surface';

        my ($ATM_strike_non_premium_adjusted, $call_strike_non_premium_adjusted, $put_strike_non_premium_adjusted);
        lives_ok {
            $ATM_strike_non_premium_adjusted = sprintf(
                "%.2f",
                get_ATM_strike_for_spot_delta({
                        atm_vol          => $atm_vol_non_premium_adjusted,
                        t                => $time_in_years,
                        r_rate           => $r,
                        q_rate           => $d,
                        spot             => $S,
                        premium_adjusted => 0
                    }));
        }
        'Can get ATM strike from non premium adjusted delta';

        lives_ok {
            $call_strike_non_premium_adjusted = sprintf(
                "%.2f",
                get_strike_for_spot_delta({
                        delta            => 0.25,
                        option_type      => 'VANILLA_CALL',
                        atm_vol          => $call_vol_non_premium_adjusted,
                        t                => $time_in_years,
                        r_rate           => $r,
                        q_rate           => $d,
                        spot             => $S,
                        premium_adjusted => 0
                    }));
        }
        'Can get call strike from non premium adjusted delta ';

        lives_ok {
            $put_strike_non_premium_adjusted = sprintf(
                "%.2f",
                get_strike_for_spot_delta({
                        delta            => 0.25,
                        option_type      => 'VANILLA_PUT',
                        atm_vol          => $put_vol_non_premium_adjusted,
                        t                => $time_in_years,
                        r_rate           => $r,
                        q_rate           => $d,
                        spot             => $S,
                        premium_adjusted => 0
                    }));
        }
        'Can get put strike from premium adjusted delta';

        # test for the strike
        cmp_ok($ATM_strike_non_premium_adjusted, '==', $expected_strike_delta->{$days_to_expiry}->{non_premium_adjusted}->{K_ATM},
            "For $days_to_expiry days , the ATM strike from non premium adjusted delta is $expected_strike_delta->{$days_to_expiry}->{non_premium_adjusted}->{K_ATM} and we are getting $ATM_strike_non_premium_adjusted"
        );

        cmp_ok($call_strike_non_premium_adjusted, '==', $expected_strike_delta->{$days_to_expiry}->{non_premium_adjusted}->{K_25C},
            "For $days_to_expiry days , the call strike from non premium adjusted delta is $expected_strike_delta->{$days_to_expiry}->{non_premium_adjusted}->{K_25C} and we are getting $call_strike_non_premium_adjusted"
        );

        cmp_ok($put_strike_non_premium_adjusted, '==', $expected_strike_delta->{$days_to_expiry}->{non_premium_adjusted}->{K_25P},
            "For $days_to_expiry days , the put strike from non premium adjusted delta is $expected_strike_delta->{$days_to_expiry}->{non_premium_adjusted}->{K_25P} and we are getting $put_strike_non_premium_adjusted"
        );
    }
};

subtest 'get_strike_for_spot_delta' => sub {

    plan tests => 2;

    my $delta         = 0.25;
    my $option_type   = 'VANILLA_PUT';
    my $sigma         = 0.1025;
    my $time_in_years = 182 / 365;
    my $r             = (1 - 0.99482) / (0.99482 * $time_in_years);
    my $d             = (1 - 0.98508) / (0.98508 * $time_in_years);
    my $S             = 103.00;

    my $strike = sprintf "%.4f",
        get_strike_for_spot_delta({
            delta            => $delta,
            option_type      => $option_type,
            atm_vol          => $sigma,
            t                => $time_in_years,
            r_rate           => $r,
            q_rate           => $d,
            spot             => $S,
            premium_adjusted => 0
        });
    my $strike_pa = sprintf "%.4f",
        get_strike_for_spot_delta({
            delta            => $delta,
            option_type      => $option_type,
            atm_vol          => $sigma,
            t                => $time_in_years,
            r_rate           => $r,
            q_rate           => $d,
            spot             => $S,
            premium_adjusted => 1
        });

    my $strike_expected = 97.4614;
    is($strike, $strike_expected, "Strike is $strike_expected, if premium is in JPY.");

    my $strike_pa_expected = 97.2213;
    is($strike_pa, $strike_pa_expected, "Strike is $strike_pa_expected, if premium is in USD %.");
};

restore_time();

sub _sample_surface {
    my $which = shift;

    my %surfaces = (
        premium_adjusted => {
            1 => {
                smile => {
                    25 => 0.137546,
                    50 => 0.14,
                    75 => 0.147546
                },
                tenor => 'ON'
            },
            7 => {
                smile => {
                    25 => 0.110842,
                    50 => 0.115,
                    75 => 0.124642
                }
            },
            14 => {
                smile => {
                    25 => 0.105571,
                    50 => 0.111,
                    75 => 0.122271
                }
            },
            30 => {
                smile => {
                    25 => 0.102748,
                    50 => 0.111,
                    75 => 0.126548
                }
            },
            60 => {
                smile => {
                    25 => 0.101492,
                    50 => 0.1105,
                    75 => 0.127492
                }
            },
            91 => {
                smile => {
                    25 => 0.0993305,
                    50 => 0.109,
                    75 => 0.12783
                }
            },
            182 => {
                smile => {
                    25 => 0.096729,
                    50 => 0.107,
                    75 => 0.129829
                }
            },
            273 => {
                smile => {
                    25 => 0.092728,
                    50 => 0.104,
                    75 => 0.128828
                }
            },
            365 => {
                smile => {
                    25 => 0.09047,
                    50 => 0.1025,
                    75 => 0.12947
                }
            },
        },
        non_premium_adjusted => {
            1 => {
                smile => {
                    25 => 0.137532,
                    50 => 0.14,
                    75 => 0.147532
                },
                tenor => 'ON'
            },
            7 => {
                smile => {
                    25 => 0.1108,
                    50 => 0.115,
                    75 => 0.1246
                }
            },
            14 => {
                smile => {
                    25 => 0.105502,
                    50 => 0.111,
                    75 => 0.122202
                }
            },
            30 => {
                smile => {
                    25 => 0.102605,
                    50 => 0.111,
                    75 => 0.126405
                }
            },
            60 => {
                smile => {
                    25 => 0.10127,
                    50 => 0.1105,
                    75 => 0.12727
                }
            },
            91 => {
                smile => {
                    25 => 0.099031,
                    50 => 0.109,
                    75 => 0.127531
                }
            },
            182 => {
                smile => {
                    25 => 0.096216,
                    50 => 0.107,
                    75 => 0.129316
                }
            },
            273 => {
                smile => {
                    25 => 0.092066,
                    50 => 0.104,
                    75 => 0.128166
                }
            },
            365 => {
                smile => {
                    25 => 0.0896504,
                    50 => 0.1025,
                    75 => 0.12865
                }
            },
        },
    );

    return $surfaces{$which};
}

1;
