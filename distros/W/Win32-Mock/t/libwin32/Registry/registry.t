use Test::More skip_all => " *** NOT IMPLEMENTED";
#Portions (c) 1995 Microsoft Corporation. All rights reserved. 
#	Developed by ActiveWare Internet Corp., http://www.ActiveWare.com

# reg.ntt
# Tests for NT Extensions - Registry Manipulation Routines
# changed to test new registry extension modules.

use Win32::Registry;

$bug = 1;

open( ME, $0 ) || die $!;
$bugs = grep( /^\$bug\+\+;\s*\n$/, <ME> );
close( ME );

print "1..$bugs\n";

$HKEY_CLASSES_ROOT->Create( 'ntperl.test.key', $hkey)|| print "not ";
print "ok $bug\n";
$bug++;

$HKEY_CLASSES_ROOT->DeleteKey( 'ntperl.test.key' )  ?
    print "ok $bug\n" : print "not ok $bug\n";
$bug++;


$HKEY_CLASSES_ROOT->DeleteKey( 'ntperl.test.key') ?
    print "not ok $bug\n" : print "ok $bug\n";
$bug++;


$HKEY_CLASSES_ROOT->Create( 'ntperl.test.key',$hkey2 ) ?
    print "ok $bug\n" : print "not ok $bug\n";
$bug++;


$hkey->Close() ?
    print "ok $bug\n" : print "not ok $bug\n";
$bug++;

$HKEY_CLASSES_ROOT->DeleteKey( 'ntperl.test.key' ) ?
    print "ok $bug\n" : print "not ok $bug\n";
$bug++;


$hkey2->Close() ?
    print "ok $bug\n" : print "not ok $bug\n";
$bug++;

#WORKS TO HERE.


$HKEY_CLASSES_ROOT->Create( 'ntperl.test.key', $hkey ) ?
    print "ok $bug\n" : print "not ok $bug\n";

$bug++;
$hkey->Create( 'k0', $sk0 ) || print "not ";
$hkey->Create( 'k1', $sk1 ) || print "not ";
$hkey->Create( 'k2', $sk2 ) || print "not ";
print "ok $bug\n";
$bug++;


$keys=[];
$hkey->GetKeys( $keys );
print "not " unless ( $#$keys == 2 );
print "ok $bug\n";
$bug++;

$i = 0;
foreach ( sort( @$keys ) ) {
    print "not " unless /^k$i$/;
    $i++;
}
print "ok $bug\n";
$bug++;

$hkey->SetValue('k0', REG_SZ, "silly piece of info" ) || print "not ";
print "ok $bug\n";
$bug++;

$hkey->QueryValue( 'k0', $data ) || print "not ";
$data eq "silly piece of info" || print "not ";
print "ok $bug\n";
$bug++;

$sk0->DeleteValue( "\000" ) ?
    print "ok $bug\n" : print "not ok $bug\n";
$bug++;

$hkey->QueryValue( 'k0', $data ) || print "not ";
$data eq "silly piece of info" ?
print "not ok $! $bug\n" : print "ok $bug\n";
$bug++;

$sk0->DeleteValue( "\000" ) ?
    print "not ok $bug\n" : print "ok $bug\n";
$bug++;

$sk0->SetValueEx( 'string0',NULL, REG_SZ, "data0" ) || print "not ";
$sk0->SetValueEx( 'string1',NULL, REG_SZ, "data1" ) || print "not ";
$sk0->SetValueEx( 'string2',NULL, REG_SZ, "data2" ) || print "not ";
print "ok $bug\n";
$bug++;

$sk0->SetValueEx( 'none',NULL, REG_NONE, "" ) || print "not ";
print "ok $bug\n";
$bug++;
$sk0->DeleteValue( 'none' ) || print "not ";
print "ok $bug\n";
$bug++;

#$sk0->show_me();
$sk0->GetValues( \%values );

@keys = keys( %values );
$#keys == 2 || print "not $!";

$i = 0;
foreach ( sort( keys( %values ) ) ) {
    $aref = $values{ $_ };
    ( $name, $type, $data ) = @$aref;
    print "not " unless
	( $name eq "string$i" && $type == &REG_SZ && $data eq "data$i" );
    $i++;
}    
print "ok $bug\n";
$bug++;

foreach ( 'string0', 'string1', 'string2' ) {
	$sk0->DeleteValue( $_ ) || print "not ";
}
print "ok $bug\n";
$bug++;


$sk0->Close();
$sk1->Close();
$sk2->Close();

$hkey->DeleteKey( 'k0' ) || print "not ";
$hkey->DeleteKey( 'k1' ) || print "not ";
$hkey->DeleteKey( 'k2' ) || print "not ";
print "ok $bug\n";
$bug++;

$hkey->Close();

$HKEY_CLASSES_ROOT->DeleteKey( 'ntperl.test.key' ) ?
    print "ok $bug\n" : print "not ok $bug\n";
$bug++;


