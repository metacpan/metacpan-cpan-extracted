package cli::numbers::random;

use 5.014;
use strict;
use warnings;

=head1 NAME

cli::numbers::random - CLIs for generating random numbers.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

	This modules provides some CLI as follows: 

	  1. saikoro -- A uniform random number generator
	  2. boxmuller -- A Gaussian random number generator
	  3. cauchydist -- cf. the Cauchy distribution.

     The rest are the online help manuals are only in Japanese.
	  4. poisson  -- for the Poisson distribution 
	  5. randexp  -- for the exponential distribution 
	  6. binom  -- for binomial distribution.

	You can refer to how to use them by --help as follows. 
	    saikoro --help
	    boxmuller --help 
	   or 
		binom --help



=head1 AUTHOR

"Toshiyuki Shimono", C<< <bin4tsv at gmail.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2018 "Toshiyuki Shimono".

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut

1; # End of cli::numbers::random
