package WebService::Affiliate::Role::Transaction;

use Moose::Role;

=head1 NAME

WebService::Affiliate::Role::transaction - Role for basic transaction attributes.

=cut

=head1 METHODS

=head2 Attributes

=cut

has  merchant            => ( is => 'rw', isa => 'WebService::Affiliate::Merchant'      );
has _click_date          => ( is => 'rw', isa => 'Str',                                                      );
has  click_date          => ( is => 'rw', isa => 'Maybe[DateTime]', lazy => 1, builder => '_build_click_date' );
has _sale_date           => ( is => 'rw', isa => 'Str',                                                      );
has  sale_date           => ( is => 'rw', isa => 'Maybe[DateTime]', lazy => 1, builder => '_build_sale_date' );
has  sale_currency       => ( is => 'rw', isa => 'Str' );
has  sale_amount         => ( is => 'rw', isa => 'Num' );
has  commission_currency => ( is => 'rw', isa => 'Str' );
has  commission_amount   => ( is => 'rw', isa => 'Num' );
has  clickref            => ( is => 'rw', isa => 'Str' );
has  status              => ( is => 'rw', isa => 'Str' );
has  payment_status      => ( is => 'rw', isa => 'Str' );

sub _build_click_date
{
    my ($self) = @_;

    return undef if ! $self->_click_date;

    return undef if $self->_click_date =~ /^0000-00-00 00:00:00$/;
    return DateTime::Format::MySQL->parse_datetime( $self->_click_date )         if $self->_click_date =~ /^\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d$/;
    return DateTime::Format::MySQL->parse_datetime( $self->_click_date . ':00' ) if $self->_click_date =~ /^\d\d\d\d\-\d\d\-\d\d \d\d:\d\d$/;
    return DateTime::Format::ISO8601->parse_datetime( $self->_click_date );
}

sub _build_sale_date
{
    my ($self) = @_;

    return undef if ! $self->_sale_date;

    return DateTime::Format::MySQL->parse_datetime( $self->_sale_date ) if $self->_sale_date =~ /^\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d$/;
    return DateTime::Format::MySQL->parse_datetime( $self->_sale_date . ':00' ) if $self->_sale_date =~ /^\d\d\d\d\-\d\d\-\d\d \d\d:\d\d$/;
    return DateTime::Format::ISO8601->parse_datetime( $self->_sale_date );
}


1;
