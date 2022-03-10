#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

BEGIN {
    skip_all("Skip for now < 5.28") unless $^V ge 5.28.0;
}

use Test::MockFile plugin => "FileTemp";

use File::Temp qw< tempfile >;

my $dir = File::Temp::tempdir();
open my $fh, ">", "$dir/thefile";
ok chmod 0777, $fh;
done_testing();

exit;
