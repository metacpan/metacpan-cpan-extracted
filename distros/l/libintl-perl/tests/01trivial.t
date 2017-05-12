# -*- perl -*-
# A trivial conversion.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use Test;

BEGIN { plan tests => 4 }

require Locale::Recode;

sub compare_internal;

my $text = 'Perl';
my $expect = [ unpack 'C*', $text ];
my $cd = Locale::Recode->new (from => 'ISO-8859-1',
							 to => 'INTERNAL');

ok !$cd->getError;

my $result = $text;
ok $cd->recode ($result) && compare_internal $expect => $result;

# Aliases!
$cd = Locale::Recode->new (from => 'lAtIn2',
						  to => 'l3');

ok !$cd->getError;

$result = $expect = $text;
ok $cd->recode ($result) && $result eq $expect;

sub compare_internal
{
	my ($bonny, $clyde) = @_;

	return unless defined $bonny;
	return unless defined $clyde;
	return unless 'ARRAY' eq ref $bonny;
	return unless 'ARRAY' eq ref $clyde;

	return unless @$bonny == @$clyde;
	
	for (my $i = 0; $i < @$bonny; ++$i) {
		return unless $bonny->[$i] == $clyde->[$i];
	}

	return 1;
}

__END__

Local Variables:
mode: perl
perl-indent-level: 4
perl-continued-statement-offset: 4
perl-continued-brace-offset: 0
perl-brace-offset: -4
perl-brace-imaginary-offset: 0
perl-label-offset: -4
tab-width: 4
End:

