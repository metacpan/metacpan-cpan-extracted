#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;

BEGIN {
    use_ok( 'URL::Normalize' );
}

{
    my $normalizer = URL::Normalize->new( 'http://www.example.com/?a=1&a=2&b=3' );

    $normalizer->remove_query_parameter( 'a' );

    is( $normalizer->url, 'http://www.example.com/?b=3', 'Removed query parameters' );
}

# {
#     my %tests = (
#         'http://www.huffingtonpost.com/2014/06/02/multilingual-benefits_n_5399980.html?ncid=tweetlnkushpmg00000067' => 'http://www.huffingtonpost.com/2014/06/02/multilingual-benefits_n_5399980.html',
#         'http://www.example.com/?utm_campaign=&utm_medium=&utm_source='                                             => 'http://www.example.com/',
#     );
#
#     while ( my ($input, $output) = each %tests ) {
#         my $normalizer = URL::Normalize->new(
#             url => $input,
#         );
#
#         $normalizer->remove_social_query_parameters;
#
#         is( $normalizer->url, $output, 'Removed social query parts.' );
#     }
# }
#
# {
#     # Check for default social query parameters.
#     my $normalizer = URL::Normalize->new( 'http://www.example.com/' );
#     is_deeply( $normalizer->social_query_params, [ 'ncid', 'utm_campaign', 'utm_content', 'utm_medium', 'utm_source', 'utm_term' ] );
#
#     # Try to add another.
#     $normalizer->add_social_query_param( 'foobar' );
#     is_deeply( $normalizer->social_query_params, [ 'ncid', 'utm_campaign', 'utm_content', 'utm_medium', 'utm_source', 'utm_term', 'foobar' ] );
# }

done_testing;
