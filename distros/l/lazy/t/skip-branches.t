use strict;
use warnings;

use lazy;

use Capture::Tiny qw( capture );
use Test::More import => [qw( done_testing is_deeply like subtest )];

my ($cb) = grep { ref $_ eq 'CODE' } @INC;

# Per perlfunc, an @INC code ref returning a non-reference truthy scalar is
# interpreted as a filename to load. Skip branches must return empty so
# require continues iterating @INC.

subtest 'auto/*.al skip returns empty' => sub {
    my ( $stdout, $stderr, @result ) = capture {
        $cb->( undef, 'auto/Foo/Bar/baz.al' );
    };
    like(
        $stderr, qr{skipping autoloader file auto::Foo::Bar::baz\.al},
        'warns about skipping autoloader'
    );
    is_deeply( \@result, [], 'returns empty list, not 1' );
};

subtest 'Net::DNS::Resolver::* skip returns empty' => sub {
    my ( $stdout, $stderr, @result ) = capture {
        $cb->( undef, 'Net/DNS/Resolver/UnixSock.pm' );
    };
    like(
        $stderr, qr{skipping Net::DNS::Resolver::UnixSock},
        'warns about skipping Net::DNS::Resolver subclass'
    );
    is_deeply( \@result, [], 'returns empty list, not 1' );
};

subtest 'Encode::ConfigLocal skip returns empty' => sub {
    my ( $stdout, $stderr, @result ) = capture {
        $cb->( undef, 'Encode/ConfigLocal.pm' );
    };
    like(
        $stderr, qr{skipping Encode::ConfigLocal},
        'warns about skipping Encode::ConfigLocal'
    );
    is_deeply( \@result, [], 'returns empty list, not 1' );
};

done_testing();
