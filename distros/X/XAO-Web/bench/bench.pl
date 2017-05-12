#!/usr/bin/perl -w
use strict;
use blib;
use XAO::Web;
use XAO::Utils;
use Benchmark;

XAO::Utils::set_debug(1);

my $site=XAO::Web->new(sitename => 'benchmark');
$site->set_current;

my $page=XAO::Objects->new(objname => 'Web::Page');

timethese($ARGV[0] || 2000, {
    var => sub {
        $page->expand(
            template    => '<%VAR/h%>',
            VAR         => '123123123123123123123123123'
        );
    },
    sim => sub {
        $page->expand(
            template    => '<%VAR%>',
            VAR         => 'a'
        );
    },
    var2 => sub {
        $page->expand(
            template    => '<%VAR1/h%>-<%VAR2/f%>',
            VAR1        => '123123123123123123123123123',
            VAR2        => '!@#$%^&*()_=',
        );
    },
    var3 => sub {
        $page->expand(
            template    => '<%VAR1/h%>-<%VAR2/f%>-<%VAR3/q%>',
            VAR1        => '!@#$%^&*()_=',
            VAR2        => '!@#$%^&*()_=',
            VAR3        => '!@#$%^&*()_=',
        );
    },
    var4 => sub {
        $page->expand(
            template    => '<%VAR1/h%>-<%VAR2/f%>-<%VAR3/q%>-<%VAR4/s%>',
            VAR1        => '!@#$%^&*()_=',
            VAR2        => '!@#$%^&*()_=',
            VAR3        => '!@#$%^&*()_=',
            VAR4        => '!@#$%^&*()_=',
        );
    },
    sim4 => sub {
        $page->expand(
            template    => '<%VAR1%>-<%VAR2%>-<%VAR3%>-<%VAR4%>',
            VAR1        => 'a',
            VAR2        => 'a',
            VAR3        => 'a',
            VAR4        => 'a',
        );
    },
    date => sub {
        $page->expand(template => '<%Date%>');
    },
    path => sub {
        $page->expand(
            path        => '/temp',
            VAR1        => '!@#$%^&*()_=',
            VAR2        => '!@#$%^&*()_=',
            VAR3        => '!@#$%^&*()_=',
            VAR4        => '!@#$%^&*()_=',
        );
    },
    pdate => sub {
        $page->expand(
            path        => '/temp-date',
            VAR1        => '!@#$%^&*()_=',
            VAR2        => '!@#$%^&*()_=',
            VAR3        => '!@#$%^&*()_=',
            VAR4        => '!@#$%^&*()_=',
        );
    },
    pdd => sub {
        $page->expand(
            path        => '/temp-dd',
            D1          => 1234567,
            D2          => 2345678,
            D3          => 3456789,
        );
    },
});

exit 0;
