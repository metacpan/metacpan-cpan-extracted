# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl XML-LibXML-xmlsec.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('XML::LibXML::xmlsec') };

my $sig=new_ok( 'XML::LibXML::xmlsec' );

ok($sig->XmlSecVersion =~ /^[\d\.]+/,'xmlsec version query');
