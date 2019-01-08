package WebService::Auth0::Management;

use Moo;
use Module::Runtime qw(use_module);

has domain => (
  is=>'ro',
  required=>1 );

has token => (
  is=>'ro',
  predicate=>'has_token',
  required=>0 );

has ua => (
  is=>'ro',
  required=>1 );

has mgmt_path_parts => (
  is=>'ro',
  required=>1,
  isa=>sub { ref($_) eq 'ARRAY' },
  default=>sub {['api', 'v2']} );

sub create {
  my ($self, $module, $args) = @_;
  my %args = (
    domain => $self->domain,
    ua => $self->ua,
    mgmt_path_parts => $self->mgmt_path_parts,
    %{$args||+{}});

  $args{token} = $self->token if $self->has_token;
  return use_module(ref($self)."::$module")->new(%args);
}

sub blacklists { shift->create('Blacklists',@_) }
sub client_grants { shift->create('ClientGrants',@_) }
sub clients { shift->create('Clients',@_) }
sub connections { shift->create('Connections',@_) }
sub device_credentials { shift->create('DeviceCredentials',@_) }
sub emails { shift->create('Emails',@_) }
sub guardian{ shift->create('Guardian',@_) }
sub jobs { shift->create('Jobs',@_) }
sub logs { shift->create('Logs',@_) }
sub resource_servers { shift->create('ResourceServers',@_) }
sub rules { shift->create('Rules',@_) }
sub stats { shift->create('Stats',@_) }
sub template { shift->create('Template',@_) }
sub tenants { shift->create('Tenants',@_) }
sub tickets { shift->create('Tickets',@_) }
sub user_blocks { shift->create('UserBlocks',@_) }
sub users { shift->create('Users',@_) }


=head1 NAME

WebService::Auth0::Management - Factory class for the Management API

=head1 SYNOPSIS

    my $mgmt = WebService::Auth0::Management->new(
      ua => $ua,
      domain => $ENV{AUTH0_DOMAIN},
      token => $ENV{AUTH0_TOKEN},
    );

    my $rules = $mgmt->create('Rules');
    my $future = $rules->get;

=head1 DESCRIPTION

Factory class for the various modules that make up the Management API.
I'm actually not keen on this approach but it seems like the way that
Auth0 did all the SDKs in other languages so I figured its probably
best to play to the standard.

You can also create each Management module standalone.

=head1 ATTRIBUTES

This class defines the following attributes:

=head2 domain

=head2 token

=head2 ua

=head2 mgmt_path_parts

=head1 METHODS

This class defines the following methods:

=head2 create ($module, \%args)

    my $rules = $mgmt->create('Rules');

Create a module based on the current arguments.  You may pass in override
arguments as the second argument of this method.

=head1 PROXY METHODS

The following methods are proxies to create a sub module

=head2 blacklists

=head2 client_grants

=head2 clients

=head2 connections

=head2 device_credentials

=head2 emails

=head2 guardian

=head2 jobs

=head2 logs

=head2 resource_servers

=head2 rules

=head2 stats

=head2 template

=head2 tenants

=head2 tickets

=head2 user_blocks

=head2 users

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;
