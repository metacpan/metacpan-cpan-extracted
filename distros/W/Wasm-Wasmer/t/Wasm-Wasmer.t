#!/usr/bin/env perl

package t::Wasm::Wasmer;

use strict;
use warnings;

use Test2::V0 -no_utf8 => 1;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use parent 'TestBase';

use Wasm::Wasmer;

__PACKAGE__->new()->runtests() if !caller;

sub test_wat2wasm__invalid : Tests(1) {
    my $err = dies { diag Wasm::Wasmer::wat2wasm('/////') };

    is(
        $err,
        check_set(
            match( qr<WAT> ),
            match( qr<WASM> ),
        ),
        'expected error',
        explain $err,
    );

    return;
}

1;
