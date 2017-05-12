# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'
#########################
use strict;
use Test;
BEGIN { plan tests => 1 }
#########################
use FindBin;
use X12::Parser;

#setup
my ( $result, $expected_result );
my $sample_file = "$FindBin::RealBin/sample_835.txt";
my $sample_cf   = "$FindBin::RealBin/../cf/835_004010X091.cf";

$expected_result = <<EOF;
         |--ISA
      1  |  |-- ISA*00*          *00*          *ZZ*USERNAME       *ZZ*PASSWORD       *030620*0730*U*00401*000000001*0*T*:
         |--GS
      2  |  |-- GS*TEST*TEST
         |--ST
      3  |  |-- ST*835*1234
      4  |  |-- BPR*A*A*A*A*A*A*A*A*A*A
      5  |  |-- TRN*1*12345*12345
      6  |  |-- DTM*111*20020916
         |--1000A
      7  |  |-- N1*PR*ALWAYS INSURANCE COMPANY
      8  |  |-- N7*1 MAIN STREET
      9  |  |-- N4*ALWAYS*YOURS*00001
     10  |  |-- REF*B*B*00001
         |--1000B
     11  |  |-- N1*PE*NEW HOSPITAL*B*127456789
         |--2000
     12  |  |-- LX*1
     13  |  |-- TS7*BTEST*BTEST*BTEST*BTEST*BTEST*BTEST
     14  |  |-- TS2*CTEST*CTEST*CTEST*CTEST
         |  |--2100
     15  |  |  |-- CLP*DTEST*DTEST*DTEST*DTEST*DTEST
     16  |  |  |-- CAS*ETEST*ETEST*ETEST
     17  |  |  |-- NM1*QC*1*LN*FN*M****1234567
     18  |  |  |-- MIA*0*0*0
     19  |  |  |-- DTM*272*20020816
     20  |  |  |-- DTM*273*20020824
     21  |  |  |-- QTY*A*5
         |--2000
     22  |  |-- LX*2
     23  |  |-- TS7*GTEST*GTEST*GTEST*GTEST*GTEST*GTEST*GTEST*GTEST
         |  |--2100
     24  |  |  |-- CLP*HTEST*HTEST*HTEST*HTEST*HTEST*HTEST*HTEST*HTEST
     25  |  |  |-- CAS*ITEST*ITEST*ITEST
     26  |  |  |-- NM1*QC*1*LN*FN*M****123456789
     27  |  |  |-- MOA*0*0*0
     28  |  |  |-- DTM*272*20020512
     29  |  |  |-- PLB*JTEST*JTEST*JTEST*JTEST
         |--SE
     30  |  |-- SE*1*1234
         |--GE
     31  |  |-- GE*1*TEST
         |--IEA
     32  |  |-- IEA*1*000000001
EOF


#create a parser instance
my $p = new X12::Parser;
$p->parsefile( file => $sample_file, conf => $sample_cf );

#test 1
$result = $p->_print_tree;
ok( $result, $expected_result );
