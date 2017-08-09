package WebService::ThreatStack;

use 5.10.0;
use strict;
use warnings;
use feature 'switch';
use feature 'say';

use JSON;
use REST::Client;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;


=head1 NAME

WebService::ThreatStack - Threat Stack API client


=head1 VERSION

Version 1.00

=cut


our $VERSION = '1.00';



has api_key => (
  is        => 'rw',
  isa       => 'Str'
);

has api_url => (
  is        => 'ro',
  isa       => 'Str',
  default   => 'https://app.threatstack.com/api/v1'
);

has headers => (
  is        => 'rw',
  isa       => 'Str',
);

has debug => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0
);



=head1 SYNOPSIS

Threat Stack is a provider of cloud security management and compliance solutions delivered using a Software as a service model. 
This API client interfaces with the Threat Stack REST API.


=head1 CONFIGURATION
 
    use WebService::ThreatStack;
 
    my $ts = WebService::ThreatStack->new(
        api_key => '[your-api-key]',
        debug   => 1
     );


=head1 SUBROUTINES/METHODS


=head2 agents

List all agents assigned to your active organization.

    my $agent_list = $ts->agents(
        page  => 0,
        count => 20,
        start => '2015-04-01',
        end   => '2017-07-01'
    );

=cut

sub agents {
  my ($self, %params) = validated_hash(
    \@_,
    organization => {isa => 'Maybe[Int]', optional => 1},
    page         => {isa => 'Maybe[Int]', optional => 1},
    count        => {isa => 'Maybe[Int]', optional => 1},
    start        => {isa => 'Maybe[Str]', optional => 1},
    end          => {isa => 'Maybe[Str]', optional => 1}
  );

  say '[agents] Get all agents' if $self->debug;

  $self->_call(endpoint => 'agents', args => \%params, method => 'GET');
}



=head2 agent_by_id

Get details of a specific agent resource. The id to use is id, not agent_id.

    my $agent_info = $ts->agent_by_id(id => $id);

=cut

sub agent_by_id {
  my ($self, %params) = validated_hash(
    \@_,
    id => {isa => 'Str'}
  );

  say '[agent] Get agent by id' if $self->debug;

  $self->_call(endpoint => "agents/$params{id}", args => {}, method => 'GET');
}



=head2 alerts

This URI retrieves all recent alerts related to your current active organization.

    my $alerts = $ts->alerts(
        count => 20,
        start => "2017-07-01",
        end   => "2017-07-20"
    );

=cut

sub alerts {
  my ($self, %params) = validated_hash(
    \@_,
    organization => {isa => 'Maybe[Int]', optional => 1},
    page         => {isa => 'Maybe[Int]', optional => 1},
    count        => {isa => 'Maybe[Int]', optional => 1},
    start        => {isa => 'Maybe[Str]', optional => 1},
    end          => {isa => 'Maybe[Str]', optional => 1}
  );

  say '[alerts] Get all alerts' if $self->debug;

  $self->_call(endpoint => 'alerts', args => \%params, method => 'GET');
}



=head2 alert_by_id

Every alert has a URI to fetch specific information about it. Additionally, each alert has a 
latest_events and rule attributes that provides events related to that alert and rule triggered 
respectively.

    my $alert_info = $ts->alert_by_id(id => $alert_id);

=cut

sub alert_by_id {
  my ($self, %params) = validated_hash(
    \@_,
    id => {isa => 'Str'}
  );

  say '[alert] Get alert by id' if $self->debug;

  $self->_call(endpoint => "alerts/$params{id}", args => {}, method => 'GET');
}



=head2 policies

Policies object manage the alerts that will be triggered when certain events matches.
A default policy is applied to each agent on creation and custom ones can be created or 
assigned via the User Interface. Note that we’ve introduced the term ruleset to supersede 
policies – the API will be updated shortly, but any existing references to policies 
will still work as expected.

    my $policies = $ts->policies();

=cut

sub policies {
  my ($self, %params) = validated_hash(
    \@_,
    organization => {isa => 'Maybe[Int]', optional => 1},
    page         => {isa => 'Maybe[Int]', optional => 1},
    count        => {isa => 'Maybe[Int]', optional => 1}
  );

  say '[policies] Get all policies' if $self->debug;

  $self->_call(endpoint => 'policies', args => \%params, method => 'GET');
}



=head2 policy_by_id

Retrieve details of a single policy object.

    my $policy_info = $ts->policy_by_id(id => $policy_id);

=cut

sub policy_by_id {
  my ($self, %params) = validated_hash(
    \@_,
    id => {isa => 'Str'}
  );

  say '[policy] Get policy by id' if $self->debug;

  $self->_call(endpoint => "policies/$params{id}", args => {}, method => 'GET');
}



=head2 organizations

This resource retrieve all organizations you own or are part of.

    my $organizations = $ts->organizations();

=cut

sub organizations {
  my $self = shift;

  say '[organizations] Get all organizations' if $self->debug;

  $self->_call(endpoint => "organizations", args => {}, method => 'GET');
}



=head2 organization_users

This resource retrieves all users that are part of your default or active (if you 
use the organization parameter). To change the context just add organization={ORG_ID} 
to do requests on that organization context.

    my $organization_users = $ts->organization_users(id => $organization_id);

=cut

sub organization_users {
  my ($self, %params) = validated_hash(
    \@_,
    id => {isa => 'Str'}
  );

  say '[organization_users] Get organization users' if $self->debug;

  $self->_call(endpoint => "organizations/$params{id}/users", args => {}, method => 'GET');
}



=head2 audit_logs

Get all audit logs

    my $audit_logs = $ts->audit_logs(
        page  => 0,
        count => 20,
        start => "2015-04-01",
        end   => "2017-07-01"
    );

=cut

sub audit_logs {
  my ($self, %params) = validated_hash(
    \@_,
    organization => {isa => 'Maybe[Int]', optional => 1},
    page         => {isa => 'Maybe[Int]', optional => 1},
    count        => {isa => 'Maybe[Int]', optional => 1},
    start        => {isa => 'Maybe[Str]', optional => 1},
    end          => {isa => 'Maybe[Str]', optional => 1}
  );

  say '[audit_logs] Get all audit logs' if $self->debug;

  $self->_call(endpoint => 'logs', args => \%params, method => 'GET');

}



=head2 search_logs

Using the q parameter you can do arbitrary search on logs that match that 
specific string pattern. For example, you can do search of q=queue, 
q=john.doe@example.com, etc.

    my $log_results = $ts->search_logs(q => "PCI");

=cut

sub search_logs {
  my ($self, %params) = validated_hash(
    \@_,
    q => {isa => 'Str'}, 
  );

  say '[search_logs] Return logs by query' if $self->debug;

  $self->_call(endpoint => 'logs', args => \%params, method => 'GET');
}



=head2 _call

Private method that makes call to API web service.

=cut

sub _call {
  my ($self, %params) = validated_hash(
    \@_,
    endpoint => {isa => 'Str'},
    args     => {isa => 'Maybe[HashRef]'},
    method   => {isa => enum([qw(POST GET)])}
  );

  my $headers = {
      "Authorization" => $self->api_key
  };

  my $url = $self->api_url . '/' . $params{endpoint};

  my $client = REST::Client->new();

  for ($params{method}) {
    when ('GET')  {
      say "[_call]: Making call GET $url" if $self->debug;
      my $url_args  = keys %{$params{args}} > 0 ? '?' . join('&', map {"$_=$params{args}{$_}"} keys %{$params{args}}) : '';
      $url .= $url_args;
      $client->GET($url, $headers);
    }
    when ('POST') {
      my $json_args = JSON->new->allow_nonref->utf8->encode($params{args}{data});
      say "[_call]: Making call POST $url" if $self->debug;
      $client->POST($url, $json_args, $headers)
    }
  }

  {
      response_code    => $client->responseCode(), 
      response_content => $client->responseContent()
  }
}




=head1 AUTHOR

Dino Simone, C<< <dino at simone.is> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-castleio at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-CastleIO>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::ThreatStack


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-ThreatStack>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-ThreatStack>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-ThreatStack>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-ThreatStack/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Dino Simone - dinosimone.com

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1; # End of WebService::ThreatStack
