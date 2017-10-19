# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

use lib qw(lib t/lib);

use WebService::Braintree;
use WebService::Braintree::TestHelper;

BEGIN { use_ok('WebService::Braintree::ValidationErrorCollection') };

subtest 'constructor and deep_errors' => sub {
    subtest 'builds an error object given an array of hashes' => sub {
        my $hash = {
            errors => [
                { attribute => 'some model attribute', code => 1, message => 'bad juju' },
                { attribute => 'some other attribute', code => 2, message => 'badder juju' },
            ],
            nested => {
                errors => [{attribute => 'a third attribute', code => 3, message => 'baddest juju'}]
            },
        };

        my $collection = WebService::Braintree::ValidationErrorCollection->new($hash);
        my $error = $collection->deep_errors->[2];
        is($error->attribute, 'a third attribute');
        is($error->code, 3);
        is($error->message, 'baddest juju');

    };
};

subtest 'for' => sub {
    subtest 'provides access to nested errors' => sub {
        my $hash = {
            errors => [{ attribute => 'some model attribute', code => 1, message => 'bad juju' }],
            nested => {
                errors => [
                    { attribute => 'number', code => 2, message => 'badder juju' },
                    { attribute => 'string', code => 3, message => 'baddest juju' },
                ],
            },
        };

        my $errors = WebService::Braintree::ValidationErrorCollection->new($hash);

        is(scalar @{$errors->deep_errors}, 3);
        is($errors->for('nested')->on('number')->[0]->code, 2);
        is($errors->for('nested')->on('number')->[0]->message, 'badder juju');
        is($errors->for('nested')->on('number')->[0]->attribute, 'number');
    };
};

done_testing();
