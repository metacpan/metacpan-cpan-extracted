#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 19;

BEGIN {
    use_ok('WebService::Wikimapia')                       || print "Bail out!";
    use_ok('WebService::Wikimapia::Params')               || print "Bail out!";
    use_ok('WebService::Wikimapia::UserAgent')            || print "Bail out!";
    use_ok('WebService::Wikimapia::UserAgent::Exception') || print "Bail out!";
    use_ok('WebService::Wikimapia::Place')                || print "Bail out!";
    use_ok('WebService::Wikimapia::City')                 || print "Bail out!";
    use_ok('WebService::Wikimapia::Comment')              || print "Bail out!";
    use_ok('WebService::Wikimapia::Street')               || print "Bail out!";
    use_ok('WebService::Wikimapia::Hotel')                || print "Bail out!";
    use_ok('WebService::Wikimapia::User')                 || print "Bail out!";
    use_ok('WebService::Wikimapia::Language')             || print "Bail out!";
    use_ok('WebService::Wikimapia::Photo')                || print "Bail out!";
    use_ok('WebService::Wikimapia::GlobalAdmin')          || print "Bail out!";
    use_ok('WebService::Wikimapia::Category')             || print "Bail out!";
    use_ok('WebService::Wikimapia::Category::Synonym')    || print "Bail out!";
    use_ok('WebService::Wikimapia::Location')             || print "Bail out!";
    use_ok('WebService::Wikimapia::Polygon')              || print "Bail out!";
    use_ok('WebService::Wikimapia::Object')               || print "Bail out!";
    use_ok('WebService::Wikimapia::Tag')                  || print "Bail out!";
}

diag( "Testing WebService::Wikimapia $WebService::Wikimapia::VERSION, Perl $], $^X" );
