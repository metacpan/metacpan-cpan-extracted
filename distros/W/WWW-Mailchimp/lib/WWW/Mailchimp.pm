package WWW::Mailchimp;
use Moo;
use LWP;
use JSON;
use URI;
use URI::Escape;
use PHP::HTTPBuildQuery qw(http_build_query);
use MooX::Types::MooseLike::Base qw(Int InstanceOf Num Str);
use Sub::Name;

our $VERSION = '0.010';
$VERSION = eval $VERSION;

=head1 NAME

WWW::Mailchimp - Perl wrapper around the Mailchimp v1.3 API

=head1 SYNOPSIS

  use strict;
  use WWW::Mailchimp

  my $mailchimp = WWW::Mailchimp->new(apikey => $apikey);
  # defaults ( datacenter => 'us1', timeout => 5, output_format => 'json', api_version => 1.3 )

  my $campaigns = $mailchimp->campaigns;
  my $lists = $mailchimp->lists;
  my $subscribers = $mailchimp->listMembers( $lists->{data}->[0]->{id} );
  my $ok = $mailchimp->listSubscribe( id => $lists->{data}->[0]->{id},
                                      email_address => 'foo@bar.com',
                                      update_existing => 1,
                                      merge_vars => [ FNAME => 'foo',
                                                      LNAME => 'bar' ] );

=head1 DESCRIPTION

WWW::Mailchimp is a simple Perl wrapper around the Mailchimp API v1.3.

It is as simple as creating a new WWW::Mailchimp object and calling ->method
Each key/value pair becomes part of a query string, for example:

  $mailchimp->listSubscribe( id => 1, email_address => 'foo@bar.com' );

results in the query string

  ?method=listSubscribe&id=1&email_address=foo@bar.com
  # apikey, output, etc are tacked on by default. This is also uri_escaped

=head1 BUGS

Currently, this module is hardcoded to JSON::from_json the result of the LWP request.
This should be changed to be dependent on the output_format. Patches welcome.

I am also rather sure handling of merge_vars can be done better. If it isn't working
properly, you can always use a key of 'merge_vars[FNAME]', for example.

=head1 SEE ALSO

Mail::Chimp::API - Perl wrapper around the Mailchimp v1.2 API using XMLRPC

=head1 AUTHOR

Justin Hunter <justin.d.hunter@gmail.com>

Fayland Lam

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Justin Hunter

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

has api_version => (
  is => 'ro',
  isa => Num,
  lazy => 1,
  default => sub { 1.3 },
);

has datacenter => (
  is => 'rw',
  isa => Str,
  lazy => 1,
  default => sub { 'us1' },
);

has apikey => (
  is => 'ro',
  isa => Str,
  required => 1,
  trigger => sub {
    my ($self, $val) = @_;
    my ($datacenter) = ($val =~ /\-(\w+)$/);
    $self->datacenter($datacenter)
  },
);

has api_url => (
  is => 'rw',
  isa => Str,
  lazy => 1,
  default => sub { my $self = shift; return 'https://' . $self->datacenter . '.api.mailchimp.com/' . $self->api_version . '/'; },
);

has output_format => (
  is => 'rw',
  isa => Str,
  lazy => 1,
  default => sub { 'json' },
);

has ua => (
  is => 'lazy',
  isa => InstanceOf['LWP::UserAgent'],
  handles => [ qw(request) ],
);

has timeout => (
  is => 'rw',
  isa => Int,
  lazy => 1,
  default => sub { 5 },
);

has json => (
  is => 'ro',
  isa => InstanceOf['JSON'],
  is => 'lazy',
);

sub _build_ua {
  my $self = shift;
  my $ua = LWP::UserAgent->new( timeout => $self->timeout, agent => __PACKAGE__ . ' ' . $VERSION, ssl_opts => { verify_hostname => 0, SSL_verify_mode => 0x00 } );
}

sub _build_json { JSON->new->allow_nonref }

sub _build_query_args {
  my ($self, %args) = @_;
  my %merge_vars = @{delete $args{merge_vars} || []};
  for my $var (keys %merge_vars) {
    if (ref($merge_vars{$var}) eq 'ARRAY') {
      my $count = 0;
      for my $val (@{$merge_vars{$var}}) {
        $args{"merge_vars[$var][$count]"} = $val;
        $count++;
      }
    } else {
      $args{"merge_vars[$var]"} = $merge_vars{$var};
    }
  }

  my $uri = URI->new( $self->api_url );
  $args{apikey} = $self->apikey;
  $args{output} = $self->output_format;
  delete $args{$_} for qw(json ua);

  return \%args;
}

sub _request {
  my $self = shift;
  my $method = shift;
  my %args = ref($_[0]) ? %{$_[0]} : @_;

  # uri must include the method (even for a POST request)
  my $uri = URI->new( $self->api_url );
  $uri->query( http_build_query( { method => $method } ) );

  # build a POST request with json-encoded arguments
  my $post_args = $self->_build_query_args(%args);
  my $req = HTTP::Request->new('POST', $uri);
  $req->content( uri_escape_utf8( $self->json->encode($post_args) ) );

  my $response = $self->request( $req );
  return $response->is_success ? $self->json->decode($response->content) : $response->status_line;
}

my @api_methods = qw(
  campaignContent
  campaignCreate
  campaignDelete
  campaignEcommOrderAdd
  campaignPause
  campaignReplicate
  campaignResume
  campaignSchedule
  campaignSegmentTest
  campaignSendNow
  campaignSendTest
  campaignShareReport
  campaignTemplateContent
  campaignUnschedule
  campaignUpdate
  campaigns
  campaignAbuseReports
  campaignAdvice
  campaignAnalytics
  campaignBounceMessage
  campaignBounceMessages
  campaignClickStats
  campaignEcommOrders
  campaignEepUrlStats
  campaignEmailDomainPerformance
  campaignGeoOpens
  campaignGeoOpensForCountry
  campaignHardBounces
  campaignMembers
  campaignSoftBounces
  campaignStats
  campaignUnsubscribes
  campaignClickDetailAIM
  campaignEmailStatsAIM
  campaignEmailStatsAIMAll
  campaignNotOpenedAIM
  campaignOpenedAIM
  ecommOrderAdd
  ecommOrderDel
  ecommOrders
  folderAdd
  folderDel
  folderUpdate
  folders
  campaignsForEmail
  chimpChatter
  generateText
  getAccountDetails
  inlineCss
  listsForEmail
  ping
  listAbuseReports
  listActivity
  listBatchSubscribe
  listBatchUnsubscribe
  listClients
  listGrowthHistory
  listInterestGroupAdd
  listInterestGroupDel
  listInterestGroupUpdate
  listInterestGroupingAdd
  listInterestGroupingDel
  listInterestGroupingUpdate
  listInterestGroupings
  listLocations
  listMemberActivity
  listMemberInfo
  listMembers
  listMergeVarAdd
  listMergeVarDel
  listMergeVarUpdate
  listMergeVars
  listStaticSegmentAdd
  listStaticSegmentDel
  listStaticSegmentMembersAdd
  listStaticSegmentMembersDel
  listStaticSegmentReset
  listStaticSegments
  listSubscribe
  listUnsubscribe
  listUpdateMember
  listWebhookAdd
  listWebhookDel
  listWebhooks
  lists
  apikeyAdd
  apikeyExpire
  apikeys
  templateAdd
  templateDel
  templateInfo
  templateUndel
  templateUpdate
  templates
);

no strict 'refs';
for my $method (@api_methods) {
  *{$method} = subname $method => sub { shift->_request($method, @_) };
}

1;
