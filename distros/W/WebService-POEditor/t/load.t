#!/usr/bin/env perl

use warnings;
use strict;

use Test::Most;

subtest 'use' => sub {
    use_ok 'WebService::POEditor';
};

subtest 'run' => sub {
    use WebService::POEditor;

    # my $poe = WebService::POEditor->new(
    #     { api_token => '' });
    # ok $poe, 'Got object.';

    # my $res = $poe->list_projects;

    pass;
};

done_testing;
