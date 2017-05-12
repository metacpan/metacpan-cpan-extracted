use strict;
use XML::Rules;

# Open output file
print "Debug: 6, open output file\n";
my $outfile = "parsedxml.txt";
open(OUT_FILE, '>', $outfile);

my $counter = 0;
my $parser = XML::Rules->new(
	rules => [
		_default => '',
		attribute => 'as array',
		material => sub {
			my $matnum = $_[1]->{value};
			foreach my $attr (@{$_[1]->{attribute}}) {
				print OUT_FILE "|$matnum|,|$attr->{value}|,|$attr->{_content}|\n";
			}

			$counter += 1;
			if ($counter % 100 == 0) {
				print "Completed $counter rows\n";
			}

			return;
		}
	],
	stripspaces => 7,
);


# Now, begin parsing the file
# Parse called handler for material - see below
my $counter = 1;
print "Debug: 7, Parse the input file\n";
#$parser->parsefile( "/XMLTwig/Data/extcatalog.xml");
$parser->parse(\*DATA);
print "Done: Completed $counter rows\n";

print "Closing OUT_FILE\n";
# close files
close(OUT_FILE);
print "OUT_FILE closed\n";
print "Exiting\n";
exit;
__DATA__
<root>
	<material value="12">
		<attribute value="one">blah blah</attribute>
		<attribute value="two">hello world</attribute>
	</material>
	<material value="99">
		<attribute value="three">nejneobhospodarovavatelnejsimi</attribute>
	</material>
</root>
