use 5.010;
use autodie;
use utf8;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Resource::Version::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Resource::Version::VERSION   = '0.001';
}

class WWW::DataWiki::Resource::Version
	extends WWW::DataWiki::Resource
	with WWW::DataWiki::Trait::RdfModel
	with WWW::DataWiki::Trait::LastModified
	with WWW::DataWiki::Trait::Title
	with WWW::DataWiki::Trait::Negotiator
{
	use File::Spec;
	use RDF::TriN3;
	use PerlIO::gzip;
	use RDF::Trine qw[statement iri literal blank];
	use RDF::QueryX::Lazy;
	use WWW::DataWiki::Utils;
	
	has page    => (is => 'ro', isa => 'WWW::DataWiki::Resource::Page', required=>1);
	has version => (is => 'ro', isa => 'Str', required=>1);

	method version_string_parser ($class:)
	{
		return DateTime::Format::Strptime->new(pattern=>'%Y%m%dT%H%M%SZ');
	}

	method storage
	{
		return File::Spec->catfile($self->page->storage, sprintf('%s.n3.gz', $self->version));
	}

	method title_string
	{
		return sprintf('%s (%s)', $self->page->wikiname, $self->last_modified);
	}

	method last_modified
	{
		return $self->version_string_parser->parse_datetime($self->version);
	}

	method page_iri
	{
		return $self->page->page_iri($self->version);
	}

	method version_iri
	{
		return $self->page->version_iri($self->version);
	}

	method formatted_page_iri ($format)
	{
		return $self->page->formatted_page_iri($format);
	}

	method formatted_version_iri ($format)
	{
		return $self->page->formatted_version_iri($self->version, $format);
	}

	method rdf_model
	{
		my $model  = RDF::Trine::Model->new;
		my $parser = RDF::Trine::Parser::Notation3->new;
		$WWW::DataWiki::Trait::RdfModel::MAP = $parser->{bindings};
		$parser->parse_into_model($self->page_iri->uri, $self->rdf_string, $model);
		return $model;
	}

	method rdf_string
	{
		open my $fh, "<:gzip", $self->storage;
		return do { local $/ = <$fh> };
	}

	method rdf_gzipped
	{
		open my $fh, '<', $self->storage;
		return do { local $/ = <$fh> };
	}
	
	method accepts_updates
	{
		1.1;
	}
	
	method execute_update ($sparql)
	{
		my $model = $self->rdf_model;
		my $query = RDF::QueryX::Lazy->new($sparql, {update=>1})
			or die RDF::QueryX::Lazy->error;
		$query->execute($model);
		
		return $self->page->create_version($model);		
	}

	method create_version_from_append_string (Str $string, Str $format)
	{
		$format = WWW::DataWiki::Utils->canonicalise_rdf_format($format);
		return unless $format;
		
		my $model = WWW::DataWiki::Utils->parse($string, $format, $self->page_iri->uri);
		return unless $model;

		my $appended = $self->rdf_string;
		$appended .= sprintf("\n\@base <%s> .\n\n", $self->page_iri->uri);
		
		if ($format eq WWW::DataWiki->FMT_N3
		or  $format eq WWW::DataWiki->FMT_TTL
		or  $format eq WWW::DataWiki->FMT_NT)
		{
			$appended .= "$string\n";
		}
		else
		{
			my $ser = RDF::Trine::Serializer->new('Turtle'); # it's not N3, so Turtle is safe
			$appended .= $ser->serialize_model_to_string($model);
		}
		
		return $self->page->create_version($appended);
	}
	
	method store_meta ($data)
	{
		return $self->page->store_meta($data, $self->version);
	}
	
	around http_headers ($ctx)
	{
		my @headers = $self->$orig($ctx);
		push @headers, ['MS-Author-Via'	=> 'DAV'];

		if (my $ext = $ctx->stash->{file_extension})
		{
			push @headers, [Content_Location => $self->formatted_version_iri($ext)->uri];
		}
		else
		{
			push @headers, [Content_Location => $self->version_iri->uri];
		}

		my $memento = sub {
				my ($rel, $ver) = @_;
				return unless blessed($ver);
				my $dt = DateTime::Format::HTTP->format_datetime(
					WWW::DataWiki::Utils->dt_fmt_short->parse_datetime($ver->version));
				push @headers,
					[Link => sprintf('<%s>; rel="memento %s"; datetime="%s"', $ver->version_iri->uri, $rel, $dt)];
			};

		push @headers, ['Memento-Datetime' => $self->last_modified_http];
		$memento->($ctx, 'first-memento', $self->page->earliest_version);
		$memento->($ctx, 'prev-memento predecessor-version',  $self->page->version_offset_from($self->version, -1));
		$memento->($ctx, 'next-memento successor-version',  $self->page->version_offset_from($self->version, +1));
		$memento->($ctx, 'last-memento latest-version',  $self->page->latest_version);
		
		push @headers, [Link => sprintf('<%s>; rel="timegate original"', $self->page_iri->uri)];
		push @headers, [Link => sprintf('<%s>; rel="timemap version-history"', $self->page->history_iri->uri)];
		push @headers, [Link => sprintf('<%s,edit>; rel="edit"', $self->page_iri->uri)];
		push @headers, [Link => sprintf('<%s,options>; rel="help"', $self->page_iri->uri)];

		push @headers, [Version => $self->version];

		return @headers;
	}
}

1;
