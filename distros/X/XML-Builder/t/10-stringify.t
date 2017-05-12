use strict;
use XML::Builder;
use Test::More tests => 4;

my $x = XML::Builder->new;

{
package SomeClass;
sub new { bless {}, shift }

package SomeClass::AsStr;
our @ISA = 'SomeClass';
sub as_string { 'an object' }

package SomeClass::Overload;
our @ISA = 'SomeClass';
use overload '""' => sub { 'no really' };

package SomeClass::AsStr::Overload;
our @ISA = 'SomeClass::AsStr';
use overload '""' => sub { 'ignore me' };
}

my $obj1 = SomeClass->new;
eval { $x->stringify( $obj1 ) };
like $@, qr/Unstringifiable object SomeClass=/, 'reject random objects';

my $obj2 = SomeClass::AsStr->new;
is $x->stringify( $obj2 ), 'an object', 'explicit object stringification';

my $obj3 = SomeClass::Overload->new;
is $x->stringify( $obj3 ), 'no really', 'implicit object stringification';

my $obj4 = SomeClass::AsStr::Overload->new;
is $x->stringify( $obj4 ), 'an object', 'explicit object stringification preferred';
