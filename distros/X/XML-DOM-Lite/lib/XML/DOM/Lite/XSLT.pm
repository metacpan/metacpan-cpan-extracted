package XML::DOM::Lite::XSLT;

use XML::DOM::Lite::XPath;
use XML::DOM::Lite::Constants qw(:all);
use Carp qw(confess);

use warnings;
use strict;

our $DEBUG = 0;

sub new { bless { }, $_[0] }

sub process {
    my ($self, $xmlDoc, $stylesheet) = @_;
    return xsltProcess($xmlDoc, $stylesheet);
}

sub xsltProcess {
  my ($xmlDoc, $stylesheet) = @_;

  $DEBUG && warn('XML STYLESHEET:');
  $DEBUG && warn(xmlText($stylesheet));
  $DEBUG && warn('XML INPUT:');
  $DEBUG && warn(xmlText($xmlDoc));

  my $output = $xmlDoc->createDocumentFragment();
  xsltProcessContext(XML::DOM::Lite::XPath::ExprContext->new($xmlDoc), $stylesheet, $output);

  my $ret = xmlText($output);

  $DEBUG && warn('HTML OUTPUT:');
  $DEBUG && warn($ret);

  return $ret;
}

sub xsltProcessContext {
  my ($input, $template, $output) = @_;
  my @nodename = split(/:/, $template->nodeName);
  if (@nodename == 1 or $nodename[0] ne 'xsl') {
    xsltPassThrough($input, $template, $output);

  } else {
    if ($nodename[1] eq 'apply-imports') {
      warn('not implemented: ' . $nodename[1]);
    } elsif ($nodename[1] eq 'apply-templates') {
      my $select = xmlGetAttribute($template, 'select');
      my $nodes;
      if ($select) {
        $nodes = xpathEval($select, $input)->nodeSetValue();
      } else {
        $nodes = $input->{node}->childNodes;
      }

      my $sortContext = $input->clone($nodes->[0], 0, $nodes);
      xsltWithParam($sortContext, $template);
      xsltSort($sortContext, $template);

      my $mode = xmlGetAttribute($template, 'mode');
      my $top = $template->ownerDocument->documentElement;
      for (my $i = 0; $i < $top->childNodes->length; ++$i) {
        my $c = $top->childNodes->[$i];
        if ($c->nodeType == ELEMENT_NODE and
            $c->nodeName eq 'xsl:template' and 
            ($c->getAttribute('mode') || '') eq ($mode || '')) {
          for (my $j = 0; $j < @{$sortContext->{nodelist}}; ++$j) {
            my $nj = $sortContext->{nodelist}->[$j];
            xsltProcessContext($sortContext->clone($nj, $j), $c, $output);
          }
        }
      }

    } elsif ($nodename[1] eq 'attribute') {
      my $nameexpr = xmlGetAttribute($template, 'name');
      my $name = xsltAttributeValue($nameexpr, $input);
      my $node = $output->ownerDocument->createDocumentFragment();
      xsltChildNodes($input, $template, $node);
      my $value = xmlValue($node);
      $output->setAttribute($name, $value);

    } elsif ($nodename[1] eq 'attribute-set') {
      warn('not implemented: ' . $nodename[1]);

    } elsif ($nodename[1] eq 'call-template') {
      my $name = xmlGetAttribute($template, 'name');
      my $top = $template->ownerDocument->documentElement;

      my $paramContext = $input->clone();
      xsltWithParam($paramContext, $template);

      for (my $i = 0; $i < $top->childNodes->length; ++$i) {
        my $c = $top->childNodes->[$i];
        if ($c->nodeType == ELEMENT_NODE and
            $c->nodeName eq 'xsl:template' and
            $c->getAttribute('name') eq $name) {
          xsltChildNodes($paramContext, $c, $output);
          last;
        }
      }
    } elsif ($nodename[1] eq 'choose') {
      xsltChoose($input, $template, $output);

    } elsif ($nodename[1] eq 'comment') {
      my $node = $output->ownerDocument->createDocumentFragment();
      xsltChildNodes($input, $template, $node);
      my $commentData = xmlValue($node);
      my $commentNode = $output->ownerDocument->createComment($commentData);
      $output->appendChild($commentNode);

    } elsif ($nodename[1] eq 'copy') {
      if ($input->{node}->nodeType == ELEMENT_NODE) {
        my $node = $output->ownerDocument->createElement($input->{node}->nodeName);
        $output->appendChild($node);
        xsltChildNodes($input, $template, $node);

      } elsif ($input->{node}->nodeType == ATTRIBUTE_NODE) {
        my $node = $output->ownerDocument->createAttribute($input->{node}->nodeName);
        $node->nodeValue = $input->{node}->nodeValue;
        $output->setAttribute($node);
      }

    } elsif ($nodename[1] eq 'copy-of') {
      my $select = xmlGetAttribute($template, 'select');
      my $value = xpathEval($select, $input);
      if ($value->{type} eq 'node-set') {
        my $nodes = $value->nodeSetValue();
        for (my $i = 0; $i < @$nodes; ++$i) {
          xsltCopyOf($output, $nodes->[$i]);
        }

      } else {
        my $node = $output->ownerDocument->createTextNode($value->stringValue());
        $output->appendChild($node);
      }

    } elsif ($nodename[1] eq 'decimal-format') {
      warn('not implemented: ' . $nodename[1]);

    } elsif ($nodename[1] eq 'element') {
      my $nameexpr = xmlGetAttribute($template, 'name');
      my $name = xsltAttributeValue($nameexpr, $input);
      my $node = $output->ownerDocument->createElement($name);
      $output->appendChild($node);
      xsltChildNodes($input, $template, $node);

    } elsif ($nodename[1] eq 'fallback') {
      warn('not implemented: ' . $nodename[1]);

    } elsif ($nodename[1] eq 'for-each') {
      my $sortContext = $input->clone();
      xsltSort($sortContext, $template);
      xsltForEach($sortContext, $template, $output);

    } elsif ($nodename[1] eq 'if') {
      my $test = xmlGetAttribute($template, 'test');
      if (xpathEval($test, $input)->booleanValue()) {
        xsltChildNodes($input, $template, $output);
      }

    } elsif ($nodename[1] eq 'import') {
      warn('not implemented: ' . $nodename[1]);

    } elsif ($nodename[1] eq 'include') {
      warn('not implemented: ' . $nodename[1]);

    } elsif ($nodename[1] eq 'key') {
      warn('not implemented: ' . $nodename[1]);

    } elsif ($nodename[1] eq 'message') {
      warn('not implemented: ' . $nodename[1]);

    } elsif ($nodename[1] eq 'namespace-alias') {
      warn('not implemented: ' . $nodename[1]);

    } elsif ($nodename[1] eq 'number') {
      warn('not implemented: ' . $nodename[1]);

    } elsif ($nodename[1] eq 'otherwise') {
      warn('not implemented: ' . $nodename[1]);

    } elsif ($nodename[1] eq 'output') {

    } elsif ($nodename[1] eq 'preserve-space') {
      warn('not implemented: ' . $nodename[1]);

    } elsif ($nodename[1] eq 'processing-instruction') {
      warn('not implemented: ' . $nodename[1]);

    } elsif ($nodename[1] eq 'sort') {

    } elsif ($nodename[1] eq 'strip-space') {
      warn('not implemented: ' . $nodename[1]);

    } elsif ($nodename[1] eq 'stylesheet' or $nodename[1] eq 'transform') {
      xsltChildNodes($input, $template, $output);

    } elsif ($nodename[1] eq 'template') {
      my $match = xmlGetAttribute($template, 'match');
      if ($match and xpathMatch($match, $input)) {
        xsltChildNodes($input, $template, $output);
      }

    } elsif ($nodename[1] eq 'text') {
      my $text = xmlValue($template);
      my $node = $output->ownerDocument->createTextNode($text);
      $output->appendChild($node);

    } elsif ($nodename[1] eq 'value-of') {
      my $select = xmlGetAttribute($template, 'select');
      my $value = xpathEval($select, $input)->stringValue();
      unless ($output->ownerDocument) { die 'no ownerDocument for '.Dumper($output) }
      my $node = $output->ownerDocument->createTextNode($value);
      $output->appendChild($node);

    } elsif ($nodename[1] eq 'param') {
      xsltVariable($input, $template, 0);

    } elsif ($nodename[1] eq 'variable') {
      xsltVariable($input, $template, 1);

    } elsif ($nodename[1] eq 'when') {
      warn('error if here: ' . $nodename[1]);

    } elsif ($nodename[1] eq 'with-param') {
      warn('error if here: ' . $nodename[1]);

    } else {
      warn('error if here: ' . $nodename[1]);
    }
  }
}

sub xsltWithParam {
  my ($input, $template) = @_;
  for (my $i = 0; $i < $template->childNodes->length; ++$i) {
    my $c = $template->childNodes->[$i];
    if ($c->nodeType == ELEMENT_NODE and $c->nodeName eq 'xsl:with-param') {
      xsltVariable($input, $c, 1);
    }
  }
}

sub xsltSort {
  my ($input, $template) = @_;
  my $sort = [];
  for (my $i = 0; $i < $template->childNodes->length; ++$i) {
    my $c = $template->childNodes->[$i];
    if ($c->nodeType == ELEMENT_NODE and $c->nodeName eq 'xsl:sort') {
      my $select = xmlGetAttribute($c, 'select');
      my $expr = xpathParse($select);
      my $type = xmlGetAttribute($c, 'data-type') || 'text';
      my $order = xmlGetAttribute($c, 'order') || 'ascending';
      push(@$sort, { expr=> $expr, type=> $type, order=> $order });
    }
  }

  xpathSort($input, $sort);
}

sub xsltVariable {
  my ($input, $template, $override) = @_;
  
  my $name = xmlGetAttribute($template, 'name');
  my $select = xmlGetAttribute($template, 'select');

  my $value;

  if ($template->childNodes->length > 0) {
    my $root = $input->{node}->ownerDocument->createDocumentFragment();
    xsltChildNodes($input, $template, $root);
    $value = new NodeSetValue([$root]);

  } elsif ($select) {
    $value = xpathEval($select, $input);

  } else {
    $value = new StringValue('');
  }

  if ($override || !$input->getVariable($name)) {
    $input->setVariable($name, $value);
  }
}


sub xsltChoose  {
  my ($input, $template, $output) = @_;
  for (my $i = 0; $i < $template->childNodes->length; ++$i) {
    my $childNode = $template->childNodes->[$i];
    if ($childNode->nodeType != ELEMENT_NODE) {
      next;

    } elsif ($childNode->nodeName eq 'xsl:when') {
      my $test = xmlGetAttribute($childNode, 'test');
      if (xpathEval($test, $input)->booleanValue()) {
        xsltChildNodes($input, $childNode, $output);
        last;
      }

    } elsif ($childNode->nodeName eq 'xsl:otherwise') {
      xsltChildNodes($input, $childNode, $output);
      last;
    }
  }
}


sub xsltForEach {
  my ($input, $template, $output) = @_;
  my $select = xmlGetAttribute($template, 'select');
  my $nodes = xpathEval($select, $input)->nodeSetValue();
  for (my $i = 0; $i < @$nodes; ++$i) {
    my $context = $input->clone($nodes->[$i], $i, $nodes);
    xsltChildNodes($context, $template, $output);
  }
}


sub xsltChildNodes {
  my ($input, $template, $output, $foo) = @_;
  my $context = $input->clone();
  foreach my $c (@{$template->childNodes}) {
    xsltProcessContext($context, $c, $output);
  }
}


sub xsltPassThrough {
  my ($input, $template, $output) = @_;
  if ($template->nodeType == TEXT_NODE) {
    if (xsltPassText($template)) {
      my $node = $output->ownerDocument->createTextNode($template->nodeValue);
      $output->appendChild($node);
    }

  } elsif ($template->nodeType == ELEMENT_NODE) {
    my $node = $output->ownerDocument->createElement($template->nodeName);
    for (my $i = 0; $i < $template->attributes->length; ++$i) {
      my $a = $template->attributes->[$i];
      if ($a) {
        my $name = $a->nodeName;
        my $value = xsltAttributeValue($a->nodeValue, $input);
        $node->setAttribute($name, $value);
      }
    }
    $output->appendChild($node);
    xsltChildNodes($input, $template, $node);

  } else {
    xsltChildNodes($input, $template, $output);
  }
}

sub xsltPassText {
  my ($template) = @_;
  unless ($template->nodeValue =~ /^\s*$/) {
    return 1;
  }

  my $element = $template->parentNode;
  if ($element->nodeName eq 'xsl:text') {
    return 1;
  }

  while ($element and $element->nodeType == ELEMENT_NODE) {
    my $xmlspace = $element->getAttribute('xml:space');
    if ($xmlspace) {
      if ($xmlspace eq 'default') {
        return 0;
      } elsif ($xmlspace eq 'preserve') {
        return 1;
      }
    }

    $element = $element->parentNode;
  }

  return 0;
}

sub xsltAttributeValue {
  my ($value, $context) = @_;
  my $parts = [ split(/{/, $value) ];
  if (@$parts == 1) {
    return $value;
  }

  my $ret = '';
  for (my $i = 0; $i < @$parts; ++$i) {
    my $rp = [ split(/}/, $parts->[$i]) ];
    if (@$rp != 2) {
      $ret .= $parts->[$i];
      next;
    }

    my $val = xpathEval($rp->[0], $context)->stringValue();
    $ret .= ($val . $rp->[1]);
  }

  return $ret;
}


sub xmlGetAttribute {
  my ($node, $name) = @_;
  my $value = $node->getAttribute($name);
  if ($value) {
    return xmlResolveEntities($value);
  } else {
    return $value;
  }
}


sub xsltCopyOf {
  my ($dst, $src) = @_;
  if ($src->nodeType == TEXT_NODE) {
    my $node = $dst->ownerDocument->createTextNode($src->nodeValue);
    $dst->appendChild($node);

  } elsif ($src->nodeType == ATTRIBUTE_NODE) {
    $dst->setAttribute($src->nodeName, $src->nodeValue);

  } elsif ($src->nodeType == ELEMENT_NODE) {
    my $node = $dst->ownerDocument->createElement($src->nodeName);
    $dst->appendChild($node);

    for (my $i = 0; $i < $src->attributes->length; ++$i) {
      xsltCopyOf($node, $src->attributes->[$i]);
    }

    for (my $i = 0; $i < $src->childNodes->length; ++$i) {
      xsltCopyOf($node, $src->childNodes->[$i]);
    }

  } elsif ($src->nodeType == DOCUMENT_FRAGMENT_NODE or
           $src->nodeType == DOCUMENT_NODE) {
    for (my $i = 0; $i < $src->childNodes->length; ++$i) {
      xsltCopyOf($dst, $src->childNodes->[$i]);
    }
  }
}

sub xpathParse {
  my ($match) = @_;
  return XML::DOM::Lite::XPath->parse($match);
}

sub xpathMatch {
  my ($match, $context) = @_;
  my $expr = xpathParse($match);

  my $ret;
  if ($expr->{steps} and (not $expr->{absolute})
      and (@{$expr->{steps}} == 1)
      and ($expr->{steps}->[0]->{axis} eq 'child')
      and (@{$expr->{steps}->[0]->{predicate}} == 0)) {
    $ret = $expr->{steps}->[0]->{nodetest}->evaluate($context)->booleanValue();
  } else {

    $ret = 0;
    my $node = $context->{node};

    while ((not $ret) and $node) {
      my $result = $expr->evaluate($context->clone($node,0,[$node]))->nodeSetValue();
      for (my $i = 0; $i < @$result; ++$i) {
        if ($result->[$i] == $context->{node}) {
          $ret = 1;
          last;
        }
      }
      $node = $node->parentNode;
    }
  }

  return $ret;
}

sub xpathSort {
  return XML::DOM::Lite::XPath::xpathSort(@_);
}

sub xpathEval {
  my ($select, $context) = @_;
  my $expr = xpathParse($select);
  my $ret = $expr->evaluate($context);
  return $ret;
}

sub xmlText {
  my ($node) = @_;
  my $ret = '';
  if ($node->nodeType == TEXT_NODE) {
    $ret .= $node->nodeValue;

  } elsif ($node->nodeType == ELEMENT_NODE) {
    $ret .= '<' . $node->nodeName;
    for (my $i = 0; $i < $node->attributes->length; ++$i) {
      my $a = $node->attributes->[$i];
      if ($a and $a->nodeName and $a->nodeValue) {
        $ret .= ' ' . $a->nodeName;
        $ret .= '="' . $a->nodeValue . '"';
      }
    }

    if ($node->childNodes->length == 0) {
      $ret .= '/>';

    } else {
      $ret .= '>';
      for (my $i = 0; $i < $node->childNodes->length; ++$i) {
        $ret .= xmlText($node->childNodes->[$i]);
      }
      $ret .= '</' . $node->nodeName . '>';
    }

  } elsif ($node->nodeType == DOCUMENT_NODE or
           $node->nodeType == DOCUMENT_FRAGMENT_NODE) {
    for (my $i = 0; $i < $node->childNodes->length; ++$i) {
      $ret .= xmlText($node->childNodes->[$i]);
    }
  }

  return $ret;
}

sub xmlResolveEntities {
  my ($s) = @_;

  my $parts = [ split(/&/, $s) ];

  my $ret = $parts->[0];
  for (my $i = 1; $i < @$parts; ++$i) {
    my $rp = [ split(/;/, $parts->[$i]) ];
    if (@$rp == 1) {
      $ret .= $parts->[$i];
      next;
    }
    
    my $ch;
    if ($rp->[0] eq 'lt') {
        $ch = '<';
    } elsif ($rp->[0] eq 'gt') {
        $ch = '>';
    } elsif ($rp->[0] eq 'amp') {
        $ch = '&';
    } elsif ($rp->[0] eq 'quot') {
        $ch = '"';
    } elsif ($rp->[0] eq 'apos') {
        $ch = "'";
    } elsif ($rp->[0] eq 'nbsp') {
        $ch = ' '; # "\x160"
    } else {
        warn 'unknown entity '.$rp->[0];
        #my span = window.document.createElement('span');
        #span.innerHTML = '&' + rp[0] + '; ';
        #ch = span.childNodes[0].nodeValue.charAt(0);
    }
    $ret .= ($ch . $rp->[1]);
  }

  return $ret;
}

1;

__END__

=head1 NAME

XML::DOM::Lite::XSLT - XSLT engine for XML::DOM::Lite

=head1 SYNOPSIS
 
 use XML::DOM::Lite qw(Parser XSLT);
 $parser = Parser->new( whitespace => 'strip' );
 $xsldoc = $parser->parse($xsl); 
 $xmldoc = $parser->parse($xml); 
 $output = XSLT->process($xmldoc, $xsldoc);

=head1 DESCRIPTION

=head1 AUTHOR

Copyright (C) 2005 Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 ACKNOWLEDGEMENTS

Google - for implementing the XPath and XSLT JavaScript libraries which I shamelessly stole

=head1 LICENCE

This library is free software and may be used under the same terms as
Perl itself.

=cut

