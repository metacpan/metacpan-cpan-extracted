package Web::MarketReceipt::Verifier::Mock::AppStore;
use Mouse;
use utf8;

extends 'Web::MarketReceipt::Verifier';

use Web::MarketReceipt;
use MIME::Base64 qw/decode_base64/;

has verifier => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub {
        my $self = shift;

        return sub { $self->_default_verifier(@_) };
    },
    lazy    => 1,
);

no Mouse;

sub _default_verifier {
    my ($self, %args) = @_;

    my $receipt = $args{receipt};

    my $parsed = $self->_parse_receipt($receipt);

    my $purchase_info = $parsed->{'purchase-info'};
    my %underscored = (
        map {
            my $key = $_;
            $key =~ s/-/_/g;
            $key => $purchase_info->{$_}
        } keys %$purchase_info
    );
    my $environment = exists $parsed->{environment} ?
        $parsed->{environment} : 'Production';

    my $result = Web::MarketReceipt->new(
        is_success => 1,
        store      => 'AppStore',
        raw        => \%underscored,
        orders     => [
            {
                product_identifier => $underscored{product_id},
                unique_identifier  => 'AppStore:' . $underscored{original_transaction_id},
                purchased_epoch    => $underscored{original_purchase_date_ms},
                quantity           => $underscored{quantity},
                environment        => $environment,
                state              => 'purchased',
            }
        ],
    );

    return $result;
}

sub verify {
    my $self = shift;

    return $self->verifier->(@_);
}

sub _parse_receipt {
    my ($class, $receipt) = @_;

    my $data = $class->_parse_oldstlye_plist($receipt);
    my $purchase_info = $class->_parse_oldstlye_plist($data->{'purchase-info'});
    $data->{'purchase-info'} = $purchase_info;

    return $data;
}

# XXX: This parser is poor but I look work with a receipt from appstore.
# If that do not parse at your receipt, please report issues or pull requests.
sub _parse_oldstlye_plist {
    my ($class, $text) = @_;

    my $data = decode_base64($text);
    my ($properties_str) = $data =~ /{(.*)}/s;
    my %kv = $properties_str =~ /\s*"(.*?)"\s*=\s*"(.*?)"\s*;/msg;

    return \%kv;
}

1;

__END__

Web::MarketReceipt::Verifier::Mock::AppStore - The mocking class for test of using Web::MarketReceipt::Verifier::AppStore

=head1 SYNOPSIS

    use Test::More;
    use Web::MarketReceipt::Verifier::Mock::AppStore;

    my $shop = MyGame::Shop->new(
        appstore_verifier => Web::MarketReceipt::Verifier::Mock::AppStore->new,
    );

    # MyApp::Game#purchase_by_appstore grant to user by receipt from AppStore.
    my $result = $shop->purchase_by_appstore(receipt => $receipt_text);

    is $result->received_items, $expected;


=head1 DESCRIPTION

Web::MarketReceipt::Verifier::Mock::AppStore is mock like Web::MarketReceipt::Verifier::AppStore.

This module without to send request to Apple's validation server.

=head1 LICENSE

Copyright (C) KAYAC Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

macopy <macopy123@gmail.com>

=cut
