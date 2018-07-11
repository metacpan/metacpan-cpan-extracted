#!/usr/bin/env perl
use warnings;
use strict;
use blib;
use XAO::Web;
use XAO::Utils;
use Benchmark qw(timethese cmpthese);
use Data::Dumper;

XAO::Utils::set_debug(1);

chomp(my $root=`pwd`);
$root.='/testcases/testroot';
dprint "Using $root as the project root";
XAO::Base::set_root($root);

XAO::Web->new(sitename => 'test1');

my $page1=XAO::Objects->new(objname => 'Web::Page', sitename => 'test1');

my $page2=XAO::Objects->new(objname => 'Web::Page', sitename => 'test1');

XAO::Web->new(sitename => 'test3');
my $page3=XAO::Objects->new(objname => 'Web::Page', sitename => 'test3');

$page3->siteconfig->put('/page/parse_cache' => 'web-page-parsed');
$page3->siteconfig->get('/page/parse_cache') ||
    die "Unable to set site configuration";

$page3->siteconfig->put('/cache/config/common/backend' => 'Cache::Memory');
$page3->siteconfig->get('/cache/config/common/backend') ||
    die "Unable to set site configuration";

XAO::Web->new(sitename => 'test4');
my $page4=XAO::Objects->new(objname => 'Web::Page', sitename => 'test4');

$page4->siteconfig->put('/xao/page/parse_cache' => 'web-page-parsed');
$page4->siteconfig->get('/xao/page/parse_cache') ||
    die "Unable to set site configuration";

$page4->siteconfig->put('/cache/config/common/backend' => 'Cache::Memcached');
$page4->siteconfig->get('/cache/config/common/backend') ||
    die "Unable to set site configuration";
$page4->siteconfig->put('/cache/memcached/servers' => [ '127.0.0.1:11211' ]);
$page4->siteconfig->get('/cache/memcached/servers') ||
    die "Unable to set site configuration";

### foreach my $page ($page1,$page2,$page3,$page4) {
###     $page->debug_set('show-read' => 1);
###     $page->debug_set('show-parse' => 1);
###     $page->debug_set('page-cache-size' => 1);
###     dprint "page $page sitename $page->{'sitename'} ",$page->siteconfig->get('/cache/config/common/backend');
### }

### if(1) {
###     $page4->parse(path => '/bits/complex-template');
###     $page4->parse(path => '/bits/complex-template');
###     $page4->parse(path => '/bits/complex-template');
###     exit 0;
### }

my $logcount=0;
XAO::Utils::set_logprint_handler(sub {
    ++$logcount;
    ### print STDERR "$logcount: ".$_[0]."\n";
});

### my $parsed=$page1->parse(path => '/bits/complex-template');
### dprint Dumper($parsed);

my $template=$page1->expand(path => '/bits/complex-template', unparsed => 1);

print "\n====== Timing:\n";
my $bm=timethese($ARGV[0] || -8, {
    'local-cache-path' => sub {
        $page1->parse(
            path        => '/bits/complex-template',
        );
    },

    'local-cache-template'  => sub {
        $page1->parse(
            template    => $template,
        );
    },

    'no-cache-path' => sub {
        $page2->parse(
            path        => '/bits/complex-template',
            uncached    => 1,
        );
    },

    'no-cache-template' => sub {
        $page2->parse(
            template    => $template,
            uncached    => 1,
        );
    },

    'memory-cache-path' => sub {
        $page3->parse(
            path        => '/bits/complex-template',
        );
    },

    'memory-cache-template' => sub {
        $page3->parse(
            template    => $template,
        );
    },

    'memcached-cache-path' => sub {
        $page4->parse(
            path        => '/bits/complex-template',
        );
    },

    'memcached-cache-template' => sub {
        $page4->parse(
            template    => $template,
        );
    },
});

print "\n====== Comparison:\n";
cmpthese($bm);

XAO::Utils::set_logprint_handler(undef);

print "\n====== Cache Size:\n";
$page1->cache_show_size();

exit 0;
