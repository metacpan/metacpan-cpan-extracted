#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Sub::Util 'subname';

use lib "t";
use testcase "t::actions";

BEGIN { $^H{"t::actions/action"} = 1 }

{
   action name { "OK" }
   ok( name(), 'default actions parses like named sub' );
   ok( defined &name, '&name is on symbol table' );
   is( subname( \&name ), "main::name", '&name has subname' );
}

{
   my $code = action nameER { "OK" };
   ok( $code->(), 'RET_EXRP + REFGEN_ANONCODE behaves as anon sub' );
   ok( defined &nameER, '&nameER is on symbol table' );
   is( subname( $code ), "main::nameER", '$code has subname' );
}

{
   my $code = action nameiER { "OK" };
   ok( $code->(), 'Unininstalled CV is still invokable' );
   ok( !defined &nameiER, '&nameiER not on symbol table' );
   # CvNAME_HEK_set() doesn't work before perl 5.22
   is( subname( $code ), "main::nameiER", '$code still has a subname anyway' ) if $] >= 5.022;
}

done_testing;
