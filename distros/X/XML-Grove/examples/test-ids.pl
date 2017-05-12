#
# $Id: test-ids.pl,v 1.1 1999/05/26 15:42:16 kmacleod Exp $
#

# This example parses each doc on the command line and prints all of
# the IDs found in the doc, with their Perl hash references

use XML::Parser;
use XML::Parser::Grove;
use XML::Grove;
use XML::Grove::IDs;

my $doc;

my $id_maker = new XML::Grove::IDs;

foreach $doc (@ARGV) {
    print "---- $doc ----\n";

    my $parser = XML::Parser->new(Style => 'grove');
    $parser->parsefile ($doc);
    my $grove = $parser->{Grove};

    my $ids = $grove->get_ids;
    my $id;
    foreach $id (sort keys %$ids) {
	# prints the id and the hash reference to the element, not
	# pretty but this is just a test.
	# printing paths would be cool.
	print "$id - $ids->{$id}\n";
    }
}
