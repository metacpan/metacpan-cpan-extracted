# VolSurface::Utils
[![Build Status](https://travis-ci.org/binary-com/perl-VolSurface-Utils.svg?branch=master)](https://travis-ci.org/binary-com/perl-VolSurface-Utils) 
[![codecov](https://codecov.io/gh/binary-com/perl-VolSurface-Utils/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-VolSurface-Utils)

A class that handles several volatility related methods

#### SYNOPSIS

A class that handles several volatility related methods such as gets strikes from a certain delta point, gets delta from a certain vol point etc.

use VolSurface::Utils;

my $delta = get_delta_for_strike({ strike => $strike, atm_vol => $atm_vol, t => $t, spot => $spot, r_rate =>$r_rate, q_rate => $q_rate, premium_adjusted => $premium_adjusted });


#### INSTALLATION



To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

#### SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc VolSurface::Utils

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=VolSurface-Utils

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/VolSurface-Utils

    CPAN Ratings
        http://cpanratings.perl.org/d/VolSurface-Utils

    Search CPAN
        http://search.cpan.org/dist/VolSurface-Utils/


i####COPYRIGHT

Copyright (C) 2015 binary.com

