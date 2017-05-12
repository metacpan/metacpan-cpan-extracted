package WWW::PagerDuty;

BEGIN {
	use strict;
	use warnings;
	
	local $@;
	
	use Exporter;
	use LWP::UserAgent;
	use JSON;

	our @ISA = qw(Exporter);
	our @EXPORT_OK = qw(new trigger resolve);

	use constant SERVICE_URL => "https://events.pagerduty.com/generic/2010-04-15/create_event.json";
	use constant TRIGGER_KEY => 'trigger';
	use constant RESOLVE_KEY => 'resolve';

	our $VERSION = 0.2;
}

sub error($$) {
	my ($self, $errstr) = @_;

	my $result = { errors => [] };

	push (@{$result->{errors}}, $errstr);

	return $result;
}

sub new($$) {

	my ($self, $params) = @_;

	return $self->error('Error: not enough parameters provided') if (!(defined $params) or ref $params ne 'HASH');

	return $self->error("Error: $@") if $@;

	return $self->error('Error: service_key *must* be defined') if (!defined $params->{service_key});

	my $lwp = undef;

	eval '$lwp = LWP::UserAgent->new()';

	return $self->error('Error: could not instantiate LWP Object') if $@;

	$self = bless {
		url => SERVICE_URL,
		user_agent => $lwp,
		trigger_key => TRIGGER_KEY,
		resolve_key => RESOLVE_KEY,
		service_key => $params->{service_key},
		incident_key => $params->{incident_key}
	}, "WWW::PagerDuty";

	return $self;
}


sub trigger($$) {
	my ($self, $params) = @_;

	return $self->error('Error: not called correctly') if (!(defined $self) or ref $self ne 'WWW::PagerDuty');

	return $self->error('Error: parameters not passed') if (!(defined $params) or ref $params ne 'HASH');

	return $self->error('Error: incident_key *must* be passed') if (!(defined $params->{incident_key}) and !(defined $self->{incident_key}));

	return $self->error('Error: description *must* be passed') if !(defined $params->{description});
	
	my $details = $params->{details};

	if (defined $params->{details} && ref $params->{details} eq 'SCALAR') {
		$details = {
			'additional_info' => $params->{details}
		};
	} elsif (defined $params->{details} && ref $params->{details} eq 'HASH') {
	
	} else {
		$details = undef;
	}

	my $request_body = {
		'service_key' => $self->{service_key},
		'incident_key' => (defined $params->{incident_key}) ? $params->{incident_key} : $self->{incident_key},
		'event_type' => $self->{trigger_key},
		'description' => $params->{description},
		'details' => $details
	};

	my $return_body = undef;
	
	local $@;

	my $data = undef;

	$data = eval { JSON::encode_json($request_body); };

	if ($data) {

		$return_body = eval  { $self->{user_agent}->post($self->{url}, Content_Type => 'application/json', Content => $data); };

		if (defined $return_body) {
			my $result = JSON::decode_json($return_body->decoded_content);
			if (defined $result && ref $result eq 'HASH') {
				if ($@) {
					if (defined $result->{errors} && ref $result->{errors} eq 'ARRAY') {
						push(@{$result->{errors}}, $@);
					}
				}
				return $result;
			} else {
				return $return_body;
			}
		} elsif($@) {
			return $self->error("Error: $@");
		} else {
			return $self->error('Error: response body was not returned');
		}

	} elsif ($@) {
		return $self->error("Error: $@");
	}

	return undef;
}


sub resolve($$) {
	my ($self, $params) = @_;

	return WWW::PagerDuty::error(undef, "Error: calling convention not followed") if !(defined $self) and ref $self ne 'WWW::PagerDuty';
	return $self->error("Error: no parameters passed") if (!(defined $params) or ref $params ne 'HASH' );
	return $self->error("Error: not initialized correctly, service_key *must* be defined") if !(defined $self->{service_key});
	return $self->error("Error: incident_key *must* be passed") if !($self->{incident_key}) and !($params->{incident_key});
	return $self->error("Error: description *must* be defined") if !($params->{description});

	my $details = $params->{details};

	if (defined $details) {
		if (ref $details eq 'SCALAR') {
			$details = {
				additional_information => $details
			};
		} elsif (ref $details eq 'HASH') {
			
		} else {
			$details = undef;
		}
	}

	my $request_body = {
		service_key => (defined $params->{service_key}) ? $params->{service_key} : $self->{service_key},
		incident_key => (defined $params->{service_key}) ? $params->{incident_key} : $self->{incident_key},
		event_type => $self->{resolve_key},
		description => $params->{details},
		details => $details
	};

	my $request_body_json = undef;
	
	local $@;

	$request_body_json = eval { JSON::encode_json($request_body); };

	if (defined $request_body_json && $request_body_json && !$@) {
		my $http_response_body = undef;

		$http_response_body = eval { $self->{user_agent}->post($self->{url}, Content_Type => 'application/json', Content => $request_body_json); };

		if (defined $http_response_body && !$@) {
			my $http_response = undef;

			$http_response = eval { JSON::decode_json($http_response_body->decoded_content); };

			if (defined $http_response) {
				if ($@) {
					if (ref $http_response eq 'HASH' && defined $http_response->{errors} && ref $http_response->{errors} eq 'ARRAY') {
						push(@{$http_response->{errors}}, $@);
					} elsif (ref $http_response eq 'HASH' && !defined $http_response->{errors}) {
						$http_response->{errors} = [];
						push(@{$http_response->{errors}}, $@);
					}
				}
				return $http_response;
			}

		} elsif (defined $http_response_body && $@) {
			return { errors => ["Error: $@"], http_response_body => $http_response_body };
		} elsif ($@) {
			return $self->error("Error: $@");
		}
	} elsif ($@) { 
		return $self->error("Error: $@");
	}

	return undef;
}



1
