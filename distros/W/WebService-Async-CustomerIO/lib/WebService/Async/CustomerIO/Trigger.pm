package WebService::Async::CustomerIO::Trigger;

use strict;
use warnings;

=head1 NAME

WebService::Async::CustomerIO::Trigger - Class for working with triggers end points

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Carp qw();

our $VERSION = '0.001';    ## VERSION

=head2 new

Creates a new API client object

Usage: C<< new(%params) -> obj >>

Parameters:

=over 4

=item * C<campaign_id>

=item * C<api_client>

=back

=cut

sub new {
    my ($cls, %param) = @_;

    $param{$_} or Carp::croak "Missing required argument: $_" for (qw(campaign_id api_client));

    return bless \%param, $cls;
}

=head2 api

=cut

sub api { return shift->{api_client} }

=head2 id

=cut

sub id { return shift->{id} }

=head2 campaign_id

=cut

sub campaign_id { return shift->{campaign_id} }

=head2 activate

Trigger broadcast campaign

Usage: C<< activate(%param) -> Future($obj) >>

=cut

sub activate {
    my ($self, $params) = @_;

    Carp::croak 'This trigger is already activated' if $self->id;

    my $campaign_id = $self->campaign_id;
    return $self->api->api_request('POST', "campaigns/$campaign_id/triggers", $params, 'trigger')->then(
        sub {
            my ($response) = @_;

            return Future->fail("UNEXPECTED_RESPONSE_FORMAT", 'customerio', $response)
                if !defined $response->{id};

            $self->{id} = $response->{id};

            return Future->done($response);
        });
}

=head2 status

Retrieve status of a broadcast

Usage: C<<  status() -> Future($response) >>

=cut

sub status {
    my ($self) = @_;

    Carp::croak 'This trigger has not been activated yet' unless $self->id;

    return $self->api->api_request(GET => 'campaigns/' . $self->campaign_id . '/triggers/' . $self->id);
}

=head2 get_errors

Retrieve per-user data file processing errors.

Usage: C<< get_errors($start, $limit) -> Future(%$result) >>

=cut

sub errors {
    my ($self, $start, $limit) = @_;

    my $trigger_id  = $self->id;
    my $campaign_id = $self->campaign_id;

    Carp::croak 'Trying to get errors for unsaved trigger' unless defined $trigger_id;
    Carp::croak "Invalid value for start $start" if defined $start && int($start) < 0;
    Carp::croak "Invalid value for limit $limit" if defined $limit && int($limit) <= 0;

    return $self->api->api_request(
        GET => "campaigns/$campaign_id/triggers/$trigger_id/errors",
        {(defined $start ? (start => int($start)) : ()), (defined $limit ? (limit => int($limit)) : ()),},
    );
}

1;
