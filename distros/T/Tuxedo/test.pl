# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tuxedo;
use tpadm;
use testflds;
require "genubbconfig.pl";


# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

###################################################################
# Create a ubbconfig and boot the tuxedo system that this test
# script will connect to as a workstation tuxedo client.
###################################################################
tuxputenv( "TUXCONFIG=" . get_tuxconfig() );
$path = tuxgetenv( "PATH" );
tuxputenv( "PATH=$path;./blib/arch/auto/Tuxedo" );
system( "tmshutdown -y" );

gen_ubbconfig();
if ( system( "tmloadcf -y ubbconfig" ) ) { die "tmloadcf failed\n"; }
system( "tmboot -y" );

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

###################################################################
# Connect to the tuxedo system
###################################################################
# TEST 1: tpalloc
my $password = "00000031". "\377" . "0" . "\377" . "utp_tester1" . "\377"  . "utputp1" . "\377";
my $buffer = tpalloc( "TPINIT", "", TPINITNEED( length($password) ) );
if ( $buffer == undef ) {
    die "tpalloc failed: " . tpstrerror(tperrno) . "\n";
}

$buffer->usrname( "utp_tester1" );
$buffer->cltname( "perl" );
$buffer->flags( TPMULTICONTEXTS );
$buffer->passwd( "SVTuxedo" );
$buffer->data( $password );
print "usrname: " . $buffer->usrname . "\n";
print "cltname: " . $buffer->cltname . "\n";
print "flags:   " . $buffer->flags   . "\n";
print "data:    " . $buffer->data    . "\n";
print "datalen: " . $buffer->datalen . "\n";
print "ok 2\n";

# TEST 2: tptypes
my ($size, $type, $subtype);
$size = tptypes( $buffer, $type, $subtype );
if ( $size == -1 ) {
    die "tptypes failed: " . tpstrerror(tperrno) . "\n";
}
print "SIZE:    " . $size . "\n";
print "TYPE:    " . $type . "\n";
print "SUBTYPE: " . $subtype . "\n";
print "ok 3\n";

# TEST 3: tuxputenv and tuxgetenv

print "TUXCONFIG = " . tuxgetenv( "TUXCONFIG" ) . "\n";

# TEST 4: tpinit, tperrno and tpstrerror
my $rval = tpinit( $buffer );
if ( $rval == -1 ) {
    print "tpinit failed: " . tpstrerror(tperrno) . "\n";
}

###################################################################
# Make some MIB service calls
###################################################################
# TEST: Fappend32
my $infml32 = tpalloc( "FML32", 0, 1024 );
my $outfml32 = tpalloc( "FML32", 0, 1024 );
if ( $infml32 == undef || $outfml32 == undef ) {
    die "tpalloc failed: " . tpstrerror(tperrno) . "\n";
}

#$rval = Fappend32( $infml32, BADFLDID, 12345, 0 );
#if ( $rval == -1 ) {
#    print "Fappend32 failed: " . Fstrerror32( Ferror32 ) . "\n";
#}

$rval = Fappend32( $infml32, TA_CLASS, "T_CLIENT", 0 );
$rval = Fappend32( $infml32, TA_OPERATION, "GET", 0 );
$rval = Findex32( $infml32, 0 );
print "Findex32 returned " . $rval . "\n";

tuxputenv( "FIELDTBLS32=tpadm" );
tuxputenv( "FLDTBLDIR32=" . tuxgetenv("TUXDIR") . "/udataobj" );
$rval = Fprint32( $infml32 );

print "calling tpcall...\n";
$rval = tpcall( ".TMIB", $infml32, 0, $outfml32, $olen, 0 );
if ( $rval == -1 ) {
    die ( "tpcall failed: " . tpstrerror(tperrno) . ".\n" );
}
$rval = Fprint32( $outfml32 );
print "finished tpcall\n";
print "Press <enter> to continue...";
#$line = <STDIN>;

print "calling tpacall...\n";
$cd = tpacall( ".TMIB", $infml32, 0, 0 );
if ( $cd == -1 ) {
    die ( "tpacallfailed: " . tpstrerror(tperrno) . ".\n" );
}

$rval = tpgetrply( $rcd, $outfml32, $olen, TPGETANY );
if ( $rval == -1 ) {
    die ( "tpgetrply failed: " . tpstrerror(tperrno) . ".\n" );
}
$rval = Fprint32( $outfml32 );
print "finished tpacall\n";
print "Press <enter> to continue...";
#$line = <STDIN>;


$rval = Fget32( $outfml32, TA_OCCURS, 0, $val, $len );
if ( $rval == -1 ) { 
    die ( "Fget32 failed: " . Fstrerror32(Ferror32) . ".\n" );
}
print "TA_OCCURS = " . $val . "\n";

# TEST : embedded FML32 buffers
$childfml32 = tpalloc( "FML32", 0, 1024 );
Fadd32( $childfml32, TA_CLASS, "CHILD", 0 );
Fadd32( $childfml32, TA_OPERATION, "BUFFER", 0 );

$parentfml32 = tpalloc( "FML32", 0, 1024 );
$rval = Fadd32( $parentfml32, TEST_FML32, $childfml32, 0 );
if ( $rval == -1 ) {
    die ( "Fadd32 failed: " . Fstrerror32(Ferror32) . "\n" ) 
}

Fadd32( $parentfml32, TEST_DOUBLE, 123.432, 0 );
Fprint32( $parentfml32 );

#my $val, $len;
$rval = Fget32( $parentfml32, TEST_FML32, 0, $val, $len );
if ( $rval == -1 ) {
    die ( "Fget32 failed: " . Fstrerror32(Ferror32) . "\n" ) 
}
Fprint32( $val );
$tempvar = $val;
$rval = Fget32( $parentfml32, TEST_DOUBLE, 0, $val, $len );
print "val = " . $val . "\n";
print "len = " . $len . "\n";


# TEST: CLIENTID ptr

$fml32in = tpalloc( "FML32", 0, 1024 );
Fadd32( $fml32in, TA_CLASS, "T_CLIENT", 0 );
Fadd32( $fml32in, TA_OPERATION, "GET", 0 );
printf( "MIB_SELF = " . MIB_SELF . "\n" );
Fadd32( $fml32in, TA_FLAGS, MIB_SELF, 0 );
Fprint32( $fml32in );
$rval = tpcall( ".TMIB", $fml32in, 0, $fml32in, $len, 0 );
if ( $rval == -1 ) {
    die ( "tpcall failed: " . tpstrerror(tperrno) . "\n" );
}
Fprint32( $fml32in );
$rval = Fget32( $fml32in, TA_CLIENTID, 0, $ta_clientid, $len );
printf( "TA_CLIENTID = $ta_clientid\n" );

#$rval = tpconvert( $ta_clientid, $clientid, TPCONVCLTID );
#@clientdata = $clientid->clientdata;
#printf ( "The size of clientdata = " . @clientdata . "\n" );
#printf ( "clientdata = " . "@clientdata" . "\n" );
#$rval = tpconvert( $strrep, $clientid, TPTOSTRING | TPCONVCLTID );
#printf ( "clientid = $strrep\n" );

$tptranid = TPTRANID_PTR::new();
@info = $tptranid->info( 1, 2, 3, 4, 5, 6 );
printf ( "tptranid->info = @info\n" );

$xid = XID_PTR::new();
$xid->data( "fat" );

printf ( "xid->data = " . $xid->data . "\n" );

# TEST: TPQCTL
$tpqctl = TPQCTL_PTR::new();
$tpqctl->flags( TPQMSGID );
$rval = tpconvert( $ta_clientid, $tpqctl->cltid, TPCONVCLTID );
@clientdata = $tpqctl->cltid->clientdata;
printf ( "clientid->clientdata = @clientdata\n" );
printf ( "tpqctl->flags = " . $tpqctl->flags . "\n" );

# TEST tpexport
$rval = tpexport( $fml32in, 0, $ostr, $olen, 0 );
if ( $rval == -1 ) {
    die ( "tpexport failed: " . tpstrerror(tperrno) . "\n" );
}
printf( "ostr = $ostr\n" );
printf( "olen = $olen\n" );

# TEST tpimport
$importbuf = tpalloc( "FML32", 0, 1024 );
$rval = tpimport( $ostr, $olen, $importbuf, $olen, 0 );
if ( $rval == -1 ) {
    die ( "tpimport failed: " . tpstrerror(tperrno) . "\n" );
}
printf( "After tpimport...\n" );
Fprint32( $importbuf );

#$importbuf = tprealloc( $importbuf, 2056 );
$rval = Fget32( $importbuf, TA_CLIENTID, 0, $ta_clientid, $len );
printf( "TA_CLIENTID = $ta_clientid\n" );
printf( "done\n" );

# TEST tpgetctxt
$rval = tpgetctxt( $ctxt, 0 );
if ( $rval == -1 ) {
    die ( "tpgetctxt failed: " . tpstrerror(tperrno) . "\n" );
}
printf( "ctxt = $ctxt\n" );

# TEST tpgetlev
$rval = tpgetlev();
if ( $rval == -1 ) {
    die ( "tpgetlev failed: " . tpstrerror(tperrno) . "\n" );
}
printf( "tpgetlev returned $rval\n" );

# TEST tpgprio
$rval = tpgprio();
if ( $rval == -1 ) {
    die ( "tpgprio failed: " . tpstrerror(tperrno) . "\n" );
}
printf( "tpgprio returned $rval\n" );

# TEST tpscmt
$rval = tpscmt( TP_CMT_LOGGED );
if ( $rval == -1 ) {
    die ( "tpscmt failed: " . tpstrerror(tperrno) . "\n" );
}
printf( "tpscmt returned $rval\n" );


# TEST tpsetunsol
tpsetunsol( \&pants );
$clientid = CLIENTID_PTR::new();
$rval = tpconvert( $ta_clientid, $clientid, TPCONVCLTID );
$unsolbuf = tpalloc( "FML32", 0, 1024 );
Fadd32( $unsolbuf, TA_CLASS, "Fat mofo", 0 );
$rval = tpnotify( $clientid, $unsolbuf, 0, 0 );
if ( $rval == -1 ) {
    die ( "tpnotify failed: " . tpstrerror(tperrno) . "\n" );
}
$clientid = 0;

# TEST Usignal
Usignal( 17, \&sigusr2 );
printf( "My process id is $$\n" );


# Test STRING buffer
my $string = tpalloc( "STRING", 0, 1024 );
if ( not defined $string ) {
    die ( "tpalloc failed: " . tpstrerror(tperrno) . "\n" );
}
$string->value( "fat boy" );
printf( "\$string = " . $string->value . "\n" );

# Test PERLSVR TOUPPER
$rval = tpcall( "TOUPPER", $string, 0, $string, $len, 0 );
if ( $rval == -1 ) {
    die ( "tpcall failed: " . tpstrerror(tperrno) . "\n" );
}
printf( "\$string = " . $string->value . "\n" );

# Test PERLSVR REVERSE
$rval = tpcall( "REVERSE", $string, 0, $string, $len, 0 );
if ( $rval == -1 ) {
    die ( "tpcall failed: " . tpstrerror(tperrno) . "\n" );
}
printf( "\$string = " . $string->value . "\n" );

# TEST 5: tpterm
$rval = tpterm();
if ( $rval == -1 ) {
    print "tpterm failed: " . tpstrerror(tperrno) . "\n";
}

userlog( "Finished test of activetux for perl." . "  You are FAT!" );

system( "tmshutdown -y" );

exit(0);

sub pants
{
    my( $buffer, $len, $flags ) = @_;
    Fprint32( $buffer );
    printf( "Inside PANTS!\n" );
}

sub sigusr2
{
    my( $signum ) = @_;
    printf( "Caught SIGUSR2\n" );
}
