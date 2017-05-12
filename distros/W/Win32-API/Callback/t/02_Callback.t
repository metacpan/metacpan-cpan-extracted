##!perl -w

# $Id: test.t,v 1.0 2001/10/30 13:57:31 dada Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use Config;
use Test::More;
use Math::Int64 qw( int64 hex_to_uint64 uint64_to_hex);
plan tests => 20;
use vars qw(
    $function
    $result
    $callback
    $test_dll
);

BEGIN {
    eval "sub PTR_SIZE () { ".length(pack(($] <= 5.007002 ? 'L':'J'),0))." }";
    push(@INC, '..'); #for W32ATest
}
use_ok('Win32::API');
use_ok('Win32::API::Callback');
use W32ATest;


ok(1, 'loaded');

$test_dll = Win32::API::Test::find_test_dll();
ok(-e $test_dll, 'found API_Test.dll');

my $cc_name = Win32::API::Test::compiler_name();
my $cc_vers = Win32::API::Test::compiler_version();
my $callback;

diag('Compiler name:',    $cc_name);
diag('Compiler version:', $cc_vers);

    $callback = Win32::API::Callback->new(
        sub {
            my ($value) = @_;
            die 'incorrect @_ count to the Perl Callback' if @_ != 1;
            return $value * 2;
        },
        'N',
        'N'
    );
    ok($callback, 'callback function defined');

    $function = new Win32::API($test_dll, 'do_callback', 'KI', 'I');
    ok(defined($function), 'defined function do_callback()');
    diag('$^E=', $^E);


    $result = $function->Call($callback, 21);
    is($result, 42, 'callback function works');

$callback = Win32::API::Callback->new(
    sub {
        #print Dumper(\@_);
        #$DB::single = 1;
        die 'incorrect @_ count to the Perl Callback' if @_ != 5;
        my $chr = $_[0];
        $chr = $_[0] & 0xFF; #x64 fill high bits with garbage
        die "bad char" if chr($chr) ne 'P';
        if(PTR_SIZE == 4){
            my ($low,$high) = unpack(IV_LET.IV_LET, $_[1]);
            die "bad unsigned int64" if $low != 0xABCDEF12;
            die "bad unsigned int64" if $high != 0x12345678;
        }else{
            print "0x".unpack('H[16]', $_[1])."\n";
            no warnings 'portable', 'overflow'; #silence on 32 bits
            die "bad unsigned int64" if $_[1] != eval "0x12345678ABCDEF12";
        }
        my $f4char = unpack('P4',pack(IV_LET,$_[2]));
        die "bad 4 char struct \"$f4char\"" if $f4char ne "JAPH";
        die "bad float" if $_[3] != 2.5;
        die "bad double" if $_[4] != 3.5;
        return 70000;
    },
    'I'. #the char
    'Q'. #the int 64
    'N'. #the pointer to 4 char struct
    'F'. #the float
    'D', #the double
    'N' #out type
);

$function = new Win32::API($test_dll, 'do_callback_5_param', 'K', 'N');
$result = $function->Call($callback);
is($result, 70000, "do_callback_5_param was successful");

SKIP: {
    skip('only 32 bit Perl uses Math::Int64', 5) if PTR_SIZE != 4;
    $callback = Win32::API::Callback->new(
        sub {
            #print Dumper(\@_);
            #$DB::single = 1;
            die 'incorrect @_ count to the Perl Callback' if @_ != 5;
            my $chr = $_[0];
            $chr = $_[0] & 0xFF; #x64 fill high bits with garbage
            die "bad char" if chr($chr) ne 'P';
            die "bad unsigned int64" if $_[1] != hex_to_uint64("0x12345678ABCDEF12");
            my $f4char = unpack('P4',pack(IV_LET,$_[2]));
            die "bad 4 char struct" if $f4char ne "JAPH";
            die "bad float" if $_[3] != 2.5;
            die "bad double" if $_[4] != 3.5;
            return 70000;
        },
        'I'. #the char
        'Q'. #the int 64
        'N'. #the pointer to 4 char struct
        'F'. #the float
        'D', #the double
        'N' #out type
    );
    
    $callback->UseMI64(1);
    $function = new Win32::API($test_dll, 'do_callback_5_param', 'K', 'N');
    $result = $function->Call($callback);
    is($result, 70000, "do_callback_5_param with Math::Int64 was successful");

    $callback = Win32::API::Callback->new(
    sub {
        #print Dumper(\@_);
        ok(@_ == 0,  "@_ should be empty");
        return hex_to_uint64("0x8000200030004000");
    },
    '', #nothing
    'Q' #out type
    );
    $function = new Win32::API::More($test_dll, 'do_callback_void_q', 'K', 'Q');
    $function->UseMI64(1);
    $callback->UseMI64(1);
    $result = $function->Call($callback);
    print uint64_to_hex($result)." ".uint64_to_hex(hex_to_uint64("0x8000200030004000"))."\n";
    is($result,
       hex_to_uint64("0x8000200030004000")
       , "do_callback_void_q with Math::Int64 was successful");
    #test that UseMI64 is not required for "out" params in Callback
    $callback->UseMI64(0);#use automatic MI64 "out" recoginition added in v0.71
    $result = $function->Call($callback);
    print uint64_to_hex($result)." ".uint64_to_hex(hex_to_uint64("0x8000200030004000"))."\n";
    is($result,
       hex_to_uint64("0x8000200030004000")
       , "do_callback_void_q with Math::Int64 was successful");

}#end of skip

$callback = Win32::API::Callback->new(
    sub {
        #print Dumper(\@_);
        #$DB::single = 1;
        die 'incorrect @_ count to the Perl Callback' if @_ != 5;
        my $chr = $_[0];
        $chr = $_[0] & 0xFF;
        die "bad char" if chr($chr) ne 'P';
        if(PTR_SIZE == 4){
            my ($low,$high) = unpack(IV_LET.IV_LET, $_[1]);
            die "bad unsigned int64" if $low != 0xABCDEF12;
            die "bad unsigned int64" if $high != 0x12345678;
        }else{
            no warnings 'portable', 'overflow'; #silence on 32 bits
            die "bad unsigned int64" if $_[1] != 0x12345678ABCDEF12;
        }
        my $f4char; 
        $f4char = unpack('P4',pack(IV_LET,$_[2]));
        die "bad 4 char struct" if $f4char ne "JAPH";
        die "bad float" if $_[3] != 2.5;
        die "bad double" if $_[4] != 3.5;
        return 90000;
    },
    'I'. #the char
    'Q'. #the int 64
    'N'. #the 4 char pointer
    'F'.#the float
    'D',#the double
    'N', #out type
    '__cdecl'
);
$function = new Win32::API($test_dll, 'do_callback_5_param_cdec', 'K', 'N');
$result = $function->Call($callback);
is($result, 90000, "do_callback_5_param_cdec was successful");


$callback = Win32::API::Callback->new(
    sub {
        #print Dumper(\@_);
        ok(@_ == 0,  "@_ should be empty");
        return 9876.5432;
    },
    '', #nothing
    'D' #out type
);
$function = new Win32::API($test_dll, 'do_callback_void_d', 'K', 'D');
$result = $function->Call($callback);
is($result, 9876.5432, "do_callback_void_d was successful");

$callback = Win32::API::Callback->new(
    sub {
        #print Dumper(\@_);
        ok(@_ == 0,  "@_ should be empty");
        return 2345.6789;
    },
    '', #nothing
    'F' #out type
);
$function = new Win32::API($test_dll, 'do_callback_void_f', 'K', 'F');
$result = $function->Call($callback);
#without the packs rounding errors cause a fail due to float to double casting
is(pack('f',$result), pack('f', 2345.6789), "do_callback_void_f was successful");


$callback = Win32::API::Callback->new(
    sub {
        #print Dumper(\@_);
        ok(@_ == 0,  "@_ should be empty");
        if(PTR_SIZE == 4){
            return pack(IV_LET.IV_LET, 0x30004000, 0x80002000);
        }
        else{
            no warnings 'portable', 'overflow'; #silence on 32 bits
            return 0x8000200030004000;
        }
    },
    '', #nothing
    'Q' #out type
);
$function = new Win32::API::More($test_dll, 'do_callback_void_q', 'K', 'Q');
$result = $function->Call($callback);

{
    no warnings 'portable', 'overflow'; #silence on 32 bits
    is($result,
       PTR_SIZE == 4 ? pack(IV_LET.IV_LET, 0x30004000, 0x80002000) : 0x8000200030004000
       , "do_callback_void_q was successful");
}
#
# End of tests
