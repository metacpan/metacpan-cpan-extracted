use strict;
use warnings;

use Test::Exception;
use Test::More tests => 3;

use Webservice::GAMSTOP;

my $instance;
subtest 'Webservice::GAMSTOP object validations' => sub {
    throws_ok {
        $instance = Webservice::GAMSTOP->new();
    }
    qr/Missing required arguments: api_key, api_url/, 'Missing required arguments';

    throws_ok {
        $instance = Webservice::GAMSTOP->new(api_url => 'dummy');
    }
    qr/Missing required arguments: api_key/, 'Missing required argument - api_key';

    throws_ok {
        $instance = Webservice::GAMSTOP->new(api_key => 'dummy');
    }
    qr/Missing required arguments: api_url/, 'Missing required argument - api_url';

    $instance = Webservice::GAMSTOP->new(
        api_url => 'dummy',
        api_key => 'dummy_key'
    );
    is $instance->timeout, 5, 'valid default timeout';

    $instance = Webservice::GAMSTOP->new(
        api_url => 'dummy',
        api_key => 'dummy_key',
        timeout => 10
    );
    is $instance->timeout, 10, 'timeout is same as sepcified one';
};

subtest 'Webservice::GAMSTOP get_exclusion_for validations' => sub {
    my $exclusion;
    throws_ok {
        $exclusion = $instance->get_exclusion_for();
    }
    qr/Missing required parameter: first_name/, 'Missing required parameter - first_name';

    throws_ok {
        $exclusion = $instance->get_exclusion_for(first_name => 'Harry');
    }
    qr/Missing required parameter: last_name/, 'Missing required parameter - last_name';

    throws_ok {
        $exclusion = $instance->get_exclusion_for(
            first_name => 'Harry',
            last_name  => 'Potter'
        );
    }
    qr/Missing required parameter: date_of_birth/, 'Missing required parameter - date_of_birth';

    throws_ok {
        $exclusion = $instance->get_exclusion_for(
            first_name    => 'Harry',
            last_name     => 'Potter',
            date_of_birth => '1970-01-01'
        );
    }
    qr/Missing required parameter: email/, 'Missing required parameter - email';

    throws_ok {
        $exclusion = $instance->get_exclusion_for(
            first_name    => 'Harry',
            last_name     => 'Potter',
            date_of_birth => '1970-01-01',
            email         => 'harry.potter@example.com'
        );
    }
    qr/Missing required parameter: postcode/, 'Missing required parameter - postcode';

    throws_ok {
        $exclusion = $instance->get_exclusion_for(
            first_name    => 'Harry',
            last_name     => 'Potter',
            date_of_birth => '1970-01-01',
            email         => 'harry.potter@example.com',
            postcode      => 'hp11aa'
        );
    }
    qr/Error - Connection error: /, 'Dummy api key and url fail with connection error';
};

subtest 'Webservice::GAMSTOP::Response validations' => sub {
    my $response = Webservice::GAMSTOP::Response->new();

    is $response->is_excluded,   0,     'Correct excluded flag for empty arguments';
    is $response->get_date,      undef, 'Date is undef for empty arguments';
    is $response->get_unique_id, undef, 'Unique id is undef for empty arguments';
    is $response->get_exclusion, undef, 'Exclusion flag is undef for empty arguments';

    my ($date, $unique_id) = ('Tue, 27 Feb 2018 04:21:23 GMT', '81991dae-5a3beb15-0114defb');

    $response = Webservice::GAMSTOP::Response->new(
        exclusion => 'P',
        unique_id => $unique_id,
        date      => $date
    );
    is $response->is_excluded, 0, 'Correct excluded flag for P';
    is $response->get_date,      $date,      'Correct date';
    is $response->get_unique_id, $unique_id, 'Correct unique_id';
    is $response->get_exclusion, 'P', 'Correct exclusion flag';

    $response = Webservice::GAMSTOP::Response->new(
        exclusion => 'N',
        unique_id => $unique_id,
        date      => $date
    );
    is $response->is_excluded, 0, 'Correct excluded flag for N';
    is $response->get_date,      $date,      'Correct date';
    is $response->get_unique_id, $unique_id, 'Correct unique_id';
    is $response->get_exclusion, 'N', 'Correct exclusion flag';

    $response = Webservice::GAMSTOP::Response->new(
        exclusion => 'Y',
        unique_id => $unique_id,
        date      => $date
    );
    is $response->is_excluded, 1, 'Correct excluded flag for Y';
    is $response->get_date,      $date,      'Correct date';
    is $response->get_unique_id, $unique_id, 'Correct unique_id';
    is $response->get_exclusion, 'Y', 'Correct exclusion flag';
};
