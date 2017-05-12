use strict;
use warnings;

package XML::LibXML::Transformer;

use Carp;
use XML::LibXML::Enhanced qw(parse_xml_chunk);

sub new {
    my ($proto, $namespace) = @_;
    
    croak "error: namespace not defined" unless defined $namespace;
    
    my $class = ref($proto) || $proto;
    
    my $self = {
	NAMESPACE => $namespace,
    };
    
    bless $self, $class;
}

sub transform {
    my ($self, $doc, @args) = @_;
    
    # In scalar context, findnodes returns a NodeList object which
    # provides iterators, etc.  This might be worth investigating if
    # findnodes is returning a lot of nodes, and the following gives
    # poor performance.

    my @n = $doc->findnodes(
	"descendant-or-self::*[namespace-uri() = '$self->{NAMESPACE}']"
    );
    
    foreach my $n (@n) {

	my $method = $n->localname;
	
	my $r = eval {
	    $self->$method($n->toAttributeHash, $n, @args);
	};
	
	# TODO check that $method actually exists before this call...

	if ($@) {
	    croak "error: call to $method failed: $@";
	}
	
	if (defined $r) {

	    # A STRING
	    if (!ref($r)) {
		$n->replaceNode($doc->adoptNode(parse_xml_chunk($r)));
	    }

	    # A NODE
	    elsif (UNIVERSAL::isa($r, "XML::LibXML::Node")) {
		$n->replaceNode($r);
	    }

	    else {
		carp qq{warning: "$method" returned neither a node nor a string};
	    }
	}

    }
    
}

1;
