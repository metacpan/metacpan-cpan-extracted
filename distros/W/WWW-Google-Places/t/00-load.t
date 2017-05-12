#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 10;

BEGIN {
    use_ok('WWW::Google::Places'              )   || print "Bail out!\n";
    use_ok('WWW::Google::Places::Params'      )   || print "Bail out!\n";
    use_ok('WWW::Google::Places::SearchResult')   || print "Bail out!\n";
    use_ok('WWW::Google::Places::DetailResult')   || print "Bail out!\n";
    use_ok('WWW::Google::Places::Location')       || print "Bail out!\n";
    use_ok('WWW::Google::Places::Geometry')       || print "Bail out!\n";
    use_ok('WWW::Google::Places::Photo')          || print "Bail out!\n";
    use_ok('WWW::Google::Places::Address')        || print "Bail out!\n";
    use_ok('WWW::Google::Places::Review')         || print "Bail out!\n";
    use_ok('WWW::Google::Places::Review::Aspect') || print "Bail out!\n";
}

diag( "Testing WWW::Google::Places $WWW::Google::Places::VERSION, Perl $], $^X" );
