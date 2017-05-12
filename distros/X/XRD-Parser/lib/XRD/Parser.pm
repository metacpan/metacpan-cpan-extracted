package XRD::Parser;

use 5.010;
use strict;

use Carp 0;
use Digest::SHA 0 qw(sha1_hex);
use Encode 0 qw(encode_utf8);
use HTTP::Link::Parser 0.102;
use LWP::UserAgent 0;
use Object::AUTHORITY 0;
use RDF::Trine 0.135;
use Scalar::Util 0 qw(blessed);
use URI::Escape 0;
use URI::URL 0;
use XML::LibXML 1.70 qw(:all);

use constant NS_HOSTMETA => 'http://host-meta.net/ns/1.0';
use constant NS_HOSTMETX => 'http://host-meta.net/xrd/1.0';
use constant NS_XML      => XML::LibXML::XML_XML_NS;
use constant NS_XRD      => 'http://docs.oasis-open.org/ns/xri/xrd-1.0';
use constant URI_DCTERMS => 'http://purl.org/dc/terms/';
use constant URI_HOST    => 'http://ontologi.es/xrd#host:';
use constant URI_RDF     => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
use constant URI_RDFS    => 'http://www.w3.org/2000/01/rdf-schema#';
use constant URI_SUBLINK => 'http://ontologi.es/xrd#sublink:';
use constant URI_TYPES   => 'http://www.iana.org/assignments/media-types/';
use constant URI_XRD     => 'http://ontologi.es/xrd#';
use constant URI_XSD     => 'http://www.w3.org/2001/XMLSchema#';
use constant SCHEME_TMPL => 'x-xrd+template+for:';

BEGIN {
	$XRD::Parser::AUTHORITY  = 'cpan:TOBYINK';
	$XRD::Parser::VERSION    = '0.201';
}

sub new
{
	my ($class, $content, $baseuri, $options, $store)= @_;
	
	# Rationalise $options
	# ====================
	# If $options is undefined, then use the default configuration
	if (!ref $options)
		{ $options = {}; }

	# Rationalise $baseuri
	# ====================
	croak "Need a valid base URI.\n"
		unless $baseuri =~ /^[a-z][a-z0-9\+\-\.]*:/i;

	# Rationalise $content and set $domtree
	# =====================================
	croak "Need to provide XML content\n"
		unless defined $content;	
	my $domtree;
	if (blessed($content) && $content->isa('XML::LibXML::Document'))
	{
		($domtree, $content) = ($content, $content->toString);
	}
	else
	{
		my $xml_parser = XML::LibXML->new;
		$domtree = $xml_parser->parse_string($content);
	}
	
	# Rationalise $store
	# ==================
	$store = RDF::Trine::Store::DBI->temporary_store
		unless defined $store;
	
	my $self = bless {
		'content'   => $content,
		'baseuri'   => $baseuri,
		'options'   => $options,
		'DOM'       => $domtree,
		'RESULTS'   => RDF::Trine::Model->new($store),
		}, $class;
	
	return $self;
}

sub new_from_url
{
	my ($class, $url, $options, $store)= @_;
	
	if (!ref $options)
		{ $options = {}; }

	my $ua = LWP::UserAgent->new;
	$ua->agent(sprintf('%s/%s (%s) ', __PACKAGE__, __PACKAGE__->VERSION, __PACKAGE__->AUTHORITY));
	$ua->default_header("Accept" => "application/xrd+xml, application/xml;q=0.1, text/xml;q=0.1");
	my $response;
	my $timeout = $options->{timeout} // 60;
	eval {
		local $SIG{ALRM} = sub { die "Request timed out\n"; };
		alarm $timeout;
		$response = $ua->get($url);
		if ($response->code == 406)
		{
			$response = $ua->get($url, Accept=>'application/xrd+xml, application/x-httpd-php');
		}
		alarm 0;
	};
	croak $@ if $@;
	croak "HTTP response not successful\n"
		unless defined $response && $response->is_success;
	croak "Non-XRD HTTP response\n"
		unless $response->content_type =~ m`^(text/xml)|(application/(xrd\+xml|xml))$`
		|| ($options->{'loose_mime'} && $response->content_type =~ m`^(text/plain)|(text/html)|(application/octet-stream)$`);
	
	return $class->new(
		$response->decoded_content,
		$response->base.'',
		$options,
		$store,
		);
}

*new_from_uri = \&new_from_url;

sub hostmeta
{
	my $class = shift;
	my $host = shift;
	my $rv;

	my ($https, $http) = hostmeta_location($host);
	return unless $https;
	
	eval { $rv = $class->new_from_url($https, {timeout=>10, loose_mime=>1,default_subject=>host_uri($host)}); };
	return $rv if $rv;
	
	eval { $rv = $class->new_from_url($http, {timeout=>15, loose_mime=>1,default_subject=>host_uri($host)}); } ;
	return $rv if $rv;
	
	return;
}

sub uri
{
	my $this  = shift;
	my $param = shift // '';
	my $opts  = shift // {};
	
	if ((ref $opts) =~ /^XML::LibXML/)
	{
		my $x = {'element' => $opts};
		$opts = $x;
	}
	
	if ($param =~ /^([a-z][a-z0-9\+\.\-]*)\:/i)
	{
		# seems to be an absolute URI, so can safely return "as is".
		return $param;
	}
	elsif ($opts->{'require-absolute'})
	{
		return undef;
	}
	
	my $base = $this->{baseuri};
	if ($this->{'options'}->{'xml_base'})
	{
		$base = $opts->{'xml_base'} // $this->{baseuri};
	}
	
	my $url = url $param, $base;
	my $rv  = $url->abs->as_string;

	# This is needed to pass test case 0114.
	while ($rv =~ m!^(http://.*)(\.\./|\.)+(\.\.|\.)?$!i)
	{
		$rv = $1;
	}
	
	return $rv;
}

sub dom
{
	my $this = shift;
	return $this->{DOM};
}

sub graph
{
	my $this = shift;
	$this->consume;
	return $this->{RESULTS};
}

sub graphs
{
	my $this = shift;
	$this->consume;
	return { $this->{'baseuri'} => $this->{RESULTS} };
}

sub set_callbacks
# Set callback functions for handling RDF triples.
{
	my $this = shift;

	if ('HASH' eq ref $_[0])
	{
		$this->{'sub'} = $_[0];
		$this->{'sub'}->{'pretriple_resource'} = \&_print0
			if lc $this->{'sub'}->{'pretriple_resource'} eq 'print';
		$this->{'sub'}->{'pretriple_literal'} = \&_print1
			if lc $this->{'sub'}->{'pretriple_literal'} eq 'print';
	}
	elsif (defined $_[0])
	{
		croak("What kind of callback hashref was that??\n");
	}
	else
	{
		$this->{'sub'} = undef;
	}
	
	return $this;
}

sub _print0
# Prints a Turtle triple.
{
	my $this    = shift;
	my $element = shift;
	my $subject = shift;
	my $pred    = shift;
	my $object  = shift;
	my $graph   = shift;
	
	if ($graph)
	{
		print "# GRAPH $graph\n";
	}
	if ($element)
	{
		printf("# Triple on element %s.\n", $element->nodePath);
	}
	else
	{
		printf("# Triple.\n");
	}

	printf("%s %s %s .\n",
		($subject =~ /^_:/ ? $subject : "<$subject>"),
		"<$pred>",
		($object =~ /^_:/ ? $object : "<$object>"));
	
	return undef;
}

sub _print1
# Prints a Turtle triple.
{
	my $this    = shift;
	my $element = shift;
	my $subject = shift;
	my $pred    = shift;
	my $object  = shift;
	my $dt      = shift;
	my $lang    = shift;
	my $graph   = shift;
	
	# Clumsy, but probably works.
	$object =~ s/\\/\\\\/g;
	$object =~ s/\n/\\n/g;
	$object =~ s/\r/\\r/g;
	$object =~ s/\t/\\t/g;
	$object =~ s/\"/\\\"/g;
	
	if ($graph)
	{
		print "# GRAPH $graph\n";
	}
	if ($element)
	{
		printf("# Triple on element %s.\n", $element->nodePath);
	}
	else
	{
		printf("# Triple.\n");
	}

	no warnings;
	printf("%s %s %s%s%s .\n",
		($subject =~ /^_:/ ? $subject : "<$subject>"),
		"<$pred>",
		"\"$object\"",
		(length $dt ? "^^<$dt>" : ''),
		((length $lang && !length $dt) ? "\@$lang" : '')
		);
	use warnings;
	
	return undef;
}

sub consume
{
	my $this = shift;
	
	return $this if $this->{'consumed'};
	
	my @xrds = $this->{'DOM'}->getElementsByTagNameNS(NS_XRD, 'XRD')->get_nodelist;
	
	my $first = 1;
	my $only  = (scalar @xrds == 1) ? 1 : 0;
	
	foreach my $XRD (@xrds)
	{
		$this->_consume_XRD($XRD, $first, $only);
		$first = 0
			if $first;
	}
	
	$this->{'consumed'}++;
	
	return $this;
}

sub _consume_XRD
{
	my $this  = shift;
	my $xrd   = shift;
	my $first = shift // 0;
	my $only  = shift // 0;
	
	my $description_uri;
	if ($xrd->hasAttributeNS(NS_XML, 'id'))
	{
		$description_uri = $this->uri('#'.$xrd->getAttributeNS(NS_XML, 'id'));
	}
	elsif ($only)
	{
		$description_uri = $this->uri;
	}
	else
	{
		$description_uri = $this->bnode;
	}
			
	my $subject_node = $xrd->getChildrenByTagNameNS(NS_XRD, 'Subject')->shift;
	my $subject;
	my @subjects;
	$subject = $this->uri(
		$this->stringify($subject_node),
		{'require-absolute'=>1})
		if $subject_node;
	push @subjects, $subject
		if defined $subject;
	NAMESPACE: foreach my $hostmeta_ns (@{[NS_HOSTMETA, NS_HOSTMETX]})
	{
		my $host_uri;
		ELEMENT: foreach my $host_node ($xrd->getChildrenByTagNameNS($hostmeta_ns, 'Host')->get_nodelist)
		{
			$host_uri = host_uri($this->stringify($host_node));
			$subject = $host_uri
				unless defined $subject;
			push @subjects, $host_uri;
		}
		last NAMESPACE if $host_uri;
	}
	unless (@subjects)
	{
		if ($first && defined $this->{'options'}->{'default_subject'})
		{
			$subject = $this->{'options'}->{'default_subject'};
			push @subjects, $subject;
		}
	}
	unless (@subjects)
	{
		$subject = $this->bnode($xrd);
		push @subjects, $subject;
	}
	
	$this->rdf_triple($xrd, $description_uri, URI_XRD.'subject', $subject);
	
	foreach my $alias ( $xrd->getChildrenByTagNameNS(NS_XRD, 'Alias')->get_nodelist )
	{
		my $alias_uri = $this->uri($this->stringify($alias),{'require-absolute'=>1});
		$this->rdf_triple($alias, $subject, URI_XRD.'alias', $alias_uri);
	}
	
	my $expires_node = $xrd->getChildrenByTagNameNS(NS_XRD, 'Expires')->shift;
	my $expires      = $this->stringify($expires_node) if $expires_node;
	if (length $expires)
	{
		$this->rdf_triple_literal($expires_node,
			$description_uri, URI_XRD.'expires', $expires, URI_XSD.'dateTime');
	}
	
	foreach my $p ($xrd->getChildrenByTagNameNS(NS_XRD, 'Property')->get_nodelist)
	{
		$this->_consume_Property($p, \@subjects);
	}
	
	foreach my $l ($xrd->getChildrenByTagNameNS(NS_XRD, 'Link')->get_nodelist)
	{
		$this->_consume_Link($l, \@subjects);
	}
}

sub _consume_Property
{
	my $this = shift;
	my $p    = shift;
	my $S    = shift;
	
	my $property_uri = $this->uri(
		$p->getAttribute('type'), {'require-absolute'=>1});
	return unless $property_uri;
	
	my $value = $this->stringify($p);
	
	foreach my $subject_uri (@$S)
	{
		$this->rdf_triple_literal(
			$p,
			$subject_uri,
			$property_uri,
			$value);
	}
}

sub _consume_Link
{
	my $this = shift;
	my $l    = shift;
	my $S    = shift;
	
	my $property_uri = HTTP::Link::Parser::relationship_uri(
		$l->getAttribute('rel'));
	return unless $property_uri;
	
	my @value;
	my $value_type;
	my ($p1,$p2);
	if ($l->hasAttribute('href'))
	{
		push @value, $this->uri($l->getAttribute('href'));
		$value_type = 'href';
		($p1,$p2) = ('', $property_uri);
	}
	elsif ($l->hasAttribute('template'))
	{
		push @value, $l->getAttribute('template');
		push @value, URI_XRD . 'URITemplate';
		$value_type = 'template';
		($p1,$p2) = (SCHEME_TMPL, $property_uri);
		$property_uri = template_uri($property_uri);
	}
	else
	{
		return;
	}

	foreach my $subject_uri (@$S)
	{
		if ($value_type eq 'href')
		{
			$this->rdf_triple(
				$l,
				$subject_uri,
				$property_uri,
				@value);
		}
		elsif ($value_type eq 'template')
		{
			$this->rdf_triple_literal(
				$l,
				$subject_uri,
				$property_uri,
				@value);
		}
	}
	
	if ($value_type eq 'href')
	{
		my $type = $l->getAttribute('type');
		if (defined $type)
		{
			$this->rdf_triple_literal($l, @value, URI_XRD.'type', $type);
		}
		
		foreach my $title ($l->getChildrenByTagName('Title')->get_nodelist)
		{
			my $lang = undef;
			if ($title->hasAttributeNS(NS_XML, 'lang'))
			{
				$lang = $title->getAttributeNS(NS_XML, 'lang');
				$lang = undef unless valid_lang($lang);
			}
			$this->rdf_triple_literal(
				$title,
				@value,
				URI_XRD.'title',
				$this->stringify($title),
				undef,
				$lang);
		}		
	}
	
	foreach my $subject_uri (@$S)
	{
		my @link_properties = $l->getChildrenByTagNameNS(NS_XRD, 'Property')->get_nodelist;
		if (@link_properties)
		{
			if ($this->{'options'}->{'link_prop'} & 1)
			{
				my $reified_statement = $this->bnode($l);		
				$this->rdf_triple($l, $reified_statement, URI_RDF.'type', URI_RDF.'Statement');			
				$this->rdf_triple($l, $reified_statement, URI_RDF.'subject', $subject_uri);
				$this->rdf_triple($l, $reified_statement, URI_RDF.'predicate', $property_uri);
				
				if ($value_type eq 'href')
				{
					$this->rdf_triple($l, $reified_statement, URI_RDF.'object', @value);
				}
				else
				{
					$this->rdf_triple_literal($l, $reified_statement, URI_RDF.'object', @value);
				}
				
				foreach my $lp (@link_properties)
				{
					$this->_consume_Property($lp, [$reified_statement]);
				}
			}
			if ($this->{'options'}->{'link_prop'} & 2)
			{
				my $subPropUri = $p1 . URI_SUBLINK . uri_escape($p2);
				my @modifiers;
				foreach my $lp (@link_properties)
				{
					my $k = $this->uri($lp->getAttribute('type'), {'require-absolute'=>1});
					my $v = $this->stringify($lp);
					push @modifiers, sprintf('%s=%s', uri_escape($k), uri_escape($v))
						if length $k;
				}
				my $supermodifier = join '&', sort @modifiers;
				$subPropUri .= '/' . sha1_hex($supermodifier);
				
				if ($value_type eq 'href')
				{
					$this->rdf_triple($l, $subject_uri, $subPropUri, @value);
				}
				else
				{
					$this->rdf_triple_literal($l, $subject_uri, $subPropUri, @value);
				}
				
				$this->rdf_triple($l, $subPropUri, URI_RDF.'type', URI_RDF.'Property');
				$this->rdf_triple($l, $subPropUri, URI_RDFS.'subPropertyOf', $property_uri);
				foreach my $lp (@link_properties)
				{
					$this->_consume_Property($lp, [$subPropUri]);
				}
			}
		}
	}
}

sub rdf_triple
# Function only used internally.
{
	my $this = shift;

	my $suppress_triple = 0;
	$suppress_triple = $this->{'sub'}->{'pretriple_resource'}($this, @_)
		if defined $this->{'sub'}->{'pretriple_resource'};
	return if $suppress_triple;
	
	my $element   = shift;  # A reference to the XML::LibXML element being parsed
	my $subject   = shift;  # Subject URI or bnode
	my $predicate = shift;  # Predicate URI
	my $object    = shift;  # Resource URI or bnode
	my $graph     = shift;  # Graph URI or bnode (if named graphs feature is enabled)

	# First make sure the object node type is ok.
	my $to;
	if ($object =~ m/^_:(.*)/)
	{
		$to = RDF::Trine::Node::Blank->new($1);
	}
	else
	{
		$to = RDF::Trine::Node::Resource->new($object);
	}

	# Run the common function
	return $this->rdf_triple_common($element, $subject, $predicate, $to, $graph);
}

sub rdf_triple_literal
# Function only used internally.
{
	my $this = shift;

	my $suppress_triple = 0;
	$suppress_triple = $this->{'sub'}->{'pretriple_literal'}($this, @_)
		if defined $this->{'sub'}->{'pretriple_literal'};
	return if $suppress_triple;

	my $element   = shift;  # A reference to the XML::LibXML element being parsed
	my $subject   = shift;  # Subject URI or bnode
	my $predicate = shift;  # Predicate URI
	my $object    = shift;  # Resource Literal
	my $datatype  = shift;  # Datatype URI (possibly undef or '')
	my $language  = shift;  # Language (possibly undef or '')
	my $graph     = shift;  # Graph URI or bnode (if named graphs feature is enabled)

	# Now we know there's a literal
	my $to;
	
	# Work around bad Unicode handling in RDF::Trine.
	$object = encode_utf8($object);

	if (defined $datatype)
	{
		if ($datatype eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral')
		{
			if ($this->{'options'}->{'use_rtnlx'})
			{
				eval
				{
					require RDF::Trine::Node::Literal::XML;
					$to = RDF::Trine::Node::Literal::XML->new($element->childNodes);
				};
			}
			
			if ( $@ || !defined $to)
			{
				my $orig = $RDF::Trine::Node::Literal::USE_XMLLITERALS;
				$RDF::Trine::Node::Literal::USE_XMLLITERALS = 0;
				$to = RDF::Trine::Node::Literal->new($object, undef, $datatype);
				$RDF::Trine::Node::Literal::USE_XMLLITERALS = $orig;
			}
		}
		else
		{
			$to = RDF::Trine::Node::Literal->new($object, undef, $datatype);
		}
	}
	else
	{
		$to = RDF::Trine::Node::Literal->new($object, $language, undef);
	}

	# Run the common function
	$this->rdf_triple_common($element, $subject, $predicate, $to, $graph);
}

sub rdf_triple_common
# Function only used internally.
{
	my $this      = shift;  # A reference to the RDF::RDFa::Parser object
	my $element   = shift;  # A reference to the XML::LibXML element being parsed
	my $subject   = shift;  # Subject URI or bnode
	my $predicate = shift;  # Predicate URI
	my $to        = shift;  # RDF::Trine::Node Resource URI or bnode
	my $graph     = shift;  # Graph URI or bnode (if named graphs feature is enabled)

	# First, make sure subject and predicates are the right kind of nodes
	my $tp = RDF::Trine::Node::Resource->new($predicate);
	my $ts;
	if ($subject =~ m/^_:(.*)/)
	{
		$ts = RDF::Trine::Node::Blank->new($1);
	}
	else
	{
		$ts = RDF::Trine::Node::Resource->new($subject);
	}

	my $statement;

	# If we are configured for it, and graph name can be found, add it.
	if (ref($this->{'options'}->{'named_graphs'}) && ($graph))
	{
		$this->{Graphs}->{$graph}++;
		
		my $tg;
		if ($graph =~ m/^_:(.*)/)
		{
			$tg = RDF::Trine::Node::Blank->new($1);
		}
		else
		{
			$tg = RDF::Trine::Node::Resource->new($graph);
		}

		$statement = RDF::Trine::Statement::Quad->new($ts, $tp, $to, $tg);
	}
	else
	{
		$statement = RDF::Trine::Statement->new($ts, $tp, $to);
	}

	my $suppress_triple = 0;
	$suppress_triple = $this->{'sub'}->{'ontriple'}($this, $element, $statement)
		if ($this->{'sub'}->{'ontriple'});
	return if $suppress_triple;

	$this->{RESULTS}->add_statement($statement);
}

sub stringify
# Function only used internally.
{
	my $this = shift;
	my $dom  = shift;
	
	if ($dom->nodeType == XML_TEXT_NODE)
	{
		return $dom->getData;
	}
	elsif ($dom->nodeType == XML_ELEMENT_NODE)
	{
		my $rv = '';
		foreach my $kid ($dom->childNodes)
			{ $rv .= $this->stringify($kid); }
		return $rv;
	}

	return '';
}

sub xmlify
# Function only used internally.
{
	my $this = shift;
	my $dom  = shift;
	my $lang = shift;
	my $rv;
	
	foreach my $kid ($dom->childNodes)
	{
		my $fakelang = 0;
		if (($kid->nodeType == XML_ELEMENT_NODE) && defined $lang)
		{
			unless ($kid->hasAttributeNS(NS_XML, 'lang'))
			{
				$kid->setAttributeNS(NS_XML, 'lang', $lang);
				$fakelang++;
			}
		}
		
		$rv .= $kid->toStringEC14N(1);
		
		if ($fakelang)
		{
			$kid->removeAttributeNS(NS_XML, 'lang');
		}
	}
	
	return $rv;
}

sub bnode
# Function only used internally.
{
	my $this    = shift;
	my $element = shift;
	
	return sprintf('http://thing-described-by.org/?%s#%s',
		$this->uri,
		$element->getAttributeNS(NS_XML, 'id'))
		if ($this->{options}->{tdb_service} && $element && length $element->getAttributeNS(NS_XML, 'id'));

	$this->{bnode_prefix} //= do {
		my $uuid = Data::UUID->new->create_str;
		$uuid =~ s/[^A-Za-z0-9]//g;
		$uuid;
		};
	
	return sprintf('_:x%sx%03d', $this->{bnode_prefix}, $this->{bnodes}++);
}

sub valid_lang
{
	my $value_to_test = shift;

	return 1 if (defined $value_to_test) && ($value_to_test eq '');
	return 0 unless defined $value_to_test;
	
	# Regex for recognizing RFC 4646 well-formed tags
	# http://www.rfc-editor.org/rfc/rfc4646.txt
	# http://tools.ietf.org/html/draft-ietf-ltru-4646bis-21

	# The structure requires no forward references, so it reverses the order.
	# It uses Java/Perl syntax instead of the old ABNF
	# The uppercase comments are fragments copied from RFC 4646

	# Note: the tool requires that any real "=" or "#" or ";" in the regex be escaped.

	my $alpha      = '[a-z]';      # ALPHA
	my $digit      = '[0-9]';      # DIGIT
	my $alphanum   = '[a-z0-9]';   # ALPHA / DIGIT
	my $x          = 'x';          # private use singleton
	my $singleton  = '[a-wyz]';    # other singleton
	my $s          = '[_-]';       # separator -- lenient parsers will use [_-] -- strict will use [-]

	# Now do the components. The structure is slightly different to allow for capturing the right components.
	# The notation (?:....) is a non-capturing version of (...): so the "?:" can be deleted if someone doesn't care about capturing.

	my $language   = '([a-z]{2,8}) | ([a-z]{2,3} $s [a-z]{3})';
	
	# ABNF (2*3ALPHA) / 4ALPHA / 5*8ALPHA  --- note: because of how | works in regex, don't use $alpha{2,3} | $alpha{4,8} 
	# We don't have to have the general case of extlang, because there can be only one extlang (except for zh-min-nan).

	# Note: extlang invalid in Unicode language tags

	my $script = '[a-z]{4}' ;   # 4ALPHA 

	my $region = '(?: [a-z]{2}|[0-9]{3})' ;    # 2ALPHA / 3DIGIT

	my $variant    = '(?: [a-z0-9]{5,8} | [0-9] [a-z0-9]{3} )' ;  # 5*8alphanum / (DIGIT 3alphanum)

	my $extension  = '(?: [a-wyz] (?: [_-] [a-z0-9]{2,8} )+ )' ; # singleton 1*("-" (2*8alphanum))

	my $privateUse = '(?: x (?: [_-] [a-z0-9]{1,8} )+ )' ; # "x" 1*("-" (1*8alphanum))

	# Define certain grandfathered codes, since otherwise the regex is pretty useless.
	# Since these are limited, this is safe even later changes to the registry --
	# the only oddity is that it might change the type of the tag, and thus
	# the results from the capturing groups.
	# http://www.iana.org/assignments/language-subtag-registry
	# Note that these have to be compared case insensitively, requiring (?i) below.

	my $grandfathered  = '(?:
			  (en [_-] GB [_-] oed)
			| (i [_-] (?: ami | bnn | default | enochian | hak | klingon | lux | mingo | navajo | pwn | tao | tay | tsu ))
			| (no [_-] (?: bok | nyn ))
			| (sgn [_-] (?: BE [_-] (?: fr | nl) | CH [_-] de ))
			| (zh [_-] min [_-] nan)
			)';

	# old:         | zh $s (?: cmn (?: $s Hans | $s Hant )? | gan | min (?: $s nan)? | wuu | yue );
	# For well-formedness, we don't need the ones that would otherwise pass.
	# For validity, they need to be checked.

	# $grandfatheredWellFormed = (?:
	#         art $s lojban
	#     | cel $s gaulish
	#     | zh $s (?: guoyu | hakka | xiang )
	# );

	# Unicode locales: but we are shifting to a compatible form
	# $keyvalue = (?: $alphanum+ \= $alphanum+);
	# $keywords = ($keyvalue (?: \; $keyvalue)*);

	# We separate items that we want to capture as a single group

	my $variantList   = $variant . '(?:' . $s . $variant . ')*' ;     # special for multiples
	my $extensionList = $extension . '(?:' . $s . $extension . ')*' ; # special for multiples

	my $langtag = "
			($language)
			($s ( $script ) )?
			($s ( $region ) )?
			($s ( $variantList ) )?
			($s ( $extensionList ) )?
			($s ( $privateUse ) )?
			";

	# Here is the final breakdown, with capturing groups for each of these components
	# The variants, extensions, grandfathered, and private-use may have interior '-'
	
	my $r = ($value_to_test =~ 
		/^(
			($langtag)
		 | ($privateUse)
		 | ($grandfathered)
		 )$/xi);
	return $r;
}

sub host_uri
{
	my $uri = shift;

	if ($uri =~ /:/)
	{
		my $tmpuri = URI->new($uri);
		
		if ($tmpuri->can('host'))
		{
			return URI_HOST . $tmpuri->host;
		}
		elsif($tmpuri->can('authority') && $tmpuri->authority =~ /\@/)
		{
			(undef, my $host) = split /\@/, $tmpuri->authority;
			return URI_HOST . $host;
		}
		elsif($tmpuri->can('opaque') && $tmpuri->opaque =~ /\@/)
		{
			(undef, my $host) = split /\@/, $tmpuri->opaque;
			return URI_HOST . $host;
		}
	}
	else
	{
		return URI_HOST . $uri;
	}
	
	return undef;
}

sub template_uri
{
	my $uri = shift;
	return SCHEME_TMPL . $uri;
}


sub hostmeta_location
{
	my $host  = shift;

	if ($host =~ /:/)
	{
		my $u = url $host;
		if ($u->can('host'))
		{
			$host = $u->host;
		}
		elsif ($u->can('authority') && $u->authority =~ /\@/)
		{
			(undef, $host) = split /\@/, $u->authority;
		}
		elsif ($u->can('opaque') && $u->opaque =~ /\@/)
		{
			(undef, $host) = split /\@/, $u->opaque;
		}
	}
	
	if (wantarray)
	{
		return ("https://$host/.well-known/host-meta", "http://$host/.well-known/host-meta");
	}
	else
	{
		return "http://$host/.well-known/host-meta";
	}
}

1;

__END__

=head1 NAME

XRD::Parser - parse XRD and host-meta files into RDF::Trine models

=head1 SYNOPSIS

  use RDF::Query;
  use XRD::Parser;
  
  my $parser = XRD::Parser->new(undef, "http://example.com/foo.xrd");
  my $results = RDF::Query->new(
    "SELECT * WHERE {?who <http://spec.example.net/auth/1.0> ?auth.}")
    ->execute($parser->graph);
	
  while (my $result = $results->next)
  {
    print $result->{'auth'}->uri . "\n";
  }

or maybe:

  my $data = XRD::Parser->hostmeta('gmail.com')
                          ->graph
                            ->as_hashref;

=head1 DESCRIPTION

While XRD has a rather different history, it turns out it can mostly
be thought of as a serialisation format for a limited subset of
RDF.

This package ignores the order of <Link> elements, as RDF is a graph
format with no concept of statements coming in an "order". The XRD spec
says that grokking the order of <Link> elements is only a SHOULD. That
said, if you're concerned about the order of <Link> elements, the
callback routines allowed by this package may be of use.

This package aims to be roughly compatible with RDF::RDFa::Parser's
interface.

=head2 Constructors

=over 4

=item C<< $p = XRD::Parser->new($content, $uri, [\%options], [$store]) >>

This method creates a new XRD::Parser object and returns it.

The $content variable may contain an XML string, or a XML::LibXML::Document.
If a string, the document is parsed using XML::LibXML::Parser, which may throw an
exception. XRD::Parser does not catch the exception.

$uri the base URI of the content; it is used to resolve any relative URIs found
in the XRD document. 

Options [default in brackets]:

=over 8

=item * B<default_subject> - If no <Subject> element. [undef]

=item * B<link_prop> - How to handle <Property> in <Link>?
0=skip, 1=reify, 2=subproperty, 3=both. [0] 

=item * B<loose_mime> - Accept text/plain, text/html and
application/octet-stream media types. [0]

=item * B<tdb_service> - Use thing-described-by.org when possible. [0]

=back

$storage is an RDF::Trine::Storage object. If undef, then a new
temporary store is created.

=item C<< $p = XRD::Parser->new_from_url($url, [\%options], [$storage]) >>

$url is a URL to fetch and parse.

This function can also be called as C<new_from_uri>. Same thing.

=item C<< $p = XRD::Parser->hostmeta($uri) >>

This method creates a new XRD::Parser object and returns it.

The parameter may be a URI (from which the hostname will be extracted) or
just a bare host name (e.g. "example.com"). The resource
"/.well-known/host-meta" will then be fetched from that host using an
appropriate HTTP Accept header, and the parser object returned.

=back

=head2 Public Methods

=over 4

=item C<< $p->uri($uri) >>

Returns the base URI of the document being parsed. This will usually be the
same as the base URI provided to the constructor.

Optionally it may be passed a parameter - an absolute or relative URI - in
which case it returns the same URI which it was passed as a parameter, but
as an absolute URI, resolved relative to the document's base URI.

This seems like two unrelated functions, but if you consider the consequence
of passing a relative URI consisting of a zero-length string, it in fact makes
sense.

=item C<< $p->dom >>

Returns the parsed XML::LibXML::Document.

=item C<< $p->graph >>

This method will return an RDF::Trine::Model object with all
statements of the full graph.

This method will automatically call C<consume> first, if it has not
already been called.

=item $p->set_callbacks(\%callbacks)

Set callback functions for the parser to call on certain events. These are only necessary if
you want to do something especially unusual.

  $p->set_callbacks({
    'pretriple_resource' => sub { ... } ,
    'pretriple_literal'  => sub { ... } ,
    'ontriple'           => undef ,
    });

Either of the two pretriple callbacks can be set to the string 'print' instead of a coderef.
This enables built-in callbacks for printing Turtle to STDOUT.

For details of the callback functions, see the section CALLBACKS. C<set_callbacks> must
be used I<before> C<consume>. C<set_callbacks> itself returns a reference to the parser
object itself.

I<NOTE:> the behaviour of this function was changed in version 0.05.

=item C<< $p->consume >>

This method processes the input DOM and sends the resulting triples to 
the callback functions (if any).

It called again, does nothing.

Returns the parser object itself.

=back

=head2 Utility Functions

=over 4

=item C<< $host_uri = XRD::Parser::host_uri($uri) >>

Returns a URI representing the host. These crop up often in graphs gleaned
from host-meta files.

$uri can be an absolute URI like 'http://example.net/foo#bar' or a host
name like 'example.com'.

=item C<< $uri = XRD::Parser::template_uri($relationship_uri) >>

Returns a URI representing not a normal relationship, but the
relationship between a host and a template URI literal.

=item C<< $hostmeta_uri = XRD::Parser::hostmeta_location($host) >>

The parameter may be a URI (from which the hostname will be extracted) or
just a bare host name (e.g. "example.com"). The location for a host-meta file
relevant to the host of that URI will be calculated.

If called in list context, returns an 'https' URI and an 'http' URI as a list.

=back

=head1 CALLBACKS

Several callback functions are provided. These may be set using the C<set_callbacks> function,
which taskes a hashref of keys pointing to coderefs. The keys are named for the event to fire the
callback on.

=head2 pretriple_resource

This is called when a triple has been found, but before preparing the triple for
adding to the model. It is only called for triples with a non-literal object value.

The parameters passed to the callback function are:

=over 4

=item * A reference to the C<XRD::Parser> object

=item * A reference to the C<XML::LibXML::Element> being parsed

=item * Subject URI or bnode (string)

=item * Predicate URI (string)

=item * Object URI or bnode (string)

=back

The callback should return 1 to tell the parser to skip this triple (not add it to
the graph); return 0 otherwise.

=head2 pretriple_literal

This is the equivalent of pretriple_resource, but is only called for triples with a
literal object value.

The parameters passed to the callback function are:

=over 4

=item * A reference to the C<XRD::Parser> object

=item * A reference to the C<XML::LibXML::Element> being parsed

=item * Subject URI or bnode (string)

=item * Predicate URI (string)

=item * Object literal (string)

=item * Datatype URI (string or undef)

=item * Language (string or undef)

=back

The callback should return 1 to tell the parser to skip this triple (not add it to
the graph); return 0 otherwise.

=head2 ontriple

This is called once a triple is ready to be added to the graph. (After the pretriple
callbacks.) The parameters passed to the callback function are:

=over 4

=item * A reference to the C<XRD::Parser> object

=item * A reference to the C<XML::LibXML::Element> being parsed

=item * An RDF::Trine::Statement object.

=back

The callback should return 1 to tell the parser to skip this triple (not add it to
the graph); return 0 otherwise. The callback may modify the RDF::Trine::Statement
object.

=head1 WHY RDF?

It abstracts away the structure of the XRD file, exposing just the meaning
of its contents. Two XRD files with the same meaning should end up producing
more or less the same RDF data, even if they differ significantly at the
syntactic level.

If you care about the syntax of an XRD file, then use L<XML::LibXML>.

=head1 SEE ALSO

L<RDF::Trine>, L<RDF::Query>, L<RDF::RDFa::Parser>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2009-2012 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
