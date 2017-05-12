#!/usr/bin/perl -w

use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
  if $@;
plan( tests => 3 );
pod_coverage_ok( 'Wx::Perl::TreeView',
                 { trustme        => [ qr/^(?:treectrl|model|[SG]etPlData)$/ ],
                   coverage_class => 'Pod::Coverage::CountParents' } );
pod_coverage_ok( 'Wx::Perl::TreeView::Model',
                 { coverage_class => 'Pod::Coverage::CountParents' } );
pod_coverage_ok( 'Wx::Perl::TreeView::SimpleModel',
                 { coverage_class => 'Pod::Coverage::CountParents' } );
