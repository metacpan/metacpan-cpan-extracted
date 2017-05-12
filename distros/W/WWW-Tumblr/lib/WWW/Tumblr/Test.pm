package WWW::Tumblr::Test;

use strict;
use warnings;

use WWW::Tumblr;

my $t = WWW::Tumblr->new(
    # These are "public" keys for my small perlapi blog test.
    # Don't be a jerk :)
    consumer_key        => 'm2TqZPKBN87VXTf0HZCDbLBmV8IKhjDnSh5SL2MrWYPrvDKIKE',
    secret_key          => 'DfNf21jsNPkDfz5rRW4tUPQf0gR1G8mYtxqBDM62XQSGHNJRY9',
    token               => '5koNK32cgylbsxs9LsTDCWFUrPccYjFCqFIbZayCFLrVlm1zuP',
    token_secret        => 'VbFLz3lZ3P2ghw5b4dHwNNw4IAq13uHgDp4reZy4N24b4VlfM8',
);

sub tumblr { $t }
sub user   { $t->user }
sub blog   { $t->blog('perlapi.tumblr.com') }

1;
