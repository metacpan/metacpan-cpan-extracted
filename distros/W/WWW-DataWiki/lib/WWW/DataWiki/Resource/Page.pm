use 5.010;
use utf8;
use autodie;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Resource::Page::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Resource::Page::VERSION   = '0.001';
}

class WWW::DataWiki::Resource::Page
	extends WWW::DataWiki::Resource
	with WWW::DataWiki::Trait::RdfModel
	with WWW::DataWiki::Trait::Title
	with WWW::DataWiki::Trait::Negotiator
{
	use File::Spec;
	use RDF::Trine qw[statement iri literal blank];
	use Time::HiRes qw[usleep];
	use HTML::HTML5::Builder qw[:standard link];
	use XML::LibXML::PrettyPrint;
	
	has wikiname => (is => 'ro', isa => 'Str', required=>1);
	
	use RDF::Trine::Namespace qw[rdf rdfs owl xsd];
	my $dc = RDF::Trine::Namespace->new('http://purl.org/dc/terms/');

	method _stem
	{
		return $self->context->uri_for('') if defined $self->context;
		return '/';
	}
	
	method storage
	{
		my $storage = WWW::DataWiki->config->{storage};
		my $n = $self->wikiname;
		$n =~ s{/}{_}g;
		return File::Spec->catdir($storage, $n);
	}

	method title_string
	{
		return $self->wikiname;
	}

	method page_iri
	{
		return iri(sprintf('%s%s', $self->_stem, $self->wikiname));
	}

	method version_iri (Str $version)
	{
		return iri(sprintf('%s%s,%s', $self->_stem, $self->wikiname, $version));
	}

	method history_iri
	{
		return iri(sprintf('%s%s,history', $self->_stem, $self->wikiname));
	}

	method formatted_page_iri ($format)
	{
		return iri(sprintf('%s%s.%s', $self->_stem, $self->wikiname, $format));
	}

	method formatted_version_iri (Str $version, $format)
	{
		return iri(sprintf('%s%s.%s,%s', $self->_stem, $self->wikiname, $format, $version));
	}

	method formatted_history_iri ($format)
	{
		return iri(sprintf('%s%s.%s,history', $self->_stem, $self->wikiname, $format));
	}
	
	method all_versions
	{
		return map
			{ $self->instantiate_version($_) }
			$self->all_version_ids;
	}
	
	method instantiate_version (Str $id)
	{
		WWW::DataWiki->resource_class('Version')->new(page =>$self, version => $id, context => $self->context);
	}

	method all_version_ids
	{
		my $dh;
		opendir $dh, $self->storage;
		my @versions = 
			map { s{^ (.*/)? ([^/]+) \.n3\.gz $}{$2}x; $_ }
			grep { /\.n3\.gz$/ }
			readdir $dh;
		return @versions;
	}
	
	method rdf_model
	{
		my $model = RDF::Trine::Model->new;
		my $old;
		$model->add_statement(statement($self->page_iri, $dc->type, iri('http://purl.org/dc/dcmitype/Dataset')));
		$model->add_statement(statement($self->page_iri, $dc->identifier, literal($self->page_iri->uri, undef, $xsd->anyURI)));
		$model->add_statement(statement($self->page_iri, $dc->provenance, $self->history_iri));
		foreach ($self->all_versions)
		{
			$model->add_statement(statement($self->page_iri, $dc->hasVersion, $_->version_iri));
			$model->add_statement(statement($_->version_iri, $dc->type, iri('http://purl.org/dc/dcmitype/Dataset')));
			$model->add_statement(statement($_->version_iri, $dc->identifier, literal($_->version_iri->uri, undef, $xsd->anyURI)));
			$model->add_statement(statement($_->version_iri, $dc->isVersionOf, $self->page_iri));
			$model->add_statement(statement($_->version_iri, $dc->dateAccepted, literal($_->last_modified->strftime('%Y-%m-%dT%H:%M:%SZ'), undef, $xsd->dateTime)));
			if (defined $old)
			{
				$model->add_statement(statement($_->version_iri, $dc->replaces, $old->version_iri));
				$model->add_statement(statement($old->version_iri, $dc->isReplacedBy, $_->version_iri));
			}
			$old = $_;
		}
		
		RDF::Trine::Parser
			->new('NTriples')
			->parse_file_into_model($self->page_iri->uri, $self->meta_filename, $model)
			if -f $self->meta_filename;
		
		return $model;
	}
	
	method latest_version
	{
		my ($latest) = reverse sort $self->all_version_ids;
		return unless defined $latest;
		return $self->instantiate_version($latest);
	}

	method earliest_version
	{
		my ($earliest) = sort $self->all_version_ids;
		return unless defined $earliest;
		return $self->instantiate_version($earliest);
	}

	method latest_version_as_of (Str $datestring)
	{
		my ($latest) = reverse sort grep { $_ le $datestring } $self->all_version_ids;
		return unless defined $latest;
		return $self->instantiate_version($latest);
	}
	
	method version_offset_from (Str $datestring, Num $offset)
	{
		my @versions = sort $self->all_version_ids;
		for (my $i=0; exists $versions[$i]; $i++)
		{
			next unless $i+$offset >= 0;
			if ($versions[$i] eq $datestring and exists $versions[$i+$offset])
			{
				return $self->instantiate_version($versions[$i+$offset]);
			}
		}
	}

	method create_version ($model)
	{
		my $storage = $self->storage;

		# Make sure directory exists
		mkdir $storage unless -d $storage;

		# Figure out filename
		my $vid = DateTime->now(formatter=>WWW::DataWiki::Utils->dt_fmt_short);
		my $fn  = File::Spec->catfile($storage, sprintf('%s.n3.gz', $vid));
		open my $fh, ">:gzip", $fn;
		
		if (blessed($model) and $model->isa('RDF::Trine::Model'))
		{
			my $ns   = $WWW::DataWiki::Trait::RdfModel::MAP;
			my $ser  = RDF::Trine::Serializer::Turtle->new(namespaces=>$ns);
			
			# Check to make sure graph is RDF-compatible.
			my $iter = $model->as_stream;
			ST: while (my $st = $iter->next)
			{
				unless ($st->rdf_compatible)
				{
					# A non-RDF statement found, so switch to Notation 3.
					$ser = RDF::Trine::Serializer::Notation3->new(namespaces=>$ns);
					last ST;
				}
			}

			# Save version. 
			$ser->serialize_model_to_file($fh, $model);
		}
		else
		{
			print $fh $model;
		}
		
		# Now it officially exists, so ...
		close $fh;
		usleep 5_000;
		my $version = $self->instantiate_version("$vid");

		# ... we can ping the Semantic Web.
		WWW::DataWiki::Utils
			->ping_the_semantic_web($version->page_iri->uri)
			if WWW::DataWiki->config->{ping_the_semantic_web};
		
		# We're done.
		return $version;
	}
	
	method create_version_from_string (Str $string, Str $format)
	{
		$format = WWW::DataWiki::Utils->canonicalise_rdf_format($format);
		return unless $format;

		my $model = WWW::DataWiki::Utils->parse($string, $format, $self->page_iri->uri);
		return unless $model;
		
		if ($format eq WWW::DataWiki->FMT_N3
		or  $format eq WWW::DataWiki->FMT_TTL
		or  $format eq WWW::DataWiki->FMT_NT)
		{
			return $self->create_version($string);
		}
		else
		{
			return $self->create_version($model);
		}
	}
	
	method accepts_updates
	{
		0;
	}
	
	method meta_filename
	{
		my $storage = $self->storage;
		mkdir $storage unless -d $storage;
		return File::Spec->catfile($storage, 'meta.nt');
	}
	
	method associated_container
	{
		return; # code below doesn't seem to entirely work
#		(my $storage = $self->storage) =~ s{/$}{}; # shouldn't have a slash at the end anyway.
#		return unless <${storage}_*>;
#		return WWW::DataWiki
#			->resource_class('Container')
#			->new(wikiname => $self->wikiname.'/', context => $self->context);
	}
	
	method store_meta ($data_template, $version_id?)
	{
		my $subject = defined $version_id ? $self->version_iri($version_id) : $self->page_id;
		my $model   = RDF::Trine::Model->new;
		my $data    = $data_template->bind_variables({self=>$subject});
		$model->add_statement($_) foreach grep {$_->rdf_compatible} $data->triples;
		
		if ($model->size)
		{
			open my $fh, ">>", $self->meta_filename;
			RDF::Trine::Serializer
				->new('NTriples')
				->serialize_model_to_file($fh, $model);
			close $fh;
		}
	}

	around http_headers ($ctx)
	{
		my @headers = $self->$orig($ctx);

		if (my $ext = $ctx->stash->{file_extension})
		{
			push @headers, [Content_Location => $self->formatted_history_iri($ext)->uri];
		}
		else
		{
			push @headers, [Content_Location => $self->history_iri->uri];
		}

		push @headers,
			[Link => sprintf('<%s>; anchor="%s"; rel="timemap version-history"', $self->history_iri->uri, $self->page_iri->uri)],
			[Link => sprintf('<%s>; rev="timemap version-history"', $self->page_iri->uri)];

		return @headers;
	}

	method help
	{
		my $dom  = html(
			-lang => 'en', '-xml:lang' => 'en', -version => 'XHTML+RDFa 1.1',
			-prefix => 'srv: http://ontologi.es/srv# u: http://purl.org/NET/uri# rdfs: http://www.w3.org/2000/01/rdf-schema# ht: http://www.w3.org/2011/http# hth: http://www.w3.org/2011/http-headers# htm: http://www.w3.org/2011/http-methods# htc: http://www.w3.org/2011/http-statusCodes#',
			head(
				title('HTTP Options for ', $self->page_iri),
				style(-type=>'text/css', -media=>'screen,projection', sprintf('@import url(%s)', '/static/styles/page.css')),
				),
			body(-about=>'[_:This]', -typeof=>'srv:Endpoint',
				h1(-lang=>'en', -rel=>'srv:uri_base', 'HTTP Options for ', span(-property=>'u:identifier', -content=>$self->page_iri->uri, $self->page_iri)),
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
							'Retrieves the graph.'
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
							strong(-rel=>'srv:req_method', -resource=>'[htm:PUT]', 'PUT'), ' ',
							span(-rel=>'srv:req_header', 'with header ', em(-typeof=>'ht:RequestHeader', span(-rel=>'ht:hdrName', -resource=>'[hth:content-type]', -property=>'ht:fieldName','Content-Type'), ': ', span(-rel=>'srv:fieldValueRange', -resource=> '[_:RDF]', '(an RDF serialisation)'))),
							),
						div(-property=>'rdfs:comment',
							'Replaces the graph, responding with the new version of the graph.'
							),
						),
					li(-typeof=>'srv:Action',
						div(
							strong(-rel=>'srv:req_method', -resource=>'[htm:POST]', 'POST'), ' ',
							span(-rel=>'srv:req_header', 'with header ', em(-typeof=>'ht:RequestHeader', span(-rel=>'ht:hdrName', -resource=>'[hth:content-type]', -property=>'ht:fieldName','Content-Type'), ': ', span(-rel=>'srv:fieldValueRange', -resource=> '[_:RDF]', '(an RDF serialisation)'))),
							),
						div(-property=>'rdfs:comment',
							'Appends to the graph, responding with the new version of the graph.'
							),
						),
					li(-typeof=>'srv:Action',
						div(
							strong(-rel=>'srv:req_method', -resource=>'[htm:POST]', 'POST'), ' ',
							span(-rel=>'srv:req_header', 'with header ', em(-typeof=>'ht:RequestHeader', span(-rel=>'ht:hdrName', -resource=>'[hth:content-type]', -property=>'ht:fieldName','Content-Type'), ': ', span(-property=>'ht:fieldValue', 'application/x-www-form-urlencoded'))), ' ',
							span(-rel=>'srv:req_param', 'with parameter ', em(-property=>'srv:name', 'update')),
							),
						div(-property=>'rdfs:comment',
							'Updates the graph with SPARQL Update, responding with the new version of the graph.'
							),
						),
					li(-typeof=>'srv:Action',
						div(
							strong(-rel=>'srv:req_method', -resource=>'[htm:POST]', 'POST'), ' ',
							span(-rel=>'srv:req_header', 'with header ', em(-typeof=>'ht:RequestHeader', span(-rel=>'ht:hdrName', -resource=>'[hth:content-type]', -property=>'ht:fieldName','Content-Type'), ': ', span(-property=>'ht:fieldValue', 'application/sparql-update'))),
							),
						div(-property=>'rdfs:comment',
							'Updates the graph with SPARQL Update, responding with the new version of the graph.'
							),
						),
					li(-typeof=>'srv:Action',
						div(
							strong(-rel=>'srv:req_method', -resource=>'[htm:PATCH]', 'PATCH'), ' ',
							span(-rel=>'srv:req_header', 'with header ', em(-typeof=>'ht:RequestHeader', span(-rel=>'ht:hdrName', -resource=>'[hth:content-type]', -property=>'ht:fieldName','Content-Type'), ': ', span(-property=>'ht:fieldValue', 'application/sparql-update'))),
							),
						div(-property=>'rdfs:comment',
							'Updates the graph with SPARQL Update, responding with the new version of the graph.'
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

	method editor 
	{
		my $dom  = html(
			-lang => 'en', '-xml:lang' => 'en', -version => 'XHTML+RDFa 1.1',
			head(
				title('Edit: ', $self->title_string),
				style(-type=>'text/css', -media=>'screen,projection', sprintf('@import url(%s)', '/static/styles/editor.css')),
				),
			body(
				h1('Edit: ', $self->title_string),
				form(-action=>'', -method => 'post',
					div(
						textarea(-name => 'body', -id => 'body', -rows => 15, -cols => 60, $self->latest_version->rdf_string_as(WWW::DataWiki->FMT_N3, 0)),
						br(),
						input(-type=>'submit', -value=>'Submit as new version'),
						' using ', label(-for=>'content-type', 'syntax'), ' ',
						HTML::HTML5::Builder::select(
							-name => 'content-type',
							-id   => 'content-type',
							map { option($_) } qw[text/n3 text/turtle text/plain]
							),
						),
					),
				WWW::DataWiki::Model::Wiki->standard_footer,
				),
			);
			
		return WWW::DataWiki->resource_class('Information')->new(dom => $dom);
	}	
}

1;
