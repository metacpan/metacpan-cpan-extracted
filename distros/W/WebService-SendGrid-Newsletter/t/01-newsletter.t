#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok('WebService::SendGrid::Newsletter');
}

my $sgn;

dies_ok {
    $sgn = WebService::SendGrid::Newsletter->new();
} 'Cannot create a new instance without required parameters';
   
lives_ok {
    $sgn = WebService::SendGrid::Newsletter->new(
        api_user => 'username',
        api_key  => 'password',
        json_options => { canonical => 1 },
    );
} 'Can successfully create a new instance';

done_testing();