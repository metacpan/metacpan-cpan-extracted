# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'
#########################
use strict;
use Test;
BEGIN { plan tests => 12 }
#########################
use FindBin;
use X12::Parser::Cf;

#setup
my $sample_cf = "$FindBin::RealBin/../cf/837_004010X098.cf";
my $cf        = X12::Parser::Cf->new();
my $root      = $cf->load( file => $sample_cf );
my ( $svalue, $ivalue, $node, $array );

#test
$ivalue = $root->get_child_count;
ok( $ivalue, 11 );

#test
$svalue = $root->get_name;
ok( $svalue, 'X12' );

#test
$node   = $root->get_child(7);
$svalue = $node->get_name;
ok( $svalue, '2000C' );

#test
$ivalue = $node->get_child_count;
ok( $ivalue, 2 );

#test
$svalue = $node->{_SEG};
ok( $svalue, 'HL' );

#test
$ivalue = $node->{_SEG_QUAL_POS};
ok( $ivalue, 3 );

#test
$array = $node->{_SEG_QUAL};
ok( @{$array}[0], '23' );

#test
$node   = $node->get_child(1);
$svalue = $node->get_name;
ok( $svalue, '2300' );

#test
$ivalue = $node->get_child_count;
ok( $ivalue, 8 );

#test
$node   = $node->get_child(7);
$svalue = $node->get_name;
ok( $svalue, '2400' );

#test
$ivalue = $node->get_child_count;
ok( $ivalue, 9 );

#test
$ivalue = $node->get_depth;
ok( $ivalue, 3 );
