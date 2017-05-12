# NAME

[![Build Status](https://travis-ci.org/binary-com/perl-TimeSeries-AdaptiveFilter.svg?branch=master)](https://travis-ci.org/binary-com/perl-TimeSeries-AdaptiveFilter)
[![codecov](https://codecov.io/gh/binary-com/perl-TimeSeries-AdaptiveFilter/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-TimeSeries-AdaptiveFilter)

TimeSeries::AdaptiveFilter - Adaptive filter for data stream with possible outliers

# VERSION

Version 0.04

# STATUS

# SYNOPSYS

    use TimeSeries::AdaptiveFilter qw/filter/;

    # creation with defaults
    my $filter = filter();

    # create filter with tuned parameters
    my $filter = filter({
      floor             => 6
      cap               => 0.2,
      lookback_capacity => 20,
      lookback_period   => 4,
      decay_speeds      => [0.03, 0.01, 0.003],
      build_up_count    => 5,
      reject_criterium  => 4,
    });

    # usage
    my $now = time;
    $filter->($now, 100.002);        # returns true, i.e. all data is valid on learning period
    $filter->($now + 1, 100.001);    # returns true
    ...                              # it learns form sample of 60 seconds
    $filter->($now + 60, 100.005);   # returns true
    $filter->($now + 61, 99.9995);   # returns true, as value does not differs much
    $filter->($now + 62, 10_0000);   # returns false, outlier data
    $filter->($now + 63, 10.0001);   # returns false, outlier data
    $filter->($now + 64, 100.011);   # returns true, even if the sample is oulier, because
                                     # the filter rejected too much values, and has to
                                     # re-adapt to time seria again

# DESCRIPTION

For the details of underlying mathematical model of the filter, configurable paramters
and their usage, please, look at the shipped `doc` folder.
