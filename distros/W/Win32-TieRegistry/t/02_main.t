#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
if ( $^O eq 'MSWin32' or $^O eq 'cygwin' ) {
	plan( tests => 8 );
} else {
	plan( skip_all => 'Not testing on non-Windows' );
}

my $reg;
use Win32API::Registry 'regLastError';
use Win32::TieRegistry (
	Delimiter   => "/",
	ArrayValues => 1,
	TiedRef     => \$reg,
	":REG_", ":KEY_",
);

$reg = $reg->Open('', {Access => KEY_READ} ); # RT#102385

my $branch_reg = 'HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer';
my $output = qx{reg query "$branch_reg" 2>&1};
my $error_code = $?;
SKIP: {
  my $branch = "CUser/Software/Microsoft/Windows/CurrentVersion/Policies/Explorer";
  my $val = $reg->{ "$branch//NoDriveTypeAutoRun" };
  skip('No NoDriveTypeAutoRun', 3) if $error_code || $output !~ /NoDriveTypeAutoRun\s*REG_DWORD/;

  ok( $val, 'Opened CU/SW/MS/Win/CV/Pol/Exp//NoDriveTypeAutoRun' );
  is( REG_DWORD, $val->[1], 'Type is REG_DWORD' );
  like( $val->[0], qr/^0x[\da-f]{8}$/i, 'Value matches expected' );
}

$branch_reg = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Management\System Programs';
$output = qx{reg query "$branch_reg" 2>&1};
$error_code = $?;
ok(!$error_code);
$output =~ /\biexplore\s*REG_SZ\s*(.*)$/m;
my $ie_value = $1;
ok($ie_value);
$branch_reg =~ s#\\#/#g;

my $val = $reg->{ "$branch_reg//iexplore" };
ok( $val, 'Opened App Management\System Programs' );
is( REG_SZ, $val->[1], 'Type is REG_SZ' );
is( $val->[0], $ie_value, 'Value matches expected' );
