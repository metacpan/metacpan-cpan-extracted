use strict;
use warnings;
use utf8;
use Test::Base::Less;
use Digest::MD5 qw/md5_hex/;

filters {
    input => [\&md5_hex],
};

is([blocks]->[0]->input, 'f561aaf6ef0bf14d4208bb46a4ccb3ad');

done_testing;

__DATA__

===
--- input: xxx
