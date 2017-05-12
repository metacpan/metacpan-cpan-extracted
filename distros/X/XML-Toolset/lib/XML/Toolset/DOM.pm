package XML::Toolset::DOM;

use strict;
use vars qw($VERSION @ISA);

use XML::Toolset;

$VERSION = sprintf"%d.%03d", q$Revision: 1.9 $ =~ /: (\d+)\.(\d+)/;
@ISA = ("XML::Toolset");

sub get_first_tag {
    &App::sub_entry if ($App::trace);
    my ($self, $doc, $xpath) = @_;
    my $dom = $self->doc2dom($doc);
    my $node = $xpath ? $self->_dom_get_value_node($dom, $xpath) : $dom;
    my ($child_node, $node_type_name, $first_tag);
    my $child_nodes = $node->getChildNodes();
    my $length = $child_nodes->getLength();
    for (my $i = 0; $i < $length; $i++) {
        $child_node = $child_nodes->item($i);
        $node_type_name = $self->node_type_name($child_node->getNodeType());
        if ($node_type_name eq "ELEMENT_NODE") {
            $first_tag = $child_node->getNodeName();
            last;
        }
    }
    &App::sub_exit($first_tag) if ($App::trace);
    return($first_tag);
}

sub get_value {
    &App::sub_entry if ($App::trace);
    my ($self, $doc, $xpath) = @_;
    my $dom = $self->doc2dom($doc);
    my $node = $self->_dom_get_value_node($dom, $xpath);
    my $value = $node ? $node->getNodeValue() : undef;
    &App::sub_exit($value) if ($App::trace);
    return($value);
}

sub set_value {
    &App::sub_entry if ($App::trace);
    my ($self, $doc, $xpath, $value) = @_;
    my $dom = $self->doc2dom($doc);
    # print "set_value($doc, $xpath, $value) dom=[$dom]\n";
    my ($node);
    eval {
        $node = $self->_dom_get_value_node($dom, $xpath, undef, 1);
    };
    if ($@) {
        print "ERROR: ", $@;
    }
    # print "set_value() node=[$node]\n";
    if ($node) {
        #$self->print_node($node);
        my $old_text_node = $node->getFirstChild();
        my $text_node = $dom->createTextNode($value);
        if ($old_text_node) {
            $node->replaceChild($text_node, $old_text_node);
        }
        else {
            $node->appendChild($text_node);
        }
    }
    &App::sub_exit() if ($App::trace);
}

sub transform {
    &App::sub_entry if ($App::trace);
    my ($self, $doc, $xform) = @_;
	die "XML::Toolset::Base::transform must be overridden. (XML::Toolset::Base is an abstract class.)";
    &App::sub_exit() if ($App::trace);
}

sub to_string {
    &App::sub_entry if ($App::trace);
    my ($self, $doc) = @_;
    my $xml = $self->doc2xml($doc);
    &App::sub_exit($xml) if ($App::trace);
    return($xml);
}

sub parse_document {
    &App::sub_entry if ($App::trace);
	my ($self, $doc) = @_;
	
    my $xml = $self->doc2xml($doc);
	$self->{parser} = undef;

	die "parse_document() called with no xml data\n" unless defined $xml and length $xml > 0;

    my $parser = $self->parser();
    my ($dom);
    eval {
        $dom = $parser->parse($xml);
    };
    if ($@) {
        $self->add_error({message => $@});
    }
	$self->{parser} = $parser;
    &App::sub_exit($dom) if ($App::trace);
	return($dom);
}

sub format_dom_to_xml {
    &App::sub_entry if ($App::trace);
	my ($self, $dom) = @_;
    my $xml = $dom->toString();
    &App::sub_exit($xml) if ($App::trace);
	return($xml);
}

sub print_node {
    &App::sub_entry if ($App::trace);
    my ($self, $node, $indent, $no_children) = @_;
    $indent ||= 0;

    my $node_type_name = $self->node_type_name($node->getNodeType());
    my $value = $node->getNodeValue();
    $value = "" if (!defined $value);
    #if ($node_type_name eq "TEXT_NODE" && $value =~ /^[ \n\t]*$/s) {
        # do nothing
    #}
    #else {
        print "", ("  " x $indent);
        $value =~ s/\n/\\n/g;
        printf("%s: %s=%s\n", $node_type_name, $node->getNodeName(), $value);
    #}

    my ($child_node);
    my $attributes = $node->getAttributes();
    if ($attributes) {
        my $length = $attributes->getLength();
        for (my $i = 0; $i < $length; $i++) {
            $child_node = $attributes->item($i);
            $self->print_node($child_node, $indent + 1, 1);
        }
    }

    #my $content = $node->getTextContent();
    #$content =~ s/\n/\\n/g;
    #if (defined $content && $content ne "") {
    #    print "", ("  " x $indent), "[$content]\n";
    #}

    if (!$no_children) {
        my ($child_nodes, $child_node);
        $child_nodes = $node->getChildNodes();
        my $length = $child_nodes->getLength();
        for (my $i = 0; $i < $length; $i++) {
            # print "node $i of $length\n";
            $child_node = $child_nodes->item($i);
            $self->print_node($child_node, $indent + 1);
        }
    }
    &App::sub_exit() if ($App::trace);
}

sub node_type_name {
    &App::sub_entry if ($App::trace);
    my ($self, $node_type) = @_;
    my %node_type_name = (
        1  => "ELEMENT_NODE",
        2  => "ATTRIBUTE_NODE",
        3  => "TEXT_NODE",
        4  => "CDATA_SECTION_NODE",
        5  => "ENTITY_REFERENCE_NODE",
        6  => "ENTITY_NODE",
        7  => "PROCESSING_INSTRUCTION_NODE",
        8  => "COMMENT_NODE",
        9  => "DOCUMENT_NODE",
        10 => "DOCUMENT_TYPE_NODE",
        11 => "DOCUMENT_FRAGMENT_NODE",
        12 => "NOTATION_NODE",
    );
    my $node_type_name = $node_type_name{$node_type} || "UNKNOWN";
    &App::sub_exit($node_type_name) if ($App::trace);
    return($node_type_name);
}

# http://www.w3.org/TR/xpath - Abbreviated Syntax
#   * para selects the para element children of the context node
#   * * selects all element children of the context node
#   * text() selects all text node children of the context node
#   * @name selects the name attribute of the context node
#   * @* selects all the attributes of the context node
#   * para[1] selects the first para child of the context node
#   * para[last()] selects the last para child of the context node
#   * */para selects all para grandchildren of the context node
#   * /doc/chapter[5]/section[2] selects the second section of the fifth chapter of the doc
#   * chapter//para selects the para element descendants of the chapter element children of the context node
#   * //para selects all the para descendants of the document root and thus selects all para elements in the same document as the context
#   * //olist/item selects all the item elements in the same document as the context node that have an olist parent
#   * . selects the context node
#   * .//para selects the para element descendants of the context node
#   * .. selects the parent of the context node
#   * ../@lang selects the lang attribute of the parent of the context node
#   * para[@type="warning"] selects all para children of the context node that have a type attribute with value warning
#   * para[@type="warning"][5] selects the fifth para child of the context node that has a type attribute with value warning
#   * para[5][@type="warning"] selects the fifth para child of the context node if that child has a type attribute with value warning
#   * chapter[title="Introduction"] selects the chapter children that have one or more title children with string-value = Introduction
#   * chapter[title] selects the chapter children of the context node that have one or more title children
#   * employee[@secretary and @assistant] selects all employee children that have both a secretary attribute and an assistant attribute
#Location Paths
#[1]     LocationPath       ::=      RelativeLocationPath    
#            | AbsoluteLocationPath  
#[2]     AbsoluteLocationPath       ::=      '/' RelativeLocationPath?   
#            | AbbreviatedAbsoluteLocationPath   
#[3]     RelativeLocationPath       ::=      Step    
#            | RelativeLocationPath '/' Step 
#            | AbbreviatedRelativeLocationPath   
#Location Steps
#[4]     Step       ::=      AxisSpecifier NodeTest Predicate*   
#            | AbbreviatedStep   
#[5]     AxisSpecifier      ::=      AxisName '::'   
#            | AbbreviatedAxisSpecifier  
#Axes
#[6]     AxisName       ::=      'ancestor'  
#            | 'ancestor-or-self'    
#            | 'attribute'   
#            | 'child'   
#            | 'descendant'  
#            | 'descendant-or-self'  
#            | 'following'   
#            | 'following-sibling'   
#            | 'namespace'   
#            | 'parent'  
#            | 'preceding'   
#            | 'preceding-sibling'   
#            | 'self'    
#A node test node() is true for any node of any type whatsoever.
#[7]     NodeTest       ::=      NameTest    
#            | NodeType '(' ')'  
#            | 'processing-instruction' '(' Literal ')'  
#Predicates
#[8]     Predicate      ::=      '[' PredicateExpr ']'   
#[9]     PredicateExpr      ::=      Expr    
#Abbreviations
#[10]    AbbreviatedAbsoluteLocationPath    ::=      '//' RelativeLocationPath   
#[11]    AbbreviatedRelativeLocationPath    ::=      RelativeLocationPath '//'
#Step    
#[12]    AbbreviatedStep    ::=      '.' 
#            | '..'  
#[13]    AbbreviatedAxisSpecifier       ::=      '@'?    
#Parentheses may be used for grouping.
#[14]    Expr       ::=      OrExpr  
#[15]    PrimaryExpr    ::=      VariableReference   
#            | '(' Expr ')'  
#            | Literal   
#            | Number    
#            | FunctionCall  
#[16]    FunctionCall       ::=      FunctionName '(' ( Argument ( ',' Argument)* )? ')'   

# This is the XML::DOM::XPath way
#sub _dom_get_value_node_std {
#    my ($self, $dom, $xpath) = @_;
#
#    my ($node);
#    my @nodes = $dom->findnodes($xpath);
#    $node = $nodes[0] if ($#nodes > -1);
#
#    return($node);
#}

# This is our own version (which also works with Xerces)
sub _dom_get_value_node {
    &App::sub_entry if ($App::trace);
    my ($self, $dom, $xpath, $context_node, $create) = @_;
    # print "_dom_get_value_node($dom, $xpath, $context_node, $create)\n";

    $context_node = $dom if ($xpath =~ s!^/!!);
    $context_node = $dom if (!$context_node);

    #$self->print_node($context_node);

    my ($node, $child_nodes, $child_node, $new_node);
    my ($i, $length, $found, $node_type_name, $nn);
    my @xpath = split(/\//, $xpath);
    $found = 0;
    foreach my $node_name (@xpath) {
        $found = 0;
        # print "_dom_get_value_node() node_name=[$node_name]\n";
        if ($node_name =~ s!^@!!) {
            $node_type_name = "ATTRIBUTE_NODE";
            $child_node = $context_node->getAttributeNode($node_name);
            if ($child_node) {
                $found = 1;
                $context_node = $child_node;
            }
            # print "_dom_get_value_node() [attrib] node_name=[$node_name] node=[$child_node]\n";
        }
        else {
            $node_type_name = "ELEMENT_NODE";
            # print "_dom_get_value_node(a) [element] node_name=[$node_name]\n";
            $child_nodes = $context_node->getChildNodes();
            # print "_dom_get_value_node(b) [element] node_name=[$node_name]\n";
            $length = $child_nodes->getLength();
            # print "_dom_get_value_node(c) [element] node_name=[$node_name] children=$length\n";
            for ($i = 0; $i < $length; $i++) {
                # print "_dom_get_value_node(d$i) [element] node_name=[$node_name]\n";
                $child_node = $child_nodes->item($i);
                $nn = $child_node->getNodeName();
                # print "_dom_get_value_node(e$i) [element] node_name=[$node_name] vs [$nn]\n";
                if ($nn eq $node_name) {
                    # print "_dom_get_value_node(f$i) [element] node_name=[$node_name]\n";
                    $found = 1;
                    $context_node = $child_node;
                    # print "Found Node [$node_name]\n";
                    last;
                }
            }
            # print "_dom_get_value_node(g) [element] node_name=[$node_name]\n";
        }
        # print "_dom_get_value_node(h) found=[$found] create=[$create]\n";
        if (!$found) {
            if ($create) {
                if ($node_type_name eq "ELEMENT_NODE") {
                    # print "_dom_get_value_node(i) element : 1\n";
                    $new_node = $dom->createElement($node_name);
                    # print "_dom_get_value_node(i) element : 2 : context_node=[$context_node] new_node=[$new_node]\n";
                    $context_node->appendChild($new_node);
                    # print "_dom_get_value_node(i) element : 3\n";
                }
                elsif ($node_type_name eq "ATTRIBUTE_NODE") {
                    # print "_dom_get_value_node(i) attribute : 1\n";
                    $context_node->setAttribute($node_name, "");
                    # print "_dom_get_value_node(i) attribute : 2\n";
                    $new_node = $context_node->getAttributeNode($node_name);
                    # print "_dom_get_value_node(i) attribute : 3\n";
                }
                $context_node = $new_node;
                $found = 1;
            }
            else {
                last;
            }
        }
        # print "_dom_get_value_node(ENDLOOP)\n";
    }
    if ($found) {
        $node = $context_node;
    }
    # print "_dom_get_value_node() = [$node]\n";

    &App::sub_exit($node) if ($App::trace);
    return($node);
}

1;

=head1 NAME

XML::Toolset::DOM - An intermediate base class which defines methods which are shared in common between the DOM-based XML::Toolset implementations

=head1 SYNOPSIS

  package XML::Toolset::XMLDOM;
  use XML::Toolset::DOM;
  @ISA = ("XML::Toolset::DOM");
  ...

=head1 DESCRIPTION

XML::Toolset::DOM is an intermediate base class which defines methods which are
shared in common between the DOM-based XML::Toolset implementations.

=head1 AUTHOR

Stephen Adkins <spadkins@gmail.com>

=head1 COPYRIGHT

(c) 2007 Stephen Adkins, for the purpose of making it Free.
This is Free Software.  It is licensed under the same terms as Perl itself.

=cut
