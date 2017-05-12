use Test::More tests => 13;

use Tk;
use strict;

use_ok( 'Tk::MARC::Subfield' );
is( $Tk::MARC::Subfield::VERSION,'0.8', 'Ok' );

my $mw = Tk::MainWindow->new();
$mw->geometry('+10+10');

my $sf0 = $mw->MARC_Subfield(-field => '245',
                             -label => 'a',
                             -value => 'Testing Tk::MARC::Subfield');
ok(Tk::Exists($sf0, 1));
ok($sf0->class, 'MARC_Subfield');
ok(ref $sf0, "Tk::MARC::Subfield");

my $subfield0 = $sf0->get();
ok(ref $subfield0, "ARRAY");
ok(@$subfield0[0] eq 'a', 'Returns correct subfield indicator');
ok(@$subfield0[1] eq 'Testing Tk::MARC::Subfield', 'Returns correct subfield value');
eval{ $sf0->destroy() };

my $sf1 = $mw->MARC_Subfield(-field => '001',
                             -label => 'DATA',
                             -value => 'PLS1234');
my $subfield1 = $sf1->get();
ok(not ref $subfield1);
ok($subfield1 eq 'PLS1234', 'Returns correct value for field < 010');

eval { $sf0 = $mw->MARC_Subfield(-field => '245', -label => 'a', -blarg => 'foo') };
ok($@ =~ /(Bad|unknown) option (\`|\")-blarg(\'|\")/, 'Correctly handles bad option');

eval { $sf0 = $mw->MARC_Subfield() };
ok($@ =~ /Missing -field/, 'Correctly handles missing -field');

eval { $sf0 = $mw->MARC_Subfield(-field => '245') };
ok($@ =~ /Missing -label/, 'Correctly handles missing -label');
