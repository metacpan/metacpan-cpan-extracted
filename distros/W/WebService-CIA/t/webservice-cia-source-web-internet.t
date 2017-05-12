use strict;
use Test::More;
use Module::Build;

if ( $ENV{ TEST_INTERNET } ) {
    plan tests => 8;
} else {
    plan skip_all => 'Skipping internet-based tests - set TEST_INTERNET to run these tests';
}

use WebService::CIA::Source::Web;

my $source = WebService::CIA::Source::Web->new;

ok( $source->get('uk') == 1, 'get() - returns 1' );

ok( $source->cached eq 'uk', 'cached() - cached country set correctly after get()' );

ok( scalar keys %{$source->cache} > 0 &&
    exists $source->cache->{'Background'} &&
    $source->cache->{'Background'}, 'cache() - cache contains values' );

ok( $source->value('uk','Background'), 'value() - valid args - returns a value' );

ok( ! defined $source->value('uk','Test'), 'value() (cached info) - invalid args - returns undef' );

ok( ! defined $source->value('testcountry', 'Test'), 'value() (non-cached info) - invalid args - returns undef' );

ok( scalar keys %{$source->all('uk')} > 0 &&
    exists $source->all('uk')->{'Background'} &&
    $source->all('uk')->{'Background'}, 'all() - valid args - returns hashref' );

ok( scalar keys %{$source->all('testcountry')} == 0, 'all() - invalid args - returns empty hashref' );
