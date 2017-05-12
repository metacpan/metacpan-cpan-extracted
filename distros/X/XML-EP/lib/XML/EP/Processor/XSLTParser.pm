################################################################################
#
# Perl module: XML::XSLT
#
# By Geert Josten, gjosten@sci.kun.nl
# and Egon Willighagen, egonw@sci.kun.nl
#
################################################################################

######################################################################
package XML::EP::Processor::XSLTParser;
######################################################################

use strict;
use XML::DOM;

use XML::DOM ();

use vars qw ( $_indent $_indent_incr $debug $warnings );
$_indent = 0;
$_indent_incr = 1;

sub new {
  my $proto = shift;
  my $parser = bless {@_}, (ref($proto) || $proto);
  $parser->__add_default_templates__($parser->{xslDocument})
    if $parser->{xslDocument};
  $parser;
}

sub openproject {
  my ($parser, $xmlfile, $xslfile) = @_;
  my $domParser = XML::DOM::Parser->new();
  $parser->{xslDocument} = $domParser->parsefile($xslfile);
  $parser->{xmlDocument} = $domParser->parsefile($xmlfile);
  $parser->__add_default_templates__($parser->{xslDocument});
}


sub process_project {
  my ($parser) = @_;
  $parser->{resultNode} = $parser->{xmlDocument}->createDocumentFragment();
  my $root_template = $parser->_find_template ('/');

  if ($root_template) {
    $parser->_evaluate_template (
        $root_template,		# starting template, the root template
	$parser->{xmlDocument},	# current XML node, the root
        '',			# current XML selection path, the root
        $parser->{resultNode}	# current result tree node, the root
    );

  }
  $parser->{resultNode};
}

sub print_result {
  my ($parser, $file) = @_;

  my $output = $parser->{resultNode}->toString();
  $output =~ s/\n\s*\n(\s*)\n/\n$1\n/g; # Substitute multiple empty lines by one
  $output =~ s/\/\>/ \/\>/g;            # Insert a space before all />

  if ($file) {
    print $file $output;
  } else {
    print $output;
  }
}

######################################################################

sub __add_default_templates__ {
  my $parser = shift;
  # Add the default templates for match="/" and match="*" #
  my $root_node = shift;

  my $stylesheet = $root_node->getElementsByTagName('xsl:stylesheet',0)->item(0);
  my $first_template = $stylesheet->getElementsByTagName('xsl:template',0)->item(0);

  my $root_template = $root_node->createElement('xsl:template');
  $root_template->setAttribute('match','/');
  $root_template->appendChild ($root_node->createElement('xsl:apply-templates'));
  $stylesheet->insertBefore($root_template,$first_template);

  my $any_element_template = $root_node->createElement('xsl:template');
  $any_element_template->setAttribute('match','*');
  $any_element_template->appendChild ($root_node->createElement('xsl:apply-templates'));
  $stylesheet->insertBefore($any_element_template,$first_template);
}

sub _find_template {
  my $parser = shift;
  my $current_xml_selection_path = shift;
  my $attribute_name = shift;
  $attribute_name = "match" unless defined $attribute_name;

  print " "x$_indent,"searching template for \"$current_xml_selection_path\": " if $debug;

  my $stylesheet = $parser->{xslDocument}->getElementsByTagName('xsl:stylesheet',0)->item(0);
  my $templates = $stylesheet->getElementsByTagName('xsl:template',0);

  for (my $i = ($templates->getLength - 1); $i >= 0; $i--) {
    my $template = $templates->item($i);
    my $template_attr_value = $template->getAttribute ($attribute_name);

    if (&__template_matches__ ($template_attr_value, $current_xml_selection_path)) {
      print "found #$i \"$template_attr_value\"$/" if $debug;

      return $template;
    }
  }
  
  print "no template found! $/" if $debug;
  warn ("No template matching $current_xml_selection_path found !!$/") if $debug;
  return "";
}

  sub __template_matches__ {
    my $template = shift;
    my $path = shift;
    
    if ($template ne $path) {
      if ($path =~ /\/.*(\@\*|\@\w+)$/) {
        # attribute selection #
        my $attribute = $1;
        return ($template eq "\@*" || $template eq $attribute);
      } elsif ($path =~ /\/(\*|\w+)$/) {
        # element selection #
        my $element = $1;
        return ($template eq "*" || $template eq $element);
      } else {
        return "";
      }
    } else {
      return "True";
    }
  }

sub _evaluate_template {
  my $parser = shift;
  my $template = shift;
  my $current_xml_node = shift;
  my $current_xml_selection_path = shift;
  my $current_result_node = shift;

  print " "x$_indent,"evaluating template content for \"$current_xml_selection_path\": $/" if $debug;
  $_indent += $_indent_incr;;

  foreach my $child ($template->getChildNodes) {
    my $ref = ref $child;
    print " "x$_indent,"$ref$/" if $debug;
    $_indent += $_indent_incr;

      if ($child->getNodeType == ELEMENT_NODE) {
        $parser->_evaluate_element ($child,
                                    $current_xml_node,
                                    $current_xml_selection_path,
                                    $current_result_node);
      } elsif ($child->getNodeType == TEXT_NODE) {
        $parser->_add_node($child, $current_result_node);
      } else {
        my $name = $template->getTagName;
        print " "x$_indent,"Cannot evaluate node $name of type $ref !$/" if $debug;
        warn ("evaluate-template: Dunno what to do with node of type $ref !!! ($name; $current_xml_selection_path)$/") if $warnings;
      }
    
    $_indent -= $_indent_incr;
  }

  $_indent -= $_indent_incr;
}

sub _add_node {
  my $parser = shift;
  my $node = shift;
  my $parent = shift;
  my $deep = (shift || "");
  my $owner = (shift || $parser->{'xmlDocument'});

  if ($debug) {
    print " "x$_indent,"adding (deep): " if $deep;
    print " "x$_indent,"adding (non-deep): " if !$deep;
  }

  $node = $node->cloneNode($deep);
  $node->setOwnerDocument($owner);
  $parent->appendChild($node);

  print "done$/" if $debug;
}

sub _apply_templates {
  my $parser = shift;
  my $current_xml_node = shift;
  my $current_xml_selection_path = shift;
  my $current_result_node = shift;

  print " "x$_indent,"applying templates on children of \"$current_xml_selection_path\":$/" if $debug;
  $_indent += $_indent_incr;

  foreach my $child ($current_xml_node->getChildNodes) {
    my $ref = ref $child;
    print " "x$_indent,"$ref$/" if $debug;
    $_indent += $_indent_incr;

      my $child_xml_selection_path = $child->getNodeName;
      $child_xml_selection_path = "$current_xml_selection_path/$child_xml_selection_path";

      if ($child->getNodeType == ELEMENT_NODE) {
          my $template = $parser->_find_template ($child_xml_selection_path);

          if ($template) {

              $parser->_evaluate_template ($template,
		 	                   $child,
                                           $child_xml_selection_path,
                                           $current_result_node);
          }
      } elsif ($child->getNodeType == TEXT_NODE) {
          $parser->_add_node($child, $current_result_node);
      } elsif ($child->getNodeType == DOCUMENT_TYPE_NODE) {
          # skip #
      } elsif ($child->getNodeType == COMMENT_NODE) {
          # skip #
      } else {
          print " "x$_indent,"Cannot apply templates on nodes of type $ref$/" if $debug;
          warn ("apply-templates: Dunno what to do with nodes of type $ref !!! ($child_xml_selection_path)$/") if $warnings;
      }

    $_indent -= $_indent_incr;
  }

  $_indent -= $_indent_incr;
}

sub _evaluate_element {
  my $parser = shift;
  my $xsl_node = shift;
  my $current_xml_node = shift;
  my $current_xml_selection_path = shift;
  my $current_result_node = shift;

  my $xsl_tag = $xsl_node->getTagName;
  print " "x$_indent,"evaluating element $xsl_tag for \"$current_xml_selection_path\": $/" if $debug;
  $_indent += $_indent_incr;

  if ($xsl_tag =~ /^xsl:/i) {
      if ($xsl_tag =~ /^xsl:apply-templates/i) {

          $parser->_apply_templates ($current_xml_node,
        			     $current_xml_selection_path,
                                     $current_result_node);
#      } elsif ($xsl_tag =~ /^xsl:call-template/i) {
#      } elsif ($xsl_tag =~ /^xsl:choose/i) {
#      } elsif ($xsl_tag =~ /^xsl:for-each/i) {
#      } elsif ($xsl_tag =~ /^xsl:include/i) {
#      } elsif ($xsl_tag =~ /^xsl:output/i) {
#      } elsif ($xsl_tag =~ /^xsl:processing-instruction/i) {
      } elsif ($xsl_tag =~ /^xsl:value-of/i) {
          $parser->_value_of ($xsl_node, $current_xml_node,
                              $current_xml_selection_path,
                              $current_result_node);
      } else {
          $parser->_add_and_recurse ($xsl_node, $current_xml_node,
                                     $current_xml_selection_path,
                                     $current_result_node);
      }
  } else {
      $parser->_add_and_recurse ($xsl_node, $current_xml_node,
                                 $current_xml_selection_path,
                                 $current_result_node);
  }

  $_indent -= $_indent_incr;
}

sub _add_and_recurse {
  my $parser = shift;
  my $xsl_node = shift;
  my $current_xml_node = shift;
  my $current_xml_selection_path = shift;
  my $current_result_node = shift;

  $parser->_add_node ($xsl_node, $current_result_node);
  $parser->_evaluate_template ($xsl_node,
			       $current_xml_node,
			       $current_xml_selection_path,
			       $current_result_node->getLastChild);
}

sub _value_of {
  my($parser, $xsl_node, $xml_node, $current_path, $result_node) = @_;
  my $path = $xsl_node->getAttribute('select');
  my $start = ($path =~ /^\//) ?
    $xml_node : $parser->{xmlDocument};

  my $value = $parser->CollectValues($start, $path);
  if ($value ne "") {
    $result_node->appendChild($parser->{xmlDocument}->createTextNode($value));
  }
}

sub CollectValues {
  my($parser, $xmlNode, $path) = @_;
  if ($path =~ s/^\/\///) {
    # Beginning with the current node, start a recursive collection
    return $parser->CollectValuesDeep($xmlNode, $path);
  }
  $path =~ s/^\///;
  if ($path =~ s/^\.\.//) {
    my $parent = $xmlNode->getParent();
    return defined $parent ? $parser->CollectValues($parent, $path) : "";
  }
  if ($path =~ s/^\.//) {
    return $parser->CollectValues($xmlNode, $path);
  }
  if ($path =~ s/^\@//) {
    return "" unless $xmlNode->getNodeType() == XML::DOM::ELEMENT_NODE();
    my $value = $xmlNode->getAttribute($path);
    return defined $value ? $value : "";
  }
  if ($path =~ s/^([\w\-\:\.]+)(?:\[(\d+)\])?//) {
    my $name = $1;
    my $index = $2;
    my @elements = $parser->FindElementsByName($xmlNode, $name);
    if ($index) { @elements = @elements > $index ? $elements[$index] : () }
    my $value = "";
    foreach my $elem (@elements) {
      $value .= $parser->CollectValues($elem, $path);
    }
    return $value;
  }
  return "" unless $path eq ""; # Dunno how to handle $path
  $parser->ElemValue($xmlNode);
}

sub ElemValue {
  my($parser, $node) = @_;
  my $type = $node->getNodeType();
  if ($type == XML::DOM::ATTRIBUTE_NODE()  ||
      $type == XML::DOM::TEXT_NODE()  ||
      $type == XML::DOM::CDATA_SECTION_NODE()) {
    $node->getData();
  } elsif ($type == XML::DOM::ELEMENT_NODE()  ||
	   $type == XML::DOM::DOCUMENT_NODE() ||
	   $type == XML::DOM::DOCUMENT_FRAGMENT_NODE()) {
    my $value = "";
    for (my $child = $node->getFirstChild();  $child;
	 $child = $child->getNextSibling()) {
      $value .= $parser->ElemValue($child);
    }
    $value;
  }
}

sub FindElementsByName {
  my($parser, $node, $name) = @_;
  my @result;
  for (my $child = $node->getFirstChild();  $child;
       $child = $child->getNextSibling()) {
    if ($child->getNodeType() == XML::DOM::ELEMENT_NODE()) {
      push(@result, $child) if $child->getTagName() eq $name;
    } elsif ($child->getNodeType() == XML::DOM::DOCUMENT_NODE()  ||
	     $child->getNodeType() == XML::DOM::DOCUMENT_FRAGMENT_NODE()) {
      push(@result, $parser->FindElementsByName($child, $name));
    }
  }
  @result;
}

sub CollectValuesDeep {
  my($parser, $xmlNode, $path) = @_;
  my $values = $parser->CollectValues($xmlNode, $path);
  for (my $child = $xmlNode->getFirstChild();  $child;
       $child = $child->getNextSibling()) {
    $values .= $child->CollectValues_deep($xmlNode, $path);
  }
  $values;
}


1;
