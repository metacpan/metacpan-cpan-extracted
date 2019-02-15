# AxkTest.pm: Test::Kit for XML::Axk
# Copyright (c) 2018 cxw42.  All rights reserved.  Artistic 2.
package AxkTest;

use Test::Kit;
use 5.020;
use strict;
use warnings;

include feature => {
    import => [':5.18']
};
include qw(strict warnings);
include qw(Test::More File::Spec XML::Axk::App XML::Axk::Core);
include qw(AxkTest::Helpers);
include 'Capture::Tiny' => {
    import => [qw(capture_stdout capture_merged)]
};

1;

# vi: set ts=4 sts=4 sw=4 et ai fdm=marker fdl=1: #
