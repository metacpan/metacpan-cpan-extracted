#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'VM::Libvirt::CloneHelper' ) || print "Bail out!\n";
}

diag( "Testing VM::Libvirt::CloneHelper $VM::Libvirt::CloneHelper::VERSION, Perl $], $^X" );
