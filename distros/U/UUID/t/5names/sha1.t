use strict;
use warnings;
use Test::More;
use MyNote;

BEGIN {
    my $has_sha1 = eval 'require Digest::SHA1';
    unless ($has_sha1) {
        plan skip_all => 'no Digest::SHA1';
    }
}

use UUID qw(parse uuid5);

ok 1, 'loaded';

my $NAME = 'www.example.com';

# Namespace_DNS
parse('6ba7b810-9dad-11d1-80b4-00c04fd430c8', my $uu_dns);
# $uu_dns now in big-endian format.

# Digest
my $ctx = Digest::SHA1->new;
$ctx->add($uu_dns);
$ctx->add($NAME);
my $digest = $ctx->hexdigest;

# trim and hyphenate
substr($digest, 32) = '';
substr $digest, 20, 0, '-';
substr $digest, 16, 0, '-';
substr $digest, 12, 0, '-';
substr $digest,  8, 0, '-';

# version
substr $digest, 14, 1, '5';

# variant
my $dval = hex(substr($digest, 19, 1)) & 3 | 8;
substr $digest, 19, 1, sprintf("%x", $dval);

# compare
my $uu5 = uuid5(dns => $NAME);
note " Digest::SHA1 => $digest";
note " UUID::uuid5  => $uu5";
is $uu5, $digest, 'uuids match';

done_testing;
