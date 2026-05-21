use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Warnings         qw( :all :no_end_test );
use WWW::Mechanize::Cached ();

use lib 't';
use TestCache;

my $cache = TestCache->new();
isa_ok( $cache, 'TestCache' );

my $was_warning = $^W;
$^W = 1;

my $mech = WWW::Mechanize::Cached->new(
    cache => $cache,
);
had_no_warnings("No warnings for accepted 'cache' parameter");

for my $boolean_attribute (
    qw(
    is_cached
    positive_cache
    ref_in_cach_key
    _verbose_dwarn
    cache_undef_content_length
    cache_zero_content_length
    cache_mismatch_content_length
    )
) {
    $mech = WWW::Mechanize::Cached->new(
        $boolean_attribute => 1,
    );
    had_no_warnings(
        "No warnings for accepted '$boolean_attribute' parameter");
}

like(
    warning {
        $mech = WWW::Mechanize::Cached->new(
            not_my_argument => 1,
        );
    },
    qr/not_my_argument/,
    'Unrecognized arguments passed through to WWW::Mechanize'
);

# Put this back
$^W = $was_warning;

done_testing();
