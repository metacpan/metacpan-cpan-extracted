#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::NoWarnings;

BEGIN {
    skip_all("Skip for now < 5.28") unless $^V ge 5.28.0;
}

# Do not load File::Temp to ensure this can be loaded under Test::MockFile
my $has_filetemp_before_load;

BEGIN {
    $has_filetemp_before_load = $INC{'File/Temp.pm'};
}

use Test::MockFile 'strict', plugin => 'FileTemp';

ok !$has_filetemp_before_load, "File::Temp is not loaded before Test::MockFile";
ok $INC{'File/Temp.pm'},       'File::Temp is loaded';

require File::Temp;    # not really needed

{

    my ( $tmp_fh, $tmp ) = File::Temp::tempfile;

    ok lives { open( my $fh, ">", "$tmp" ) }, "we can open a tempfile";

    {
        my $tempdir = File::Temp::tempdir( CLEANUP => 1 );
        ok lives { opendir( my $dh, "$tempdir" ) }, "Can open directory from tempdir";

        ok lives { open( my $fh, ">", "$tempdir/here" ) }, "we can open a tempfile under a tempdir";
    }

    # scalar context

    {
        my $fh = File::Temp::tempfile;
        ok lives { print {$fh} "test" }, "print to a tempfile - scalar context";
    }

}

{
    my $dir = File::Temp->newdir();
    ok opendir( my $dh, "$dir" ),             "opendir - newdir";
    ok open( my $f, '>', "$dir/myfile.txt" ), "open a file created under newdir";
}

done_testing;
