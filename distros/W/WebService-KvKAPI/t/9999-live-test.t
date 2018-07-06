use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;

use WebService::KvKAPI;
use Sub::Override;
use Test::Mock::One;
use Test::Deep;

unless ($ENV{KVKAPI_KEY}) {
    plan(skip_all => q{
These tests require internet connectivity and some environment variables:

    KVKAPI_KEY
    KVKAPI_SEARCH_KVK_NUMBER
    KVKAPI_SEARCH_BRANCH_NUMBER
    KVKAPI_SEARCH_RSIN
    KVKAPI_SEARCH_MAIN_BRANCH

}
    );
}

my $api = WebService::KvKAPI->new(
    api_key => $ENV{KVKAPI_KEY}
);

sub test_search {
    my $rv = $api->search(
        exists $ENV{KVKAPI_SEARCH_KVK_NUMBER} ? (kvkNumber => $ENV{KVKAPI_SEARCH_KVK_NUMBER}) : (),
        exists $ENV{KVKAPI_SEARCH_BRANCH_NUMBER} ? (branchNumber => $ENV{KVKAPI_SEARCH_BRANCH_NUMBER}) : (),
        exists $ENV{KVKAPI_SEARCH_RSIN} ? (rsin => $ENV{KVKAPI_SEARCH_RSIN}) : (),
        exists $ENV{KVKAPI_SEARCH_MAIN_BRANCH} ? (mainBranch => $ENV{KVKAPI_SEARCH_KVK_MAIN_BRANCH}) : (),
    );

    diag explain $rv;
    isnt(@$rv, 0, "Search returned items");
}

sub test_search_all {
    my $rv = $api->search_all(
        exists $ENV{KVKAPI_SEARCH_KVK_NUMBER} ? (kvkNumber => $ENV{KVKAPI_SEARCH_KVK_NUMBER}) : (),
        exists $ENV{KVKAPI_SEARCH_BRANCH_NUMBER} ? (branchNumber => $ENV{KVKAPI_SEARCH_BRANCH_NUMBER}) : (),
        exists $ENV{KVKAPI_SEARCH_RSIN} ? (rsin => $ENV{KVKAPI_SEARCH_RSIN}) : (),
        exists $ENV{KVKAPI_SEARCH_MAIN_BRANCH} ? (mainBranch => $ENV{KVKAPI_SEARCH_KVK_MAIN_BRANCH}) : (),
    );

    diag explain $rv;
    isnt(@$rv, 10, "Search returned more than 10 items");
}

sub test_search_max {
    my $rv = $api->search_max(
        $ENV{KVKAPI_SEARCH_MAX},
        exists $ENV{KVKAPI_SEARCH_KVK_NUMBER} ? (kvkNumber => $ENV{KVKAPI_SEARCH_KVK_NUMBER}) : (),
        exists $ENV{KVKAPI_SEARCH_BRANCH_NUMBER} ? (branchNumber => $ENV{KVKAPI_SEARCH_BRANCH_NUMBER}) : (),
        exists $ENV{KVKAPI_SEARCH_RSIN} ? (rsin => $ENV{KVKAPI_SEARCH_RSIN}) : (),
        exists $ENV{KVKAPI_SEARCH_MAIN_BRANCH} ? (mainBranch => $ENV{KVKAPI_SEARCH_KVK_MAIN_BRANCH}) : (),
    );

    diag explain $rv;
    is(@$rv, $ENV{KVKAPI_SEARCH_MAX}, "Search returned no more than $ENV{KVKAPI_SEARCH_MAX} items");
}

test_search;
test_search_max;
test_search_all;

done_testing;
