#!/usr/bin/env perl

package t::Wasm::Wasmer::Global;

use strict;
use warnings;

use Test2::V0 -no_utf8 => 1;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use parent 'TestBase';

use Encode;

use Wasm::Wasmer::Memory;

__PACKAGE__->new()->runtests() if !caller;

sub test_constants : Tests(1) {
    can_ok(
        'Wasm::Wasmer::Memory',
        'PAGE_SIZE',
    );

    return;
}

1;
