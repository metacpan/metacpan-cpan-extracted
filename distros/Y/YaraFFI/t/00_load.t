#!/usr/bin/env perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 6;

BEGIN {
    use_ok('YaraFFI')                    || print "Bail out!\n";
    use_ok('YaraFFI::Event')             || print "Bail out!\n";
    use_ok('YaraFFI::Record::YR_MATCH')  || print "Bail out!\n";
    use_ok('YaraFFI::Record::YR_META')   || print "Bail out!\n";
    use_ok('YaraFFI::Record::YR_RULE')   || print "Bail out!\n";
    use_ok('YaraFFI::Record::YR_STRING') || print "Bail out!\n";
}

diag("Testing YaraFFI $YaraFFI::VERSION, Perl $], $^X");
