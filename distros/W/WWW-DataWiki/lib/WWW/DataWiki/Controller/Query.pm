use 5.010;
use strict;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Controller::Query::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Controller::Query::VERSION   = '0.001';
}

# These are really just helpers for WWW::DataWiki::Controller::Page.
#

class WWW::DataWiki::Controller::Query
	extends WWW::DataWiki::Controller
{
	use File::Slurp qw[slurp];
	use CatalystX::Syntax::Action;

	__PACKAGE__->config(
		namespace => '',
		action => {
			query   => { Private => 1 },
			update  => { Private => 1 },
			},
		);

	sub req_is_query
	{
		shift if $_[0] eq __PACKAGE__;
		my ($req) = @_;
		return 1
			if $req->content_type =~ m#^application/sparql-query#i
			|| exists $req->params->{query};
		return;
	}

	sub req_is_update
	{
		shift if $_[0] eq __PACKAGE__;
		my ($req) = @_;
		return 1
			if $req->content_type =~ m#^application/sparql-update#i
			|| exists $req->params->{update};
		return;
	}

	action query
	{
		return unless $ctx->stash->{resource}->DOES('WWW::DataWiki::Trait::RdfModel');
		return unless req_is_query($ctx->req);
		
		my $query;
		if ($ctx->req->content_type =~ m#^application/sparql-query#i)
		{
			$query = $ctx->req->body;
			$query = slurp($query)
				if $query =~ m#^/# && -f $query;
		}
		elsif (exists $ctx->req->params->{query})
		{
			$query = $ctx->req->params->{query};
		}
		
		$ctx->stash(resource => $ctx->stash->{resource}->get_resultset($query));
	}
	
	action update
	{
		return unless $ctx->stash->{resource}->DOES('WWW::DataWiki::Trait::RdfModel');
		return unless req_is_update($ctx->req);

		my $update;
		if ($ctx->req->content_type =~ m#^application/sparql-update#i)
		{
			$update = $ctx->req->body;
			$update = slurp($update)
				if $update =~ m#^/# && -f $update;
		}
		elsif (exists $ctx->req->params->{update})
		{
			$update = $ctx->req->params->{update};
		}
		
		my $new = $ctx->stash->{resource}->execute_update($update);
		if ($new)
		{
			$new->store_meta( WWW::DataWiki::Utils->ctx_to_provenance($ctx) );
			
			$ctx->set_http_status_code(201 => 'Created');
			$ctx->stash(resource => $new);
		}
		else
		{
			WWW::DataWiki::Exception->throw(500 => 'Error performing update');
		}
	}
}

1;
