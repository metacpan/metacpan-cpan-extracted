package WebService::Cmis::Agent::BasicAuth;

=head1 NAME

WebService::Cmis::Agent::BasicAuth - authenticate via HTTP basic auth

=head1 DESCRIPTION

This class implements authentication using HTTP basic authentication.
It will be used when no other authentication mechanism has been specified
for a client.

  my $client = WebService::Cmis::getClient(
    url => "http://cmis.alfresco.com/service/cmis",
    useragent => new WebService::Cmis::Agent::BasicAuth(
      user => "user",
      password => "password",
    );
  );
  
  my $repo = $client->getRepository;

Parent class: L<WebService::Cmis::Agent>

=cut

use strict;
use warnings;

use WebService::Cmis::Agent ();
our @ISA = qw(WebService::Cmis::Agent);

=head1 METHODS

=over 4

=item new(%params)

Create a new WebService::Cmis::Agent::BasicAuth. 

See L<LWP::UserAgent> for more options.

Parameters:

=over 4

=item * user

=item * password

=back

=cut 

sub new {
  my ($class, %params) = @_;

  my $user = delete $params{user};
  my $password = delete $params{password};

  my $this = $class->SUPER::new(%params);

  $this->{user} = $user;
  $this->{password} = $password;

  return $this;
}

=item login(%params) 

sets the user and password for the current user agent

Parameters:

=over 4

=item * user 

=item * password

=back

=cut

sub login {
  my $this = shift;
  my %params = @_;

  $this->{user} = $params{user} if defined $params{user};
  $this->{password} = $params{password} if defined $params{password};
}

=item logout() 

invalidates the user credentials

=cut

sub logout {
  my $this = shift;

  $this->{user} = undef;
  $this->{password} = undef;
}

=item get_basic_credentials()

overrides the method in LWP::UserAgent to implement the given authentication mechanism.

=cut

sub get_basic_credentials {
  my ($this, $realm) = @_;

  return ($this->{user}, $this->{password});
}

=back


=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;
