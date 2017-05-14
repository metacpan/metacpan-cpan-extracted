use 5.010;
use strict;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Utils::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Utils::VERSION   = '0.001';
}

class WWW::DataWiki::Utils
{
	use DateTime;
	use DateTime::Format::Strptime;
	use LWP::UserAgent;
	use RDF::RDFa::Parser 1.096;
	use RDF::TriN3;
	use RDF::Trine qw[literal iri blank statement variable];
	use RDF::Trine::Namespace qw[rdf rdfs owl xsd];
	use URI::Escape qw[uri_escape];
	
	method dt_fmt_short ($class:)
	{
		return DateTime::Format::Strptime->new(
			pattern   => '%Y%m%dT%H%M%SZ',
			time_zone => 'UTC',
			);
	}
	
	method ping_the_semantic_web ($class: Str $url, Str $service?)
	{
		$service //= 'http://pingthesemanticweb.com/rest/?url=';
		
		my $ua   = LWP::UserAgent->new(
			agent => sprintf('WWW::DataWiki/%s', WWW::DataWiki->VERSION),
			);
		my $ping = $service . uri_escape($url);
		$ua->get($ping)->is_success;
	}

	method ctx_to_provenance ($class: $ctx)
	{
		my $req = $ctx->req;
		my @prov;
		
		if ($req->address)
		{
			push @prov, statement(
				variable('self'),
				iri('http://rdfs.org/sioc/ns#ip_address'),
				literal($req->address),
				);
		}

		if ($req->header('Title'))
		{
			push @prov, statement(
				variable('self'),
				iri('http://purl.org/dc/terms/title'),
				literal($req->header('Title')),
				);
		}

		if ($req->header('Content-Language') =~ /^[a-zA-Z]{1,8}(-[a-zA-Z0-9]{1,8})*$/)
		{
			push @prov, statement(
				variable('self'),
				iri('http://purl.org/dc/terms/language'),
				literal($req->header('Content-Language'), undef, $xsd->language),
				);
		}

		my $pub = blank();
		if ($req->header('From') =~ /^(mailto:)?(.+)\@(.+)$/)
		{
			$pub = iri(sprintf('tag:buzzword.org.uk,2011:datawiki:publisher:%s:%s',
				uri_escape($3),
				uri_escape($2),
				));
			push @prov, statement(
				$pub,
				iri('http://xmlns.com/foaf/0.1/mbox'),
				iri(sprintf('mailto:%s@%s', $2, $3)),
				);
		}

		push @prov, statement(
			variable('self'),
			iri('http://purl.org/dc/terms/publisher'),
			$pub,
			);		

		return RDF::Trine::Pattern->new(@prov);
	}

	# passed a media type, format name, etc,
	# returns a WWW::DataWiki->FMT_* constant
	method canonicalise_rdf_format ($class: Str $format)
	{
		return WWW::DataWiki->FMT_TTL   if $format =~ m{^Turtle}i;
		return WWW::DataWiki->FMT_TTL   if $format =~ m{^text/(x-)?turtle}i;
		return WWW::DataWiki->FMT_TTL   if $format =~ m{^application/(x-)?turtle}i;
		
		return WWW::DataWiki->FMT_N3    if $format =~ m{^N3}i;
		return WWW::DataWiki->FMT_N3    if $format =~ m{^Notation[\s_/-]?3}i;
		return WWW::DataWiki->FMT_N3    if $format =~ m{^text/(x-)?(rdf\+)?n3(\+rdf)?}i;
		
		return WWW::DataWiki->FMT_NT    if $format =~ m{^N[\s_/-]?Triples}i;
		return WWW::DataWiki->FMT_NT    if $format =~ m{^text/plain}i;
		
		return WWW::DataWiki->FMT_HTML  if $format =~ m{^HTML}i;
		return WWW::DataWiki->FMT_HTML  if $format =~ m{^text/html}i;

		return WWW::DataWiki->FMT_XHTML if $format =~ m{^(XHTML|RDFa)}i;
		return WWW::DataWiki->FMT_XHTML if $format =~ m{^application/xhtml\+xml}i;
		
		return WWW::DataWiki->FMT_JSON  if $format =~ m{^(RDF[\s_/-]?)?JSON}i;
		return WWW::DataWiki->FMT_JSON  if $format =~ m{^application/json}i;
		
		return WWW::DataWiki->FMT_XML   if $format =~ m{^(RDF[\s_/-])?XML}i;
		return WWW::DataWiki->FMT_XML   if $format =~ m{^application/rdf\+xml}i;
		return WWW::DataWiki->FMT_XML   if $format =~ m{^application/xml}i;
		return WWW::DataWiki->FMT_XML   if $format =~ m{^text/xml}i;
		
		return undef;
	}
	
	method parse ($class: Str $string, Str $format, Str $base?, $model?)
	{
		$model //= RDF::Trine::Model->new;
		$base  //= '';

		local $@ = undef;
		my $result = eval
		{
			my $parser;
			if ($format eq WWW::DataWiki->FMT_HTML)
			{
				my $cfg = RDF::RDFa::Parser::Config->new('html', '1.1');
				$parser = RDF::Trine::Parser::RDFa->new(options => $cfg);
			}
			elsif ($format eq WWW::DataWiki->FMT_XHTML)
			{
				my $cfg = RDF::RDFa::Parser::Config->new('xhtml', '1.1');
				$parser = RDF::Trine::Parser::RDFa->new(options => $cfg);
			}
			elsif ($format eq WWW::DataWiki->FMT_N3)
			{
				$parser = RDF::Trine::Parser::Notation3->new;
			}
			else
			{
				$parser = RDF::Trine::Parser->new($format);
			}
			die "No parser" unless defined $parser;
			$parser->parse_into_model($base, $string, $model);
			'success';
		};
		warn $@ if $@;
		return undef unless $result eq 'success';		
		return $model;
	}
}

1;
