package WWW::Asana::Response;
BEGIN {
  $WWW::Asana::Response::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::Asana::Response::VERSION = '0.003';
}
# ABSTRACT: Asana Response Class

use MooX qw(
	+WWW::Asana::Error
	+JSON
);

use Class::Load ':all';

with 'WWW::Asana::Role::HasClient';

has request => (
	is => 'ro',
	required => 1,
);

has http_response => (
	is => 'ro',
	required => 1,
	handles => [qw(
		is_success
		code
	)],
);

has to => (
	is => 'ro',
	required => 1,
);

has errors => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub has_errors { !shift->is_success }

sub _build_errors {
	my ( $self ) = @_;
	return [] unless $self->has_errors;
	my @errors;
	if (defined $self->json_decoded_body->{errors}) {
		for (@{$self->json_decoded_body->{errors}}) {
			push @errors, WWW::Asana::Error->new(
				message => $_->{message},
				defined $_->{phrase} ? ( phrase => $_->{phrase} ) : (),
			);
		}
	}
	return \@errors;
}

has status_error_message => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_status_error_message {
	my ( $self ) = @_;
	return if $self->is_success;
	return "Invalid request" if $self->code == 400;
	return "No authorization" if $self->code == 401;
	return "Access denied" if $self->code == 403;
	return "Not found" if $self->code == 404;
	return "Rate Limit Enforced" if $self->code == 429;
	return "Server error" if $self->code == 500;
}

has json => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_json {
	my $json = JSON->new;
	$json->allow_nonref;
	return $json;
}

has json_decoded_body => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_json_decoded_body {
	my ( $self ) = @_;
	#use DDP; p($self->http_response->content);
	$self->json->decode($self->http_response->content);
}

has data => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_data { shift->json_decoded_body->{data} }

sub BUILDARGS {
	my ( $class, @args ) = @_;
	my $request = shift @args;
	my $http_response = shift @args;
	my $to = shift @args;
	my $client = shift @args;
	return { request => $request, http_response => $http_response, to => $to, client => $client, @args };
}

has result => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_result {
	my ( $self ) = @_;
	my @codes;
	@codes = @{$self->request->codes} if $self->request->has_codes;
	if ($self->has_errors) {
		return $self->errors;
	} elsif ($self->to eq '') {
		return 1;
	} elsif ($self->to =~ /\[([\w\d:]+)\]/) {
		my $class = 'WWW::Asana::'.$1;
		load_class($class) unless is_class_loaded($class);
		my @results;
		for (@{$self->data}) {
			my %data = %{$_};
			$data{client} = $self->client if $self->has_client;
			$data{response} = $self;
			for (@codes) {
				my %extra_data = $_->(%data);
				$data{$_} = $extra_data{$_} for (keys %extra_data);
			}
			push @results, $class->new_from_response(\%data);
		}
		return \@results;
	} else {
		my $class = 'WWW::Asana::'.$self->to;
		load_class($class) unless is_class_loaded($class);
		my %data = %{$self->data};
		$data{client} = $self->client if $self->has_client;
		$data{response} = $self;
		for (@codes) {
			my %extra_data = $_->(%data);
			$data{$_} = $extra_data{$_} for (keys %extra_data);
		}
		return $class->new_from_response(\%data);
	}
}

1;

__END__
=pod

=head1 NAME

WWW::Asana::Response - Asana Response Class

=head1 VERSION

version 0.003

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

