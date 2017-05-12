use strict;
use warnings;
#use Data::Dumper; $Data::Dumper::Indent = 1;
use Test::More tests => 2;

use XML::Atom::Service;

is $XML::Atom::DefaultVersion, '1.0';
is $XML::Atom::Service::DefaultNamespace, 'http://www.w3.org/2007/app';
