#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  t::Test::STDmaker::tgA1;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.06';
$DATE = '2004/05/22';
$FILE = __FILE__;

__DATA__

Name: t::Test::STDmaker::tgA1^
File_Spec: Unix^
UUT: Test::STDmaker::tg1^
Revision: -^
Version: 0.01^
End_User: General Public^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
STD2167_Template: ^
Detail_Template: ^
Classification: None^
Demo: tgA1.d^
Verify: tgA1.t^

 T: 0^

 C: 
    #########
    # For "TEST" 1.24 or greater that have separate std err output,
    # redirect the TESTERR to STDOUT
    #
    tech_config( 'Test.TESTERR', \*STDOUT );   
^  

QC: my $expected1 = 'hello world'; ^

 N: Quiet Code^
 A: 'hello world'^
 E: $expected1^

 N: ok subroutine^
TS: \&tolerance^
 A: 99^
 E: [100, 10]^

 N: skip subroutine^
 S: 0^
TS: \&tolerance^
 A: 80 ^
 E: [100, 10] ^

 N: Pass test^
 R: L<Test::STDmaker::tg1/capability-A [1]>^
 C: my $x = 2^
 C: my $y = 3^
 A: $x + $y^
SE: 5^

 N: Todo test that passes^
 U: xy feature^
 A: $y-$x^
 E: 1^

 R: 
    L<Test::STDmaker::tg1/capability-A [2]>
    L<Test::STDmaker::tg1/capability-B [1]>
 ^
 N: Test that fails^
 A: $x+4^
 E: 7^

 N: Skipped tests^
 S: 1^
 A: $x*$y*2^
 E: 6^

 N: Todo Test that Fails^
 U: zyw feature^
 S: 0^
 A: $x*$y*2^
 E: 6^

 N: demo only^
DO: ^
 A: $x^
 E: $y^

 N: verify only^
VO: ^
 A: $x^
 E: $x^

 N: Test loop^
 C:
    my @expected = ('200','201','202');
    my $i;
    for( $i=0; $i < 3; $i++) {
 ^

 A: $i+200^
 R: L<Test::STDmaker::tg1/capability-C [1]>^
 E: $expected[$i]^

 A: $i + ($x * 100)^
 R: L<Test::STDmaker::tg1/capability-B [4]>^
 E: $expected[$i]^

C:
    }
^

 N: Failed test that skips the rest^
 R: L<Test::STDmaker::tg1/capability-B [2]>^
 A: $x + $y^
SE: 6^

 N: A test to skip^
 A: $x + $y + $x^
 E: 9^

 N: A not skip to skip^
 S: 0^
 R: L<Test::STDmaker::tg1/capability-B [3]>^
 A: $x + $y + $x + $y^
 E: 10^

 N: A skip to skip^
 S: 1^
 R: L<Test::STDmaker::tg1/capability-B [3]>^
 A: $x + $y + $x + $y + $x^
 E: 10^

QC:
    sub tolerance
    {   
        my ($actual,$expected) = @_;
        my ($average, $tolerance) = @$expected;
        use integer;
        $actual = (($average - $actual) * 100) / $average;
        no integer;
        (-$tolerance < $actual) && ($actual < $tolerance) ? 1 : 0;
    }
^

See_Also: L<Test::STDmaker::tg1> ^

Copyright: This STD is public domain.^

HTML: ^

~-~