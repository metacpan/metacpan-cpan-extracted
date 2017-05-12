#perl -T

use strict;
use warnings;

use Test::More tests => 9 + 1;
use Test::NoWarnings;
use Test::Exception;

BEGIN {
    use_ok('Tie::Sub');
}

# tie only
my $object = tie my %sub, 'Tie::Sub';
isa_ok(
    $object,
    'Tie::Sub',
);

# not configured
throws_ok(
    sub {
        () = $sub{undef};
    },
    qr{\b \QCall of method "config" is necessary\E \b}xms,
    'initiating dying if sub is missing',
);

# false configuration
throws_ok(
    sub {
        $object->config(undef);
    },
    qr{\Q'undef'\E}xms,
    'initiating dying by configure wrong reference',
);
throws_ok(
    sub {
        $object->config([]);
    },
    qr{\Q'arrayref'\E}xms,
    'initiating dying by configure wrong reference',
);

# read back no configuration
ok(
    ! defined $object->config,
    'read back no configuration',
);
my $sub1 = sub {};
ok(
    ! defined $object->config($sub1),
    'read back no configuration after config a new',
);

# read back true configuration
my $sub2 = sub { return shift };
cmp_ok(
    $object->config($sub2),
    'eq',
    $sub1,
    'configurate a new subroutine and get back the previous subroutine',
);

# test not implemented method
throws_ok(
    sub {
        $sub{1} = 2;
    },
    qr{\b STORE \b}xms,
    'initiating dying by storing into tied hash',
);
