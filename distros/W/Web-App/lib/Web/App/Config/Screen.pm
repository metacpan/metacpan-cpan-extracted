package Web::App::Config::Screen;
# $Id: Screen.pm,v 1.8 2009/03/29 10:06:46 apla Exp $

use Class::Easy;

has 'init_calls';
has 'process_calls';
has 'request';
has 'id';
has 'params';
has 'params_hash';
has 'auth';

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub create {
	my $class = shift;
	my $id    = shift;

	my $self  = {
		'id'            => $id,
		'init_calls'    => [],
		'process_calls' => [],
		'presentation'  => {
			'type'      => undef,
			'file'      => undef,
		},
		'request' => {
			'max-size' => 10240,
		},
	};

	bless $self, $class;

	return $self;
}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub add_call {
	my $self = shift;
	my @functions = @_;

	$self->add_init_call (@_);
	$self->add_process_call (@_);
}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub add_init_call {
	my $self = shift;
	my $params = shift;

	push @{$self->{'init_calls'}}, $params;
}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub add_process_call {
	my $self = shift;
	my $params = shift;

	push @{$self->{'process_calls'}}, $params;
}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub presentation {
	my $self  = shift;
	my $attrs = shift;
	
	$self->{presentation} = $attrs;
}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub presentation_type {
	my $self = shift;
	my $received_type = shift;

	return $self->{'presentation'}->{'type'}
		unless defined $received_type;
  
	$self->{'presentation'}->{'type'} = $received_type;
}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub presentation_file {
	my $self = shift;
	my $received_filename = shift;

	return $self->{'presentation'}->{'file'}
		unless defined $received_filename;

	$self->{'presentation'}->{'file'} = $received_filename;
} 
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub authenticated {
	my $self    = shift;
	my $session = shift;
	
	my $auth = $self->auth;
	
	return 1
		if (not defined $auth or ($auth and defined $session->id));
	
	return 0;
}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

1;

