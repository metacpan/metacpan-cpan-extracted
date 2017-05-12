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
$VERSION = '0.02';
$DATE = '2004/05/18';
$FILE = __FILE__;

########
# The Test::STDmaker module uses the data after the __DATA__ 
# token to automatically generate the this file.
#
# Don't edit anything before __DATA_. Edit instead
# the data after the __DATA__ token.
#
# ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
#
# the next time Test::STDmaker generates this file.
#
#

__DATA__

Name: t::Test::STDmaker::tgB1^
File_Spec: Unix^
UUT: Test::STDmaker::tg1^
Revision: -^
End_User: General Public^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
Detail_Template: ^
STD2167_Template: ^
Version: 0.01^
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
