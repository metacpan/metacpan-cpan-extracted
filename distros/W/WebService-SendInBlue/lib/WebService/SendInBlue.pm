package WebService::SendInBlue;
{
  $WebService::SendInBlue::VERSION = '0.005';
}

use strict;
use warnings;

use HTTP::Request;
use LWP::UserAgent;
use JSON;
use Data::Dumper;
use IO::Socket::INET;
use URI::Query;

use WebService::SendInBlue::Response;

=head1 NAME

WebService::SendInBlue - Perl API for https://www.sendinblue.com/ REST API 

=head1 SYNOPSIS
  use WebService::SendInBlue;

  my $api = WebService::SendInBlue->new('api_key'=>'API_KEY') 

  my $campaigns_list = $a->campaigns();

  unless ( $campaigns_list->is_success ) {
    die "Error getting campaigns: 
  }

  for my $campaign ( @{ $campaigns_list->data()->{'campaign_records'} ) {
    ... do something for each campaign
  }
  

=head1 DESCRIPTION

This module provides a simple API to the SendInBlue API.

The API reference can be found here: https://apidocs.sendinblue.com/

You will need to register and set up your account with SendInBlue, you'll
need an API key to use this module.

=cut

our $API_BASE_URI = 'https://api.sendinblue.com/v2.0/';

=head1 CONSTRUCTOR

=over 4

=item new ( api_key => 'your_api_key' )

This is the constructor for a new WebService::SendInBlue object. 
The C<app_key> is required.

=back

=cut

sub new {
    my ($class, %args) = @_;

    die "api_key is mandatory" unless $args{'api_key'};

    my $debug = $args{'debug'} || $ENV{'SENDINBLUE_DEBUG'} || 0;

    return bless { api_key => $args{'api_key'}, debug => $debug }, $class;
}

=head1 METHODS

=head2 Campaign API

=head3 Lists 

=over 4

=item lists ( %params )

Retrieves lists information.

Supported parameters: https://apidocs.sendinblue.com/list/#1

=back

=cut

sub lists {
    my ($self, %args) = @_;

    return $self->_make_request("list", 'GET', params => \%args);
} 

=over 4

=item lists_users ( lists_ids => [...], %params )

Retrieves details of all users for the given lists. C<lists_ids> is mandatory.

Supported parameters: L<https://apidocs.sendinblue.com/list/#1>

=back

=cut

sub lists_users {
    my ($self, %args) = @_;

    $args{'listids'} = delete $args{'lists_ids'};

    return $self->_make_request("list/display", 'POST', params => \%args);
} 

=head3 Campaigns 

=over 4

=item campaigns ( %params )

Retrieves details of all campaigns.

Supported parameters: L<https://apidocs.sendinblue.com/campaign/#1>

=back

=cut

sub campaigns {
    my ($self, %args) = @_;
    return $self->_make_request("campaign/detailsv2", 'GET', params => \%args);
}

=over 4

=item campaign_details ( $campaign_id, %params )

Retrieve details of any particular campaign. $campaign_id is mandatory.

Supported parameters: L<https://apidocs.sendinblue.com/campaign/#1>

=back

=cut

sub campaign_details {
    my ($self, $campaign_id) = @_;
    return $self->_make_request(sprintf("campaign/%s/detailsv2", $campaign_id), 'GET');
}

=over 4

=item campaign_recipients ( $campaign_id, $notify_url, $type )

Export the recipients of a specified campaign. It returns the background process ID which on completion calls the notify URL that you have set in the input. $campaign_id, $notify_url and $type are mandatory.

Supported parameters: L<https://apidocs.sendinblue.com/campaign/#6>

=back

=cut

sub campaign_recipients {
    my ($self, $campaign_id, $notify_url, $type) = @_;
    my %params = ( type => $type, notify_url => $notify_url );
    return $self->_make_request(sprintf("campaign/%s/recipients", $campaign_id), 'POST', params => \%params);
}

=over 4

=item campaign_recipients_file_url ( $campaign_id, $type )

Exports the recipients of a specified campaign and returns the remote url of the export result file.
This method calls the campaign_recipients, waits for the export job completion, and retrieves the url of the export file.
The file url is returned in the response data 'url' attribute

Example:

    my $result = $api->campaign_recipients_file_url($campaign_id, 'all');
    my $file_url = $result->data->{'url'};


Supported parameters: L<https://apidocs.sendinblue.com/campaign/#6>

=back

=cut

sub campaign_recipients_file_url{
    my ($self, $campaign_id, $type) = @_;

    my $inbox = $self->ua->post("http://api.webhookinbox.com/create/");
    die "Inbox request failed" unless $inbox->is_success;

    $self->log($inbox->decoded_content);
    sleep(1);

    my $inbox_data = decode_json($inbox->decoded_content);
    my $inbox_url  = $inbox_data->{'base_url'};

    my $req = $self->campaign_recipients( $campaign_id, $inbox_url."/in/", $type );
    return $req unless $req->{'code'} eq 'success';

    my $process_id = $req->{'data'}->{'process_id'};

    my $max_wait = 10;
    for (my $i=0; $i <= $max_wait; $i++) {
        # Get inbox items
        my $items = $self->ua->get($inbox_url."/items/?order=-created&max=20");
        die "Inbox request failed" unless $items->is_success;

        $self->log($items->decoded_content);

        my $items_data = decode_json($items->decoded_content);
        for my $i (@{$items_data->{'items'}}) {
            my %data = URI::Query->new($i->{'body'})->hash;
            $self->log(Dumper(\%data));

            next unless $data{'proc_success'} == $process_id;

            return { 'code' => 'success', 'data' => $data{'url'} }; 
        }

        sleep(10);
    }
    die "Unable to wait more for the export file url";
}


=head2 SMTP API

=head3 Aggregate reports 

=over 4

=item smtp_statistics( %params )

Retrieves reports for the SendinBlue SMTP account

Supported parameters: L<https://apidocs.sendinblue.com/statistics/>

=back

=cut

sub smtp_statistics {
    my ($self, %args) = @_;
    return $self->_make_request("statistics", 'POST', params => \%args);
}

sub processes {
    my ($self, %args) = @_;
    return $self->_make_request("process", 'GET', params => \%args);
}

sub _make_request {
    my ($self, $uri, $method, %args) = @_;
    
    my $req = HTTP::Request->new();

    $req->header('api-key' => $self->{'api_key'});
    $req->header('api_key' => $self->{'api_key'});
    $req->method($method);
    $req->uri($API_BASE_URI.$uri);

    if ( $args{'params'} ) {
        $req->content(encode_json($args{'params'}));
        $self->log(encode_json($args{'params'}));
    }

    my $resp = $self->ua->request($req);

    $self->log(Dumper($resp->content));

    my $json = decode_json($resp->content());

    $self->log(Dumper($json));

    return WebService::SendInBlue::Response->new($json);
}

sub ua {
    my $self = shift;

    return LWP::UserAgent->new();
}

sub log {
    my ($self, $line) = @_;

    return unless $self->{'debug'};

    print STDERR "[".ref($self)."] $line\n";
}

=head1 SEE ALSO

For information about the SendInBlue API:
L<https://apidocs.sendinblue.com>

To sign up for an account:
L<https://www.sendinblue.com/>

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2016 Bruno Tavares. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Bruno Tavares <eu@brunotavares.net>

=cut

1;
