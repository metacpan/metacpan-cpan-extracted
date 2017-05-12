use Test::More tests => 12;

use Tk;
use strict;

use_ok( 'Tk::MARC::Field' );
is( $Tk::MARC::Field::VERSION,'0.11', 'Ok' );

# Build a MARC field
my $field = MARC::Field->new('100','','','a' => 'Christensen, David A.');

my $mw = Tk::MainWindow->new();
$mw->geometry('+10+10');

my $f0 = $mw->MARC_Field(-field => $field);
ok(Tk::Exists($f0, 1));
ok($f0->class, 'MARC_Field');
ok(ref $f0, "Tk::MARC::Field");

my $field2 = $f0->get();
ok(ref $field2, "MARC::Field");

ok( $field != $field2, 'Correctly does not return reference to original' );
ok( $field->as_formatted eq $field2->as_formatted, 'Returned and original match content' );

eval { $f0 = $mw->MARC_Field(-field => 'foo') };
ok($@ =~ /Not a MARC::Field/, 'Correctly handles non-MARC::Field -field');

eval { $f0 = $mw->MARC_Field(-field => $field, -blarg => 'foo') };
ok($@ =~ /(Bad|unknown) option (\`|\")-blarg(\'|\")/, 'Correctly handles bad option');

eval { $f0 = $mw->MARC_Field() };
ok($@ =~ /Missing -tag/, 'Correctly handles missing -tag');

eval { $f0 = $mw->MARC_Field(-tag => '100') };
ok($@ =~ /Missing -subfields/, 'Correctly handles missing -subfields');

