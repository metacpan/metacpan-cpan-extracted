use XML::Parser;
use XML::Parser::Grove;
use XML::Grove;
use XML::Grove::Sub;

my $doc;

my $filter = new Sub;

foreach $doc (@ARGV) {
    my $parser = XML::Parser->new(Style => 'grove');
    $parser->parsefile ($doc);
    my $grove = $parser->{Grove};

    # this sub returns all the elements with a name containing the letter `d'.
    my $sub = sub {
	my ($object) = @_;

	if (ref($object) =~ /::Element/
	    && $object->{Name} =~ /d/i) {
	    return ($object);
	}

	return ();
    };
	    
    my @matches = $grove->filter($sub);
    my $match;
    foreach $match (@matches) {
	# prints the element name of the match.
	print $match->{Name} . "\n";
    }
}
