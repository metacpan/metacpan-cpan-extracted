package WWW::Tumblr::Test;

use strict;
use warnings;

use WWW::Tumblr;
use Test::More;

my $t = WWW::Tumblr->new(
    # These are "public" keys for my small perlapi blog test.
    # Don't be a jerk :)
    consumer_key        => 'm2TqZPKBN87VXTf0HZCDbLBmV8IKhjDnSh5SL2MrWYPrvDKIKE',
    secret_key          => 'DfNf21jsNPkDfz5rRW4tUPQf0gR1G8mYtxqBDM62XQSGHNJRY9',
    token               => '5koNK32cgylbsxs9LsTDCWFUrPccYjFCqFIbZayCFLrVlm1zuP',
    token_secret        => 'VbFLz3lZ3P2ghw5b4dHwNNw4IAq13uHgDp4reZy4N24b4VlfM8',
);

# Track if we've hit the rate limit during this test run
my $rate_limited = 0;

sub tumblr { $t }
sub user   { $t->user }
sub blog   { $t->blog('perlapi.tumblr.com') }

# Check if live tests should be skipped (env var or already rate limited)
sub skip_live_tests {
    return 'TUMBLR_SKIP_LIVE_TESTS environment variable is set'
        if $ENV{TUMBLR_SKIP_LIVE_TESTS};
    return 'Rate limit was hit earlier in this test run'
        if $rate_limited;
    return;
}

# Check if we should skip posting tests specifically
sub skip_posting_tests {
    my $reason = skip_live_tests();
    return $reason if $reason;
    return 'TUMBLR_SKIP_POSTING_TESTS environment variable is set'
        if $ENV{TUMBLR_SKIP_POSTING_TESTS};
    return;
}

# Check an error object for rate limiting; sets flag and returns true if rate limited
sub check_rate_limit {
    my $error = shift;
    return 0 unless $error && $error->can('is_rate_limited');
    
    if ($error->is_rate_limited) {
        $rate_limited = 1;
        diag("NOTE: Tumblr rate limit hit - skipping remaining posting tests");
        diag("This is harmless and does not indicate a bug in WWW::Tumblr");
        return 1;
    }
    return 0;
}

# Returns true if rate limited flag is set
sub is_rate_limited { $rate_limited }

# Helper to run a test that might hit rate limits
# Usage: rate_limit_ok { $blog->post(...) } "post succeeded";
sub rate_limit_ok (&$) {
    my ($code, $name) = @_;
    
    if (my $skip = skip_posting_tests()) {
        SKIP: {
            skip $skip, 1;
        }
        return 1;
    }
    
    my $result = $code->();
    if ($result) {
        pass($name);
        return 1;
    } else {
        # Check if it's a rate limit error
        my $obj = $t->blog('perlapi.tumblr.com');
        if ($obj->error && check_rate_limit($obj->error)) {
            SKIP: {
                skip "Rate limit exceeded", 1;
            }
            return 1;
        }
        fail($name);
        return 0;
    }
}

1;
