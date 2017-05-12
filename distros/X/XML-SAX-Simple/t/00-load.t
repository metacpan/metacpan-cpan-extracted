use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('XML::SAX::Simple') || print "Bail out!\n"; }
diag( "Testing XML::SAX::Simple $XML::SAX::Simple::VERSION, Perl $], $^X" );
