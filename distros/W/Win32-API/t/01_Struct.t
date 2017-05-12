##!perl -w

# $Id$

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use Config;
use File::Spec;
use Test::More;
use Math::Int64 qw( hex_to_int64 );
BEGIN {
    eval { require Encode; };
    if($@){
        require Encode::compat;
    }
    Encode->import();
    eval 'sub OPV () {'.$].'}';
    sub OPV();
}
plan tests => 50;

use vars qw(
    $function
    $result
    $test_dll
);

use_ok('Win32::API');
use W32ATest;

ok(1, 'loaded');

$test_dll = Win32::API::Test::find_test_dll();
ok(-s $test_dll, 'found API test dll');

typedef Win32::API::Struct(
    'simple_struct', qw(
        int a;
        double b;
        LPSTR c;
        DWORD_PTR d;
        )
);

my $simple_struct = Win32::API::Struct->new('simple_struct');

$simple_struct->align('auto');

$simple_struct->{a} = 5;
$simple_struct->{b} = 2.5;
$simple_struct->{c} = "test";
$simple_struct->{d} = 0x12345678;

my $mangled_d;

if (Win32::API::Test::is_perl_64bit()) {
    $mangled_d = 18446744073404131719
        ; #0xffffffffedcba987; perl errors on hex constants that large, but for some reason not decimal ones
}
else {
    $mangled_d = 0xedcba987;
}

$function = new Win32::API($test_dll, 'mangle_simple_struct', 'S', 'I');
ok(defined($function), 'mangle_simple_struct() function');
diag('$^E=', $^E);

$result = $function->Call($simple_struct);

#print "\n\n\na=$simple_struct->{a} b=$simple_struct->{b} c=$simple_struct->{c} d=$simple_struct->{d}\n\n\n";
#printf "\n\n\na=%s b=%s c=%s d=%08x\n\n\n", $simple_struct->{a}, $simple_struct->{b},
#   $simple_struct->{c}, $simple_struct->{d};

ok( $simple_struct->{a} == 2
        && $simple_struct->{b} == 5
        && $simple_struct->{c} eq 'TEST'
        && $simple_struct->{d} == $mangled_d,
    'mangling of simple structures work'
);

my %simple_struct;
tie %simple_struct, 'Win32::API::Struct' => 'simple_struct';
tied(%simple_struct)->align('auto');

$simple_struct{a} = 5;
$simple_struct{b} = 2.5;
$simple_struct{c} = "test";
$simple_struct{d} = $mangled_d;

#printf "\n\n\na=%s b=%s c=%s d=%08x\n\n\n", $simple_struct->{a}, $simple_struct->{b},
#    $simple_struct->{c}, $simple_struct->{d};
$result = $function->Call(\%simple_struct);

ok( $simple_struct{a} == 2
        && $simple_struct{b} == 5
        && $simple_struct{c} eq 'TEST'
        && $simple_struct->{d} == $mangled_d,
    'tied interface works'
);

#old fashioned way first
{
    $function = Win32::API->new($test_dll, 'WlanConnect', 'QNPPN', 'I');
    if(IV_SIZE == 4 && defined(&Win32::API::UseMI64)){ #defined bc dont fatal error on 0.68
        $function->UseMI64(1);
    }
    my $SSIDstruct = pack('LZ32',length("TheSSID"), "TheSSID" );
    my $profname = Encode::encode("UTF-16LE","TheProfileName\x00");
    my $Wlan_connection_parameters;
    if(OPV > 5.007002){
        $Wlan_connection_parameters = pack('Lx![p]PP'.PTR_LET().'LL', 0
                                          ,$profname
                                          , $SSIDstruct, 0, 3, 1);
    }
    else {#5.6 nranch not 64 bit compatible, missing alignment
        $Wlan_connection_parameters = pack('LPP'.PTR_LET().'LL', 0
                                          ,$profname
                                          , $SSIDstruct, 0, 3, 1);
    }
    #$Wlan_connection_parameters->{wlanConnectionMode} = 0;
    #$Wlan_connection_parameters->{strProfile}         = $profilename;
    #$Wlan_connection_parameters->{pDot11Ssid}         = $pDot11Ssid;
    #$Wlan_connection_parameters->{pDesiredBssidList}  = 0;
    #$Wlan_connection_parameters->{dot11BssType}       = 3;
    #$Wlan_connection_parameters->{dwFlags}            = 1;
    is($function->Call(hex_to_int64("0x8000000050000000"),
                       0x12344321,
               "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x10\x11\x12\x13\x14\x15\x16"
               , $Wlan_connection_parameters,
               0xF080F080), 0, "manual packing fake WlanConnect returned ERROR_SUCCESS");
}
{
    Win32::API::Type->typedef( 'WLAN_CONNECTION_MODE', 'INT');
    Win32::API::Type->typedef( 'DOT11_BSS_TYPE', 'INT');
    Win32::API::Type->typedef( 'PDOT11_BSSID_LIST', 'UINT_PTR');
    
    Win32::API::Struct->typedef ('DOT11_SSID', qw(
      ULONG uSSIDLength;
      UCHAR ucSSID[32];
    ));
    
    Win32::API::Type->typedef( 'PDOT11_SSID', 'DOT11_SSID *');
    
    Win32::API::Struct->typedef('WLAN_CONNECTION_PARAMETERS', qw(
      WLAN_CONNECTION_MODE wlanConnectionMode;
      LPCWSTR              strProfile;
      PDOT11_SSID          pDot11Ssid;
      PDOT11_BSSID_LIST    pDesiredBssidList;
      DOT11_BSS_TYPE       dot11BssType;
      DWORD                dwFlags;
      ));
    Win32::API::Type->typedef('PWLAN_CONNECTION_PARAMETERS', 'WLAN_CONNECTION_PARAMETERS *');
    Win32::API::Type->typedef( 'GUID *', 'char *');
    $function = Win32::API->new($test_dll, 'DWORD 
WlanConnect(
    unsigned __int64 quad,
    HANDLE hClientHandle,
    GUID *pInterfaceGuid, 
    PWLAN_CONNECTION_PARAMETERS pConnectionParameters,
    UINT_PTR pReserved
)');
    my $pDot11Ssid = Win32::API::Struct->new('DOT11_SSID');
    $pDot11Ssid->{uSSIDLength} = length "TheSSID";
    $pDot11Ssid->{ucSSID}      = "TheSSID";
    my $Wlan_connection_parameters = Win32::API::Struct->new('WLAN_CONNECTION_PARAMETERS');
    $Wlan_connection_parameters->{wlanConnectionMode} = 0;
    $Wlan_connection_parameters->{strProfile}         = Encode::encode("UTF-16LE","TheProfileName\x00");
    $Wlan_connection_parameters->{pDot11Ssid}         = $pDot11Ssid;
    $Wlan_connection_parameters->{pDesiredBssidList}  = 0;
    $Wlan_connection_parameters->{dot11BssType}       = 3;
    $Wlan_connection_parameters->{dwFlags}            = 1;
{
    no warnings 'portable';
    is($function->Call(IV_SIZE == 4?
                       "\x00\x00\x00\x50\x00\x00\x00\x80":
                       0x8000000050000000,
                    0x12344321,
                    "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x10\x11\x12\x13\x14\x15\x16",
                    $Wlan_connection_parameters,
                    0xF080F080), 0, "::Struct fake WlanConnect returned ERROR_SUCCESS");
}
    Win32::API::Struct->typedef('WLANPARAMCONTAINER', 'PWLAN_CONNECTION_PARAMETERS', 'wlan;');
    $function = Win32::API->new($test_dll, ' void __stdcall GetConParams('
                                .'BOOL Fill, WLANPARAMCONTAINER * param)');
    my $Wlan_cont = Win32::API::Struct->new('WLANPARAMCONTAINER');
    $Wlan_cont->{wlan} = undef;
    diag("leaked mem warning intentional");
    $function->Call(1, $Wlan_cont);
    ok($Wlan_cont->{wlan}->{wlanConnectionMode} == 0
       && $Wlan_cont->{wlan}->{pDot11Ssid}->{ucSSID} eq "TheFilledSSID"
       && $Wlan_cont->{wlan}->{pDot11Ssid}->{uSSIDLength} == 13
       && $Wlan_cont->{wlan}->{pDesiredBssidList} == 0
       #UTF16 readback is garbage b/c null termination
       #&& $Wlan_cont->{wlan}->{strProfile} eq  Encode::encode("UTF-16LE","FilledTheProfileName"),
       
       ,"undef child struct turned to defined");
    $function->Call(0, $Wlan_cont);
    ok(! defined $Wlan_cont->{wlan} ,"defined child struct turned to undefined");
    
}

{
    ok(  typedef Win32::API::Struct(
    'EIGHT_CHARS', qw(
        char c1;
        char c2;
        char c3;
        char c4;
        char c5;
        char c6;
        char c7;
        char c8;
        )
), "typedefing EIGHT_CHARS worked");
    my $struct = Win32::API::Struct->new('EIGHT_CHARS');
    for(1..8){
        $struct->{'c'.$_} = 0;
    }
    $function = Win32::API->new($test_dll, 'void __stdcall buffer_overflow(LPEIGHT_CHARS string)');
    $function->Call($struct);
    for(1..8){
        $struct->{'c'.$_} = pack('c', $struct->{'c'.$_});
    }
    ok($struct->{'c1'} eq 'J'
       &&$struct->{'c2'} eq 'A'
       &&$struct->{'c3'} eq 'P'
       &&$struct->{'c4'} eq 'H'
       &&$struct->{'c5'} eq 'J'
       &&$struct->{'c6'} eq 'A'
       &&$struct->{'c7'} eq 'P'
       &&$struct->{'c8'} eq 'H'
       , "buffer_overflow filled the struct correctly");
    #now check struct type checking
    $struct = Win32::API::Struct->new('simple_struct');
    eval {$function->Call($struct);};
    ok(index($@, "doesn't match type") != -1, "type mismatch check worked");
    typedef Win32::API::Struct(
    'EIGHT_CHAR_ARR', qw(
        char str[8];
        )
    );
    $struct = Win32::API::Struct->new('EIGHT_CHAR_ARR');
    $struct->{str} = "\x00";
    $function = Win32::API->new($test_dll, 'void __stdcall buffer_overflow(LPEIGHT_CHAR_ARR string)');
    $function->Call($struct);
    is($struct->{str}, 'JAPHJAPH', "buffer_overflow filled the struct correctly");
    diag("unknown type is intentional");    
    $struct = Win32::API::Struct->new('LPEIGHT_CHAR_ARR');
    #Win32::API::Struct has never known the LP____ types automatically,
    #This conflicts with the v0.70 and older POD for ::Struct
    #only Win32::API::Call() knows to remove the LP prefix to get the real
    #struct name, actually in <=0.70, the struct's type was never matched
    #to the C proto (if one exists), so any ::Struct would work, but the C
    #func would get a corrupt struct then, so thats why <= 0.70 "knew" the LP
    #prefix (TLDR, it doesn't know the LP prefix under the hood)
    #> 0.70 got ::Struct type matching, so Call does under the hood remove
    #the LP prefix if any
    if(! defined $struct)
    { ok(1, "can not ::Struct::new a LP prefixed struct name for a defined struct");}
    else{ #0.70 and older code path
        $struct->Pack();
        is($struct->{buffer}, '', "can not ::Struct::new a LP prefixed struct name for a defined struct");
    }
    ok(Win32::API::Type->typedef('LPEIGHT_CHAR_ARR', 'EIGHT_CHAR_ARR *')
       , "Type::typedef worked");
    $struct = Win32::API::Struct->new('LPEIGHT_CHAR_ARR');
    ok(! defined $struct, "Type::typedef doesn't change the ::Struct db");
}
{
    Win32::API::Struct->typedef(SYSTEMTIME => qw(
      WORD wYear;
      WORD wMonth;
      WORD wDayOfWeek;
      WORD wDay;
      WORD wHour;
      WORD wMinute;
      WORD wSecond;
      WORD wMilliseconds;
    ));
    Win32::API::Struct->typedef(TIME_ZONE_INFORMATION => qw(
      LONG       Bias;
      WCHAR      StandardName[32];
      SYSTEMTIME StandardDate;
      LONG       StandardBias;
      WCHAR      DaylightName[32];
      SYSTEMTIME DaylightDate;
      LONG       DaylightBias;
    ));
    #test CPAN #92971, memory corruption when WCHAR array inline in a struct
    $function = Win32::API::More->new(
      $test_dll, 'DWORD WINAPI MyGetTimeZoneInformation( LPTIME_ZONE_INFORMATION lpTimeZoneInformation );'
    );
sub fillSYSTEMTIME {
    my $st = shift;
    $st->{wYear} = 0;
    $st->{wMonth} = 0;
    $st->{wDayOfWeek} = 0;
    $st->{wDay} = 0;
    $st->{wHour} = 0;
    $st->{wMinute} = 0;
    $st->{wSecond} = 0;
    $st->{wMilliseconds} = 0;
}
    my $tzi = Win32::API::Struct->new('TIME_ZONE_INFORMATION');
    fillSYSTEMTIME($tzi->{StandardDate});
    fillSYSTEMTIME($tzi->{DaylightDate});
    $tzi->{StandardName} = '';
    $tzi->{DaylightName} = '';
    $tzi->{Bias} = 0;
    $tzi->{StandardBias} = 0;
    $tzi->{DaylightBias} = 0;
    ok($function->Call($tzi), "MyGetTimeZoneInformation call works");
    ok($tzi->{Bias} ==  1, "MGTZI Bias");
    ok($tzi->{StandardName} eq "v\x00w\x00x\x00y\x00z\x00v\x00w\x00x\x00y\x00z\x00v\x00w\x00x\x00y\x00z\x00v\x00w\x00x\x00y\x00z\x00v\x00w\x00x\x00y\x00z\x00v\x00w\x00x\x00y\x00z\x00w\x00x\x00"
        , "MGTZI StandardName");
    ok($tzi->{StandardDate}{wYear} == 1, "MGTZI StandardDate wYear");
    ok($tzi->{StandardDate}{wMonth} == 2, "MGTZI StandardDate wMonth");
    ok($tzi->{StandardDate}{wDayOfWeek} == 3, "MGTZI StandardDate wDayOfWeek");
    ok($tzi->{StandardDate}{wDay} == 4, "MGTZI StandardDate wDay");
    ok($tzi->{StandardDate}{wHour} == 5, "MGTZI StandardDate wHour");
    ok($tzi->{StandardDate}{wMinute} == 6, "MGTZI StandardDate wMinute");
    ok($tzi->{StandardDate}{wSecond} == 7, "MGTZI StandardDate wSecond");
    ok($tzi->{StandardDate}{wMilliseconds} == 8, "MGTZI StandardDate wMilliseconds");
    ok($tzi->{StandardBias} == 2, "MGTZI StandardBias");
    ok($tzi->{DaylightName} eq "D\x00A\x00Y\x00L\x00N\x00D\x00A\x00Y\x00L\x00N\x00D\x00A\x00Y\x00L\x00N\x00D\x00A\x00Y\x00L\x00N\x00D\x00A\x00Y\x00L\x00N\x00D\x00A\x00Y\x00L\x00N\x00D\x00A\x00"
        , "MGTZI DaylightName");
    ok($tzi->{DaylightDate}{wYear} == 1, "MGTZI DaylightDate wYear");
    ok($tzi->{DaylightDate}{wMonth} == 2, "MGTZI DaylightDate wMonth");
    ok($tzi->{DaylightDate}{wDayOfWeek} == 3, "MGTZI DaylightDate wDayOfWeek");
    ok($tzi->{DaylightDate}{wDay} == 4, "MGTZI DaylightDate wDay");
    ok($tzi->{DaylightDate}{wHour} == 5, "MGTZI DaylightDate wHour");
    ok($tzi->{DaylightDate}{wMinute} == 6, "MGTZI DaylightDate wMinute");
    ok($tzi->{DaylightDate}{wSecond} == 7, "MGTZI DaylightDate wSecond");
    ok($tzi->{DaylightDate}{wMilliseconds} == 8, "MGTZI DaylightDate wMilliseconds");
    ok($tzi->{DaylightBias} == 3, "MGTZI DaylightBias");

    #make a fresh one
    $tzi = Win32::API::Struct->new('TIME_ZONE_INFORMATION');
    $tzi->{Bias} = 1;
    $tzi->{StandardName} = Encode::encode("UTF-16LE","vwxyzvwxyzvwxyzvwxyzvwxyzvwxyzwx");
    $tzi->{StandardDate}{wYear} = 1;
    $tzi->{StandardDate}{wMonth} = 2;
    $tzi->{StandardDate}{wDayOfWeek} = 3;
    $tzi->{StandardDate}{wDay} = 4;
    $tzi->{StandardDate}{wHour} = 5;
    $tzi->{StandardDate}{wMinute} = 6;
    $tzi->{StandardDate}{wSecond} = 7;
    $tzi->{StandardDate}{wMilliseconds} = 8;
    $tzi->{StandardBias} = 2;
    $tzi->{DaylightName} = Encode::encode("UTF-16LE","DAYLNDAYLNDAYLNDAYLNDAYLNDAYLNDA");
    $tzi->{DaylightDate}{wYear} = 1;
    $tzi->{DaylightDate}{wMonth} = 2;
    $tzi->{DaylightDate}{wDayOfWeek} = 3;
    $tzi->{DaylightDate}{wDay} = 4;
    $tzi->{DaylightDate}{wHour} = 5;
    $tzi->{DaylightDate}{wMinute} = 6;
    $tzi->{DaylightDate}{wSecond} = 7;
    $tzi->{DaylightDate}{wMilliseconds} = 8;
    $tzi->{DaylightBias} = 3;
    $function = Win32::API::More->new(
      $test_dll, 'DWORD WINAPI MySetTimeZoneInformation( LPTIME_ZONE_INFORMATION lpTimeZoneInformation );'
    );
    ok($function->Call($tzi), "MySetTimeZoneInformation call works");

    #test partial (null truncation) strings in arrays inline in a struct CPAN #92971
    Win32::API::Struct->typedef(ARR_IN_STRUCT => qw(
    unsigned int first;
    CHAR str [32];
    unsigned int last;
    ));
    $function = Win32::API::More->new(
      $test_dll, 'void __stdcall WriteArrayInStruct(ARR_IN_STRUCT* s)'
    );
    my $inlinearr = Win32::API::Struct->new('ARR_IN_STRUCT');
    $function->Call($inlinearr);
    ok($inlinearr->{first} == 0xFFFFFFFF, 'char inline array - member first');
    ok($inlinearr->{str} eq "12345123451234512345", 'char inline array - member str');
    ok($inlinearr->{last} == 0xFFFFFFFF, 'char inline array - member last');

    Win32::API::Struct->typedef(WARR_IN_STRUCT => qw(
    unsigned int first;
    WCHAR str [32];
    unsigned int last;
    ));
    $function = Win32::API::More->new(
      $test_dll, 'void __stdcall WriteWArrayInStruct(WARR_IN_STRUCT* s)'
    );
    $inlinearr = Win32::API::Struct->new('WARR_IN_STRUCT');
    $function->Call($inlinearr);
    ok($inlinearr->{first} == 0xFFFFFFFF, 'wchar inline array - member first');
    ok($inlinearr->{str} eq Encode::encode("UTF-16LE","12345123451234512345"), 'wchar inline array - member str');
    ok($inlinearr->{last} == 0xFFFFFFFF, 'wchar inline array - member last');
}
{
    my $s = "\x00\x00\x00\x00";
    Win32::API::_TruncateToWideNull($s);
    ok($s eq '', '_TruncateToWideNull just wide nulls');
    $s = "A\x00B\x00";
    Win32::API::_TruncateToWideNull($s);
    ok($s eq "A\x00B\x00", '_TruncateToWideNull no wide nulls');
    $s = '';
    Win32::API::_TruncateToWideNull($s);
    ok($s eq '', '_TruncateToWideNull empty string');
    $s = "A\x00B\x00\x00\x00\x00\x00";
    Win32::API::_TruncateToWideNull($s);
    ok($s eq "A\x00B\x00", '_TruncateToWideNull extra wide nulls');
}
