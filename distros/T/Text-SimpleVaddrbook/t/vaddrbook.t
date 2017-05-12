use Test::More 'no_plan';
use Text::SimpleVaddrbook;

my $aBook = Text::SimpleVaddrbook->new( 't/std1.vcf', 't/std2.vcf');

my $cnt = 0;
while( my $vCard = $aBook->next()) {
   is( $vCard->getFullName(), 'Musterfrau, Elke',       'next() returns 1. vcard in initial open') if( $cnt == 0);
   is( $vCard->getFullName(), 'Mustermann, Klaus',      'next() returns 2. vcard in initial open') if( $cnt == 1);
   is( $vCard->getFullName(), 'Musterfamilie, Christa', 'next() returns 2. vcard in initial open') if( $cnt == 2);
   is( $vCard->getFullName(), 'Heiermann, Heike',       'next() returns 2. vcard in initial open') if( $cnt == 3);
   is( $vCard->getFullName(), 'Saubermann, Heike',      'next() returns 2. vcard in initial open') if( $cnt == 4);
   $cnt++;
}
$aBook->rewind();
$cnt = 0;
while( my $vCard = $aBook->next()) {
   is( $vCard->getFullName(), 'Musterfrau, Elke',       'next() returns 1. vcard in initial open') if( $cnt == 0);
   is( $vCard->getFullName(), 'Mustermann, Klaus',      'next() returns 2. vcard in initial open') if( $cnt == 1);
   is( $vCard->getFullName(), 'Musterfamilie, Christa', 'next() returns 2. vcard in initial open') if( $cnt == 2);
   is( $vCard->getFullName(), 'Heiermann, Heike',       'next() returns 2. vcard in initial open') if( $cnt == 3);
   is( $vCard->getFullName(), 'Saubermann, Heike',      'next() returns 2. vcard in initial open') if( $cnt == 4);
   $cnt++;
}

