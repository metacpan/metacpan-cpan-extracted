use Test::More 'no_plan';
use Text::SimpleVcard;

my $dat = "BEGIN:VCARD\r\n" .
	  "ADR;TYPE=home:;;Musterstr. 23;Münster;;12345;\r\n" .
	  "BDAY:1968-05-19T00:00:00Z\r\n" .
	  "CLASS:PUBLIC\r\n" .
	  "EMAIL:a.bcd\@web.de\r\n" .
	  "FN:Tomuschat\\, Michael\r\n" .
	  "N:Tomuschat;Michael;;;\r\n" .
	  "ORG:Ing. Büro Tomuschat\r\n" .
	  "REV:2008-01-23T10:21:45Z\r\n" .
	  "TEL;TYPE=HOME:(04711) 12345\r\n" .
	  "TEL;TYPE=WORK:(04711) 123456\r\n" .
	  "TEL;TYPE=FAX;TYPE=WORK:(04711) 123457\r\n" .
	  "TEL;TYPE=CELL:(0815) 9876543\r\n" .
	  "UID:8\r\n" .
	  "VERSION:3.0\r\n" .
	  "END:VCARD\r\n";

my $vCard = Text::SimpleVcard->new( $dat);
my $fullname = $vCard->getFullName();
my $propFN = $vCard->getSimpleValue( 'FN');
my $propEmail = $vCard->getSimpleValue( 'EmaiL');
my $propTEL = $vCard->getSimpleValue( 'TEL', 2);
my $undef1 = $vCard->getSimpleValue( 'dummy');
my $undef2 = $vCard->getSimpleValue( 'FN', 27);
my %h1 = $vCard->getValuesAsHash( 'TEL', [qw( WORK HOME VOICE FAX)]);
my %h2 = $vCard->getValuesAsHash( 'TEL');
my @dat1 = split( /[\r\n]+/, $dat);
shift @dat1;
pop @dat1;
@dat1 = sort @dat1;
my @dat2 = sort split( /[\r\n]+/, $vCard->sprint());
my $dat1 = join( '\n', @dat1);
my $dat2 = join( '\n', @dat2);
ok( defined $vCard,                     'new() returning something');
ok( $vCard->isa( 'Text::SimpleVcard'),  'new() returning hash-reference of type SimpleVcard');
is( keys %$vCard, 11,                   'new() returning correct count of properties');
is( $fullname, 'Tomuschat, Michael',    'getFullName() returning correct fullname');
is( $propFN, 'Tomuschat\, Michael',     'getSimpleValue() returning correct FN-property');
is( $propEmail, 'a.bcd@web.de',         'getSimpleValue() with upper/lower spelling');
is( $propTEL, '(04711) 123457',         'getsimpleValue() with in-range-index');
is( $undef1, undef,                     'getSimpleValue() with unknown element');
is( $undef2, undef,                     'getSimpleValue() with index too big');
is( scalar( keys %h1), 3,               'getValuesAsHash() returning correct count of properties');
is( $h1{ '(04711) 123457'}, 'WORK,FAX', 'getValuesAsHash() returning correct types');
is( $h1{ '(04711) 123456'}, 'WORK',     'getValuesAsHash() returning correct types');
is( $h1{ '(04711) 12345'}, 'HOME',      'getValuesAsHash() returning correct types');
is( $h1{ '(0815) 9876543'}, undef,      'getValuesAsHash() returning correct types');
is( $h2{ '(04711) 123457'}, 'FAX,WORK', 'getValuesAsHash() returning correct types when no types provided');
is( $dat1, $dat2,                       'sprint() returning complete vCard');
