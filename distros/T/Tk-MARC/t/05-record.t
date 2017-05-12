use Test::More tests => 11;

use Tk;
use strict;

use_ok( 'Tk::MARC::Record' );
is( $Tk::MARC::Record::VERSION,'0.11', 'Ok' );

# Build a (minimal) MARC record
my $marc = MARC::Record->new();
my $field = MARC::Field->new('100','','','a' => 'Christensen, David A.');
$marc->append_fields($field);
$field = MARC::Field->new('245','','','a' => 'Testing Tk::MARC');
$marc->append_fields($field);

my $mw = Tk::MainWindow->new();
$mw->geometry('+10+10');

my $r0 = $mw->MARC_Record(-record => $marc);
ok(Tk::Exists($r0, 1));
ok($r0->class, 'MARC_Record');
ok(ref $r0, "Tk::MARC::Record");

my $marc2 = $r0->get();
ok(ref $marc2, "MARC::Record");

ok( $marc != $marc2, 'Correctly does not return reference to original' );
ok( $marc->as_formatted eq $marc2->as_formatted, 'Returned and original match content' );

eval { $r0 = $mw->MARC_Record(-record => 'foo') };
ok($@ =~ /Not a MARC::Record/, 'Correctly handles non-MARC -record');

eval { $r0 = $mw->MARC_Record(-record => $marc, -blarg => 'foo') };
ok($@ =~ /(Bad|unknown) option (\`|\")-blarg(\'|\")/, 'Correctly handles bad option');

eval { $r0 = $mw->MARC_Record() };
ok($@ =~ /Missing -record/, 'Correctly handles missing -record');

