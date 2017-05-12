package WebService::Affiliate::Role::Voucher;

use Moose::Role;

use DateTime::Format::ISO8601;
use DateTime::Format::MySQL;
use URI;

=head1 NAME

WebService::Affiliate::Role::Voucher - Role for basic voucher code attributes.

=cut

=head1 METHODS

=head2 Attributes

=cut

has  code        => ( is => 'rw', isa => 'Str',                                                                  );
has _starts      => ( is => 'rw', isa => 'Str',                                                                  );
has  starts      => ( is => 'rw', isa => 'Maybe[DateTime]',               lazy => 1, builder => '_build_starts'  );
has _expires     => ( is => 'rw', isa => 'Str',                                                                  );
has  expires     => ( is => 'rw', isa => 'Maybe[DateTime]',               lazy => 1, builder => '_build_expires' );
has  description => ( is => 'rw', isa => 'Str',                                                                  );
has _url         => ( is => 'rw', isa => 'Str',                                                                  );
has  url         => ( is => 'rw', isa => 'Maybe[URI]',                    lazy => 1, builder => '_build_url'     );
has  merchant    => ( is => 'rw', isa => 'WebService::Affiliate::Merchant'                                       );


sub _build_starts
{
    my ($self) = @_;

    return undef if ! $self->_starts;

    return DateTime::Format::MySQL->parse_datetime( $self->_starts ) if $self->_starts =~ /^\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d$/;
    return DateTime::Format::MySQL->parse_datetime( $self->_starts . ':00' ) if $self->_starts =~ /^\d\d\d\d\-\d\d\-\d\d \d\d:\d\d$/;
    return DateTime::Format::ISO8601->parse_datetime( $self->_starts );
}

sub _build_expires
{
    my ($self) = @_;

    return undef if ! $self->_expires;

    return DateTime::Format::MySQL->parse_datetime( $self->_expires ) if $self->_expires =~ /^\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d$/;
    return DateTime::Format::MySQL->parse_datetime( $self->_expires . ':00' ) if $self->_expires =~ /^\d\d\d\d\-\d\d\-\d\d \d\d:\d\d$/;
    return DateTime::Format::ISO8601->parse_datetime( $self->_expires );
}

sub _build_url
{
    my ($self) = @_;

    return $self->_url ? URI->new( $self->_url ) : undef;
}


1;
