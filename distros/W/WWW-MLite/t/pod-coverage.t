#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
#
# Copyright (C) 1998-2014 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: pod-coverage.t 28 2014-07-31 15:30:31Z minus $
#
#########################################################################

use Test::More;
eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;
plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";
plan tests => 10;

#plan skip_all => "Currently FAILS FOR MANY MODULES!";
#all_pod_coverage_ok();

pod_coverage_ok( "WWW::MLite", { trustme => [qr/^(new)$/] } );

# WWW::MLite::*
pod_coverage_ok( "WWW::MLite::Config" );
pod_coverage_ok( "WWW::MLite::Transaction" );
pod_coverage_ok( "WWW::MLite::Util" );
pod_coverage_ok( "WWW::MLite::Log" );
pod_coverage_ok( "WWW::MLite::AuthSsn" );

# WWW::MLite::Store::*
pod_coverage_ok( "WWW::MLite::Store::DBI", { trustme => [qr/^(new)$/] } );

# WWW::MLite::Helper::*
pod_coverage_ok( "WWW::MLite::Helper::Install" );
pod_coverage_ok( "WWW::MLite::Helper::Skel" );
pod_coverage_ok( "WWW::MLite::Helper" );

1;
