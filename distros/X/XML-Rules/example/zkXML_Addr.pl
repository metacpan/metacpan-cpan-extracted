use strict;
use IO::Handle;
use Text::CSV_XS;
use XML::Rules;

my $csv = Text::CSV_XS->new ({binary => 1});
my $xml = XML::Rules->new(rules=>[]);

my $headers = $csv->getline(\*DATA) or die "The file is not CSV!\n";

print "<ADDRESSES>\n";
while (my $row = $csv->getline(\*DATA)) {
	my @data;
	for my $i (0 .. $#$headers) {
		push @data, {name => $headers->[$i], value => $row->[$i]};
	}
	print '  ', $xml->ToXML(struct => {field => \@data}, 0, '  ', '  '), "\n";
}
print "</ADDRESSES>\n";


__END__
First,Last,City
John,Doe,San Francisco
Jane,Johnson,New York City
