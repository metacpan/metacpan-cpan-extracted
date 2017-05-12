# -*- perl -*-

use strict;
use utf8;
use Fcntl ();
use URI ();
use LWP::Simple ();
use XML::DOM ();
use XML::EP::Processor::XSLTParser ();

package XML::EP::Processor::XSLT;

sub new {
    my $proto = shift;
    my $self = (@_ == 1) ? \%{ shift() } : { @_ };
    bless($self, (ref($proto) || $proto));

}

sub Process {
    my($self, $req, $xml) = @_;

    die "Missing href attribute in stylesheet declaration"
	unless $self->{'pidata'} =~ /\bhref=\"(.*?)\"/;
    my $url = $1;
    my $base = $req->Request()->Uri();
    $url = URI::URL->new($url, $base)->abs();
    my $content = LWP::Simple::get($url)
	|| die "Failed to access stylesheet $url.\n";
    my $parser = XML::DOM::Parser->new();
    my $stylesheet = $parser->parse($content);

    my $xslt = XML::EP::Processor::XSLTParser->new('xmlDocument' => $xml,
						   'xslDocument' => $stylesheet);

    my $result = $xslt->process_project();

    # The XSLT parser returns a document fragment. We have to replace
    # the old document contents with the document fragments.
    while (my $child = $xml->getFirstChild()) {
	$xml->removeChild($child);
    }
    my $child = $result->getFirstChild();
    while ($child) {
	my $c = $child;
	$child = $c->getNextSibling();
	next if $c->getNodeType() == XML::DOM::TEXT_NODE; # Skip blanks
	$result->removeChild($c);
	$xml->appendChild($c);
    }
    $xml;
}

1;
