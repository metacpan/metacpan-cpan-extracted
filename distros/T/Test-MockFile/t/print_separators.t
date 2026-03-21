#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockFile qw<nostrict>;

note "--- output field separator (\$,) ---";

{
    my $mock = Test::MockFile->file("/fake/ofs_test");
    open( my $fh, '>', "/fake/ofs_test" ) or die;

    {
        local $, = ",";
        print $fh "a", "b", "c";
    }

    close $fh;
    is( $mock->contents, "a,b,c", 'print with $, = "," joins args with comma' );
}

{
    my $mock = Test::MockFile->file("/fake/ofs_tab");
    open( my $fh, '>', "/fake/ofs_tab" ) or die;

    {
        local $, = "\t";
        print $fh "col1", "col2", "col3";
    }

    close $fh;
    is( $mock->contents, "col1\tcol2\tcol3", 'print with $, = "\t" joins args with tab' );
}

{
    my $mock = Test::MockFile->file("/fake/ofs_none");
    open( my $fh, '>', "/fake/ofs_none" ) or die;

    # $, is undef by default
    print $fh "a", "b", "c";

    close $fh;
    is( $mock->contents, "abc", 'print without $, concatenates directly' );
}

{
    my $mock = Test::MockFile->file("/fake/ofs_single");
    open( my $fh, '>', "/fake/ofs_single" ) or die;

    {
        local $, = ",";
        print $fh "only";
    }

    close $fh;
    is( $mock->contents, "only", 'print with $, and single arg has no separator' );
}

{
    my $mock = Test::MockFile->file("/fake/ofs_multichar");
    open( my $fh, '>', "/fake/ofs_multichar" ) or die;

    {
        local $, = " | ";
        print $fh "x", "y";
    }

    close $fh;
    is( $mock->contents, "x | y", 'print with multi-char $, works' );
}

note "--- verify printf is unaffected by \$, ---";

{
    my $mock = Test::MockFile->file("/fake/printf_ofs");
    open( my $fh, '>', "/fake/printf_ofs" ) or die;

    {
        local $, = ",";
        printf $fh "%s=%d", "answer", 42;
    }

    close $fh;
    is( $mock->contents, "answer=42", 'printf ignores $, (format handles args)' );
}

done_testing();
