# AxkTest::Helpers: Helper functions to be injected by AxkTest into
# test modules.
# Copyright (c) 2018 cxw42.  All rights reserved.  Artistic 2.

package AxkTest::Helpers;

use 5.020;
use parent 'Exporter';

our @EXPORT = qw(tpath);

# tpath(filename) returns the path to `filename`, assuming `filename` is in
# the `t` directory.
sub tpath {

    # Where is the `t` directory?
    state @voldir;
    unless(@voldir) {
        my ($vol, $dirs, $file) = File::Spec->splitpath(__FILE__);
        my @dirs = File::Spec->splitdir($dirs);
        pop @dirs while $dirs[$#dirs] ne 't';	# get back up to t/
        @voldir = ($vol, File::Spec->catdir(@dirs));
    }

    # Paste it on to the provided filename
    return File::Spec->catpath(@voldir, shift)
} #tpath()

1;
