#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  t::Tie::Form;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.01';
$DATE = '2004/05/09';
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


=head1 TITLE PAGE

 Detailed Software Test Description (STD)

 for

 Perl Tie::Form Program Module

 Revision: -

 Version: 

 Date: 2004/05/09

 Prepared for: General Public 

 Prepared by:  http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com

 Classification: None

=head1 SCOPE

This detail STD and the 
L<General Perl Program Module (PM) STD|Test::STD::PerlSTD>
establishes the tests to verify the
requirements of Perl Program Module (PM) L<Tie::Form|Tie::Form>

The format of this STD is a tailored L<2167A STD DID|Docs::US_DOD::STD>.
in accordance with 
L<Detail STD Format|Test::STDmaker/Detail STD Format>.

#######
#  
#  4. TEST DESCRIPTIONS
#
#  4.1 Test 001
#
#  ..
#
#  4.x Test x
#
#

=head1 TEST DESCRIPTIONS

The test descriptions uses a legend to
identify different aspects of a test description
in accordance with
L<STD FormDB Test Description Fields|Test::STDmaker/STD FormDB Test Description Fields>.

=head2 Test Plan

 T: 7^

=head2 ok: 1


  C:
     use File::Package;
     use File::SmartNL;
     use File::Spec;
     my $uut = 'Tie::Form'; # Unit Under Test
     my $fp = 'File::Package';
     my $loaded;
     my (@fields);  # force context
     my $out_file = File::Spec->catfile('_Form_','form1.txt');;
     unlink $out_file;
     my $lenient_in_file = File::Spec->catfile('_Form_','lenient0.txt');
     my $strict_in_file = File::Spec->catfile('_Form_','strict0.txt');
     my $version = $Tie::Form::VERSION;
     $version = '' unless $version;
 ^

 QC:
 ######
 # Not needed for demo, so use the Quiet Code (QC) 
 # 
 my $lenient_expected_file = File::Spec->catfile('_Form_','lenient2.txt');
 my $strict_expected_file = File::Spec->catfile('_Form_','lenient2.txt');
 my @test_data1 = (
 [
   'UUT',
   'File/Version.pm',
   'File_Spec',
   '',
   'Revision',
   '',
   'End_User',
   '',
   'Author',
   'http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com',
   'SVD',
   'SVD::DataCop-DataFile',
   'Template',
   'STD/STD001.frm',
 ],
 [
    'Email',
    'nobody@hotmail.com',
    'Form',
    'Udo-fully processed oils',
    'Tutorial',
    '*~~* Better Health thru Biochemistry *~~*',
    'REMOTE_ADDR',
    '213.158.186.150',
    'HTTP_USER_AGENT',
    'Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)',
    'HTTP_REFERER',
    'http://computerdiamonds.com/',
 ],
   
 [   'EOF',
      '\n',
     'EOL',
     '\n^^\n',
     'EOV',
     '}',
     'SOV',
     '${'
 ],
 [  'EOF', 
     '^^',
    'EOL',
     '~-~',
     'SOV',
     '${',
     'EOV',
     '}'
 ],
 [   'EOF', 
     '^^^',
     'EOL',
      '~---~',   
      'SOV',
      '${',
      'EOV',
      '}',
 ]
 );
 ^
 VO: ^
  N: UUT not loaded^
  A: $loaded = $fp->is_package_loaded($uut)^
 SE:  ''^
 ok: 1^

=head2 ok: 2

  N: Load UUT^
  C: my $errors = $fp->load_package($uut)^
  A: $errors^
 SE: ''^
 ok: 2^

=head2 ok: 3

  N: Tie::Form Version $version loaded^
  A: $fp->is_package_loaded($uut)^
  E: 1^
 ok: 3^

=head2 ok: 4

  N: Read lenient Form^

  R:
      L<Tie::Form/format [1] - separator strings>
      L<Tie::Form/format [2] - separator escapes>
      L<Tie::Form/format [3] - field names>
      L<Tie::Form/format [4] - field names>
      L<Tie::Form/format [5] - EON>
      L<Tie::Form/format [7] - Lenient EOD>
      L<Tie::Form/methods [2] - decode_field>
      L<Tie::Form/methods [4] - decode_record>
      L<Tie::Form/methods [6] - get_record>
      L<Tie::Form/methods [7] - get_record>
 ^

  C:
     tie *FORM, 'Tie::Form';
     open FORM,'<',File::Spec->catfile($lenient_in_file);
     @fields = <FORM>;
     close FORM;
 ^
  A: [@fields]^
  E: [@test_data1]^
 ok: 4^

=head2 ok: 5

  N: Write lenient Form^

  R:
      L<Tie::Form/format [1] - separator strings>
      L<Tie::Form/format [2] - separator escapes>
      L<Tie::Form/format [3] - field names>
      L<Tie::Form/format [4] - field names>
      L<Tie::Form/format [5] - EON>
      L<Tie::Form/format [7] - Lenient EOD>
      L<Tie::Form/methods [1] - encode_field>
      L<Tie::Form/methods [3] - encode_record>
      L<Tie::Form/methods [5] - put_record>
 ^

  C:
     open FORM, '>', $out_file;
     print FORM @fields;
     close FORM;
 ^
  A: File::SmartNL->fin($out_file)^
  E: File::SmartNL->fin($lenient_expected_file)^
 ok: 5^

=head2 ok: 6

  N: Read strict Form^

  R:
      L<Tie::Form/format [1] - separator strings>
      L<Tie::Form/format [2] - separator escapes>
      L<Tie::Form/format [3] - field names>
      L<Tie::Form/format [4] - field names>
      L<Tie::Form/format [5] - EON>
      L<Tie::Form/format [6] - Strict EOD>
      L<Tie::Form/methods [2] - decode_field>
      L<Tie::Form/methods [4] - decode_record>
      L<Tie::Form/methods [6] - get_record>
      L<Tie::Form/methods [7] - get_record>
 ^

  C:
     tie *FORM, 'Tie::Form';
     open FORM,'<',File::Spec->catfile($strict_in_file);
     @fields = <FORM>;
     close FORM;
 ^
  A: [@fields]^
  E: [@test_data1]^
 ok: 6^

=head2 ok: 7

  N: Write strict Form^

  R:
      L<Tie::Form/format [1] - separator strings>
      L<Tie::Form/format [2] - separator escapes>
      L<Tie::Form/format [3] - field names>
      L<Tie::Form/format [4] - field names>
      L<Tie::Form/format [5] - EON>
      L<Tie::Form/format [6] - Strict EOD>
      L<Tie::Form/methods [1] - encode_field>
      L<Tie::Form/methods [3] - encode_record>
      L<Tie::Form/methods [5] - put_record>
 ^

  C:
     open FORM, '>', $out_file;
     print FORM @fields;
     close FORM;
 ^
  A: File::SmartNL->fin($out_file)^
  E: File::SmartNL->fin($strict_expected_file)^
 ok: 7^



#######
#  
#  5. REQUIREMENTS TRACEABILITY
#
#

=head1 REQUIREMENTS TRACEABILITY

  Requirement                                                      Test
 ---------------------------------------------------------------- ----------------------------------------------------------------
 L<Tie::Form/format [1] - separator strings>                      L<t::Tie::Form/ok: 4>
 L<Tie::Form/format [1] - separator strings>                      L<t::Tie::Form/ok: 5>
 L<Tie::Form/format [1] - separator strings>                      L<t::Tie::Form/ok: 6>
 L<Tie::Form/format [1] - separator strings>                      L<t::Tie::Form/ok: 7>
 L<Tie::Form/format [2] - separator escapes>                      L<t::Tie::Form/ok: 4>
 L<Tie::Form/format [2] - separator escapes>                      L<t::Tie::Form/ok: 5>
 L<Tie::Form/format [2] - separator escapes>                      L<t::Tie::Form/ok: 6>
 L<Tie::Form/format [2] - separator escapes>                      L<t::Tie::Form/ok: 7>
 L<Tie::Form/format [3] - field names>                            L<t::Tie::Form/ok: 4>
 L<Tie::Form/format [3] - field names>                            L<t::Tie::Form/ok: 5>
 L<Tie::Form/format [3] - field names>                            L<t::Tie::Form/ok: 6>
 L<Tie::Form/format [3] - field names>                            L<t::Tie::Form/ok: 7>
 L<Tie::Form/format [4] - field names>                            L<t::Tie::Form/ok: 4>
 L<Tie::Form/format [4] - field names>                            L<t::Tie::Form/ok: 5>
 L<Tie::Form/format [4] - field names>                            L<t::Tie::Form/ok: 6>
 L<Tie::Form/format [4] - field names>                            L<t::Tie::Form/ok: 7>
 L<Tie::Form/format [5] - EON>                                    L<t::Tie::Form/ok: 4>
 L<Tie::Form/format [5] - EON>                                    L<t::Tie::Form/ok: 5>
 L<Tie::Form/format [5] - EON>                                    L<t::Tie::Form/ok: 6>
 L<Tie::Form/format [5] - EON>                                    L<t::Tie::Form/ok: 7>
 L<Tie::Form/format [6] - Strict EOD>                             L<t::Tie::Form/ok: 6>
 L<Tie::Form/format [6] - Strict EOD>                             L<t::Tie::Form/ok: 7>
 L<Tie::Form/format [7] - Lenient EOD>                            L<t::Tie::Form/ok: 4>
 L<Tie::Form/format [7] - Lenient EOD>                            L<t::Tie::Form/ok: 5>
 L<Tie::Form/methods [1] - encode_field>                          L<t::Tie::Form/ok: 5>
 L<Tie::Form/methods [1] - encode_field>                          L<t::Tie::Form/ok: 7>
 L<Tie::Form/methods [2] - decode_field>                          L<t::Tie::Form/ok: 4>
 L<Tie::Form/methods [2] - decode_field>                          L<t::Tie::Form/ok: 6>
 L<Tie::Form/methods [3] - encode_record>                         L<t::Tie::Form/ok: 5>
 L<Tie::Form/methods [3] - encode_record>                         L<t::Tie::Form/ok: 7>
 L<Tie::Form/methods [4] - decode_record>                         L<t::Tie::Form/ok: 4>
 L<Tie::Form/methods [4] - decode_record>                         L<t::Tie::Form/ok: 6>
 L<Tie::Form/methods [5] - put_record>                            L<t::Tie::Form/ok: 5>
 L<Tie::Form/methods [5] - put_record>                            L<t::Tie::Form/ok: 7>
 L<Tie::Form/methods [6] - get_record>                            L<t::Tie::Form/ok: 4>
 L<Tie::Form/methods [6] - get_record>                            L<t::Tie::Form/ok: 6>
 L<Tie::Form/methods [7] - get_record>                            L<t::Tie::Form/ok: 4>
 L<Tie::Form/methods [7] - get_record>                            L<t::Tie::Form/ok: 6>


  Test                                                             Requirement
 ---------------------------------------------------------------- ----------------------------------------------------------------
 L<t::Tie::Form/ok: 4>                                            L<Tie::Form/format [1] - separator strings>
 L<t::Tie::Form/ok: 4>                                            L<Tie::Form/format [2] - separator escapes>
 L<t::Tie::Form/ok: 4>                                            L<Tie::Form/format [3] - field names>
 L<t::Tie::Form/ok: 4>                                            L<Tie::Form/format [4] - field names>
 L<t::Tie::Form/ok: 4>                                            L<Tie::Form/format [5] - EON>
 L<t::Tie::Form/ok: 4>                                            L<Tie::Form/format [7] - Lenient EOD>
 L<t::Tie::Form/ok: 4>                                            L<Tie::Form/methods [2] - decode_field>
 L<t::Tie::Form/ok: 4>                                            L<Tie::Form/methods [4] - decode_record>
 L<t::Tie::Form/ok: 4>                                            L<Tie::Form/methods [6] - get_record>
 L<t::Tie::Form/ok: 4>                                            L<Tie::Form/methods [7] - get_record>
 L<t::Tie::Form/ok: 5>                                            L<Tie::Form/format [1] - separator strings>
 L<t::Tie::Form/ok: 5>                                            L<Tie::Form/format [2] - separator escapes>
 L<t::Tie::Form/ok: 5>                                            L<Tie::Form/format [3] - field names>
 L<t::Tie::Form/ok: 5>                                            L<Tie::Form/format [4] - field names>
 L<t::Tie::Form/ok: 5>                                            L<Tie::Form/format [5] - EON>
 L<t::Tie::Form/ok: 5>                                            L<Tie::Form/format [7] - Lenient EOD>
 L<t::Tie::Form/ok: 5>                                            L<Tie::Form/methods [1] - encode_field>
 L<t::Tie::Form/ok: 5>                                            L<Tie::Form/methods [3] - encode_record>
 L<t::Tie::Form/ok: 5>                                            L<Tie::Form/methods [5] - put_record>
 L<t::Tie::Form/ok: 6>                                            L<Tie::Form/format [1] - separator strings>
 L<t::Tie::Form/ok: 6>                                            L<Tie::Form/format [2] - separator escapes>
 L<t::Tie::Form/ok: 6>                                            L<Tie::Form/format [3] - field names>
 L<t::Tie::Form/ok: 6>                                            L<Tie::Form/format [4] - field names>
 L<t::Tie::Form/ok: 6>                                            L<Tie::Form/format [5] - EON>
 L<t::Tie::Form/ok: 6>                                            L<Tie::Form/format [6] - Strict EOD>
 L<t::Tie::Form/ok: 6>                                            L<Tie::Form/methods [2] - decode_field>
 L<t::Tie::Form/ok: 6>                                            L<Tie::Form/methods [4] - decode_record>
 L<t::Tie::Form/ok: 6>                                            L<Tie::Form/methods [6] - get_record>
 L<t::Tie::Form/ok: 6>                                            L<Tie::Form/methods [7] - get_record>
 L<t::Tie::Form/ok: 7>                                            L<Tie::Form/format [1] - separator strings>
 L<t::Tie::Form/ok: 7>                                            L<Tie::Form/format [2] - separator escapes>
 L<t::Tie::Form/ok: 7>                                            L<Tie::Form/format [3] - field names>
 L<t::Tie::Form/ok: 7>                                            L<Tie::Form/format [4] - field names>
 L<t::Tie::Form/ok: 7>                                            L<Tie::Form/format [5] - EON>
 L<t::Tie::Form/ok: 7>                                            L<Tie::Form/format [6] - Strict EOD>
 L<t::Tie::Form/ok: 7>                                            L<Tie::Form/methods [1] - encode_field>
 L<t::Tie::Form/ok: 7>                                            L<Tie::Form/methods [3] - encode_record>
 L<t::Tie::Form/ok: 7>                                            L<Tie::Form/methods [5] - put_record>


=cut

#######
#  
#  6. NOTES
#
#

=head1 NOTES

copyright © 2004 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.

#######
#
#  2. REFERENCED DOCUMENTS
#
#
#

=head1 SEE ALSO

L<Tie::Layers>

=back

=for html


=cut

__DATA__

File_Spec: Unix^
UUT: Tie::Form^
Revision: -^
End_User: General Public^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
Detail_Template: ^
STD2167_Template: ^
Version: ^
Classification: None^
Temp: temp.pl^
Demo: Form.d^
Verify: Form.t^


 T: 7^


 C:
    use File::Package;
    use File::SmartNL;
    use File::Spec;

    my $uut = 'Tie::Form'; # Unit Under Test
    my $fp = 'File::Package';
    my $loaded;

    my (@fields);  # force context
    my $out_file = File::Spec->catfile('_Form_','form1.txt');;
    unlink $out_file;

    my $lenient_in_file = File::Spec->catfile('_Form_','lenient0.txt');
    my $strict_in_file = File::Spec->catfile('_Form_','strict0.txt');

    my $version = $Tie::Form::VERSION;
    $version = '' unless $version;
^


QC:
######
# Not needed for demo, so use the Quiet Code (QC) 
# 
my $lenient_expected_file = File::Spec->catfile('_Form_','lenient2.txt');
my $strict_expected_file = File::Spec->catfile('_Form_','lenient2.txt');

my @test_data1 = (
[
  'UUT',
  'File/Version.pm',
  'File_Spec',
  '',
  'Revision',
  '',
  'End_User',
  '',
  'Author',
  'http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com',
  'SVD',
  'SVD::DataCop-DataFile',
  'Template',
  'STD/STD001.frm',
],

[
   'Email',
   'nobody@hotmail.com',
   'Form',
   'Udo-fully processed oils',
   'Tutorial',
   '*~~* Better Health thru Biochemistry *~~*',
   'REMOTE_ADDR',
   '213.158.186.150',
   'HTTP_USER_AGENT',
   'Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)',
   'HTTP_REFERER',
   'http://computerdiamonds.com/',
],
  
[   'EOF',
     '\n',
    'EOL',
    '\n^^\n',
    'EOV',
    '}',
    'SOV',
    '${'
],

[  'EOF', 
    '^^',
   'EOL',
    '~--~',
    'SOV',
    '${',
    'EOV',
    '}'
],

[   'EOF', 
    '^^^',
    'EOL',
     '~----~',   
     'SOV',
     '${',
     'EOV',
     '}',
]

);
^

VO: ^
 N: UUT not loaded^
 A: $loaded = $fp->is_package_loaded($uut)^
SE:  ''^
ok: 1^

 N: Load UUT^
 C: my $errors = $fp->load_package($uut)^
 A: $errors^
SE: ''^
ok: 2^

 N: Tie::Form Version $version loaded^
 A: $fp->is_package_loaded($uut)^
 E: 1^
ok: 3^

 N: Read lenient Form^

 R:
     L<Tie::Form/format [1] - separator strings>
     L<Tie::Form/format [2] - separator escapes>
     L<Tie::Form/format [3] - field names>
     L<Tie::Form/format [4] - field names>
     L<Tie::Form/format [5] - EON>
     L<Tie::Form/format [7] - Lenient EOD>
     L<Tie::Form/methods [2] - decode_field>
     L<Tie::Form/methods [4] - decode_record>
     L<Tie::Form/methods [6] - get_record>
     L<Tie::Form/methods [7] - get_record>
^


 C:
    tie *FORM, 'Tie::Form';
    open FORM,'<',File::Spec->catfile($lenient_in_file);
    @fields = <FORM>;
    close FORM;
^

 A: [@fields]^
 E: [@test_data1]^
ok: 4^

 N: Write lenient Form^

 R:
     L<Tie::Form/format [1] - separator strings>
     L<Tie::Form/format [2] - separator escapes>
     L<Tie::Form/format [3] - field names>
     L<Tie::Form/format [4] - field names>
     L<Tie::Form/format [5] - EON>
     L<Tie::Form/format [7] - Lenient EOD>
     L<Tie::Form/methods [1] - encode_field>
     L<Tie::Form/methods [3] - encode_record>
     L<Tie::Form/methods [5] - put_record>
^


 C:
    open FORM, '>', $out_file;
    print FORM @fields;
    close FORM;
^

 A: File::SmartNL->fin($out_file)^
 E: File::SmartNL->fin($lenient_expected_file)^
ok: 5^

 N: Read strict Form^

 R:
     L<Tie::Form/format [1] - separator strings>
     L<Tie::Form/format [2] - separator escapes>
     L<Tie::Form/format [3] - field names>
     L<Tie::Form/format [4] - field names>
     L<Tie::Form/format [5] - EON>
     L<Tie::Form/format [6] - Strict EOD>
     L<Tie::Form/methods [2] - decode_field>
     L<Tie::Form/methods [4] - decode_record>
     L<Tie::Form/methods [6] - get_record>
     L<Tie::Form/methods [7] - get_record>
^


 C:
    tie *FORM, 'Tie::Form';
    open FORM,'<',File::Spec->catfile($strict_in_file);
    @fields = <FORM>;
    close FORM;
^

 A: [@fields]^
 E: [@test_data1]^
ok: 6^

 N: Write strict Form^

 R:
     L<Tie::Form/format [1] - separator strings>
     L<Tie::Form/format [2] - separator escapes>
     L<Tie::Form/format [3] - field names>
     L<Tie::Form/format [4] - field names>
     L<Tie::Form/format [5] - EON>
     L<Tie::Form/format [6] - Strict EOD>
     L<Tie::Form/methods [1] - encode_field>
     L<Tie::Form/methods [3] - encode_record>
     L<Tie::Form/methods [5] - put_record>
^


 C:
    open FORM, '>', $out_file;
    print FORM @fields;
    close FORM;
^

 A: File::SmartNL->fin($out_file)^
 E: File::SmartNL->fin($strict_expected_file)^
ok: 7^

 C: unlink $out_file;^

See_Also: L<Tie::Layers>^

Copyright:
copyright © 2004 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

\=over 4

\=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

\=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

\=back

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.
^

HTML: ^


~-~
