#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use Test::More tests => 8;

use lib (File::Spec->catdir($Bin, 'lib'));

# pre-unimport sanity-check
eval 'use Good';
is $@, '', 'use: Good using true';
is Good::Good(), 'Good', 'use: Good loaded OK';

eval 'use DirectTopLevelUnimport';
like $@, qr{DirectTopLevelUnimport.pm did not return a true value\b}, 'use: direct top-level unimport works';

eval 'use DirectNestedUnimport';
like $@, qr{DirectNestedUnimport.pm did not return a true value\b}, 'use: direct nested unimport works';

eval 'use IndirectTopLevelUnimport';
like $@, qr{IndirectTopLevelUnimport.pm did not return a true value\b}, 'use: indirect top-level unimport works';

eval 'use IndirectNestedUnimport';
like $@, qr{IndirectNestedUnimport.pm did not return a true value\b}, 'use: indirect nested unimport works';

# post-unimport sanity-check
eval 'use Ugly';
is $@, '', 'use: Ugly using true';
is Ugly::Ugly(), 'Ugly', 'use: Ugly loaded OK';
