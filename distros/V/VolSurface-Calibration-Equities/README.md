### VolSurface::Calibration::Equities

[![Build Status](https://travis-ci.org/binary-com/perl-VolSurface-Calibration-Equities.svg?branch=master)](https://travis-ci.org/binary-com/perl-VolSurface-Calibration-Equities)
[![codecov](https://codecov.io/gh/binary-com/perl-VolSurface-Calibration-Equities/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-VolSurface-Calibration-Equities)

This repository is [Binary.com](https://www.Binary.com)'s equities volatility calibration - a variant of standard SABR model. This assumes that the input volatility surface is in moneyness terms, with a matrix of moneyness and tenor defined. 

Basically a Volatility Surface Calibration algorithm tries to check a Vol-Surface to make sure it satisfies some basic requirements. If not, it will change the surface to make it a valid VolSurface - satisfying arbitrage free prices across tenors and strikes. The standard SABR (stochastic alpha, beta, rho) model is used to estimate implied volatility of an instrument in the derivatives market. It is one of the most popular models in the industry, represented by:

```

σ_impl= α x log⁡(F_0⁄K)/D(ζ) x  {1+[(2γ_2-γ_(1 )^2+1⁄(F_mid^2 ))/24 x   ((σ_0 C(F_mid ))/α)^2+ (ργ_1)/4 x  (σ_0 C((F_mid ))/α+ (2-3ρ^2)/24]  x ε }

```
The above equation basically expresses implied volatility as some sort of moneyness function (the alpha x log(F/K)D(...) part). This term is adjusted by a factor in the square brackets and then added back. In our variant of the standard SABR approach, we modify the terms in the square brackets. This calibration approach is based upon modeling the term structure of ATM volatility and Skew using exponential functions, as it is widely observed that ATM vols term structure or skew term structure is mostly convex. We have observed that this variant results in a more consistent option prices.

For optimization, we use a form of the Downhill Simplex Method or Nelder-Mead (available as the R function optim). 

### Documentation

Further details of the calibration model is available in MS Word and pdf formats inside 'documentation' directory as below:

[MS Word Format](documentation/Binary's_equities_volatility_calibration.docx)

[PDF Format](documentation/Binary's_equities_volatility_calibration.pdf)

### Example

Here is an example on how to call this module to get calibration parameters for a Volatility Surface.

```

use VolSurface::Calibration::Equities;

my $vol_surface = { 7  => { smile => { 90 => 0.1, 100 => 0.09, 110 => 0.2 } },
                    31 => { smile => { 90 => 0.2, 100 => 0.1 , 110 => 0.3 } },
                    61 => { smile => { 90 => 0.3, 100 => 0.2 , 110 => 0.3 } }
                  };

my $calibrator = VolSurface::Calibration::Equities->new(
                        surface => $vol_surface, 
                        term_by_day => [7, 31, 61], 
                        smile_points => [90, 100, 110]);

my $calibration_parameters = $calibrator->compute_parameterization;


```

The result will contain *calibration error* and *calibration parameters*. The calibration error is stored in `$calibration_parameters->{calibration_error}`. 
The calibration parameters (atmvol1year, kurtosisshort, atmvolshort, kurtosislong, skewlong, skewwingL, skewshort, atmvolLong, atmWingL, atmWingR, skew1year and kurtosisgrowth)
are stored in `$calibration_parameters->{values}` in a hashmap.
As this algorithm is recursive, you can feed the result `$calibration_parameters` again into the calibrator to achieve a better calibration result.

```

$calibrator = VolSurface::Calibration::Equities->new(
                        surface => $vol_surface, 
                        term_by_day => [7, 31, 61], 
                        smile_points => [90, 100, 110],
                        parameterization => $calibration_parameters);

my $better_calibration_parameters = $calibrator->compute_parameterization;

```

Here is a sample output of `compute_parameterization`:

```

{
  'date' => '2015-10-15T02:11:08Z',
  'calibration_error' => '74.4405707998374',
  'values' => {
                'skewwingR' => '1.85252856710673',
                'atmvol1year' => '0.208269684036621',
                'kurtosisshort' => '0.77476212605903',
                'atmvolshort' => '-0.0841520078952032',
                'kurtosislong' => '-0.393354944343425',
                'skewlong' => '-0.963533070236581',
                'skewwingL' => '1.93193338213629',
                'skewshort' => '0.405037188649962',
                'atmvolLong' => '-0.252945255396345',
                'atmWingL' => '1.19267660894242',
                'atmWingR' => '1.82430685141442',
                'skew1year' => '0.302983949090027',
                'kurtosisgrowth' => '0.69108830722333'
              }
};

```
