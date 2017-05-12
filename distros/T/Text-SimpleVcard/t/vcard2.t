use Test::More 'no_plan';
use Text::SimpleVcard;

my $dat = "BEGIN:VCARD\r\n" .
	  "VERSION:2.1\r\n" .
	  "N:Gump;Forrest\r\n" .
	  "FN:Forrest Gump\r\n" .
	  "ORG:Bubba Gump Shrimp Co.\r\n" .
	  "TITLE:Shrimp Man\r\n" .
	  "TEL;WORK:(111) 555-1212\r\n" .
	  "TEL;HOME;VOICE:(404) 555-1212\r\n" .
	  "TEL;CELL:(404) 555-1212\r\n" .
	  "ADR;WORK:;;100 Waters Edge;Baytown;LA;30314;United States of America\r\n" .
	  "LABEL;WORK;ENCODING=QUOTED-PRINTABLE:100 Waters Edge=0D=0ABaytown, LA 30314=0D=0AUnited States of America\r\n" .
	  "ADR;HOME:;;42 Plantation St.;Baytown;LA;30314;United States of America\r\n" .
	  "LABEL;HOME;ENCODING=QUOTED-PRINTABLE:42 Plantation St.=0D=0ABaytown, LA 30314=0D=0AUnited States of America\r\n" .
	  "EMAIL;PREF;INTERNET:forrestgump\@example.com\r\n" .
	  "REV:20080424T195243Z\r\n" .
	  "END:VCARD\r\n";

my $vCard = Text::SimpleVcard->new( $dat);
my $fullname = $vCard->getFullName();
my $propLBL1 = $vCard->getSimpleValueOfType( 'LABEL', [ 'WORK']); 
my $lbl1 = "100 Waters Edge\r\nBaytown, LA 30314\r\nUnited States of America";
my $propLBL2 = $vCard->getSimpleValue( 'LABEL', 1);
my $lbl2 = "42 Plantation St.\r\nBaytown, LA 30314\r\nUnited States of America";
my %h1 = $vCard->getValuesAsHash( 'TEL', [qw( WORK HOME)]);
my %h2 = $vCard->getValuesAsHash( 'TEL');

ok( defined $vCard,                     'new() returning something');
ok( $vCard->isa( 'Text::SimpleVcard'),  'new() returning hash-reference of type SimpleVcard');
is( keys %$vCard, 10,                   'new() returning correct count of properties');
is( $fullname, 'Forrest Gump',          'getFullName() returning correct fullname');
is( $propLBL1, $lbl1,                   'getsimpleValue() with in-range-index');
is( $propLBL2, $lbl2,                   'getsimpleValue() with in-range-index');
is( scalar( keys %h1), 2,               'getValuesAsHash() returning correct count of properties (1)');
is( scalar( keys %h2), 2,               'getValuesAsHash() returning correct count of properties (2)');
is( $h1{ '(404) 555-1212'}, 'HOME',     'getValuesAsHash() returning correct types');
is( $h1{ '(111) 555-1212'}, 'WORK',     'getValuesAsHash() returning correct types');
is( $h1{ '(0815) 9876543'}, undef,      'getValuesAsHash() returning correct types');
is( $h2{ '(404) 555-1212'}, 'HOME,VOICE,CELL', 'getValuesAsHash() returning correct types when no types provided');
