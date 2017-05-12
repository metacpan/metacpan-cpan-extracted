package Web::App::Response;
# $Id: Response.pm,v 1.5 2009/03/23 00:36:38 apla Exp $

use Class::Easy;

use Storable ('dclone');

use HTTP::Headers;

has 'headers', is => 'rw';
has 'data';
has 'presenter', is => 'rw';

our $template = {
	headers => HTTP::Headers->new (
		'Content-Type'  => 'text/html; charset=utf-8',
		'Cache-Control' => 'no-store',
	),
	data => {
		form => {
			values => {},
			errors => {},
		},
	},
};

sub xhr_fix {
	my $self = shift;
	my $app    = shift;
	my $params = shift;
	
	return unless $app->request->type eq 'XHR';
		
	# we need to add fixes for xhr:
	# 1. set correct presentation
	# 2. remove redirect header
	
	$app->set_presentation ({type => 'json'});
	
	return;
}

sub new {
	my $class = shift;
	
	my $self = dclone ($template);
	
	if ($Class::Easy::DEBUG) {
		$self->{data}->{'debug-mode'} = $Class::Easy::DEBUG;
	}
	
	bless $self, $class;
	
	return $self;
	
}

sub generic_error {
	my $self = shift;
	my $code = shift;
	
	$self->data->{result} = 'error';
	
	push @{$self->data->{errors}->{generic}}, $code;
}

sub field_error {
	my $self  = shift;
	my $field = shift;
	my $code  = shift;
	
	my $d = $self->data;
	
	my $fields = $d->{request}->screen->params;
	
	my $field_params = (grep {$_->{name} eq $field} @$fields)[0];
	
	$d->{result} = 'error';
	
	$d->{errors}->{$field} = [
		$field_params->{required} ? 'required' : 'optional',
		$code
	];
}


1;