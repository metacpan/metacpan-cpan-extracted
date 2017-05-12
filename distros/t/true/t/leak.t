#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use Test::More tests => 6;

use lib (File::Spec->catdir($Bin, 'lib'));

# pre-leak sanity-check
eval 'use Good';
is $@, '', 'use: Good using true';
is Good::Good(), 'Good', 'use: Good loaded OK';

eval 'use DirectTrueLoadUntrue';
like $@, qr{Untrue1.pm did not return a true value\b},
    "leak (direct): true doesn't leak into a module that doesn't use it";

eval 'use IndirectTrueLoadUntrue';
like $@, qr{Untrue2.pm did not return a true value\b},
    "leak (indirect): true doesn't leak into a module that doesn't use it";

# post-leak sanity-check
eval 'use Ugly';
is $@, '', 'use: Ugly using true';
is Ugly::Ugly(), 'Ugly', 'use: Ugly loaded OK';
