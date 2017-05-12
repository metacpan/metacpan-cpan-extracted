# NAME

Web::MarketReceipt - iOS and Android receipt verification module.

# SYNOPSIS

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

# DESCRIPTION

Web::MarketReceipt is iOS and Android receipt verification module

# LICENSE

Copyright (C) KAYAC Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Konboi <ryosuke.yabuki@gmail.com>
