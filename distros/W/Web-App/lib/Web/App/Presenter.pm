package Web::App::Presenter;

use strict;

use Web::App;

1;

sub init {
	my $class  = shift;
	my $params = shift || {};
	
	bless $params, $class;
	
	my $app = Web::App->app;
	
	my $type = ($params->{'type'} =~ /^presenter:(.*)/)[0];
	
	$app->config->int->{'presenters'}->{$type} = $params;
	
	if ($params->can ('_init')) {
		$params->_init;
	}
	
	return $params;
}