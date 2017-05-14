use 5.010;
use strict;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Controller::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Controller::VERSION   = '0.001';
}

class WWW::DataWiki::Controller
	extends Catalyst::Controller
{
	use CatalystX::Syntax::Action;

	method _dispatch_by_method ($ctx, $action_stem)
	{
		my $action_name = sprintf('%s_%s', $action_stem, uc $ctx->req->method);
		
		if ($self->can($action_name))
		{
			if (uc $ctx->req->method eq 'OPTIONS')
			{
				my $allow = join ', ', $self->_allowed_http_methods_for($action_stem);
				$ctx->res->header(Allow => $allow);
			}
			
			$ctx->detach(ref $self, $action_name);
		}
		else
		{
			my $allow = join ', ', $self->_allowed_http_methods_for($action_stem);
			WWW::DataWiki::Exception->throw(405 => 'Method Not Allowed',
				"The following HTTP methods are allowed for this resource: ${allow}.",
				{Allow => $allow});
		}
	}
	
	method _allowed_http_methods_for ($action_stem)
	{
		return
			map { s/^${action_stem}_//; $_ }
			grep { /^${action_stem}_[A-Z0-9]+$/ }
			$self->meta->get_all_method_names;
	}
	
	action HTCPCP
	{
		WWW::DataWiki::Exception->throw(418 => "I'm a little teapot",
			'This server does not implement HTCPCP.');
	}

	action end
	{
		my $resource = $ctx->stash->{resource};

		my $str = join ', ',
			map
			{ sprintf('%s/%s', $_, ($_->VERSION // 'undef')) }
			qw/WWW::DataWiki Catalyst RDF::Trine RDF::TriN3 RDF::Query/;
		$ctx->res->headers->push_header('X-Powered-By' => $str);
		$ctx->res->headers->remove_header('X-Catalyst');
		
		if (blessed($resource))
		{
			$ctx->forward( $ctx->view('General') );
		}
	}
}
