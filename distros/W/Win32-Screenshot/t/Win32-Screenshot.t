#!perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-Screenshot.t'

#########################

use Test;
BEGIN { plan tests => 11 };
use Win32::Screenshot qw(:all);
ok(1); # If we made it this far, we're ok.


my $fail;
foreach my $constname (qw(
	GW_CHILD GW_HWNDFIRST GW_HWNDLAST GW_HWNDNEXT GW_HWNDPREV GW_OWNER
	SW_HIDE SW_MAXIMIZE SW_MINIMIZE SW_RESTORE SW_SHOW SW_SHOWDEFAULT
	SW_SHOWMAXIMIZED SW_SHOWMINIMIZED SW_SHOWMINNOACTIVE SW_SHOWNA
	SW_SHOWNOACTIVATE SW_SHOWNORMAL)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Win32::Screenshot macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }
}

ok ( !$fail );

#########################

my @data;

@data = CaptureHwndRect( GetActiveWindow, -5, -5, 10, 10 );
ok( $data[0], 10 ); # width
ok( $data[1], 10 ); # height
ok( length $data[2], 10*10*4 ); # screen buffer length
ok( $data[2] & "\0\0\0\xFF"x(10*10), "\0\0\0\xFF"x(10*10) ); # screen buffer data

@data = CaptureHwndRect( GetActiveWindow, -5, -5, 5, 5 );
ok( $data[0], 5 ); # width
ok( $data[1], 5 ); # height
ok( length $data[2], 5*5*4 ); # screen buffer length
ok( $data[2], "\0\0\0\xFF"x(5*5) ); # screen buffer data


$out = JoinRawData( 3, 3, 3, "\x10\x20\x30\xFF"x9, "\x01\x02\x03\xFF"x9 );
ok( $out, ("\x10\x20\x30\xFF"x3 . "\x01\x02\x03\xFF"x3)x3 );