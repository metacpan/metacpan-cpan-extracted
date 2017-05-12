package WWW::Asana;
BEGIN {
  $WWW::Asana::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::Asana::VERSION = '0.003';
}
# ABSTRACT: Client Class for accessing Asana API


use MooX qw(
	+LWP::UserAgent
	+WWW::Asana::Response
	+WWW::Asana::Request
	+URI
);

use Carp qw( croak );

our $VERSION ||= '0.000';


has api_key => (
	is => 'ro',
	required => 1,
);


has version => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_version { '1.0' }


has base_uri => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_base_uri { 'https://app.asana.com/api' }


has useragent => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_useragent {
	my ( $self ) = @_;
	LWP::UserAgent->new(
		agent => $self->useragent_agent,
		$self->has_useragent_timeout ? (timeout => $self->useragent_timeout) : (),
	);
}


has useragent_agent => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_useragent_agent { (ref $_[0] ? ref $_[0] : $_[0]).'/'.$VERSION }


has useragent_timeout => (
	is => 'ro',
	predicate => 'has_useragent_timeout',
);


has request_class => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_request_class { 'WWW::Asana::Request' }


has response_class => (
	is => 'ro',
	lazy => 1,
	builder => 1,
);

sub _build_response_class { 'WWW::Asana::Response' }

#############################################################################################################

sub BUILDARGS {
	my ( $class, @args ) = @_;
	unshift @args, "api_key" if @args % 2 && ref $args[0] ne 'HASH';
	return { @args };
}


sub request {
	my ( $self, @args ) = @_;
	my $request;
	if (ref $args[0] eq $self->request_class) {
		$request = $args[0];
	} else {
		$request = $self->get_request(@args);
	}
	my $http_response = $self->useragent->request($request->http_request);
	my $class_response = $self->response_class;
	return $class_response->new($request, $http_response, $request->to, $self);
}


sub get_uri {
	my ( $self, @args ) = @_;
	return join('/',$self->base_uri,$self->version,@args);
}


sub get_request {
	my ( $self, @args ) = @_;
	my $to = shift @args;
	my $method = shift @args;
	my @path_parts;
	my %data;
	my @params;
	my @codes;
	for my $arg (@args) {
		if (ref $arg eq 'HASH') {
			$data{$_} = $arg->{$_} for (keys %{$arg});
		} elsif (ref $arg eq 'ARRAY') {
			push @params, [@{$arg}];
		} elsif (ref $arg eq 'CODE') {
			push @codes, $arg;
		} else {
			push @path_parts, $arg;
		}
	}
	my $uri = $self->get_uri(@path_parts);
	my $request_class = $self->request_class;
	return $request_class->new(
		api_key => $self->api_key,
		uri => $uri,
		to => $to,
		method => $method,
		%data ? ( data => \%data ) : (),
		@params ? ( params => \@params ) : (),
		@codes ? ( codes => \@codes ) : (),
	);
}


sub do {
	my ( $self, @args ) = @_;
	my $response = $self->request(@args);
	if ($response->has_errors) {
		croak "Asana Errors:\n".join("\n",map { $_->message.( $_->has_phrase ? " [phrase:".$_->phrase."]" : "" ) } @{$response->errors})."\n";
	}
	return $response->result;
}


sub me_args { 'User','GET','users','me' }
sub me {
	my $self = shift;
	$self->do($self->me_args(@_));
}


sub users_args { '[User]','GET','users' }
sub users {
	my $self = shift;
	$self->do($self->users_args(@_));
}


sub user_args { shift; '[User]','GET','users',shift }
sub user {
	my $self = shift;
	$self->do($self->user_args(@_));
}

1;


__END__
=pod

=head1 NAME

WWW::Asana - Client Class for accessing Asana API

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  my $asana = WWW::Asana->new(
    api_key => $asana_api_key,
  );

  my $me = $asana->me;

  print $me->email;

  for (@{$asana->users}) {
    print $_->name;
  }

  my $current_me = $me->reload;

  my @workspaces = @{$me->workspaces};

  my @tasks = @{$some_workspace->tasks($me)};
  my @projects = @{$some_workspace->projects};
  my @tags = @{$some_workspace->tags};

  my $new_task = $some_workspace->create_task({
    name => 'Test out WWW::Asana',
    notes => 'really cool library, should test it out',
    assignee => $me,
  });

  $new_task->completed(1);
  $new_task->due_on($new_task->created_at + DateTime::Duration->new( days => 1 ));
  my $new_version_of_task = $new_task->update;

  $new_task->add_project($some_project);

  $new_task->add_tag($some_tag);

  my $story = $new_task->comment('I still didnt made it, DAMN!');

  print $story->created_by->name;

=head1 DESCRIPTION

This library gives an abstract to access the API of the L<Asana|https://www.asana.com/> issue system.

=head1 ATTRIBUTES

=head2 api_key

API Key for the account given on the Account Settings of your Asana (see under API)

=head2 version

Version of the API in use, so far only B<1.0> is supported and this is also the default value here.

=head2 base_uri

Base of the URL of the Asana API, the default value here is B<https://app.asana.com/api>.

=head2 useragent

L<LWP::UserAgent> object used for the HTTP requests.

=head2 useragent_agent

The user agent string used for the L</useragent> object.

=head2 useragent_timeout

The timeout value in seconds used for the L</useragent> object, defaults to default value of
L<LWP::UserAgent>.

=head2 request_class

Request class used to generate the request. Defaults to L<WWW::Asana::Request>.

=head2 response_class

Response class used to handle the response of the request. Defaults to L<WWW::Asana::Response>.

=head1 METHODS

=head2 request

Takes a L<WWW::Asana::Request> object and gives back a L<WWW::Asana::Response>. If not given a
L<WWW::Asana::Request>, then it will pass the arguments to L</get_request> to get one.

TODO: Adding an auto-retry option on reaching limits

=head2 get_url

Takes L</base_uri>, L</version> and the arguments and joins them together with B</>.

=head2 get_request

Generates a L<WWW::Asana::Request> out of the parameter. The first parameter is target class name given 
without the B<WWW::Asana::> namespace. The second parameter is the method to use for the generated request,
the other parameters are taken as part of the URL on the Asana API. If additional is given a HashRef at the
end of the parameters, then those are used as data for the request.

=head2 do

This method is actually executing a request specified by all parameters beside the first one, which
are given to L</get_request>. On this response then is called L<WWW::Asana::Response/to> with the
first parameter as argument. The result of this is given back, the type then depends on the parameter
for the L<WWW::Asana::Response/to> function.

=head2 me

Makes a request to B</users/me> and gives back a L<WWW::Asana::User> of yourself.

=head2 users

Makes a request to B</users> and gives back an arrayref of L<WWW::Asana::User> with all the
users of the system.

=head2 user

Makes a request to B</users/> together with the first argument given, which needs to be an Asana user id.
It gives back a L<WWW::Asana::User> of the given user.

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-www-asana
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-www-asana/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

