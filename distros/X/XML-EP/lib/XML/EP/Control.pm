# -*- perl -*-

use strict;
use XML::DOM ();

package XML::EP::Control;

$XML::EP::Control::VERSION = '0.01';


sub new {
    my $proto = shift;
    my $self = (@_ == 1) ? \%{ shift() } : { @_ };
    bless($self, (ref($proto) || $proto));
}

sub CreatePipe {
    my $self = shift;  my $ep = shift;
    my $class = $ep->{cfg}->{Producer} || "XML::EP::Producer::File";
    $ep->Require($class);
    my $producer = $class->new();
    my $xml = $producer->Produce($ep);
    my $processors = $ep->{cfg}->{Processors} || [];
    my $formatter = $ep->{cfg}->{Formatter} || "XML::EP::Formatter::HTML";
    my $elem = $xml->getFirstChild();
    while ($elem) {
	my $pi = $elem;
	$elem = $pi->getNextSibling();
	next unless $pi->getNodeType() ==
	    XML::DOM::PROCESSING_INSTRUCTION_NODE();
	if ($pi->getTarget() eq "xmlep:processor") {
	    my $data = $pi->getData();
	    if ($data =~ /^\s*(\S+)\s*(.*)/) {
		$ep->Require($1);
		push(@$processors, $1->new('pidata' => $2));
		$xml->removeChild($pi);
	    } else {
		die "Failed to parse processor instruction: $data";
	    }
	} elsif ($pi->getTarget() eq "xml-stylesheet") {
	    my $data = $pi->getData();
	    require XML::EP::Processor::XSLT;
	    push(@$processors,
	         XML::EP::Processor::XSLT->new('pidata' => $data));
	    $xml->removeChild($pi);
	} elsif ($pi->getTarget() eq "xmlep:formatter") {
	    my $data = $pi->getData();
	    if ($data =~ /^\s*(\S+)\s*(.*)/) {
		$ep->Require($1);
		$formatter = $1->new('pidata' => $2);
		$xml->removeChild($pi);
	    } else {
		die "Failed to parse formatter instruction: $data";
	    }
	}
    }
    $ep->Formatter($formatter);
    $ep->Processors($processors);
    $xml;
}


__END__
