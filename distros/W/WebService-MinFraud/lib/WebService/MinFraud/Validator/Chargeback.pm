package WebService::MinFraud::Validator::Chargeback;

use Moo;
use namespace::autoclean;

use Data::Rx;
use WebService::MinFraud::Data::Rx::Type::Enum;
use WebService::MinFraud::Data::Rx::Type::IPAddress;

our $VERSION = '1.009001';

extends 'WebService::MinFraud::Validator::Base';

sub _build_rx_plugins {
    Data::Rx->new(
        {
            prefix => {
                maxmind => 'tag:maxmind.com,MAXMIND:rx/',
            },
            type_plugins => [
                qw(
                    WebService::MinFraud::Data::Rx::Type::Enum
                    WebService::MinFraud::Data::Rx::Type::IPAddress
                    )
            ],
        },
    );
}

sub _build_request_schema_definition {
    return {
        type     => '//rec',
        required => {
            ip_address => {
                type => '/maxmind/ip',
            },
        },
        optional => {
            chargeback_code => '//str',
            tag             => {
                type     => '/maxmind/enum',
                contents => {
                    type   => '//str',
                    values => [
                        'not_fraud',
                        'suspected_fraud',
                        'spam_or_abuse',
                        'chargeback',
                    ],
                },
            },
            maxmind_id => {
                type   => '//str',
                length => { 'min' => 8, 'max' => 8 },
            },
            minfraud_id => {
                type   => '//str',
                length => { 'min' => 36, 'max' => 36 },
            },
            transaction_id => '//str',
        },
    };
}

1;

# ABSTRACT: Validation for the minFraud Chargeback

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Validator::Chargeback - Validation for the minFraud Chargeback

=head1 VERSION

version 1.009001

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/minfraud-api-perl/issues>.

=head1 AUTHOR

Mateu Hunter <mhunter@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
