# -*- cperl -*-
# $Id: LibXMLCompat.pm,v 2.5 2007-04-02 13:19:55 pajas Exp $

package XML::XSH2::LibXMLCompat;

use strict;
use XML::LibXML;
use XML::LibXML::Iterator;
use XML::LibXML::NodeList;
use vars qw($VERSION);

  $VERSION='2.2.8'; # VERSION TEMPLATE

sub module {
  return "XML::LibXML";
}

sub version {
  return $XML::LibXML::VERSION;
}

sub toStringUTF8 {
  my ($class,$node,$mode)=@_;
  return unless $node;
  $mode = 0 unless $mode;
  if ($class->is_document($node)) {
    return XML::LibXML::encodeToUTF8($node->getEncoding(),$node->toString($mode));
  } elsif ($class->is_namespace($node)) {
    return 'xmlns'.($node->name() ne '' ? ':' : '').
      $node->name()."='".$node->getNamespaceURI()."'";
  } elsif ($class->is_attribute($node)) {
    return $node->name()."='".$node->value()."'";
  } else {
    return $node->can('toString') ?
      $node->toString($mode) :
      $node->to_literal();
  }
}

sub new_parser {
  return XML::LibXML->new();
}

sub owner_document {
  my ($self,$node)=@_;
  if ($self->is_document($node)) {
    return $node
  } else {
    return $node->ownerDocument()
  }
}

sub doc_URI {
  my ($class,$dom)=@_;
  return $dom->URI();
}

sub doc_encoding {
  my ($class,$dom)=@_;
  return $dom->getEncoding();
}

sub set_encoding {
  my ($class,$dom,$encoding)=@_;
  return $dom->setEncoding($encoding);
}

sub xml_equal {
  my ($class,$a,$b)=@_;
  return $a->isSameNode($b);
}

sub doc_process_xinclude {
  my ($class,$parser,$doc)=@_;
  $parser->processXIncludes($doc);
}

sub init_parser {
  my ($class,$parser)=@_;
  $parser->validation(0+$XML::XSH2::Functions::VALIDATION);
  $parser->recover(0+$XML::XSH2::Functions::RECOVERING) if $parser->can('recover');
  $parser->expand_entities(0+$XML::XSH2::Functions::PARSER_EXPANDS_ENTITIES);
  $parser->keep_blanks(0+$XML::XSH2::Functions::KEEP_BLANKS);
  $parser->pedantic_parser(0+$XML::XSH2::Functions::PEDANTIC_PARSER);
  $parser->load_ext_dtd(0+$XML::XSH2::Functions::LOAD_EXT_DTD);
  $parser->complete_attributes(0+$XML::XSH2::Functions::PARSER_COMPLETES_ATTRIBUTES);
  $parser->expand_xinclude(0+$XML::XSH2::Functions::PARSER_EXPANDS_XINCLUDE);
  if ($parser->can('line_numbers')) {
    $parser->line_numbers(0+$XML::XSH2::Functions::LINE_NUMBERS);
  }
}

sub load_catalog {
  my ($class,$parser,$catalog)=@_;
  $parser->load_catalog($catalog);
}

sub parse_chunk {
  my ($class,$parser,$str)=@_;
  $class->init_parser($parser);
  return $parser->parse_xml_chunk($str);
}

sub parse_string {
  my ($class,$parser,$str)=@_;
  $class->init_parser($parser);
   return $parser->parse_string($str);
}

sub parse_html_file {
  my ($class,$parser,$file)=@_;
  $class->init_parser($parser);
  my $doc=$parser->parse_html_file($file);
  return $doc;
}

sub parse_html_fh {
  my ($class,$parser,$fh)=@_;
  $class->init_parser($parser);
  my $doc=$parser->parse_html_fh($fh);
  return $doc;
}

sub parse_html_string {
  my ($class,$parser,$file)=@_;
  $class->init_parser($parser);
  my $doc=$parser->parse_html_string($file);
  return $doc;
}

sub parse_sgml_file {
  my ($class,$parser,$file,$encoding)=@_;
  $class->init_parser($parser);
  my $doc=$parser->parse_sgml_file($file,$encoding);
  return $doc;
}

sub parse_sgml_fh {
  my ($class,$parser,$fh,$encoding)=@_;
  $class->init_parser($parser);
  my $doc=$parser->parse_sgml_fh($fh,$encoding);
  return $doc;
}

sub parse_sgml_string {
  my ($class,$parser,$fh,$encoding)=@_;
  $class->init_parser($parser);
  my $doc=$parser->parse_sgml_string($fh,$encoding);
  return $doc;
}

sub parse_fh {
  my ($class,$parser,$fh)=@_;
  $class->init_parser($parser);
  return $parser->parse_fh($fh);
}

sub parse_file {
  my ($class,$parser,$file)=@_;
  $class->init_parser($parser);
  return $parser->parse_file($file);
}

sub is_node {
  my ($class,$node)=@_;
  return ref($node) && $node->isa('XML::LibXML::Node');
}

sub is_dtd {
  my ($class,$node)=@_;
  return $node->nodeType == XML::LibXML::XML_DTD_NODE()
}

sub is_xinclude_start {
  my ($class,$node)=@_;
  return $node->nodeType == XML::LibXML::XML_XINCLUDE_START();
}

sub is_xinclude_end {
  my ($class,$node)=@_;
  return $node->nodeType == XML::LibXML::XML_XINCLUDE_END();
}

sub is_element {
  my ($class,$node)=@_;
  return $node->nodeType == XML::LibXML::XML_ELEMENT_NODE();
}

sub is_attribute {
  my ($class,$node)=@_;
  return $node->nodeType == XML::LibXML::XML_ATTRIBUTE_NODE();
}

sub is_text {
  my ($class,$node)=@_;
  return $node->nodeType == XML::LibXML::XML_TEXT_NODE();
}

sub is_text_or_cdata {
  my ($class,$node)=@_;
  return $node->nodeType == XML::LibXML::XML_TEXT_NODE() || $node->nodeType == XML::LibXML::XML_CDATA_SECTION_NODE();
}

sub is_cdata_section {
  my ($class,$node)=@_;
  return $node->nodeType == XML::LibXML::XML_CDATA_SECTION_NODE();
}


sub is_pi {
  my ($class,$node)=@_;
  return $node->nodeType == XML::LibXML::XML_PI_NODE();
}

sub is_entity_reference {
  my ($class,$node)=@_;
  return $node->nodeType == XML::LibXML::XML_ENTITY_REF_NODE();
}

sub is_document {
  my ($class,$node)=@_;
  return $node->nodeType == XML::LibXML::XML_DOCUMENT_NODE() ||
    $node->nodeType == XML::LibXML::XML_HTML_DOCUMENT_NODE();
}

sub is_document_fragment {
  my ($class,$node)=@_;
  return $node->nodeType == XML::LibXML::XML_DOCUMENT_FRAG_NODE();
}

sub is_comment {
  my ($class,$node)=@_;
  return $node->nodeType == XML::LibXML::XML_COMMENT_NODE();
}

sub is_namespace {
  my ($class,$node)=@_;
  return $node->nodeType == XML::LibXML::XML_NAMESPACE_DECL();
}

sub document_type {
  my ($class,$node)=@_;
  my $doc=$class->owner_document($node);
  if ($doc->nodeType == XML::LibXML::XML_DOCUMENT_NODE) {
    return 'xml';
  } elsif ($doc->nodeType == XML::LibXML::XML_HTML_DOCUMENT_NODE) {
    return 'html';
  } else {
    return 'unknown';
  }
}

sub has_dtd {
  my ($class,$doc)=@_;
  foreach my $node ($doc->childNodes()) {
    if ($node->nodeType == XML::LibXML::XML_DTD_NODE()) {
      return 1;
    }
  }
  return 0;
}

sub get_dtd {
  my ($class,$doc,$quiet)=@_;
  my $dtd;
  foreach my $node ($doc->childNodes()) {
    if ($node->nodeType == XML::LibXML::XML_DTD_NODE()) {
      if ($node->hasChildNodes()) {
	$dtd=$node;
      } else {
	my $str=$node->toString();
	my $name=$node->getName();
	my $public_id;
	my $system_id;
	if ($str=~/PUBLIC\s+(\S)([^\1]*\1)\s+(\S)([^\3]*)\3/) {
	  $public_id=$2;
	  $system_id=$4;
	}
	if ($str=~/SYSTEM\s+(\S)([^\1]*)\1/) {
	  $system_id=$2;
	}
	if ($system_id!~m(/)) {
	  $system_id="$1$system_id" if ($class->doc_URI($doc)=~m(^(.*/)[^/]+$));
	}
	print STDERR "loading external dtd: $system_id\n" unless $quiet;
	$dtd=XML::LibXML::Dtd->new($public_id, $system_id)
	  if $system_id ne "";
	if ($dtd) {
	  $dtd->setName($name);
	} else {
	  print STDERR "failed to load dtd: $system_id\n" unless $quiet;
	}
      }
    }
  }
  return $dtd;
}

sub clone_node {
  my ($class, $dom, $node)=@_;
  return $dom->importNode($node);
}

sub remove_node {
  my ($class,$node)=@_;
  return $node->unbindNode();
}

sub iterator {
  my ($class,$node)=@_;
  my $iter= XML::LibXML::SubTreeIterator->new( $node );
  $iter->iterator_function(\&XML::LibXML::SubTreeIterator::subtree_iterator);
  return $iter;
}


package # hide from PAUSE
    XML::LibXML::SubTreeIterator;
use strict;
use base qw(XML::LibXML::Iterator);
# (inheritance is not a real necessity here)

sub subtree_iterator {
    my $self = shift;
    my $dir  = shift;
    my $node = undef;


    if ( $dir < 0 ) {
        return undef if $self->{CURRENT}->isSameNode( $self->{FIRST} )
          and $self->{INDEX} <= 0;

        $node = $self->{CURRENT}->previousSibling;
        return $self->{CURRENT}->parentNode unless defined $node;

        while ( $node->hasChildNodes ) {
	  return undef if $node->isSameNode( $self->{FIRST} )
	    and $self->{INDEX} > 0;
            $node = $node->lastChild;
        }
    }
    else {
        return undef if $self->{CURRENT}->isSameNode( $self->{FIRST} )
          and $self->{INDEX} > 0;

        if ( $self->{CURRENT}->hasChildNodes ) {
            $node = $self->{CURRENT}->firstChild;
        }
        else {
            $node = $self->{CURRENT}->nextSibling;
            my $pnode = $self->{CURRENT}->parentNode;
            while ( not defined $node ) {
                last unless defined $pnode;
		return undef if $pnode->isSameNode( $self->{FIRST} );
                $node = $pnode->nextSibling;
                $pnode = $pnode->parentNode unless defined $node;
            }
        }
    }

    return $node;
}

{
  local $^W=0;
  eval <<'EOF';
  package # hide from PAUSE
      XML::LibXML::Namespace;
  sub parentNode {}

  package # hide from PAUSE
      XML::LibXML::NodeList;

  use overload
               '""' => \&value,
               '0+' => \&value,
               '+' => \&add,
               '-' => \&subtract,
               'bool' => \&to_boolean,
	       'fallback' => undef;

  sub add {
    if (UNIVERSAL::isa($_[1],'XML::LibXML::NodeList')) {
      if (defined($_[2])) {
	$_[2] ? XML::LibXML::NodeList->new(@{$_[1]},@{$_[0]}) :
	        XML::LibXML::NodeList->new(@{$_[0]},@{$_[1]});
      } else {
	$_[0]->append($_[1]);
	$_[0]
      }
    } else {
      $_[0]->value + $_[1]
    }
  }

  sub subtract {
    if (UNIVERSAL::isa($_[1],'XML::LibXML::NodeList')) {
      my ($plus,$minus);
      ($plus,$minus)= $_[2] ? ($_[1],$_[0]) : ($_[0],$_[1]);
      my %minus; @minus{ map $$_,@$minus } = ();
      return XML::LibXML::NodeList->new(grep !exists($minus{$$_}),@$plus);
    } else {
      $_[0]->value - $_[1]
    }
  }

  sub value {
    my $self = CORE::shift;
    my $result = join('', grep {defined $_} map { $_->string_value } @$self);
    return $result;
  }

  package # hide from PAUSE
      XML::LibXML::Literal;
  use overload
        '""' => \&value,
        '0+' => \&value,
        'cmp' => \&cmp,
        '<=>' => sub { defined($_[2]) && $_[2] ? ($_[1] <=> ${$_[0]}) : (${$_[0]} <=> $_[1]) },
        '+' => sub { ${$_[0]}+$_[1] },
        '-' => sub { defined($_[2]) && $_[2] ? $_[1]-${$_[0]} : ${$_[0]}-$_[1] },
        '*' => sub { ${$_[0]}*$_[1] },
        '**' => sub { ${$_[0]}**$_[1] },
        '/' => sub { ${$_[0]}/$_[1] },
        '%' => sub { ${$_[0]}%$_[1] },
        'x'   => sub { defined($_[2]) && $_[2] ? $_[1] x ${$_[0]} : ${$_[0]} x $_[1] },
        'fallback' => undef;


  package # hide form PAUSE
      XML::LibXML::Number;

  use overload
        '""' => \&value,
        '0+' => \&value,
        '<=>' => \&cmp,
        'cmp' => sub { defined($_[2]) && $_[2] ? ($_[1] cmp ${$_[0]}) : (${$_[0]} cmp $_[1]) },
        '+' => sub { ${$_[0]}+$_[1] },
        '-' => sub { defined($_[2]) && $_[2] ? $_[1]-${$_[0]} : ${$_[0]}-$_[1] },
        '*' => sub { ${$_[0]}*$_[1] },
        '**' => sub { defined($_[2]) && $_[2] ? $_[1]**${$_[0]} : ${$_[0]}**$_[1] },
        '/' => sub { defined($_[2]) && $_[2] ? $_[1]/${$_[0]} : ${$_[0]}/$_[1] },
        '%' => sub { defined($_[2]) && $_[2] ? $_[1] % ${$_[0]} : ${$_[0]} % $_[1] },
        'x'   => sub { defined($_[2]) && $_[2] ? $_[1] x ${$_[0]} : ${$_[0]} x $_[1] },
        'fallback' => undef;

  sub new {
     my $class = shift;
     my $number = shift;
     if ($number !~ /^\s*(-\s*)?(\d+(\.\d*)?|\.\d+)\s*$/) {
         $number = undef;
     }
     else {
         $number =~ s/\s*//g;
     }
     bless \$number, $class;
  }

EOF
  die $@ if $@;
};



1;


