use 5.008008;
use strict;
use warnings;

package portable::lib;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use FindBin qw($Bin);
push @portable::INC, $Bin;
push @portable::INC, "$Bin/lib" if -d "$Bin/lib";

sub import {
	my $me = shift;
	push @portable::INC, map { (my $fn = $_) =~ s(/$)(); $fn } @_;
}

1;
