#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  t::Test::STDmaker::tgB1;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.04';
$DATE = '2004/05/23';
$FILE = __FILE__;

########
# The Test::STDmaker module uses the data after the __DATA__ 
# token to automatically generate the this file.
#
# Do not edit anything before __DATA_. Edit instead
# the data after the __DATA__ token.
#
# ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
#
# the next time Test::STDmaker generates this file.
#
#


=head1 NAME

t::Test::STDmaker::tgB1 - Software Test Description for Test::STDmaker::tg1

=head1 TITLE PAGE

 Detailed Software Test Description (STD)

 for

 Perl Test::STDmaker::tg1 Program Module

 Revision: -

 Version: 0.01

 Date: 2004/05/23

 Prepared for: General Public 

 Prepared by:  http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com

 Classification: None

#######
#  
#  1. SCOPE
#
#
=head1 SCOPE

This detail STD and the 
L<General Perl Program Module (PM) STD|Test::STD::PerlSTD>
establishes the tests to verify the
requirements of Perl Program Module (PM) L<Test::STDmaker::tg1|Test::STDmaker::tg1>
The format of this STD is a tailored L<2167A STD DID|Docs::US_DOD::STD>.

#######
#  
#  3. TEST PREPARATIONS
#
#
=head1 TEST PREPARATIONS

Test preparations are establishes by the L<General STD|Test::STD::PerlSTD>.


#######
#  
#  4. TEST DESCRIPTIONS
#
#
=head1 TEST DESCRIPTIONS

The test descriptions uses a legend to
identify different aspects of a test description
in accordance with
L<STD PM Form Database Test Description Fields|Test::STDmaker/STD PM Form Database Test Description Fields>.

=head2 Test Plan

 T: 2^

=head2 ok: 1


  C:
     #########
     # For "TEST" 1.24 or greater that have separate std err output,
     # redirect the TESTERR to STDOUT
     #
     tech_config( 'Test.TESTERR', \*STDOUT );
 ^
  R: L<Test::STDmaker::tg1/capability-A [1]>^
  C: my $x = 2^
  C: my $y = 3^
  A: $x + $y^
 SE: 5^
 ok: 1^

=head2 ok: 2

  A: [($x+$y,$y-$x)]^
  E: [5,2]^
 ok: 2^



#######
#  
#  5. REQUIREMENTS TRACEABILITY
#
#

=head1 REQUIREMENTS TRACEABILITY

  Requirement                                                      Test
 ---------------------------------------------------------------- ----------------------------------------------------------------
 L<Test::STDmaker::tg1/capability-A [1]>                          L<t::Test::STDmaker::tgB1/ok: 1>


  Test                                                             Requirement
 ---------------------------------------------------------------- ----------------------------------------------------------------
 L<t::Test::STDmaker::tgB1/ok: 1>                                 L<Test::STDmaker::tg1/capability-A [1]>


=cut

#######
#  
#  6. NOTES
#
#

=head1 NOTES

This STD is public domain

#######
#
#  2. REFERENCED DOCUMENTS
#
#
#

=head1 SEE ALSO

L<Test::STDmaker::tg1>

=back

=for html
<hr>
<!-- /BLK -->
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>

=cut

__DATA__

Name: t::Test::STDmaker::tgB1^
File_Spec: Unix^
UUT: Test::STDmaker::tg1^
Revision: -^
Version: 0.01^
End_User: General Public^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
STD2167_Template: ^
Detail_Template: ^
Classification: None^
Temp: temp.pl^
Demo: tgB1.d^
Verify: tgB1.t^


 T: 2^


 C:
    #########
    # For "TEST" 1.24 or greater that have separate std err output,
    # redirect the TESTERR to STDOUT
    #
    tech_config( 'Test.TESTERR', \*STDOUT );
^

 R: L<Test::STDmaker::tg1/capability-A [1]>^
 C: my $x = 2^
 C: my $y = 3^
 A: $x + $y^
SE: 5^
ok: 1^

 A: [($x+$y,$y-$x)]^
 E: [5,2]^
ok: 2^


See_Also: L<Test::STDmaker::tg1>^
Copyright: This STD is public domain^

HTML:
<hr>
<!-- /BLK -->
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>
^



~-~
