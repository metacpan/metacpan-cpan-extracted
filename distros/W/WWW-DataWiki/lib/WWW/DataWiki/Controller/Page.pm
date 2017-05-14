use 5.010;
use strict;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Controller::Page::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Controller::Page::VERSION   = '0.001';
}

class WWW::DataWiki::Controller::Page
	extends WWW::DataWiki::Controller
{
	use CatalystX::Syntax::Action;
	use DateTime;
	use File::Slurp qw(slurp);
	use URI::Escape qw(uri_escape);
	
	our $RE_page = '((?:[a-z][a-z0-9-]*[a-z0-9])(?:/[a-z][a-z0-9-]*[a-z0-9])*)';
	our $RE_ext  = '(\.nt|\.n3|\.ttl|\.x?html|\.xml|\.json|\.txt|\.csv|\.tab)';
	our $RE_path = "${RE_page}${RE_ext}?";
	our $RE_vid  = '(\d{4}(?:\d{2}(?:\d{2}(?:T\d{4,6}(?:\.\d+)?Z?)?)?)?)';
	__PACKAGE__->config(
		namespace => '',
		action => {
			wikipage    => { Regex => "^${RE_path}(?:[,]${RE_vid})?\$" },
			wikihistory => { Regex => "^${RE_path},history\$" },
			wikioptions => { Regex => "^${RE_path},options\$" },
			wikieditor  => { Regex => "^${RE_path},edit\$" },
			end         => { Private => 1 },
			},
		);

	action wikipage    { $ctx->add_http_vary('Accept-Datetime'); $self->_dispatch_by_method($ctx, 'wikipage'); }
	action wikihistory { $self->_dispatch_by_method($ctx, 'wikihistory');  }
	action wikioptions { $self->_dispatch_by_method($ctx, 'wikioptions'); }
	action wikieditor  { $self->_dispatch_by_method($ctx, 'wikieditor'); }

	# TODO: on redirect, should append query string!
	action wikipage_GET
	{
		my ($wikiname, $ext, $v) = @{ $ctx->req->captures };		
		$v =~ s/^,// if defined $v; # trim leading comma

		my ($ver, $redirect_allowed) = (undef, 1);
		if (defined $v and length $v)
		{
			my $blank    = '00000101T000000Z';
			my $v_padded = $v . substr($blank, length $v);
			
			my $parser = WWW::DataWiki->resource_class('Version')->version_string_parser;
			if ($parser->parse_datetime($v_padded) > DateTime->now)
			{
				# Version requested from future. Return current as non-authoritative.
				$ver = $ctx->model('Wiki')->page($wikiname)->latest_version;
				$ctx->set_http_status_code(203 => 'Version requested from future.');
				$redirect_allowed = 0;
			}
		}

		$ver //= $ctx->model('Wiki')->version($wikiname, $v);

		if (!defined $ver)
		{
			my $earliest = $ctx->model('Wiki')->page($wikiname)->earliest_version;
			if ($earliest)
			{
				$ext
					? $ctx->res->redirect($earliest->formatted_version_iri($ext)->uri, 303)
					: $ctx->res->redirect($earliest->version_iri->uri, 303);
				$ctx->detach;
			}
			else
			{
				WWW::DataWiki::Exception->throw(404 => 'Page not found');
			}
		}
		
		$ctx->stash(resource => $ver);
		
		if (WWW::DataWiki::Controller::Query->req_is_query($ctx->req))
		{
			$ctx->detach('Controller::Query', 'query');
		}

		if (defined $ver
		and defined $v
		and length $v
		and $ver->version ne $v
		and $redirect_allowed)
		{
			$ext
				? $ctx->res->redirect($ver->formatted_version_iri($ext)->uri, 302)
				: $ctx->res->redirect($ver->version_iri->uri, 302);
			$ctx->detach;
		}		

		if (my $accept_dt = $ctx->req->header('Accept-Datetime') and not defined $v)
		{
			$accept_dt = DateTime::Format::HTTP->parse_datetime($accept_dt);
			# should probably throw an exception if in future
			$accept_dt = WWW::DataWiki::Utils->dt_fmt_short->format_datetime($accept_dt);
			my $memento = $ctx->model('Wiki')->version($wikiname, $accept_dt);
			if ($memento)
			{
				$ext
					? $ctx->res->redirect($memento->formatted_version_iri($ext)->uri, 302)
					: $ctx->res->redirect($memento->version_iri->uri, 302);
				$ctx->detach;
			}
			else
			{
				WWW::DataWiki::Exception->throw(406 => 'Not Acceptable',
					'No versions exist that early.');
			}
		}
	}

	action wikipage_POST 
	{
		my ($wikiname, undef, $v) = @{ $ctx->req->captures };		
		$v =~ s/^,// if defined $v; # trim leading comma
		
		my $ver = $ctx->model('Wiki')->version($wikiname, $v);
		WWW::DataWiki::Exception->throw(404 => 'Page not found') unless defined $ver;
		$ctx->stash(resource => $ver);
		
		if (WWW::DataWiki::Controller::Query->req_is_query($ctx->req))
		{
			$ctx->detach('Controller::Query', 'query');
		}
		elsif (WWW::DataWiki::Controller::Query->req_is_update($ctx->req))
		{
			$ctx->detach('Controller::Query', 'update');
		}
		elsif (defined (my $fmt = WWW::DataWiki::Utils->canonicalise_rdf_format($ctx->req->content_type)))
		{
			my $data = $ctx->req->body;
			$data = slurp($data)
				if $data =~ m#^/# && -f $data;
				
			my $new = $ver->create_version_from_append_string($data, $fmt);
			if ($new)
			{
				$new->store_meta( WWW::DataWiki::Utils->ctx_to_provenance($ctx) );
				
				$ctx->set_http_status_code(201 => 'Created');
				$ctx->stash(resource => $new);
			}
			else
			{
				$ctx->stash(resource => undef);
				WWW::DataWiki::Exception->throw(500 => 'Error creating new version');
			}			
		}
		else
		{
			WWW::DataWiki::Exception->throw(415 => 'Unsupported media type',
				'This resource accepts POST requests using SPARQL Query/Update, and accepts RDF data to append to the wiki page.',
				{'X-Accept' => 'application/x-www-form-urlencoded, application/sparql-query, application/sparql-update, text/n3, text/turtle, text/plain, application/rdf+xml;q=0.5, application/json;q=0.1, application/xhtml+xml;q=0.1, text/html;q=0.1'});
		}
	}

	action wikipage_PATCH
	{
		my ($wikiname, undef, $v) = @{ $ctx->req->captures };		
		$v =~ s/^,// if defined $v; # trim leading comma
		
		my $ver = $ctx->model('Wiki')->version($wikiname, $v);
		WWW::DataWiki::Exception->throw(404 => 'Page not found') unless defined $ver;
		$ctx->stash(resource => $ver);
		
		if (WWW::DataWiki::Controller::Query->req_is_update($ctx->req))
		{
			$ctx->detach('Controller::Query', 'update');
		}
		else
		{
			WWW::DataWiki::Exception->throw(415 => 'Unsupported media type',
				'This resource accepts PATCH requests using SPARQL Update.',
				{'X-Accept' => 'application/x-www-form-urlencoded, application/sparql-update'});
		}
	}

	action wikipage_PUT 
	{
		my ($wikiname, undef, $v) = @{ $ctx->req->captures };		
		$v =~ s/^,// if defined $v; # trim leading comma
		
		my $page = $ctx->model('Wiki')->page($wikiname);
		
		if (defined (my $fmt = WWW::DataWiki::Utils->canonicalise_rdf_format($ctx->req->content_type)))
		{
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
				WWW::DataWiki::Exception->throw(500 => 'Error creating new version');
			}			
		}
		else
		{
			WWW::DataWiki::Exception->throw(415 => 'Unsupported media type',
				'Accepts Notation 3 (preferred), and most common RDF serializations.',
				{'X-Accept' => 'text/n3, text/turtle, text/plain, application/rdf+xml;q=0.5, application/json;q=0.1, application/xhtml+xml;q=0.1, text/html;q=0.1'});
		}
	}

	action wikipage_DELETE
	{
		my ($wikiname, undef, $v) = @{ $ctx->req->captures };		
		$v =~ s/^,// if defined $v; # trim leading comma
		
		my $page = $ctx->model('Wiki')->page($wikiname);
		
		my $new = $page->create_version_from_string('', WWW::DataWiki->FMT_NT);
		if ($new)
		{
			$new->store_meta( WWW::DataWiki::Utils->ctx_to_provenance($ctx) );
				
			$ctx->set_http_status_code(200 => 'OK');
			$ctx->stash(resource => $new);
		}
		else
		{
			WWW::DataWiki::Exception->throw(500 => 'Resource could not be deleted.');
		}			
	}

	action wikipage_HEAD { goto &wikipage_GET; }

	action wikipage_OPTIONS
	{
		my ($wikiname, undef, $v) = @{ $ctx->req->captures };
		my $help = $ctx->model('Wiki')->page($wikiname)->help;
		$ctx->stash(resource => $help);
	}

	action wikihistory_GET
	{
		my ($wikiname) = @{ $ctx->req->captures };
		my $wikipage = $ctx->model('Wiki')->page($wikiname);
		WWW::DataWiki::Exception->throw(404 => 'Page not found')
			unless defined $wikipage and defined $wikipage->latest_version;
		$ctx->stash(resource => $wikipage);

		if (defined $wikipage and $ctx->req->method =~ m'^(GET|HEAD)$'i
		and WWW::DataWiki::Controller::Query->req_is_query($ctx->req))
		{
			$ctx->detach('Controller::Query', 'query');
		}
	}
	
	action wikihistory_POST 
	{
		my ($wikiname) = @{ $ctx->req->captures };
		my $wikipage = $ctx->model('Wiki')->page($wikiname);
		WWW::DataWiki::Exception->throw(404 => 'Page not found')
			unless defined $wikipage and defined $wikipage->latest_version;
		$ctx->stash(resource => $wikipage);
		
		if (WWW::DataWiki::Controller::Query->req_is_query($ctx->req))
		{
			$ctx->detach('Controller::Query', 'query');
		}
		else
		{
			WWW::DataWiki::Exception->throw(400 => 'Unsupported POST',
				'This resource accepts POST requests using SPARQL Protocol 1.0.',
				{'X-Accept' => 'application/x-www-form-urlencoded, application/sparql-query'});
				}
	}

	action wikihistory_HEAD { goto &wikihistory_GET; }	

	action wikioptions_GET
	{
		my ($wikiname, undef, $v) = @{ $ctx->req->captures };
		my $help = $ctx->model('Wiki')->page($wikiname)->help;
		$ctx->stash(resource => $help);
	}

	action wikioptions_HEAD    { goto &wikioptions_GET; }	

	action wikieditor_GET
	{
		my ($wikiname) = @{ $ctx->req->captures };
		my $editor = $ctx->model('Wiki')->page($wikiname)->editor;
		WWW::DataWiki::Exception->throw(404 => 'Page not found')
			unless defined $ctx->model('Wiki')->page($wikiname)->latest_version;
		$ctx->stash(resource => $editor);
	}

	action wikieditor_HEAD    { goto &wikieditor_GET; }	

	action wikieditor_POST 
	{
		my ($wikiname, undef, $v) = @{ $ctx->req->captures };		
		$v =~ s/^,// if defined $v; # trim leading comma

		my $page = $ctx->model('Wiki')->page($wikiname);
		
		if (defined (my $fmt = WWW::DataWiki::Utils->canonicalise_rdf_format($ctx->req->params->{'content-type'})))
		{
			my $data = $ctx->req->params->{body};
				
			my $new = $page->create_version_from_string($data, $fmt);
			if ($new)
			{
				$new->store_meta( WWW::DataWiki::Utils->ctx_to_provenance($ctx) );				
				$ctx->stash(resource => $new);
				
				$ctx->res->redirect($new->version_iri->uri, 303);
				$ctx->detach;
			}
			else
			{
				WWW::DataWiki::Exception->throw(500 => 'Error creating new version');
			}			
		}
		else
		{
			WWW::DataWiki::Exception->throw(415 => 'Unsupported media type',
				'Accepts Notation 3 (preferred), and most common RDF serializations.',
				{'X-Accept' => 'application/x-www-form-urlencoded'});
		}
	}

	action wikipage_BREW
	{
		$self->HTCPCP($ctx);
	}
	
	*wikihistory_BREW  =
	*wikihistory_WHEN  =
	*wikioptions_BREW  =
	*wikioptions_WHEN  =
	*wikieditor_BREW   =
	*wikieditor_WHEN   =
	*wikipage_WHEN     =
		\&wikipage_BREW;
}

1;
