package WebService::Salesforce::Message::Notification;

use Moo;
use XML::LibXML;

our $VERSION = '0.04';

has 'notification_element' => ( is => 'ro', required => 1 );

has 'id' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->notification_element->getChildrenByTagName( 'Id' )->[0]
            ->textContent;
        }
);

has 'sobject' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->notification_element->getChildrenByTagName( 'sObject' )->[0];
        }
);

has 'object_type' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my ( $ns, $type ) =
            split( ':', $self->sobject->getAttribute( 'xsi:type' ) );
        return $type;
        }
);

has 'attrs' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self       = shift;
        my @childnodes = $self->sobject->childNodes();
        return [
            map      { $_->localname }
                grep { $_->isa( 'XML::LibXML::Element' ) } @childnodes
        ];
        }
);


sub get {
    my ( $self, $attr ) = @_;
    return $self->sobject->findnodes( "./sf:$attr" )->[0]->textContent;
}



1;
