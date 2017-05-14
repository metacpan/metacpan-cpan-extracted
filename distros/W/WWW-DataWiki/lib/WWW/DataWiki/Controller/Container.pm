use 5.010;
use strict;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Controller::Container::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Controller::Container::VERSION   = '0.001';
}

class WWW::DataWiki::Controller::Container
	extends WWW::DataWiki::Controller
{
	use CatalystX::Syntax::Action;
	use Data::UUID qw(NameSpace_URL);
	use File::Slurp qw(slurp);
	use URI::Escape qw(uri_escape);
	
	has uuid_generator => (is => 'ro', isa => 'Data::UUID', lazy => 1, builder => '_build_uuid_generator');
	
	our $RE_page = '((?:[a-z][a-z0-9-]*[a-z0-9])(?:/[a-z][a-z0-9-]*[a-z0-9])*)';
	our $RE_path = "${RE_page}/";
	
	__PACKAGE__->config(
		namespace => '',
		action => {
			container   => { Regex => "^${RE_path}\$" },
			end         => { Private => 1 },
			},
		);
		
	method _build_uuid_generator
	{
		return Data::UUID->new;
	}

	action container { $self->_dispatch_by_method($ctx, 'container'); }

	action container_GET
	{
		my ($wikiname) = @{ $ctx->req->captures || [] };
		$wikiname //= '';
		
		my $c = $ctx->model('Wiki')->container("${wikiname}/");
		WWW::DataWiki::Exception->throw(404 => 'Container not found') unless defined $c;
		#WWW::DataWiki::Exception->throw(404 => 'Container not found') unless $c->all_member_names; # somewhat of a hack
		$ctx->stash(resource => $c);

		if (WWW::DataWiki::Controller::Query->req_is_query($ctx->req))
		{
			$ctx->detach('Controller::Query', 'query');
		}		
	}

	action container_POST 
	{
		my ($wikiname) = @{ $ctx->req->captures || [''] };
		
		my $c = $ctx->model('Wiki')->container("${wikiname}/");
		WWW::DataWiki::Exception->throw(404 => 'Container not found') unless defined $c;
		#WWW::DataWiki::Exception->throw(404 => 'Container not found') unless $c->all_member_names; # somewhat of a hack
		$ctx->stash(resource => $c);
		
		if (WWW::DataWiki::Controller::Query->req_is_query($ctx->req))
		{
			$ctx->detach('Controller::Query', 'query');
		}
		elsif (defined (my $fmt = WWW::DataWiki::Utils->canonicalise_rdf_format($ctx->req->content_type)))
		{
			my $slug = lc $ctx->req->header('Slug');
			$slug =~ s/[^a-z0-9]/-/;
			$slug =~ s/[-]{2,}/-/g;
			(my $full = "${wikiname}/${slug}") =~ s{^/}{};
			while ( $ctx->model('Wiki')->page($full)->latest_version )
			{
				$slug++;
				($full = "${wikiname}/${slug}") =~ s{^/}{};
			}
			$slug = sprintf('uuid-%s', lc $self->uuid_generator->create_from_name_str(NameSpace_URL, $c->container_iri->uri))
				unless $slug =~ /^[a-z][a-z0-9-]*[a-z0-9]$/;

			($full = "${wikiname}/${slug}") =~ s{^/}{};
			my $page = $ctx->model('Wiki')->page($full);
			my $data = $ctx->req->body;
			$data = slurp($data)
				if $data =~ m#^/# && -f $data;
				
			my $new = $page->create_version_from_string($data, $fmt);
			if ($new)
			{
				$new->store_meta( WWW::DataWiki::Utils->ctx_to_provenance($ctx) );
				
				$ctx->set_http_status_code(201 => 'Created');
				$ctx->stash(resource => $new);
			}
			else
			{
				WWW::DataWiki::Exception->throw(500 => 'Error creating page');
			}						
		}
		else
		{
			WWW::DataWiki::Exception->throw(415 => 'Unsupported media type',
				'This resource accepts POST requests using SPARQL Query, and accepts RDF data to create a new resource in the collection.',
				{'X-Accept' => 'application/x-www-form-urlencoded, application/sparql-query, text/n3, text/turtle, text/plain, application/rdf+xml;q=0.5, application/json;q=0.1, application/xhtml+xml;q=0.1, text/html;q=0.1'});
		}
	}

	action container_OPTIONS
	{
		my ($wikiname) = @{ $ctx->req->captures || [] };
		$wikiname //= '';
		
		my $c = $ctx->model('Wiki')->container("${wikiname}/");
		WWW::DataWiki::Exception->throw(404 => 'Container not found') unless defined $c;
		$ctx->stash(resource => $c->help);
	}

	action container_HEAD { goto &container_GET; }

	action container_BREW
	{
		$self->HTCPCP($ctx);
	}
	
	*container_WHEN    =
		\&container_BREW;
}

1;
