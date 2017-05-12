package Web::MarketReceipt;
use 5.010000;
our $VERSION = "0.02";

use Mouse;
use Mouse::Util::TypeConstraints;
use utf8;

use Web::MarketReceipt::Order;

subtype 'ArrayRefWebMarketReceiptOrder',
    as 'ArrayRef[Web::MarketReceipt::Order]';

coerce 'ArrayRefWebMarketReceiptOrder'
    => from 'ArrayRef',
    => via { [ map { Web::MarketReceipt::Order->new($_) } @$_ ] };

has is_success => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

has raw => (
    is       => 'ro',
    required => 1,
);

has orders => (
    is     => 'ro',
    isa    => 'ArrayRefWebMarketReceiptOrder',
    coerce => 1,
);

has store => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

no Mouse;

sub dump {
    my $self = shift;

    +{
        is_success => $self->is_success,
        raw        => $self->raw,
        ($self->orders ? (orders => [map {$_->dump} @{ $self->orders }]) : ())
    };
}

1;
__END__

=head1 NAME

Web::MarketReceipt - iOS and Android receipt verification module.

=head1 SYNOPSIS

    use Web::MarketReceipt::Verifier::AppStore;
    use Web::MarketReceipt::Verifier::GooglePlay;

    my $ios_result = Web::MarketReceipt::Verifier::AppStore->verify(
        receipt => $ios_receipt,
    );

    if ($ios_result->is_success) {
        # some payment function
    } else {
        # some error function
    }

    my $android_result = Web::MarketReceipt::Verifier::GooglePlay->new(
        public_key => $some_key
    )->verify(
        signed_data => $android_receipt_signed_data,
        signature   => $android_receipt_signature,
    );

    if ($android_result->is_success) {
        # some payment function
    } else {
        # some error function
    }

=head1 DESCRIPTION

Web::MarketReceipt is iOS and Android receipt verification module

=head1 LICENSE

Copyright (C) KAYAC Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Konboi <ryosuke.yabuki@gmail.com>

=cut
