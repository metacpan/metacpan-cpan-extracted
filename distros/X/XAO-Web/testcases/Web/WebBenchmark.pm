package testcases::Web::WebBenchmark;
use strict;
use JSON;
use XAO::Utils;
use XAO::Objects;
use XAO::Projects;

use base qw(XAO::testcases::Web::base);

###############################################################################

sub test_all {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    my $benchmark=XAO::Objects->new(objname => 'Web::Benchmark');
    my $benchmark2=XAO::Objects->new(objname => 'Web::Benchmark');

    $benchmark->expand('mode' => 'system-start');

    $self->assert($page->benchmark_enabled(),
        "Benchmarking is not enabled after 'benchmark-start'");

    $benchmark->expand('mode' => 'system-stop');

    $self->assert(! $page->benchmark_enabled(),
        "Benchmarking is not disabled after 'benchmark-stop'");

    $benchmark->expand('mode' => 'system-start');

    $self->assert($page->benchmark_enabled(),
        "Benchmarking is not enabled after 'benchmark-start' (2)");

    $page->expand(template => 'blah');

    $benchmark->expand('mode' => 'enter', tag => 'test');

    for(1..10) {
        $page->expand(path => '/bits/system-test', 'xao.cacheable' => 1, TEST => 'foo', RUN => ($_ <= 5 ? $_ : 'X'));
        $page->expand(path => '/bits/complex-template', RUN => ($_ <= 5 ? $_ : 'X'));
        $page->expand(path => '/bits/test-recurring', RUN => ($_ <= 5 ? $_ : 'X'));
        $page->clipboard->put('test_clipboard' => $_ * 10);
        $page->expand(path => '/bits/test-non-cacheable', FOO => ($_ <= 5 ? 'A' : 'B'));
    }

    for(1..20) {
        $page->expand(path => '/bits/complex-template');
    }

    $benchmark2->expand('mode' => 'leave', tag => 'test');

    my $stats=$page->benchmark_stats();

    ### dprint "STATS: ".to_json($stats,{pretty => 1, utf8 => 1, canonical => 1});

    $self->assert(ref $stats eq 'HASH',
        "Expected to get a HASH from benchmark_stats()");

    my $stats2=XAO::Objects->new(objname => 'Web::Action')->benchmark_stats();

    $self->assert(ref $stats2 eq 'HASH',
        "Expected to get a HASH from benchmark_stats()");

    my $json1=to_json($stats,{ canonical => 1 });
    my $json2=to_json($stats2,{ canonical => 1 });

    $self->assert($json1 eq $json2,
        "Expected to get identical stats from two web objects ($json1 != $json2)");

    my %counts=(
        'test'                      => [ 1,  1,  1, 0 ],
        'p:/bits/system-test'       => [ 10, 6,  1, 1 ],
        'p:/bits/complex-template'  => [ 30, 7,  1, 0 ],
        'p:/bits/test-recurring'    => [ 20, 7,  1, 0 ],
        'p:/bits/test-non-cacheable'=> [ 10, 2,  0, 0 ],
    );

    foreach my $tag (keys %counts) {
        my $tag_stats=$page->benchmark_stats($tag);

        $json1=to_json({ $tag => $stats->{$tag}},{ canonical => 1 });
        $json2=to_json($tag_stats,{ canonical => 1 });

        $self->assert($json1 eq $json2,
            "Expected tag-specific stats ($json2) be the same as global value ($json1)");

        my $tagdata=$stats->{$tag};

        my $count=$tagdata->{'count'} || 0;
        $self->assert($count == $counts{$tag}->[0],
            "Expected '$tag' count to be $counts{$tag}->[0], got $count");

        $self->assert($tagdata->{'average'} > 0,
            "Expected 'average' for '$tag' to be positive");

        $self->assert($tagdata->{'median'} > 0,
            "Expected 'median' for '$tag' to be positive");

        $self->assert(ref $tagdata->{'last'} eq 'ARRAY',
            "Expected 'last' for '$tag' to be an array");

        $self->assert(scalar(@{$tagdata->{'last'}}) > 0,
            "Expected 'last' for '$tag' to have elements");

        my $cacheable=$tagdata->{'cacheable'} ? 1 : 0;
        $self->assert($cacheable == $counts{$tag}->[2],
            "Expected 'cacheable' for '$tag' to be $counts{$tag}->[2], got $cacheable");

        my $cache_flag=$tagdata->{'cache_flag'} ? 1 : 0;
        $self->assert($cache_flag == $counts{$tag}->[3],
            "Expected 'cache_flag' for '$tag' to be $counts{$tag}->[3], got $cache_flag");

        my $rundata=$tagdata->{'runs'};
        $self->assert(ref $rundata,
            "Expected to have 'runs' ref on '$tag'");
            
        $self->assert(scalar(keys %$rundata) == $counts{$tag}->[1],
            "Expected to have $counts{$tag}->[1] unique runs on '$tag', got ".scalar(keys %$rundata));

        ### dprint to_json($rundata,{pretty => 1});

        foreach my $run_key (keys %$rundata) {
            $self->assert(ref $rundata->{$run_key}->{'content'},
                "Expected to have 'content' data for run $run_key of '$tag'");
        }
    }

    $self->assert($stats->{'p:/bits/complex-template'}->{'total'} > $stats->{'p:/bits/system-test'}->{'total'},
        "Expected 'p:/bits/complex-template' to take longer than 'p:/bits/system-test'");

    $self->assert($stats->{'test'}->{'total'} > $stats->{'p:/bits/system-test'}->{'total'},
        "Expected 'test' to take longer than 'p:/bits/system-test'");

    my $text=$benchmark2->expand(
        'mode'              => 'stats',
        'header.template'   => '<$TOTAL_ITEMS$>|',
        'template'          => '(<$TAG$>:<$COUNT$>:<$CACHEABLE$>:<$CACHE_FLAG$>)',
        'footer.template'   => '|<$TOTAL_ITEMS$>',
    );

    ### dprint $text;

    my $expect='5|(test:1:1:0)(p:/bits/complex-template:30:1:0)(p:/bits/test-recurring:20:1:0)(p:/bits/test-non-cacheable:10:0:0)(p:/bits/system-test:10:1:1)|5';
    $self->assert($text eq $expect,
        "Expected to render into '$expect', got '$text'");

    $text=$benchmark2->expand(
        'mode'              => 'stats',
        'limit'             => 3,
        'orderby'           => 'tag',
        'header.template'   => '<$TOTAL_ITEMS$>|',
        'template'          => '(<$TAG$>:<$COUNT$>:<$CACHEABLE$>:<$CACHE_FLAG$>)',
        'footer.template'   => '|<$TOTAL_ITEMS$>',
    );

    ### dprint $text;

    $expect='3|(p:/bits/complex-template:30:1:0)(p:/bits/system-test:10:1:1)(p:/bits/test-non-cacheable:10:0:0)|3';
    $self->assert($text eq $expect,
        "Expected to render into '$expect', got '$text'");

    $text=$benchmark2->expand(
        'mode'              => 'stats',
        'limit'             => 2,
        'orderby'           => 'count',
        'header.template'   => '<$TOTAL_ITEMS$>|',
        'template'          => '(<$TAG$>:<$COUNT$>:<$CACHEABLE$>:<$CACHE_FLAG$>)',
        'footer.template'   => '|<$TOTAL_ITEMS$>',
    );

    ### dprint $text;

    $expect='2|(p:/bits/complex-template:30:1:0)(p:/bits/test-recurring:20:1:0)|2';
    $self->assert($text eq $expect,
        "Expected to render into '$expect', got '$text'");

    $text=$benchmark2->expand(
        'mode'              => 'stats',
        'tag'               => 'test',
        'path'              => '/bits/bench-row',
        'footer.template'   => '|<$TOTAL_ITEMS$>',
    );

    ### dprint $text;

    $expect='(test:1:1:0)|1';
    $self->assert($text eq $expect,
        "Expected to render into '$expect', got '$text'");

    $text=$benchmark2->expand(
        'mode'              => 'stats',
        'dprint'            => 1,
    );

    ### dprint $text;

    $expect='';
    $self->assert($text eq $expect,
        "Expected to render into '$expect', got '$text'");

    # This resulted in a memory overflow until only scalar
    # parameters started to be digested for cache keys.
    #
    $text=$benchmark->expand('mode' => 'stats', 'path' => '/bits/bench-row');
    $text=$benchmark->expand('mode' => 'stats', 'path' => '/bits/bench-row');
    $text=$benchmark->expand('mode' => 'stats', 'path' => '/bits/bench-row');
}

###############################################################################
1;
