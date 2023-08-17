use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Fatal;
use WebService::Async::SmartyStreets::Address;

subtest 'Parsing test' => sub {
    my %dummy_data = (
        input_id     => 12345,
        organization => 'Beenary',
        metadata     => {
            latitude          => 101.2131,
            longitude         => 180.1223,
            geocode_precision => "Premise",
        },
        analysis => {
            verification_status => "Partial",
            address_precision   => "Premise",
        });

    my $parsed_data = WebService::Async::SmartyStreets::Address->new(%dummy_data);

    # Checks if the data is correctly parsed
    is($parsed_data->input_id,          12345,     "input_id is correctly parsed");
    is($parsed_data->organization,      'Beenary', "Organization is correctly parsed");
    is($parsed_data->latitude,          101.2131,  "latitude is correctly parsed");
    is($parsed_data->longitude,         180.1223,  "longitude is correctly parsed");
    is($parsed_data->geocode_precision, "Premise", "geocode_precision is correctly parsed");
    is($parsed_data->status,            "partial", "status is correctly parsed");
    # Checks if data can be retrieved if it is not passed in
    is($parsed_data->address_format, undef, "address_format is undef");

    # Check if status check is correct
    is($parsed_data->status_at_least('none'),     1,  "Verification score is correct");
    is($parsed_data->status_at_least('verified'), '', "Verification score is correct");

    # Check if address accuracy level check is correct
    is($parsed_data->accuracy_at_least('locality'),           1,  "Accuracy checking is correct");
    is($parsed_data->accuracy_at_least('administrativearea'), 1,  "Accuracy checking is correct");
    is($parsed_data->accuracy_at_least('deliverypoint'),      '', "Accuracy checking is correct");

    subtest 'undefined accuracy' => sub {
        my %dummy_data = (
            input_id     => 12345,
            organization => 'Beenary',
            metadata     => {
                latitude          => 101.2131,
                longitude         => 180.1223,
                geocode_precision => "Premise",
            },
            analysis => {
                verification_status => "Partial",
            });

        my $parsed_data = WebService::Async::SmartyStreets::Address->new(%dummy_data);
        is($parsed_data->accuracy_at_least('locality'), 0, "Accuracy not defined");
    };

    subtest 'unknown accuracy' => sub {
        my %dummy_data = (
            input_id     => 12345,
            organization => 'Beenary',
            metadata     => {
                latitude          => 101.2131,
                longitude         => 180.1223,
                geocode_precision => "Premise",
            },
            analysis => {
                verification_status => "Partial",
                address_precision   => "IDK"
            });

        my $parsed_data = WebService::Async::SmartyStreets::Address->new(%dummy_data);

        my $exception = exception {
            $parsed_data->accuracy_at_least('locality')
        };

        ok $exception =~ /unknown accuracy idk/;
    };

    subtest 'unknown target' => sub {
        my %dummy_data = (
            input_id     => 12345,
            organization => 'Beenary',
            metadata     => {
                latitude          => 101.2131,
                longitude         => 180.1223,
                geocode_precision => "Premise",
            },
            analysis => {
                verification_status => "Partial",
                address_precision   => "IDK"
            });

        my $parsed_data = WebService::Async::SmartyStreets::Address->new(%dummy_data);

        my $exception = exception {
            $parsed_data->accuracy_at_least('idk')
        };

        ok $exception =~ /unknown target accuracy idk/;
    };
};

subtest lc_uninitialie_error => sub {
    my %dummy_data = (
        input_id     => 12345,
        organization => 'Beenary',
        metadata     => {
            latitude          => 101.2131,
            longitude         => 180.1223,
            geocode_precision => "Premise",
        },
        analysis => {});

    my $parsed_data = WebService::Async::SmartyStreets::Address->new(%dummy_data);
    is($parsed_data->status,                'none', 'undef will be none');
    is($parsed_data->address_precision,     '',     'undef will be empty string');
    is($parsed_data->max_address_precision, '',     'undef will be empty string');
};
done_testing;
