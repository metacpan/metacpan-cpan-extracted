# -*- perl -*-

use strict;
use utf8;
use Fcntl ();

package XML::EP::Processor::EmbPerl;

sub new {
    my $proto = shift;
    my $self = (@_ == 1) ? \%{ shift() } : { @_ };
    bless($self, (ref($proto) || $proto));
}

sub Process {
    my($self, $req, $xml) = @_;

    die "Failed to create package: Producer did not set a path"
	unless $req->{'path'};
    my $package = $req->{'path'};
    $package =~ s/\./_/g;
    $package =~ s/[^\/\\a-zA-Z0-9_]//g;
    $package =~ s/[\/\\]/\:\:/g;
    $package = "XML::EP::Processor::EmbPerl::Compiled::$package";

    my $basedir = $req->{'embperl_basedir'} ||
	exists($ENV{'DOCUMENT_ROOT'}) ? $ENV{'DOCUMENT_ROOT'} : "/var/embperl";

    my $basefile = "$req->{'path'}c";
    my $exists = -f $basefile;
    if ($exists  &&  (stat _)[9] >= $req->{'path_mtime'}) {
	# Slurp in the cached file.
	require $basefile;
    } else {
	# Compile the file and try to save it
	my $source = $self->Compile($req, $xml, $package);

	local *FH;
	if (open(FH, ">$basefile~") && (print FH $source) && close(FH)) {
	    unlink $basefile;
	    rename "$basefile~", $basefile;
	}
	eval $source;
	die $@ if $@;
    }

    my $document = $package->Document();
}

sub Compile {
    my($self, $req, $xml, $package) = @_;

    $self->{'init'} = '';
    my $source = $self->ProcessNode($xml);

    $self->{'init'} =~ s/^/    /mg;
    $source =~ s/^/    /mg;

    qq[use strict;
package $package;
sub Document {
    my \$self = shift;
    my \$document = XML::DOM::Document->new();
    my \$node = \$document;
    my \$current;
    my \@nodes;
$self->{'init'}

$source
    \$document;
}
];
}

sub ProcessNode {
    my($self, $node) = @_;
    my $type = $node->getNodeType();
    if ($type == XML::DOM::ELEMENT_NODE()) {
	my $source = "push(\@nodes, \$node);\n" .
	    "\$current = \$document->createElement(" .
	    $self->QuoteString($node->getTagName()) . ");\n" .
	    "\$node->appendChild(\$current);\n" .
	    "\$node = \$current;\n";
	if (my $attr = $node->getAttributes()) {
	    for (my $i = 0;  $i < $attr->getLength();  $i++) {
		my $a = $attr->item($i);
		$source .= '$node->setAttribute(' .
		    $self->QuoteString($a->getName()) .
		    ', ' . $self->QuoteString($a->getValue()) . ");\n";
	    }
	}
	for (my $child = $node->getFirstChild();  $child;
	     $child = $child->getNextSibling()) {
	    $source .= $self->ProcessNode($child);
	}
	$source . "\$node = pop \@nodes;\n";
    } elsif ($type == XML::DOM::TEXT_NODE()) {
	my $subs = "";
	my $num = 0;
	my $source = "{ my \$__result = '';\n";

	my $text = $node->getData();
	while ($text =~ s/(.*?)\[(?:\+(.*?)\+|\-(.*?)\-)\]//) {
	    my $prefix = $1;
	    my $plus_text = $2;
	    my $minus_text = $3;
	    if ($prefix ne "") {
		$source .= "  \$__result .= " .
		    $self->QuoteString($prefix) . ";\n";
	    }
	    if ($plus_text) {
		$source .= "  \$__result .= &{sub { $plus_text }};\n";
	    } else {
		$source .= "  $minus_text;\n";
	    }
	}
	$source .
	($text eq "" ?
	 "" : "  \$__result .= " . $self->QuoteString($text). ";\n") .
	"  \$node->appendChild(\$document->createTextNode(\$__result));\n}\n";
    } elsif ($type == XML::DOM::CDATA_SECTION_NODE()) {
	'$node->appendChild($document->createCDATASection(' .
	    $self->QuoteString($node->getData()) . "));\n";
    } elsif ($type == XML::DOM::PROCESSING_INSTRUCTION_NODE()) {
	'$node->appendChild($document->createProcessingInstruction(' .
	    $self->QuoteString($node->getTarget()) . ', ' .
	    $self->QuoteString($node->getData()) . "));\n";
    } elsif ($type == XML::DOM::COMMENT_NODE()) {
	'$node->appendChild($document->createComment(' .
	    $self->QuoteString($node->getData()) . "));\n";
    } elsif ($type == XML::DOM::DOCUMENT_NODE()) {
	my $source = "";
	for (my $child = $node->getFirstChild();  $child;
	     $child = $child->getNextSibling()) {
	    $source .= $self->ProcessNode($child);
	}
	$source;
    } elsif ($type == XML::DOM::DOCUMENT_TYPE_NODE()) {
	my $source = "";
	for (my $child = $node->getFirstChild();  $child;
	     $child = $child->getNextSibling()) {
	    $source .= $self->ProcessNode($child);
	}
	$source;
    } elsif ($type == XML::DOM::NOTATION_NODE()) {
	'$document->addNotation(' .
	    $self->QuoteString($node->getName()) . ", " .
	    $self->QuoteString($node->getBase()) . ", " .
	    $self->QuoteString($node->getSysId()) . ", " .
	    $self->QuoteString($node->getPubId()) . ");\n";
    } else {
	die("Failed to compile document: Unknown node type $type (",
	    ref($node), ")");
    }
}

sub QuoteString {
    my $self = shift;  my $str = shift;
    "\"" . quotemeta($str) . "\"";
}

1;
