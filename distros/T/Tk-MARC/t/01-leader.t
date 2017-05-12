use Test::More tests => 8;

use Tk;
use MARC::Record;
use strict;

use_ok( 'Tk::MARC::Leader' );
is( $Tk::MARC::Leader::VERSION,'0.3', 'Ok' );

# Build a (minimal) MARC record
my $marc = MARC::Record->new();
my $field = MARC::Field->new('100','','','a' => 'Christensen, David A.');
$marc->append_fields($field);
$field = MARC::Field->new('245','','','a' => 'Testing Tk::MARC');
$marc->append_fields($field);

# this is NOT CORRECT for this record!
# (but as no error checking is done, we'll go with is....
$marc->leader('01148cam  220325 a 4500'); 

my $mw = Tk::MainWindow->new();
$mw->geometry('+10+10');

my $ldr = $mw->MARC_Leader(-record => $marc);

ok(Tk::Exists($ldr, 1));
ok($ldr->class, 'MARC_Leader');
ok(ref $ldr, "Tk::MARC::Leader");

my $leader = $ldr->get();
ok($leader eq '01148cam  220325 a 4500', 'Returns correct leader');

eval { $ldr = $mw->MARC_Leader(-record => $marc, -blarg => 'foo')};
ok($@ =~ /(Bad|unknown) option (\`|\")-blarg(\'|\")/, 'Correctly handles bad option');

eval { $ldr = $mw->MARC_Leader() };
ok($@ =~ /Missing -record/, 'Correctly handles missing -record');
