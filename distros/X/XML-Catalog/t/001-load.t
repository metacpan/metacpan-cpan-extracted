use strict;
use warnings;

use Test::More tests => 5;
use Cwd qw(abs_path);

BEGIN {
    use_ok('XML::Catalog');
}

diag("Testing XML::Catalog $XML::Catalog::VERSION");

my $catalog = XML::Catalog->new( 'file://' . abs_path('t/oasis.cat') );
isa_ok( $catalog, 'XML::Catalog', 'Check ISA' );

my $pubid = '-//OASIS//TEST DTD//EN';
my $file  = $catalog->resolve_public($pubid);

is( $file, 'file://' . abs_path('t/test.dtd'), 'Reslove PublicID' );

$pubid = '-//OASIS//TEST 2 DTD//EN';
$file  = $catalog->resolve_public($pubid);

is( $file, 'file://' . abs_path('t/test.dtd'), 'Reslove deligated PublicID' );

$pubid = '-//OASIS//TEST 3 DTD//EN';
$file  = $catalog->resolve_public($pubid);

is( $file, 'file://' . abs_path('t/test2.dtd'), 'Reslove nextCatalog' );

