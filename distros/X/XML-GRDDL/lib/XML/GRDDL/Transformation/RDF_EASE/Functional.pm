package XML::GRDDL::Transformation::RDF_EASE::Functional;

use 5.008;
use base qw[Exporter];
use strict;

use CSS;
use CSS::Parse::PRDGrammar;
use XML::GRDDL::Transformation::RDF_EASE::Selector;
use Exporter;
use XML::LibXML;

our $VERSION = '0.004';

our @EXPORT_OK = qw(&rdfease_to_rdfa &parse_sheet &parse_value &bnode_for_element &rule_matches_node);
our %EXPORT_TAGS = (
		'standard' => [qw(&rdfease_to_rdfa)],
		'extended' => [qw(&rdfease_to_rdfa &parse_sheet &parse_value &bnode_for_element &rule_matches_node)]
	);

our $_RDFEASE_MatcherCacher   = {};
our $_RDFEASE_BlankNodes      = {};
our $_RDFEASE_BlankNode_Count = 0;
our $_RDFEASE_Protocols_Seen  = {};
	
sub rdfease_to_rdfa
{
	my $ease  = shift;
	my $html  = shift;
	my $asDOM = shift || 0;
	
	# Initialise shared variables
	$_RDFEASE_MatcherCacher   = {};
	$_RDFEASE_BlankNodes      = {};
	$_RDFEASE_BlankNode_Count = 0;
	$_RDFEASE_Protocols_Seen  = {};

	# Parse XHTML into DOM tree
	my $parser  = XML::LibXML->new();
	my $DOMTree = $parser->parse_string($html);
	
	# RDF-EASE Algorithm: step 2.
	# Generate a 'kwijibo' string
	my $kwijibo = 'RDFEASE';
	while ($html =~ /$kwijibo/i)
		{ $kwijibo = 'RDFEASE'.int(rand(900000)+100000); }
	
	# RDF-EASE Algorithm, steps 1, 3, 4 and 5.
	# Parse RDF-EASE into structure
	my $ParsedEASE = parse_sheet($ease);
	
	# RDF-EASE Algorithm: step 6 and a little of step 2.
	# Process tree
	process_tree($DOMTree, $ParsedEASE, $kwijibo);
	
	# RDF-EASE Algorithm: we don't do step 7, as we want to return RDFa.
	{} ;
	
	# If they requested the DOM representation, then return it
	return $DOMTree if $asDOM;
	
	# Otherwise, return the result as an XHTML string.
	return $DOMTree->documentElement->toString;
}

sub process_tree
{
	my $DOM     = shift;
	my $EASE    = shift;
	my $kwijibo = shift;
	
	process_element($DOM->documentElement, $DOM, $EASE, $kwijibo);

	foreach my $proto (keys %$_RDFEASE_Protocols_Seen)
	{
		$DOM->documentElement->setAttribute('xmlns:'.$kwijibo.$proto, $proto.':');
	}
}

sub process_element
{
	my $elem    = shift; # 'E'
	my $DOM     = shift;
	my $CSS     = shift;
	my $kwijibo = shift;

	# For each rule set rs in RuleList
	foreach my $rule_block (@{$CSS->{'data'}})
	{
		# If the selector of rule set rs does not match element E, move on to the
		# next rule set in RuleList
		next unless rule_matches_node($rule_block, $elem, $DOM);

		# Each property value pair (p, v) within rs should be handled as follows
		foreach my $rule (@{$rule_block->{'properties'}})
		{
			# Skip non "-rdf-" rules.
			my $prop;
			if ($rule->{'property'} =~ /^\-rdf\-(.*)$/i)
				{ $prop = lc($1); }
			else
				{ next; }

			my @vals = parse_value($rule->{'value'}, $CSS->{'prefixes'});

			if ($prop =~ /^(typeof|rel|rev|property|role)$/)
			{
				if (grep {/^reset$/i} @vals)
					{ $elem->setAttribute('x-rdf-'.$prop, undef); }
					
				my $new = $elem->getAttribute('x-rdf-'.$prop);
				$new .= ' ' if ($new);
				foreach my $v (@vals)
				{
					next if ($v eq 'reset');
					$_RDFEASE_Protocols_Seen->{$1} = 1
						if ($v =~ /^([^:]+)/);
					$new .= "$kwijibo$v ";
				}
				$new =~ s/ $//;
				$elem->setAttribute('x-rdf-'.$prop, $new);
			}
			elsif ($prop eq 'about')
			{
				my $v = $vals[0];

				if (lc($v) eq 'reset')
					{ $elem->removeAttribute('x-rdf-about'); }
				elsif (lc($v) eq 'document')
				{
					$elem->setAttribute('x-rdf-about', '')
						unless (defined $elem->getAttribute($prop));
				}
				elsif ($v =~ /^NEAR:\s+(.+)$/)
				{
					my @matched = $DOM->documentElement->findnodes(XML::GRDDL::Transformation::RDF_EASE::Selector::to_xpath($1));
					my $best_match;
					foreach my $matching_node (@matched)
					{
						if (substr($elem->nodePath, 0, length($matching_node->nodePath)) eq $matching_node->nodePath)
						{
							$best_match = $matching_node
								if ((!$best_match)
								||  (length($matching_node->nodePath) > length($best_match->nodePath)));
						}
					}
					if ($best_match)
					{
						$elem->setAttribute('x-rdf-about', '['.bnode_for_element($best_match, $kwijibo).']');
					}
				}
			}
			elsif ($prop eq 'content')
			{
				if ($rule->{'value'} =~ /^\s*attr\([\'\"]?(.+)[\'\"]?\)\s*$/i)
					{ $elem->setAttribute('x-rdf-content', $elem->getAttribute($1)); }
			}
			elsif ($prop eq 'datatype')
			{
				my $v = $vals[0];
				
				if (lc($v) eq 'reset')
					{ $elem->removeAttribute('x-rdf-datatype'); }
				elsif (lc($v) eq 'string')
					{ $elem->setAttribute('x-rdf-datatype', ''); }
				elsif ($v =~ /\:/)
				{
					$_RDFEASE_Protocols_Seen->{$1} = 1
						if ($v =~ /^([^:]+)/);
					$elem->setAttribute('x-rdf-datatype', "$kwijibo$v");
				}
			}
		}
	}
	
	foreach my $prop (qw(about content datatype))
	{
		if (defined $elem->getAttribute('x-rdf-'.$prop))
		{
			$elem->setAttribute($prop, $elem->getAttribute('x-rdf-'.$prop))
				if (!defined $elem->getAttribute($prop));
			$elem->removeAttribute('x-rdf-'.$prop);
		}
	}
	foreach my $prop (qw(typeof rel rev property role))
	{
		if ($elem->getAttribute('x-rdf-'.$prop))
		{
			if ($elem->getAttribute($prop))
			{
				$elem->setAttribute($prop,
					$elem->getAttribute($prop).' '.
					$elem->getAttribute('x-rdf-'.$prop));
			}
			else
			{
				$elem->setAttribute($prop,
					$elem->getAttribute('x-rdf-'.$prop));
			}
			$elem->removeAttribute('x-rdf-'.$prop);
		}
	}

	my $recurse = 1;
	if (length $elem->getAttribute('property'))
	{
		$recurse = 0 if (!defined $elem->getAttribute('datatype'));
		$recurse = 0 if ($elem->getAttribute('datatype') =~ /XMLLiteral\s*$/);
		$recurse = 1 if (defined $elem->getAttribute('content'));
	}
	
	if ($recurse)
	{
		foreach my $child ($elem->getChildrenByTagName('*'))
		{
			process_element($child, $DOM, $CSS, $kwijibo);
		}
	}
}

sub bnode_for_element
{
	my $elem     = shift;
	my $kwijibo  = shift;
	my $nodepath = $elem->nodePath;
	
	unless (defined $_RDFEASE_BlankNodes->{$nodepath})
	{
		$_RDFEASE_BlankNode_Count++;
		$_RDFEASE_BlankNodes->{$nodepath} = sprintf('%s_Node%s',
			$kwijibo, $_RDFEASE_BlankNode_Count);
	}

	return '_:'.$_RDFEASE_BlankNodes->{$nodepath};
}

sub rule_matches_node
{
	my $rule = shift;
	my $elem = shift;
	my $dom  = shift;
	
	my $rulepath = $rule->{'xpath'};
	my $elempath = $elem->nodePath;
	
	return $_RDFEASE_MatcherCacher->{'Answers'}->{$rulepath}->{$elempath}
		if defined $_RDFEASE_MatcherCacher->{'Answers'}->{$rulepath}->{$elempath};
		
	unless (defined $_RDFEASE_MatcherCacher->{'Lists'}->{$rulepath})
	{
		my $xpc = XML::LibXML::XPathContext->new;
		$xpc->registerNs(xhtml => 'http://www.w3.org/1999/xhtml');
		$_RDFEASE_MatcherCacher->{'Lists'}->{$rulepath} = $xpc->findnodes($rulepath, $dom);
	}
	
	my $rv = 0;
	foreach my $match ($_RDFEASE_MatcherCacher->{'Lists'}->{$rulepath}->get_nodelist)
	{
		if ($match->isSameNode($elem))
		{
			$rv++;
			last;
		}
	}
	
	#warn sprintf("%s %s %s\n", $rulepath, ($rv?'matches':'DOES NOT MATCH'), $elempath);
	
	$_RDFEASE_MatcherCacher->{'Answers'}->{$rulepath}->{$elempath} = $rv;
	
	return $rv;
}

sub parse_value
{
	my $vals = shift;
	my $pfxs = shift;
	my @rv;
	
	return @rv
		if ($vals =~ /^ \s* normal \s* $/i); 
	
	while (length $vals)
	{
		if ($vals =~ /^ \s* (reset|document|string) \s* (.*) $/x)
		{
			push @rv, $1;
			$vals = $2;
		}
		elsif ($vals =~ /^ \s* url\(\s*\'([^\']*)\'\s*\) \s* (.*) $/ix)
		{
			push @rv, $1;
			$vals = $2;
		}
		elsif ($vals =~ /^ \s* url\(\s*\"([^\"]*)\"\s*\) \s* (.*) $/ix)
		{
			push @rv, $1;
			$vals = $2;
		}
		elsif ($vals =~ /^ \s* url\(\s*([^\"\'\)]*)\s*\) \s* (.*) $/ix)
		{
			push @rv, $1;
			$vals = $2;
		}
		elsif ($vals =~ /^ \s* nearest\-ancestor\(\s*\'([^\']*)\'\s*\) \s* (.*) $/ix)
		{
			push @rv, "NEAR: $1";
			$vals = $2;
		}
		elsif ($vals =~ /^ \s* nearest\-ancestor\(\s*\"([^\"]*)\"\s*\) \s* (.*) $/ix)
		{
			push @rv, "NEAR: $1";
			$vals = $2;
		}
		elsif ($vals =~ /^ \s* nearest\-ancestor\(\s*([^\"\'\)]*)\s*\) \s* (.*) $/ix)
		{
			push @rv, "NEAR: $1";
			$vals = $2;
		}
		elsif ($vals =~ /^ \s* \'([^\'\:]*)\:([^\']*)\' \s* (.*) $/ix)
		{
			push @rv, $pfxs->{$1}.$2;
			$vals = $3;
		}
		elsif ($vals =~ /^ \s* \"([^\"\:]*)\:([^\"]*)\" \s* (.*) $/ix)
		{
			push @rv, $pfxs->{$1}.$2;
			$vals = $3;
		}
		elsif ($vals =~ /^ \s* ([^\"\'\:\s]*)\:([^\"\'\s]*) \s* (.*) $/ix)
		{
			push @rv, $pfxs->{$1}.$2;
			$vals = $3;
		}
		else
		{
			my @null;
			return @null;
		}
	}
	
	return @rv;
}

sub parse_sheet
{
	my $css = shift;

	my @data;
	my ($prefixes, $i) = ({
		'dc'    => 'http://purl.org/dc/terms/',
		'foaf'  => 'http://xmlns.com/foaf/0.1/',
		'owl'   => 'http://www.w3.org/2002/07/owl#',
		'rdf'   => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
		'rdfs'  => 'http://www.w3.org/2000/01/rdf-schema#',
		'sioc'  => 'http://rdfs.org/sioc/ns#',
		'skos'  => 'http://www.w3.org/2004/02/skos/core#',
		'xsd'   => 'http://www.w3.org/2001/XMLSchema#'
	}, 0);

	# Handle at-rules in advance, as CSS::Parse::Heavy doesn't support them.
	while ($css =~ /^\s*(\@\S+)\s+([^\;]+)\s*\;\s*(.*)$/s)
	{
		$css = $3;

		my $atrule = $1;
		my $stuff  = $2;
		
		if ($atrule =~ /^\@(prefix|namespace)$/i)
		{
			if ($stuff =~ /^\s*([A-Za-z0-9\._-]+)\s+(.+)\s*$/)
			{
				my $pfx = $1;
				my $uri = $2;
				
				if ($uri =~ /^url\((.*)\)$/)
					{ $uri = $1; }
				if ($uri =~ /^\"(.*)\"$/)
					{ $uri = $1; }
				elsif ($uri =~ /^\'(.*)\'$/)
					{ $uri = $1; }
					
				$prefixes->{ $pfx } = $uri;
			}
		}
	}

	# Patch CSS::Parse::Heavy because it doesn't support CSS properties that
	# start with a dash.
	$CSS::Parse::PRDGrammar::GRAMMAR =~ s#macro_nmstart:\s+/\[a-zA-Z\]/
	                                     #macro_nmstart:   /[a-zA-Z_-]/
	                                     #x;	

	# Actually parse the CSS, using CSS::Parse::Heavy.
	my $parser = CSS->new( { 'parser' => 'CSS::Parse::Heavy' } )->read_string($css);

	foreach my $block (@$parser)
	{
		foreach my $selector (@{ $block->{selectors} })
		{
			if ($selector->{name} eq '_')
			{
				foreach my $property (@{ $block->{properties} })
				{
					my $prefix = $property->{options}->{property};
					my $url    = $property->{options}->{value};
					
					$url = $1 if ($url =~ /url\([\'\"]?([^\'\"]+)[\'\"]?\)/i);
					$prefixes->{$prefix} = $url;
				}
				next;
			}
			
			my $x = {};
			foreach my $property (@{ $block->{properties} })
			{
				push @{ $x->{properties} }, $property->{options};
			}
			$x->{selector}    = $selector->{name};
			$x->{order}       = ++$i;
			$x->{tokens}      = XML::GRDDL::Transformation::RDF_EASE::Selector::get_tokens($x->{selector});
			$x->{specificity} = XML::GRDDL::Transformation::RDF_EASE::Selector::specificity(@{ $x->{tokens} });
			$x->{xpath}       = XML::GRDDL::Transformation::RDF_EASE::Selector::to_xpath(@{ $x->{tokens} });
			push @data, $x;
		}
	}
	
	my @sorted = sort css21_cascade_order @data;
	
	return {
		prefixes => $prefixes,
		data     => \@sorted
	};
}

sub css21_cascade_order
{
	return ($a->{order} <=> $b->{order})
		if $a->{specificity} == $b->{specificity};

	return ($a->{specificity} <=> $b->{specificity});
}

1;

__END__

=head1 NAME

XML::GRDDL::Transformation::RDF_EASE::Functional - stand-alone RDF-EASE module

=head1 DESCRIPTION

This module exports one function:

=over 4

=item C<< rdfease_to_rdfa( $css, $xhtml, $as_dom ) >>

Takes an RDF-EASE (CSS) transformation and an XHTML document (well-formed
string) and returns the resulting XHTML+RDFa document, which can then be
fed to L<RDF::RDFa::Parser>.

If $as_dom is true, returns an XML::LibXML::Document; otherwise, a string.

=back

=head1 SEE ALSO

L<XML::GRDDL>, L<XML::GRDDL::Transformation::RDF_EASE>.

L<RDF::RDFa::Parser>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2008-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
