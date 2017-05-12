#!perl -wT
# Win32::GUI test suite.
# $Id: 98_Pod.t,v 1.3 2006/03/16 21:11:13 robertemay Exp $

# Testing RichEdit::GetCharFormat()

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};
all_pod_files_ok(all_pod_files('.'));
