#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
plan( tests => 3 );

my $reg;
use Win32API::Registry 'regLastError';
use Win32::TieRegistry (
	Delimiter   => "/",
	ArrayValues => 1,
	TiedRef     => \$reg,
	":REG_", ":KEY_",
);

$reg = $reg->Open('', {Access => KEY_READ} ); # RT#102385

my $branch_reg = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Internet Explorer";
my $output = qx{reg query "$branch_reg" 2>&1};
my $error_code = $?;
SKIP: {
  $branch_reg =~ s#\\#/#g;
  skip("No $branch_reg - error $error_code", 3) if $error_code;
  $output =~ /\bVersion\s*REG_SZ\s*(.*)$/m or skip('No "Version" key', 3);
  my $val_ext = $1;

  my $val = $reg->{ "$branch_reg//Version" };

  ok( $val, "Opened $branch_reg" );
  is( REG_SZ, $val->[1], 'Type is REG_SZ' );
  is( $val->[0], $val_ext, 'Value matches expected' );
}
