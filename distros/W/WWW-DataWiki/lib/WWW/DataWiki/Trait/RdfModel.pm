use 5.010;
use utf8;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Trait::RdfModel::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Trait::RdfModel::VERSION   = '0.001';
}

role WWW::DataWiki::Trait::RdfModel
	# for WWW::DataWiki::Resource
{
	use HTML::HTML5::Writer;
	use HTML::HTML5::Builder qw[:standard link];
	use IO::Compress::Gzip qw[gzip];
	use RDF::TriN3;
	use RDF::QueryX::Lazy;
	use RDF::Trine qw[statement iri literal blank];
	use RDF::RDFa::Generator::HTML::Pretty;
	use Try::Tiny;
	
	requires 'rdf_model';
	requires 'accepts_updates';
	requires 'context';

	our $MAP = RDF::Trine::NamespaceMap->new;

	method available_formats
	{
		return (
			[WWW::DataWiki::FMT_N3,    1.0, 'text/n3',     undef, 'utf-8'],
			[WWW::DataWiki::FMT_TTL,   0.6, 'text/turtle', undef, 'utf-8'],
			[WWW::DataWiki::FMT_NT,    0.6, 'text/plain',  undef, 'utf-8'],
			[WWW::DataWiki::FMT_JSON,  0.6, 'application/json',      undef, 'utf-8'],
			[WWW::DataWiki::FMT_XML,   0.6, 'application/rdf+xml',   undef, 'utf-8'],
			[WWW::DataWiki::FMT_XHTML, 1.0, 'application/xhtml+xml', undef, 'utf-8'],
			[WWW::DataWiki::FMT_HTML,  1.0, 'text/html',   undef, 'utf-8'],
			);
	}

	method extension_map
	{
		return {
			'.nt'   => 'text/plain',
			'.n3'   => 'text/n3',
			'.ttl'  => 'text/turtle',
			'.xml'  => 'application/rdf+xml',
			'.xhtml'=> 'application/xhtml+xml',
			'.html' => 'text/html',
			'.json' => 'application/json',
			};
	}

	method rdf_string_conforms_to ($format)
	{
		return 1 if $format eq WWW::DataWiki::FMT_N3;
		
		if ($format eq WWW::DataWiki::FMT_TTL
		or  $format eq WWW::DataWiki::FMT_NT)
		{
			my $parser = RDF::Trine::Parser->new($format);
			return
				try { $parser->parse('http://example.com/', $self->rdf_string, sub {}); 1; }
				catch { 0; };
		}
		
		return 0;
	}
	
	method rdf_string_as ($format, $gzipped)
	{
		if ($gzipped and $format eq WWW::DataWiki::FMT_N3)
		{
			return $self->rdf_gzipped;
		}
		
		my $str;
		
		if ($format eq WWW::DataWiki::FMT_HTML)
		{
			my $writer = HTML::HTML5::Writer->new(markup=>'html');
			$str = $writer->document($self->rdf_dom);
		}
		elsif ($format eq WWW::DataWiki::FMT_XHTML)
		{
			my $writer = HTML::HTML5::Writer->new(markup=>'xhtml');
			$str = $writer->document($self->rdf_dom);
		}
		elsif ($self->rdf_string_conforms_to($format))
		{
			$str = $self->rdf_string;
		}
		else
		{
			warn $format;
			my $model = $self->rdf_model;
			my $ser   = RDF::Trine::Serializer->new($format, namespaces=>$MAP);
			$str = $ser->serialize_model_to_string($model);
		}
		
		return $str unless $gzipped;
		
		my $zstr;
		gzip \$str => \$zstr;
		return $zstr;
	}

	method rdf_dom
	{
		my $title = 'Data';
		$title = $self->title_string if $self->DOES('WWW::DataWiki::Trait::Title');
		
		my $gen = RDF::RDFa::Generator::HTML::Pretty->new;
		return html(
			head(
				title(-lang=>'en', $title),
				style(-type=>'text/css', -media=>'screen,projection', sprintf('@import url(%s)', '/static/styles/rdfmodel.css')),
				),
			body(
				h1(-lang=>'en', $title),
				form(-action=>'', -method=>'post',
					div(
						label(-for=>'query', 'SPARQL Query'), ':', br(),
						textarea(-name=>'query', -id=>'query', -cols=>60, -rows=>6), br(),
						input(-type=>'submit', -value=>'Run Query'),
						),
					),
				$gen->nodes($self->rdf_model),
				WWW::DataWiki::Model::Wiki->standard_footer,
				),
			);
	}
	
	method rdf_string
	{
		my $model = $self->rdf_model;
		my $ser   = RDF::Trine::Serializer->new('Turtle', namespaces=>$MAP);
		return $ser->serialize_model_to_string($model);
	}

	method rdf_gzipped
	{
		my $str = $self->rdf_string;
		my $zstr;
		gzip \$str => \$zstr;
		return $zstr;
	}

	method get_resultset ($query)
	{
		my $q = RDF::QueryX::Lazy->new($query, {update=>0})
			or die RDF::QueryX::Lazy->error;
		my $r = $q->execute($self->rdf_model);
		
		if ($r->is_bindings)
		{
			return WWW::DataWiki->resource_class('ResultBindings')->new(rs => $r, query => $q, source => $self, context => $self->context);
		}
		elsif ($r->is_graph)
		{
			return WWW::DataWiki->resource_class('ResultGraph')->new(rs => $r, query => $q, source => $self, context => $self->context);
		}
		elsif ($r->is_boolean)
		{
			return WWW::DataWiki->resource_class('ResultBoolean')->new(rs => $r, query => $q, source => $self, context => $self->context);
		}
	}
}

