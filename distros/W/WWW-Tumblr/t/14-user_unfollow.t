use strict;
use warnings;

use Test::More;

# Must load these first to check skip conditions
use WWW::Tumblr;
use WWW::Tumblr::Test;

# Check if we should skip posting tests entirely
if (my $reason = WWW::Tumblr::Test::skip_posting_tests()) {
    plan skip_all => $reason;
}

my $user = WWW::Tumblr::Test::user();

my $unfollow = $user->unfollow( url => 'staff.tumblr.com' );

if ($unfollow) {
    pass('user unfollow is fine');
} else {
    if ($user->error && WWW::Tumblr::Test::check_rate_limit($user->error)) {
        SKIP: { skip "Rate limit exceeded", 1; }
    } else {
        fail('user unfollow is fine');
        diag("Error: " . join(', ', @{$user->error->reasons || ['Unknown']}));
    }
}

done_testing();
