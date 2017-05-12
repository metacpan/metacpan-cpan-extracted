package WebService::Cmis::Agent::HeaderAuth;

=head1 NAME

WebService::Cmis::Agent::BasicAuth - authenticate via HTTP headers

=head1 DESCRIPTION

This class implements authentication using HTTP headers.

TODO: this is not yet there.

See: L<http://wiki.alfresco.com/wiki/Alfresco_Authentication_Subsystems#External>

  my $client = WebService::Cmis::getClient(
    url => "http://cmis.alfresco.com/service/cmis",
    useragent => new WebService::Cmis::Agent::HeaderAuth(
      remoteUserHeader => 'X-Alfresco-Remote-User'
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

Create a new WebService::Cmis::Agent::HeaderAuth. 

See L<LWP::UserAgent> for more options.

Parameters:

=over 4

=item * remoteUserHeader

=back

=cut 

sub new {
  my ($class, %params) = @_;

  my $remoteUserHeader = delete $params{remoteUserHeader};

  my $this = $class->SUPER::new(%params);

  $this->{remoteUserHeader} = $remoteUserHeader;

  return $this;
}

=back


=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;

