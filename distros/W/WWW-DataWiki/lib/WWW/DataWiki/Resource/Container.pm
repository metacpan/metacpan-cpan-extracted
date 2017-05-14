use 5.010;
use utf8;
use autodie;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Resource::Container::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Resource::Container::VERSION   = '0.001';
}

class WWW::DataWiki::Resource::Container
	extends WWW::DataWiki::Resource
	with WWW::DataWiki::Trait::RdfModel
	with WWW::DataWiki::Trait::Title
	with WWW::DataWiki::Trait::Negotiator
{
	use DateTimeX::Format::Ago;
	use HTML::HTML5::Builder qw/:standard/;
	use HTML::HTML5::Writer;
	use IO::Compress::Gzip qw[gzip];
	use List::MoreUtils qw[uniq];
	use RDF::RDFa::Parser;
	use XML::Atom::FromOWL;
	use XML::LibXML::PrettyPrint;
	
	use RDF::Trine qw[iri literal blank statement];
	use RDF::Trine::Namespace qw[rdf rdfs owl xsd];
	my $awol = RDF::Trine::Namespace->new('http://bblfish.net/work/atom-owl/2006-06-06/#');
	my $rel  = RDF::Trine::Namespace->new('http://www.iana.org/assignments/relation/');
	
	has wikiname => (is => 'ro', isa => 'Str', required=>1);
	
	method _stem
	{
		return $self->context->uri_for('') if defined $self->context;
		return '/';
	}
	
	method container_iri
	{
		(my $wn = $self->wikiname) =~ s{^/}{};
		return iri(sprintf('%s%s', $self->_stem, $wn));
	}

	method title_string
	{
		return 'WWW::DataWiki' if $self->wikiname eq '/';
		return $self->wikiname;
	}
	
	method all_members
	{
		return map
			{ WWW::DataWiki->resource_class('Page')->new(wikiname=>$_, context=>$self->context) }
			$self->all_member_names;
	}

	method all_member_names
	{
		my $storage = WWW::DataWiki->config->{storage};
		(my $dirname = $self->wikiname) =~ s{/}{_}g;
		$dirname = '' if $dirname eq '_';
		
		my $dh;
		opendir $dh, $storage;
		my @members = 
			map { s{_}{/}g; $_ }
			grep { -d File::Spec->catdir($storage, $_) }
			grep { m!^${dirname}([^_]+)$! }
			grep { !/^[.]/ }
			readdir $dh;
		return sort @members;
	}
	
	method all_children
	{
		return map
			{ WWW::DataWiki->resource_class('Container')->new(wikiname=>$_, context=>$self->context) }
			$self->all_child_names;
	}
	
	method all_child_names
	{
		my $storage = WWW::DataWiki->config->{storage};
		(my $dirname = $self->wikiname) =~ s{/}{_}g;
		$dirname = '' if $dirname eq '_';
		
		my $dh;
		opendir $dh, $storage;
		my @kids = 
			uniq
			map { s<^(${dirname}[^_]+_).*><$1>g; s{_}{/}g; $_ }
			grep { -d File::Spec->catdir($storage, $_) }
			grep { m!^${dirname}([^_]+)_! }
			grep { !/^[.]/ }
			readdir $dh;
		return sort @kids;
	}
	
	method available_formats
	{
		my @formats = WWW::DataWiki::Trait::RdfModel::available_formats($self);
		push @formats, ['atom', 1.0, 'application/atom+xml', undef, 'utf-8'];
		return @formats;
	}

	method rdf_string_as ($format, $gzipped) 
	{
		my ($writer, $str);
		if ($format eq WWW::DataWiki->FMT_HTML)
		{
			$writer = HTML::HTML5::Writer->new(markup => 'html');
		}
		elsif ($format eq WWW::DataWiki->FMT_XHTML)
		{
			$writer = HTML::HTML5::Writer->new(markup => 'xhtml');
		}
		elsif ($format eq 'atom')
		{
			my $fromowl = XML::Atom::FromOWL->new;
			my ($feed)  = $fromowl->export_feeds($self->rdf_model);
			$str = $feed->as_xml;
		}
		
		if ($writer)
		{
			$str = $writer->document($self->index_dom(1));
		}
		
		if ($str)
		{
			return $str unless $gzipped;			
			my $zstr;
			gzip \$str => \$zstr;
			return $zstr;
		}
		
		return WWW::DataWiki::Trait::RdfModel::rdf_string_as($self, $format, $gzipped);
	}

	method rdf_model
	{
		my $parser = RDF::RDFa::Parser->new(
			$self->index_dom,
			$self->container_iri->uri,
			RDF::RDFa::Parser::Config->new('xhtml', '1.0'),
			);
		return $parser->graph;
	}

	method index_dom ($do_pp?)
	{
		my $ago = DateTimeX::Format::Ago->new(language=>'en');
		my $dom = html(
			{ 'xmlns:awol' => 'http://bblfish.net/work/atom-owl/2006-06-06/#', 'xmlns:rel' => 'http://www.iana.org/assignments/relation/' },
			head(
				title($self->title_string),
				style(-type=>'text/css', -media=>'screen,projection', sprintf('@import url(%s)', '/static/styles/page.css')),
				HTML::HTML5::Builder::link(-rel=>'alternate', -type=>'application/atom+xml', -href=>$self->container_iri->uri.'?accept=application%2fatom%2bxml'),
				),
			body(
				-about => '', -rev => 'rel:self', 
				div(
					-about => '_:feed', -typeof => 'awol:Feed', -property => 'awol:id', -content => $self->container_iri->uri, 
					h1(-property => 'awol:title', $self->title_string),
					h2('Pages in this Container'),
					$self->all_members ? ul(
						-rel => 'awol:entry',
						map
						{
							my $page = $_;
							my $ver  = $page->latest_version;
							if ($ver)
							{
								my $modified = $ver->last_modified;
								$modified->set_formatter($ago);
								my $published = $page->earliest_version->last_modified;
								
								li(
									-typeof => 'awol:Entry', -property => 'awol:id', -content => $page->page_iri->uri,
									strong(a(-rel=>'rel:self', -href=>$page->page_iri->uri, -property => 'awol:title', $page->title_string)), 
									' (', a(-rel=>'rel:alternate', -href=>$ver->formatted_page_iri('html')->uri, 'html'), ')',
									' (', a(-rel=>'rel:alternate', -href=>$ver->formatted_page_iri('xml')->uri, 'xml'), ')',
									' (', a(-rel=>'rel:alternate', -href=>$ver->formatted_page_iri('n3')->uri, 'n3'), ')',
									' (', a(-rel=>'rel:alternate', -href=>$ver->formatted_page_iri('json')->uri, 'json'), ')',
									br(
										-property => 'awol:published',
										-content  => $published->strftime('%Y-%m-%dT%H:%M:%SZ'),
										-datatype => $xsd->dateTime->uri,
										),
									'Modified ', HTML::HTML5::Builder::time(
										-property => 'awol:updated',
										-content  => $modified->strftime('%Y-%m-%dT%H:%M:%SZ'),
										-datetime => $modified->strftime('%Y-%m-%dT%H:%M:%SZ'),
										-datatype => $xsd->dateTime->uri,
										$modified,
										),
									' (', a(-rel=>'rel:version-history', -href=>$ver->page->history_iri->uri, 'history'), ')',
									' (', a(-rel=>'rel:edit', -href=>$ver->page->page_iri->uri.',edit', 'edit'), ')',
									do {
										if ( my $child = $page->associated_container )
											{ (br(), 'This page has ', a(-href => $child->container_iri->uri, 'subpages'), '.'); }
										else
											{ @{[]}; }
										}
									);
							}
							else
							{
								();
							}
						}
						$self->all_members,
						) : p('(none)'),
						h2('Subcontainers'),
						$self->all_children ? ul(
							map
							{
								li(
									a(-href => $_->container_iri->uri, $_->title_string),
									);
							}
							$self->all_children,
							) : p('(none)'),
					),
					WWW::DataWiki::Model::Wiki->standard_footer,
				),
			);
		
		if ($do_pp)
		{
			# We don't really need to pretty-print this, but it's usually only a small DOM.
			my $pp = XML::LibXML::PrettyPrint->new_for_html;
			push @{$pp->{element}{preserves_whitespace}}, sub
			{
				if ($_[0]->hasAttribute('property') and not $_[0]->hasAttribute('content'))
				{
					# Preserve whitespace when element is an RDFa literal.
					return 1;
				}
				return undef;
			};
			$pp->pretty_print($dom);
		}
		
		return $dom;
	}

	method help
	{
		my $dom  = html(
			-lang => 'en', '-xml:lang' => 'en', -version => 'XHTML+RDFa 1.1',
			-prefix => 'srv: http://ontologi.es/srv# u: http://purl.org/NET/uri# rdfs: http://www.w3.org/2000/01/rdf-schema# ht: http://www.w3.org/2011/http# hth: http://www.w3.org/2011/http-headers# htm: http://www.w3.org/2011/http-methods# htc: http://www.w3.org/2011/http-statusCodes#',
			head(
				title('HTTP Options for ', $self->container_iri),
				style(-type=>'text/css', -media=>'screen,projection', sprintf('@import url(%s)', '/static/styles/page.css')),
				),
			body(-about=>'[_:This]', -typeof=>'srv:Endpoint',
				h1(-lang=>'en', -rel=>'srv:uri_base', 'HTTP Options for ', span(-property=>'u:identifier', -content=>$self->container_iri->uri, $self->container_iri)),
				ul(-rev=>'srv:endpoint',
					li(-typeof=>'srv:Action',
						div(
							strong(-rel=>'srv:req_method', -resource=>'[htm:OPTIONS]', 'OPTIONS'), ' ',
							),
						div(-property=>'rdfs:comment',
							'Shows this help.'
							),
						),
					li(-typeof=>'srv:Action',
						div(
							strong(-rel=>'srv:req_method', -resource=>'[htm:GET]', 'GET'), ' ',
							'with no parameters',
							),
						div(-property=>'rdfs:comment',
							'Retrieves a list of members of the collection, modelled as an RDF graph.'
							),
						),
					li(-typeof=>'srv:Action',
						div(
							strong(-rel=>'srv:req_method', -resource=>'[htm:GET]', 'GET'), ' ',
							span(-rel=>'srv:req_param', 'with parameter ', em(-property=>'srv:name', 'query')),
							),
						div(-property=>'rdfs:comment',
							'Queries the graph with SPARQL, returning the results.'
							),
						),
					li(-typeof=>'srv:Action',
						div(
							strong(-rel=>'srv:req_method', -resource=>'[htm:POST]', 'POST'), ' ',
							span(-rel=>'srv:req_header', 'with header ', em(-typeof=>'ht:RequestHeader', span(-rel=>'ht:hdrName', -resource=>'[hth:content-type]', -property=>'ht:fieldName','Content-Type'), ': ', span(-property=>'ht:fieldValue', 'application/x-www-form-urlencoded'))), ' ',
							span(-rel=>'srv:req_param', 'with parameter ', em(-property=>'srv:name', 'query')),
							),
						div(-property=>'rdfs:comment',
							'Queries the graph with SPARQL, returning the results.'
							),
						),
					li(-typeof=>'srv:Action',
						div(
							strong(-rel=>'srv:req_method', -resource=>'[htm:POST]', 'POST'), ' ',
							span(-rel=>'srv:req_header', 'with header ', em(-typeof=>'ht:RequestHeader', span(-rel=>'ht:hdrName', -resource=>'[hth:content-type]', -property=>'ht:fieldName','Content-Type'), ': ', span(-property=>'ht:fieldValue', 'application/sparql-query'))),
							),
						div(-property=>'rdfs:comment',
							'Queries the graph with SPARQL, returning the results.'
							),
						),
					li(-typeof=>'srv:Action',
						div(
							strong(-rel=>'srv:req_method', -resource=>'[htm:POST]', 'POST'), ' ',
							span(-rel=>'srv:req_header', 'with header ', em(-typeof=>'ht:RequestHeader', span(-rel=>'ht:hdrName', -resource=>'[hth:content-type]', -property=>'ht:fieldName','Content-Type'), ': ', span(-rel=>'srv:fieldValueRange', -resource=> '[_:RDF]', '(an RDF serialisation)'))),
							),
						div(-property=>'rdfs:comment',
							'Creates a new member of the collection.'
							),
						),
					),
				WWW::DataWiki::Model::Wiki->standard_footer,
				),
			);
		
		# We don't really need to pretty-print this, but it's only a small DOM.
		my $pp = XML::LibXML::PrettyPrint->new_for_html;
		push @{$pp->{element}{preserves_whitespace}}, sub
		{
			if ($_[0]->hasAttribute('property') and not $_[0]->hasAttribute('content'))
			{
				# Preserve whitespace when element is an RDFa literal.
				return 1;
			}
			return undef;
		};
		$pp->pretty_print($dom);
		
		return WWW::DataWiki->resource_class('Information')->new(dom => $dom);
	}

	method accepts_updates
	{
		0;
	}

	around http_headers ($ctx)
	{
		my @headers = $self->$orig($ctx);
		push @headers, ['MS-Author-Via' => 'DAV'];
		push @headers, [Content_Location => $self->container_iri->uri];
		push @headers,
			[Link => sprintf('<%s>; rev="index"', $_->page_iri->uri)]
			foreach $self->all_members;
		push @headers,
			[Link => sprintf('<%s>; rev="up"', $_->container_iri->uri)]
			foreach $self->all_children;
		push @headers, [Link => sprintf('<%s>; x-http-method="OPTIONS"; rel="help"', $self->container_iri->uri)];
		return @headers;
	}

}

1;
