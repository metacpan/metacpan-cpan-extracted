use strict;

use Test::More;
unless ( XML::Comma->defs_from_PARs() ) {
  plan skip_all => "not using defs_from_PARs";
} else {
  plan tests => 6;
}

use FindBin;

use lib ".test/lib/";

use XML::Comma;
use XML::Comma::Util qw( dbg );

my $par_filename = File::Spec->catdir ( $FindBin::Bin, 'par_def.par' );
require PAR;
import  PAR  $par_filename;

ok("require and import PAR");

my $doc = XML::Comma::Doc->new ( type => '_test_par_def' );
ok("Doc->new from PAR");

$doc->sing ( 'hello' );
ok("Doc->\$element from PAR")  if  $doc->sing() eq 'hello';

$doc->plu ( 'you' ); $doc->plu ( 'and' ); $doc->plu ( 'you' );
ok("Doc->\$plurals from PAR")  if  $doc->plu()->[0] eq 'you' and
                                   $doc->plu()->[1] eq 'and' and
                                   $doc->plu()->[2] eq 'you';

#TODO: give better test names for these two
$doc->digits_el ( 23 );
ok("digits_el test 1");

eval { $doc->digits_el ( 'hello' ) };
ok("digits_el test 2")  if  $@;





