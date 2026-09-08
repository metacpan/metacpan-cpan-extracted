use strict;
use warnings;

use lazy;

use Test::More import => [qw( done_testing is_deeply subtest )];

my ($cb) = grep { ref $_ eq 'CODE' } @INC;

# Per perlfunc, an @INC code ref returning a non-reference truthy scalar is
# interpreted as a filename to load. Skip branches must return empty so
# require continues iterating @INC. They intentionally emit no warning: these
# probes fire constantly during normal @INC searching.

subtest 'auto/*.al skip returns empty' => sub {
    my @result = $cb->( undef, 'auto/Foo/Bar/baz.al' );
    is_deeply( \@result, [], 'returns empty list, not 1' );
};

subtest 'Net::DNS::Resolver::* skip returns empty' => sub {
    my @result = $cb->( undef, 'Net/DNS/Resolver/UnixSock.pm' );
    is_deeply( \@result, [], 'returns empty list, not 1' );
};

subtest 'Encode::ConfigLocal skip returns empty' => sub {
    my @result = $cb->( undef, 'Encode/ConfigLocal.pm' );
    is_deeply( \@result, [], 'returns empty list, not 1' );
};

done_testing();
