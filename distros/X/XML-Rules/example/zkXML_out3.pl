use strict;
use XML::Rules;

my $parser =XML::Rules->new(rules =>[]);

my @list;
while (<DATA>) {
  chomp;
  my ($m, $d) = split(' ', $_);
  push(@list, { label => $m, value => $d });
}

print $parser->ToXML(
	chart => {
		caption => 'Monthly Sales Summary',
		subcaption => 'For the year 2006',
		xAxisName => 'Month',
		yAxisName => 'Sales',
		numberPrefix => '$',
		set => \@list,
	},
	0, '  '
)

__END__
January 17400
February 19800
March 21800
April 23800
May 29600
June 27600
July 31800
August 39700
September 37800
October 21900
November 32900
December 39800
