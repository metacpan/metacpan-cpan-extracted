#!/usr/bin/perl -w

use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
  if $@;
plan( tests => 4 );
pod_coverage_ok( 'Wx::Perl::EntryList',
                 { coverage_class => 'Pod::Coverage::CountParents' } );
pod_coverage_ok( 'Wx::Perl::EntryList::Iterator',
                 { coverage_class => 'Pod::Coverage::CountParents' } );
pod_coverage_ok( 'Wx::Perl::EntryList::FwBwIterator',
                 { coverage_class => 'Pod::Coverage::CountParents' } );
pod_coverage_ok( 'Wx::Perl::EntryList::VirtualListCtrlView',
                 { coverage_class => 'Pod::Coverage::CountParents' } );
# pod_coverage_ok( 'Wx::Perl::EntryList::ListBoxView',
#                  { coverage_class => 'Pod::Coverage::CountParents' } );
