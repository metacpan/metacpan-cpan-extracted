use 5.010;
use utf8;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Trait::ResultSet::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Trait::ResultSet::VERSION   = '0.001';
}

role WWW::DataWiki::Trait::ResultSet
	# for WWW::DataWiki::Resource
{
	use HTML::HTML5::Builder qw[:standard tr link];
	use RDF::Trine qw[statement iri literal blank];
	use Try::Tiny;
	
	requires 'rs';
	
	method available_formats
	{
		return (
			[WWW::DataWiki::FMT_RS_XML,   1.0, 'application/sparql-results+xml', undef, 'utf-8'],
			[WWW::DataWiki::FMT_RS_JSON,  0.9, 'application/x-sparql-results+json', undef, 'utf-8'],
			[WWW::DataWiki::FMT_RS_TEXT,  0.6, 'text/plain', undef, 'utf-8'],
			[WWW::DataWiki::FMT_RS_HTML,  1.0, 'text/html', undef, 'utf-8'],
			[WWW::DataWiki::FMT_RS_XHTML, 1.0, 'application/xhtml+xml', undef, 'utf-8'],
			[WWW::DataWiki::FMT_RS_CSV,   0.8, 'text/csv', undef, 'utf-8'],
			[WWW::DataWiki::FMT_RS_TSV,   0.8, 'text/tab-separated-values', undef, 'utf-8'],
			);
	}

	method extension_map
	{
		return {
			'.xml'  => 'application/sparql-results+xml',
			'.xhtml'=> 'application/xhtml+xml',
			'.html' => 'text/html',
			'.json' => 'application/x-sparql-results+json',
			'.txt'  => 'text/plain',
			'.csv'  => 'text/csv',
			'.tab'  => 'text/tab-separated-values',
			};
	}

	method rs_string_as ($fmt)
	{
		my $str;
		given ($fmt)
		{
			when (WWW::DataWiki::FMT_RS_JSON)  { $str = $self->rs->as_json; }
			when (WWW::DataWiki::FMT_RS_XML)   { $str = $self->rs->as_xml; }
			when (WWW::DataWiki::FMT_RS_TEXT)  { $str = $self->rs->as_string; }
			when (WWW::DataWiki::FMT_RS_CSV)   { $str = RDF::Trine::Exporter::CSV->new->serialize_iterator_to_string($self->rs); }
			when (WWW::DataWiki::FMT_RS_TSV)   { $str = RDF::Trine::Exporter::CSV->new->(sep_char => "\t")->serialize_iterator_to_string($self->rs); }
			when (WWW::DataWiki::FMT_RS_HTML)  { $str = $self->rs_html({markup=>'html'}); }
			when (WWW::DataWiki::FMT_RS_XHTML) { $str = $self->rs_html({markup=>'xhtml', polyglot=>1}); }
			default                            { $str = $self->rs->as_string; }
		}
		return $str;
	}
	
	method rs_html ($params)
	{
		my $writer = HTML::HTML5::Writer->new(%{ $params // {} });
		return $writer->document($self->rs_dom);
	}
	
	method rs_dom
	{
		my $title = 'Query Results';
		$title = $self->title_string if $self->DOES('WWW::DataWiki::Trait::Title');
		
		return html(
			head(
				title(-lang=>'en', $title),
				style(-type=>'text/css', -media=>'screen,projection', sprintf('@import url(%s)', '/static/styles/resultset.css')),
				),
			body(
				h1(-lang=>'en', $title),
				pre($self->can('query') ? $self->query->as_sparql : ''),
				table(
					thead(
						&tr(map { th($_) } $self->rs->binding_names),
						),
					tbody(
						do {
							my @rows;
							while (my $row = $self->rs->next)
							{
								push @rows,
									&tr(
										map { 
											td(
												do {
													if (!defined $_)
														{ i('null') }
													elsif ($_->is_resource)
														{ a(-href=>$_->uri, $_->uri) }
													elsif ($_->is_blank)
														{ b($_->as_ntriples) }
													elsif ($_->is_literal and $_->has_datatype)
														{ span(samp($_->literal_value), small('^^<', $_->literal_datatype, '>')) }
													elsif ($_->is_literal)
														{ span(-lang=>$_->literal_value_language, $_->literal_value) }
													else
														{ b('???') }
													}
												)
											} $self->rs->binding_values
										)
							}
							@rows;
							}
						),
					),
					WWW::DataWiki::Model::Wiki->standard_footer,
				),
			);
	}
}

