
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 10;
use strict;
use warnings;

my @preset = qw(blessed dump peek refaddr);
use_ok( 'UNIVERSAL::dump',@preset );
can_ok( 'UNIVERSAL',@preset );

sub Foo::testing { "Testing $_[0]" }
UNIVERSAL::dump->import( { testing => 'Foo::testing' } );
can_ok( 'UNIVERSAL','testing' );

UNIVERSAL::dump->import( { _dump   => 'dump' } );
can_ok( 'UNIVERSAL','_dump' );

require Data::Dumper;
my $foo = bless {},'Foo';
is( $foo->dump,Data::Dumper::Dumper( $foo ),"Check if Data::Dumper dump ok" );
is( $foo->_dump,Data::Dumper::Dumper( $foo ),"Check if Data::Dumper _dump ok" );

is( $foo->testing,Foo::testing( $foo ),"Check if Foo dump ok" );
is( bar->testing( $foo ),Foo::testing( $foo ),"Check if Foo dump ok" );

eval { UNIVERSAL::dump->import( { testing => 'Foo::otherdump' } ) };
like( $@,qr#^Cannot install#,"If same method, different sub causes error" );

eval { UNIVERSAL::dump->import( { testing => 'Foo::testing' } ) };
is( $@,'',"If same method, same sub does not cause error" );
