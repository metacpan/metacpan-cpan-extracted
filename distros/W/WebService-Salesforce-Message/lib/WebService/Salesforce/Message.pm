package WebService::Salesforce::Message;

use Moo;
use XML::LibXML;
use WebService::Salesforce::Message::Notification;

our $VERSION = '0.04';

has 'xml' => ( is => 'ro', required => 1 );

has 'dom' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        XML::LibXML->load_xml( string => $self->xml );
        }
);

has 'notifications_element' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self                      = shift;
        my ( $node )                  = $self->dom->findnodes( '/soapenv:Envelope/soapenv:Body' );
        my ( $notifications_element ) = $node->getChildrenByTagName( 'notifications' );

        return $notifications_element;

        }
);

has 'notifications' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self                  = shift;
        my $notification_elements = $self->notifications_element->getChildrenByTagName( 'Notification' );

        my @notifications;
        foreach my $notification_element ( @{$notification_elements} ) {
            push @notifications, WebService::Salesforce::Message::Notification->new( {
                    notification_element => $notification_element } );
        }
        return \@notifications;
        }
);

has 'organization_id' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->notifications_element->getChildrenByTagName( 'OrganizationId' )->[0]
            ->textContent;
        }
);

has 'action_id' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->notifications_element->getChildrenByTagName( 'ActionId' )->[0]
            ->textContent;
        }
);

has 'session_id' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->notifications_element->getChildrenByTagName( 'SessionId' )->[0]
            ->textContent;
        }
);

has 'enterprise_url' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->notifications_element->getChildrenByTagName( 'EnterpriseUrl' )->[0]
            ->textContent;
        }
);

has 'partner_url' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->notifications_element->getChildrenByTagName( 'PartnerUrl' )->[0]
            ->textContent;
        }
);

has 'ack' => (
    is      => 'ro',
    default => sub {
        return <<ACK;
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
    <soapenv:Body>
        <notificationsResponse xmlns="http://soap.sforce.com/2005/09/outbound">
            <Ack>true</Ack>
        </notificationsResponse>
    </soapenv:Body>
</soapenv:Envelope>
ACK
        }
);

1;

__END__


=head1 NAME

WebService::Salesforce::Message - Perl extension for Salesforce outbound messages

=head1 SYNOPSIS

  use WebService::Salesforce::Message;

  my $xml = read_in_salesforce_soap_message();
  my $message = WebService::Salesforce::Message->new( xml => $xml );
  my $organization_id = $message->organization_id;
  my $ack = $message->ack; # xml response to SFDC to indicate success

  my $notifications = $message->notifications; # array of notification objects;
  my $attrs = $notifications->[0]->attrs; # Id, other attributes of the object in the message
  my $object_id = $notifications->[0]->get('Id');

=head1 DESCRIPTION

Salesforce.com can send outbound SOAP messages on status changes. Use this
module to parse those message and inspect the object attributes.

See the source for available methods. Documentation will be added in 0.02, or 
as patches are provided.

=head1 SEE ALSO

L<WWW::Salesforce>
L<SOAP::Lite>

=head1 AUTHOR

Fred Moyer<lt>fred@redhotpenguin.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by iParadigms LLC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
