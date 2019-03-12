#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use Test::More tests => 4;

use lib (File::Spec->catdir($Bin, 'lib'));

subtest Good => sub {
    # pre-exception sanity-check
    eval 'use Good';
    is $@, '', 'use: Good using true';
    is Good::Good(), 'Good', 'use: Good loaded OK';
};

subtest DirectCompileTimeException => sub {
    local $TODO = "don't clean after itself yet";
    eval 'use DirectCompileTimeException';
    # make sure the entry was cleared from %true::TRUE
    like $@, qr{\bDirectCompileTimeException\b}, 'direct: module throws a compile-time exception';
    is_deeply \%true::TRUE, {}, 'direct: true cleans up correctly';
};

subtest IndirectCompileTimeException => sub {
    local $TODO = "don't clean after itself yet";
    eval 'use IndirectCompileTimeException';
    # make sure the entry was cleared from %true::TRUE
    like $@, qr{\bIndirectCompileTimeException\b}, 'indirect: module throws a compile-time exception';
    is_deeply \%true::TRUE, {}, 'direct: true cleans up correctly';
};

# post-exception sanity-check
subtest Ugly => sub {
    eval 'use Ugly';
    is $@, '', 'use: Ugly using true';
    is Ugly::Ugly(), 'Ugly', 'use: Ugly loaded OK';
};
