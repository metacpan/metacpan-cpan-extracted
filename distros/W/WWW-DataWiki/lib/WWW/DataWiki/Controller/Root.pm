use 5.010;
use strict;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Controller::Root::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Controller::Root::VERSION   = '0.001';
}

class WWW::DataWiki::Controller::Root
	extends WWW::DataWiki::Controller
{
	use CatalystX::Syntax::Action;
	
	__PACKAGE__->config(
		namespace => '',
		action => {
			index   => { Path => '', Args => 0, },
			},
		);

	action index { $self->_dispatch_by_method($ctx, 'index'); }

	action index_HEAD
	{
		$ctx->detach('Controller::Container', 'container');
	}
	
	*index_GET      =
	*index_POST     =
	*index_OPTIONS  =
	*index_BREW     =
	*index_WHEN     =
		\&index_HEAD;
}

1;
