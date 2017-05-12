use strict;

use Test;
use XML::SAX::Machines qw( :all );

my @tests = (
sub { ok Pipeline()->isa( "XML::SAX::Pipeline" ); },
sub { ok Manifold()->isa( "XML::SAX::Manifold" ); },
sub { ok Machine() ->isa( "XML::SAX::Machine"  ); },
sub { ok Tap()     ->isa( "XML::SAX::Tap"      ); },
);

plan tests => scalar @tests;

$_->() for @tests;

