package Web::App::Test;

use strict;

use Class::Easy;

sub list_items {
	my $class = shift;
	my $app   = shift;
	my $params = shift;
	
	debug "inside";
	
	$app->var->{test} = {yea => 1};
}

sub auth_method {
	my $self = shift;
	
	return "auth_cookie";
}

sub redirect {
	my $class = shift;
	my $app   = shift;
	my $params = shift;
	
	debug "redirecting";
	
	$app->redirect_to_screen ('');
}

1;