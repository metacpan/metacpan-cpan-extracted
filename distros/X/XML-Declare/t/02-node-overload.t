#!/usr/bin/env perl -w

use strict;
use warnings;
use lib::abs '../lib';
use Test::More tests => 4;
use Test::NoWarnings ();
use overload ();
use XML::LibXML;

sub overloaded {
	my ($pk,$m) = @_;
	overload::ov_method(overload::mycan($pk,'('.$m),$pk);
}

my $node = XML::LibXML::Element->new('test');
$node->appendText("test");

if (overloaded('XML::LibXML::Element', 'bool')) {
	delete local $XML::LibXML::Element::{ '()' };
	bless $node,ref $node; # reapply overload magic
}

diag "str  = ", my $str  = "$node";
diag "bool = ", my $bool = !!$node;
diag "num  = ", my $num  = 0+$node;

require XML::Declare;
bless $node,ref $node; # reapply overload magic

diag "str  = ", my $ostr  = "$node";
diag "bool = ", my $obool = !!$node;
diag "num  = ", my $onum  = 0+$node;

# like $str, qr/^XML::LibXML::Element=/, 'string not overloaded';
is $ostr, "<test>test</test>", 'string overloaded';
is $obool,$bool, 'bool is ok';
is $onum,$num, 'num is ok';

Test::NoWarnings::had_no_warnings();

exit;
require Test::NoWarnings; # Stupid hack for cpants::kwalitee
