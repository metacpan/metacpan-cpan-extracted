use strict;
use warnings;
use Test::More;
use MyNote;

BEGIN {
    my $has_md5 = eval 'require Digest::MD5';
    unless ($has_md5) {
        plan skip_all => 'no Digest::MD5';
    }
}

use UUID qw(parse uuid3);

ok 1, 'loaded';

my $NAME = 'www.example.com';

# Namespace_DNS
parse('6ba7b810-9dad-11d1-80b4-00c04fd430c8', my $uu_dns);
# $uu_dns now in big-endian format.

# Digest
my $ctx = Digest::MD5->new;
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
substr $digest, 14, 1, '3';

# variant
my $dval = hex(substr($digest, 19, 1)) & 3 | 8;
substr $digest, 19, 1, sprintf("%x", $dval);

# compare
my $uu3 = uuid3(dns => $NAME);
note "Digest::MD5 => $digest";
note "UUID::uuid3 => $uu3";
is $uu3, $digest, 'uuids match';

done_testing;
