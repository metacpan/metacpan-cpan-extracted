#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;

use Test::Run::Obj;
use Test::Run::Plugin::TrimDisplayedFilenames;

use Test::Run::Trap::Obj;

package MyTestRun;

use vars qw(@ISA);

@ISA = (qw(Test::Run::Plugin::TrimDisplayedFilenames Test::Run::Obj));

package main;

use Test::More tests => 8;

{
    # TEST:$num_queries=4

    foreach my $query
    (
        'fromre:long',
        'fromre:\Areally-really-really-long-dir-name\z',
        'fromre:re.l+y',
        'keep:1',
    )
    {
        my $got = Test::Run::Trap::Obj->trap_run(
            {
                class => "MyTestRun",
                args =>
                [
                    test_files =>
                    [
                        "t/sample-tests/really-really-really-long-dir-name/one-ok.t",
                        "t/sample-tests/really-really-really-long-dir-name/several-oks.t"
                    ],
                    trim_displayed_filenames_query => $query,
                ]
            }
        );

        # TEST*$num_queries
        $got->field_like("stdout", qr/^one-ok \.{2,8} ok/ms,
            "one-ok.t appears alone without the long path."
        );

        # TEST*$num_queries
        $got->field_like("stdout", qr/^several-oks \.{2,8} ok/ms,
            "several-oks.t appears alone without the long path."
        );
    }
}

