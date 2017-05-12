package WebService::Cmis::Agent::TokenAuth;

=head1 NAME

WebService::Cmis::Agent::TokenAuth - token-based authentication handler

=head1 DESCRIPTION

This user agent adds tocken-based authentication for subsequent calls to the
CMIS backend while the first one is still performed using HTTP basic auth. Alfresco
is one server that implements token-based authentication.

  my $client = WebService::Cmis::getClient(
    url => "http://cmis.alfresco.com/service/cmis",
    useragent => new WebService::Cmis::Agent::TokenAuth(
      loginUrl => "http://cmis.alfresco.com/service/api/login?u={username}&pw={password}",
      logoutUrl => "http://cmis.alfresco.com/service/api/login/ticket/{ticket}"
    )
  );
  
  $client->login(
    user => "user",
    password => "password",
  );

  my $repo = $client->getRepository;

Parent class: L<WebService::Cmis::Agent>

=cut

use strict;
use warnings;

use WebService::Cmis::Agent ();
our @ISA = qw(WebService::Cmis::Agent);

use Error qw(:try);

=head1 METHODS

=over 4

=item new(%params)

Create a new WebService::Cmis::Agent::TokenAuth. It remembers the session state
using a token that is used instead of the normal user credentials to authenticate.

Parameters:

=over 4

=item * user

=item * password

=item * loginUrl - url used for ticket-based authentication; example:

  "http://cmis.alfresco.com/service/api/login?u={username}&pw={password}"

=item * logoutUrl - url used for ticket-based authentication; example:

  "http://cmis.alfresco.com/service/api/login/ticket/{ticket}"

=back

See L<LWP::UserAgent> for more options.

=cut 

sub new {
  my ($class, %params) = @_;

  my $user = delete $params{user};
  my $password = delete $params{password};
  my $loginUrl = delete $params{loginUrl};
  my $logoutUrl = delete $params{logoutUrl};

  my $this = $class->SUPER::new(%params);

  $this->{user} = $user;
  $this->{password} = $password;
  $this->{loginUrl} = $loginUrl;
  $this->{logoutUrl} = $logoutUrl;

  return $this;
}

=item login(%params) -> $ticket

logs in to the web service 

Parameters:

=over 4

=item * user 

=item * password

=item * ticket

=back

Login using basic auth. A ticket will be aquired to be
used for later logins for the same user.

  my $ticket = $client->login({
    user => "user", 
    password => "pasword"
  });

  $client->login({
    user => "user", 
    ticket => "ticket"
  });

=cut

sub login {
  my $this = shift;
  my %params = @_;

  $this->{user} = $params{user} if defined $params{user};
  $this->{password} = $params{password} if defined $params{password};
  $this->{ticket} = $params{ticket} if defined $params{ticket};

  my $loginUrl = $this->{loginUrl};

  unless(defined $this->{ticket}) {

    $loginUrl =~ s/{username}/$this->{user}/g;
    $loginUrl =~ s/{password}/$this->{password}/g;

    my $doc = $this->{client}->get($loginUrl);
    $this->{ticket} = $doc->findvalue("ticket");

    throw Error::Simple("no ticket found in response: ".$doc->toString(1))
      unless defined $this->{ticket};
  }

  return $this->{ticket};
}

=item logout() 

logs out of the web service deleting a ticket previously aquired

=cut

sub logout {
  my $this = shift;

  if (defined $this->{logoutUrl} && defined $this->{ticket}) {
    my $logoutUrl = $this->{logoutUrl};
    $logoutUrl =~ s/{ticket}/$this->{ticket}/g;
    $this->{client}->delete($logoutUrl);
  }

  $this->{user} = undef;
  $this->{password} = undef;
  $this->{ticket} = undef;
}

=item get_basic_credentials()

overrides the method in LWP::UserAgent to implement the given authentication mechanism.

=cut

sub get_basic_credentials {
  my $this = shift;

  #print STDERR "TokenAuth::get_basic_credentials\n";
  my $ticket = $this->{ticket};

  # TODO: any other "ticket users"?
  return ('ROLE_TICKET', $ticket) if defined $ticket;

  #print STDERR "TokenAuth::fallback\n";
  return ($this->{user}, $this->{password});
}

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;
