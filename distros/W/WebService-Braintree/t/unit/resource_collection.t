# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

use lib qw(lib t/lib);

use WebService::Braintree;
use WebService::Braintree::TestHelper;

subtest "each" => sub {
    my $response = {search_results => {ids => [1,2,3,4,5], page_size => 2}};
    my $page_counter = 0;
    my $resource_collection = WebService::Braintree::ResourceCollection->new({
        response => $response,
        callback => sub {
            $page_counter = $page_counter + 1;
            return [$page_counter];
        },
    });

    my @page_counts = ();
    $resource_collection->each(sub {
        push(@page_counts, shift);
    });

    is $resource_collection->maximum_size, 5;
    is_deeply(\@page_counts, [1, 2, 3]);
};

done_testing();
