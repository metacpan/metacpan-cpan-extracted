#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  t::Tie::FormA;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.02';
$DATE = '2004/06/03';
$FILE = __FILE__;

########
# The Test::STDmakerA module uses the data after the __DATA__ 
# token to automatically generate the this file.
#
# Do not edit anything before __DATA_. Edit instead
# the data after the __DATA__ token.
#
# ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
#
# the next time Test::STDmakerA generates this file.
#
#


####
# The program module overall STD collects the tracebility
# from the individual test STD and makes one big tracebility
# matrice.
#

#<-- BLK ID="TRACEBILITY" -->

my $trace_req = 

{
          'Requirement L<methods [5] - put_record|Tie::FormA/methods [5] - put_record>' => {
                                                                                             'Test t::Tie::FormA, Test Case L<4.1.7 Write strict FormA|t::Tie::FormA/4.1.7 Write strict FormA>' => undef,
                                                                                             'Test t::Tie::FormA, Test Case L<4.1.5 Write lenient FormA|t::Tie::FormA/4.1.5 Write lenient FormA>' => undef
                                                                                           },
          'Requirement L<methods [2] - decode_field|Tie::FormA/methods [2] - decode_field>' => {
                                                                                                 'Test t::Tie::FormA, Test Case L<4.1.4 Read lenient FormA|t::Tie::FormA/4.1.4 Read lenient FormA>' => undef,
                                                                                                 'Test t::Tie::FormA, Test Case L<4.1.6 Read strict FormA|t::Tie::FormA/4.1.6 Read strict FormA>' => undef
                                                                                               },
          'Requirement L<format [7] - Lenient EOD|Tie::FormA/format [7] - Lenient EOD>' => {
                                                                                             'Test t::Tie::FormA, Test Case L<4.1.4 Read lenient FormA|t::Tie::FormA/4.1.4 Read lenient FormA>' => undef,
                                                                                             'Test t::Tie::FormA, Test Case L<4.1.5 Write lenient FormA|t::Tie::FormA/4.1.5 Write lenient FormA>' => undef
                                                                                           },
          'Requirement L<format [4] - field names|Tie::FormA/format [4] - field names>' => {
                                                                                             'Test t::Tie::FormA, Test Case L<4.1.4 Read lenient FormA|t::Tie::FormA/4.1.4 Read lenient FormA>' => undef,
                                                                                             'Test t::Tie::FormA, Test Case L<4.1.7 Write strict FormA|t::Tie::FormA/4.1.7 Write strict FormA>' => undef,
                                                                                             'Test t::Tie::FormA, Test Case L<4.1.6 Read strict FormA|t::Tie::FormA/4.1.6 Read strict FormA>' => undef,
                                                                                             'Test t::Tie::FormA, Test Case L<4.1.5 Write lenient FormA|t::Tie::FormA/4.1.5 Write lenient FormA>' => undef
                                                                                           },
          'Requirement L<format [2] - separator escape|Tie::FormA/format [2] - separator escapes>' => {
                                                                                                        'Test t::Tie::FormA, Test Case L<4.1.4 Read lenient FormA|t::Tie::FormA/4.1.4 Read lenient FormA>' => undef
                                                                                                      },
          'Requirement L<methods [1] - encode_field|Tie::FormA/methods [1] - encode_field>' => {
                                                                                                 'Test t::Tie::FormA, Test Case L<4.1.7 Write strict FormA|t::Tie::FormA/4.1.7 Write strict FormA>' => undef,
                                                                                                 'Test t::Tie::FormA, Test Case L<4.1.5 Write lenient FormA|t::Tie::FormA/4.1.5 Write lenient FormA>' => undef
                                                                                               },
          'Requirement L<format [2] - separator escapes|Tie::FormA/format [2] - separator escapes>' => {
                                                                                                         'Test t::Tie::FormA, Test Case L<4.1.7 Write strict FormA|t::Tie::FormA/4.1.7 Write strict FormA>' => undef,
                                                                                                         'Test t::Tie::FormA, Test Case L<4.1.6 Read strict FormA|t::Tie::FormA/4.1.6 Read strict FormA>' => undef,
                                                                                                         'Test t::Tie::FormA, Test Case L<4.1.5 Write lenient FormA|t::Tie::FormA/4.1.5 Write lenient FormA>' => undef
                                                                                                       },
          'Requirement L<format [5] - EON|Tie::FormA/format [5] - EON>' => {
                                                                             'Test t::Tie::FormA, Test Case L<4.1.4 Read lenient FormA|t::Tie::FormA/4.1.4 Read lenient FormA>' => undef,
                                                                             'Test t::Tie::FormA, Test Case L<4.1.7 Write strict FormA|t::Tie::FormA/4.1.7 Write strict FormA>' => undef,
                                                                             'Test t::Tie::FormA, Test Case L<4.1.6 Read strict FormA|t::Tie::FormA/4.1.6 Read strict FormA>' => undef,
                                                                             'Test t::Tie::FormA, Test Case L<4.1.5 Write lenient FormA|t::Tie::FormA/4.1.5 Write lenient FormA>' => undef
                                                                           },
          'Requirement L<methods [6] - get_record|Tie::FormA/methods [6] - get_record>' => {
                                                                                             'Test t::Tie::FormA, Test Case L<4.1.4 Read lenient FormA|t::Tie::FormA/4.1.4 Read lenient FormA>' => undef,
                                                                                             'Test t::Tie::FormA, Test Case L<4.1.6 Read strict FormA|t::Tie::FormA/4.1.6 Read strict FormA>' => undef
                                                                                           },
          'Requirement L<format [1] - separator strings|Tie::FormA/format [1] - separator strings>' => {
                                                                                                         'Test t::Tie::FormA, Test Case L<4.1.4 Read lenient FormA|t::Tie::FormA/4.1.4 Read lenient FormA>' => undef,
                                                                                                         'Test t::Tie::FormA, Test Case L<4.1.7 Write strict FormA|t::Tie::FormA/4.1.7 Write strict FormA>' => undef,
                                                                                                         'Test t::Tie::FormA, Test Case L<4.1.6 Read strict FormA|t::Tie::FormA/4.1.6 Read strict FormA>' => undef,
                                                                                                         'Test t::Tie::FormA, Test Case L<4.1.5 Write lenient FormA|t::Tie::FormA/4.1.5 Write lenient FormA>' => undef
                                                                                                       },
          'Requirement L<methods [3] - encode_record|Tie::FormA/methods [3] - encode_record>' => {
                                                                                                   'Test t::Tie::FormA, Test Case L<4.1.7 Write strict FormA|t::Tie::FormA/4.1.7 Write strict FormA>' => undef,
                                                                                                   'Test t::Tie::FormA, Test Case L<4.1.5 Write lenient FormA|t::Tie::FormA/4.1.5 Write lenient FormA>' => undef
                                                                                                 },
          'Requirement L<methods [7] - get_record|Tie::FormA/methods [7] - get_record>' => {
                                                                                             'Test t::Tie::FormA, Test Case L<4.1.4 Read lenient FormA|t::Tie::FormA/4.1.4 Read lenient FormA>' => undef,
                                                                                             'Test t::Tie::FormA, Test Case L<4.1.6 Read strict FormA|t::Tie::FormA/4.1.6 Read strict FormA>' => undef
                                                                                           },
          'Requirement L<format [3] - field names|Tie::FormA/format [3] - field names>' => {
                                                                                             'Test t::Tie::FormA, Test Case L<4.1.4 Read lenient FormA|t::Tie::FormA/4.1.4 Read lenient FormA>' => undef,
                                                                                             'Test t::Tie::FormA, Test Case L<4.1.7 Write strict FormA|t::Tie::FormA/4.1.7 Write strict FormA>' => undef,
                                                                                             'Test t::Tie::FormA, Test Case L<4.1.6 Read strict FormA|t::Tie::FormA/4.1.6 Read strict FormA>' => undef,
                                                                                             'Test t::Tie::FormA, Test Case L<4.1.5 Write lenient FormA|t::Tie::FormA/4.1.5 Write lenient FormA>' => undef
                                                                                           },
          'Requirement L<format [6] - Strict EOD|Tie::FormA/format [6] - Strict EOD>' => {
                                                                                           'Test t::Tie::FormA, Test Case L<4.1.7 Write strict FormA|t::Tie::FormA/4.1.7 Write strict FormA>' => undef,
                                                                                           'Test t::Tie::FormA, Test Case L<4.1.6 Read strict FormA|t::Tie::FormA/4.1.6 Read strict FormA>' => undef
                                                                                         },
          'Requirement L<methods [4] - decode_record|Tie::FormA/methods [4] - decode_record>' => {
                                                                                                   'Test t::Tie::FormA, Test Case L<4.1.4 Read lenient FormA|t::Tie::FormA/4.1.4 Read lenient FormA>' => undef,
                                                                                                   'Test t::Tie::FormA, Test Case L<4.1.6 Read strict FormA|t::Tie::FormA/4.1.6 Read strict FormA>' => undef
                                                                                                 }
        }
;

#<-- /BLK -->


#<-- BLK ID="POD" -->

=head1 NAME

t::Tie::FormA - Complete Software Test Description for the Tie::FormA Program Module

=head1 TITLE PAGE

Detailed Software Test Description (STD)

for

Complete Test of the Perl Tie::FormA Program Module

Revision: -

Version: 

Date: 2004/06/02

Prepared for: General Public 

Prepared by:  http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com

Classification: None

=head1 1.0 SCOPE

This document establishes detail Software Test Description (STD) for 
the Complete Test of the Perl L<Tie::FormA|Tie::FormA> program module.

This Software Test Description (STD) is a  detail Software Test Description 
in the form of a STD specification sheet, which is incomplete without
reference to the L<General Perl Program Module STD|Test::STD::PerlSTD> specification.
This detail STD and the
L<General Perl Program Module STD|Test::STD::PerlSTD>
constitute the total requirements for the
Perl L<Tie::FormA|Tie::FormA> program module.


=head1 3.0 TEST PREPARATIONS

Test preparations are as specified in the L<General Perl Program Module STD|Test::STD::PerlSTD>.

=head1 4.0 TEST DESCRIPTIONS

The test descriptions uses a legend to
identify different aspects of a test description
in accordance with
L<STD PM Form Database Test Description Fields|Test::STDmakerA/STD PM Form Database Test Description Fields>.

=head2 4.1 Complete Test

This test verifies both the lenient
and strict formats of the 
C<Tie::FormA> program module.

=head2 4.1.1 UUT not loaded


  C:
     use File::Package;
     use File::SmartNL;
     use File::Spec;
     my $uut = 'Tie::FormA'; # Unit Under Test
     my $fp = 'File::Package';
     my $loaded;
     my (@fields);  # force context
     my $out_file = File::Spec->catfile('FormA','form1.txt');;
     unlink $out_file;
     my $lenient_in_file = File::Spec->catfile('FormA','lenient0.txt');
     my $strict_in_file = File::Spec->catfile('FormA','strict0.txt');
 ^

 QC:
 ######
 # Not needed for demo, so use the Quiet Code (QC) 
 # 
 my $lenient_expected_file = File::Spec->catfile('FormA','lenient2.txt');
 my $strict_expected_file = File::Spec->catfile('FormA','lenient2.txt');
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

=head2 4.1.2 Load UUT

  N: Load UUT^
  C: my $errors = $fp->load_package($uut)^
  A: $errors^
 SE: ''^
 ok: 2^

=head2 4.1.3 Tie::FormA Version $Tie::FormA::VERSION loaded

  N: Tie::FormA Version $Tie::FormA::VERSION loaded^
  A: $fp->is_package_loaded($uut)^
  E: 1^
 ok: 3^

=head2 4.1.4 Read lenient FormA

  N: Read lenient FormA^

  R:
      L<format [1] - separator strings|Tie::FormA/format [1] - separator strings>
      L<format [2] - separator escape|Tie::FormA/format [2] - separator escapes>
      L<format [3] - field names|Tie::FormA/format [3] - field names>
      L<format [4] - field names|Tie::FormA/format [4] - field names>
      L<format [5] - EON|Tie::FormA/format [5] - EON>
      L<format [7] - Lenient EOD|Tie::FormA/format [7] - Lenient EOD>
      L<methods [2] - decode_field|Tie::FormA/methods [2] - decode_field>
      L<methods [4] - decode_record|Tie::FormA/methods [4] - decode_record>
      L<methods [6] - get_record|Tie::FormA/methods [6] - get_record>
      L<methods [7] - get_record|Tie::FormA/methods [7] - get_record>
 ^

  C:
     tie *FORM, 'Tie::FormA';
     open FORM,'<',File::Spec->catfile($lenient_in_file);
     @fields = <FORM>;
     close FORM;
 ^
  A: [@fields]^
  E: [@test_data1]^
 ok: 4^

=head2 4.1.5 Write lenient FormA

  N: Write lenient FormA^

  R:
      L<format [1] - separator strings|Tie::FormA/format [1] - separator strings>
      L<format [2] - separator escapes|Tie::FormA/format [2] - separator escapes>
      L<format [3] - field names|Tie::FormA/format [3] - field names>
      L<format [4] - field names|Tie::FormA/format [4] - field names>
      L<format [5] - EON|Tie::FormA/format [5] - EON>
      L<format [7] - Lenient EOD|Tie::FormA/format [7] - Lenient EOD>
      L<methods [1] - encode_field|Tie::FormA/methods [1] - encode_field>
      L<methods [3] - encode_record|Tie::FormA/methods [3] - encode_record>
      L<methods [5] - put_record|Tie::FormA/methods [5] - put_record>
 ^

  C:
     open FORM, '>', $out_file;
     print FORM @fields;
     close FORM;
 ^
  A: File::SmartNL->fin($out_file)^
  E: File::SmartNL->fin($lenient_expected_file)^
 ok: 5^

=head2 4.1.6 Read strict FormA

  N: Read strict FormA^

  R:
      L<format [1] - separator strings|Tie::FormA/format [1] - separator strings>
      L<format [2] - separator escapes|Tie::FormA/format [2] - separator escapes>
      L<format [3] - field names|Tie::FormA/format [3] - field names>
      L<format [4] - field names|Tie::FormA/format [4] - field names>
      L<format [5] - EON|Tie::FormA/format [5] - EON>
      L<format [6] - Strict EOD|Tie::FormA/format [6] - Strict EOD>
      L<methods [2] - decode_field|Tie::FormA/methods [2] - decode_field>
      L<methods [4] - decode_record|Tie::FormA/methods [4] - decode_record>
      L<methods [6] - get_record|Tie::FormA/methods [6] - get_record>
      L<methods [7] - get_record|Tie::FormA/methods [7] - get_record>
 ^

  C:
     tie *FORM, 'Tie::FormA';
     open FORM,'<',File::Spec->catfile($strict_in_file);
     @fields = <FORM>;
     close FORM;
 ^
  A: [@fields]^
  E: [@test_data1]^
 ok: 6^

=head2 4.1.7 Write strict FormA

  N: Write strict FormA^

  R:
      L<format [1] - separator strings|Tie::FormA/format [1] - separator strings>
      L<format [2] - separator escapes|Tie::FormA/format [2] - separator escapes>
      L<format [3] - field names|Tie::FormA/format [3] - field names>
      L<format [4] - field names|Tie::FormA/format [4] - field names>
      L<format [5] - EON|Tie::FormA/format [5] - EON>
      L<format [6] - Strict EOD|Tie::FormA/format [6] - Strict EOD>
      L<methods [1] - encode_field|Tie::FormA/methods [1] - encode_field>
      L<methods [3] - encode_record|Tie::FormA/methods [3] - encode_record>
      L<methods [5] - put_record|Tie::FormA/methods [5] - put_record>
 ^

  C:
     open FORM, '>', $out_file;
     print FORM @fields;
     close FORM;
 ^
  A: File::SmartNL->fin($out_file)^
  E: File::SmartNL->fin($strict_expected_file)^
 ok: 7^



=head1 5.0 REQUIREMENTS TRACEABILITY

=head2 5.1 Requirement to Test Case Tracebility

=over 4

=item Requirement L<format [1] - separator strings|Tie::FormA/format [1] - separator strings>

Test Case L<4.1.4 Read lenient FormA|/4.1.4 Read lenient FormA>

Test Case L<4.1.5 Write lenient FormA|/4.1.5 Write lenient FormA>

Test Case L<4.1.6 Read strict FormA|/4.1.6 Read strict FormA>

Test Case L<4.1.7 Write strict FormA|/4.1.7 Write strict FormA>

=item Requirement L<format [2] - separator escapes|Tie::FormA/format [2] - separator escapes>

Test Case L<4.1.5 Write lenient FormA|/4.1.5 Write lenient FormA>

Test Case L<4.1.6 Read strict FormA|/4.1.6 Read strict FormA>

Test Case L<4.1.7 Write strict FormA|/4.1.7 Write strict FormA>

=item Requirement L<format [2] - separator escape|Tie::FormA/format [2] - separator escapes>

Test Case L<4.1.4 Read lenient FormA|/4.1.4 Read lenient FormA>

=item Requirement L<format [3] - field names|Tie::FormA/format [3] - field names>

Test Case L<4.1.4 Read lenient FormA|/4.1.4 Read lenient FormA>

Test Case L<4.1.5 Write lenient FormA|/4.1.5 Write lenient FormA>

Test Case L<4.1.6 Read strict FormA|/4.1.6 Read strict FormA>

Test Case L<4.1.7 Write strict FormA|/4.1.7 Write strict FormA>

=item Requirement L<format [4] - field names|Tie::FormA/format [4] - field names>

Test Case L<4.1.4 Read lenient FormA|/4.1.4 Read lenient FormA>

Test Case L<4.1.5 Write lenient FormA|/4.1.5 Write lenient FormA>

Test Case L<4.1.6 Read strict FormA|/4.1.6 Read strict FormA>

Test Case L<4.1.7 Write strict FormA|/4.1.7 Write strict FormA>

=item Requirement L<format [5] - EON|Tie::FormA/format [5] - EON>

Test Case L<4.1.4 Read lenient FormA|/4.1.4 Read lenient FormA>

Test Case L<4.1.5 Write lenient FormA|/4.1.5 Write lenient FormA>

Test Case L<4.1.6 Read strict FormA|/4.1.6 Read strict FormA>

Test Case L<4.1.7 Write strict FormA|/4.1.7 Write strict FormA>

=item Requirement L<format [6] - Strict EOD|Tie::FormA/format [6] - Strict EOD>

Test Case L<4.1.6 Read strict FormA|/4.1.6 Read strict FormA>

Test Case L<4.1.7 Write strict FormA|/4.1.7 Write strict FormA>

=item Requirement L<format [7] - Lenient EOD|Tie::FormA/format [7] - Lenient EOD>

Test Case L<4.1.4 Read lenient FormA|/4.1.4 Read lenient FormA>

Test Case L<4.1.5 Write lenient FormA|/4.1.5 Write lenient FormA>

=item Requirement L<methods [1] - encode_field|Tie::FormA/methods [1] - encode_field>

Test Case L<4.1.5 Write lenient FormA|/4.1.5 Write lenient FormA>

Test Case L<4.1.7 Write strict FormA|/4.1.7 Write strict FormA>

=item Requirement L<methods [2] - decode_field|Tie::FormA/methods [2] - decode_field>

Test Case L<4.1.4 Read lenient FormA|/4.1.4 Read lenient FormA>

Test Case L<4.1.6 Read strict FormA|/4.1.6 Read strict FormA>

=item Requirement L<methods [3] - encode_record|Tie::FormA/methods [3] - encode_record>

Test Case L<4.1.5 Write lenient FormA|/4.1.5 Write lenient FormA>

Test Case L<4.1.7 Write strict FormA|/4.1.7 Write strict FormA>

=item Requirement L<methods [4] - decode_record|Tie::FormA/methods [4] - decode_record>

Test Case L<4.1.4 Read lenient FormA|/4.1.4 Read lenient FormA>

Test Case L<4.1.6 Read strict FormA|/4.1.6 Read strict FormA>

=item Requirement L<methods [5] - put_record|Tie::FormA/methods [5] - put_record>

Test Case L<4.1.5 Write lenient FormA|/4.1.5 Write lenient FormA>

Test Case L<4.1.7 Write strict FormA|/4.1.7 Write strict FormA>

=item Requirement L<methods [6] - get_record|Tie::FormA/methods [6] - get_record>

Test Case L<4.1.4 Read lenient FormA|/4.1.4 Read lenient FormA>

Test Case L<4.1.6 Read strict FormA|/4.1.6 Read strict FormA>

=item Requirement L<methods [7] - get_record|Tie::FormA/methods [7] - get_record>

Test Case L<4.1.4 Read lenient FormA|/4.1.4 Read lenient FormA>

Test Case L<4.1.6 Read strict FormA|/4.1.6 Read strict FormA>

=back 



=head2 5.2 Test Case to Requirement Tracebility

=over 4

=item Test Case L<4.1.4 Read lenient FormA|/4.1.4 Read lenient FormA>

Requirement L<format [1] - separator strings|Tie::FormA/format [1] - separator strings>

Requirement L<format [2] - separator escape|Tie::FormA/format [2] - separator escapes>

Requirement L<format [3] - field names|Tie::FormA/format [3] - field names>

Requirement L<format [4] - field names|Tie::FormA/format [4] - field names>

Requirement L<format [5] - EON|Tie::FormA/format [5] - EON>

Requirement L<format [7] - Lenient EOD|Tie::FormA/format [7] - Lenient EOD>

Requirement L<methods [2] - decode_field|Tie::FormA/methods [2] - decode_field>

Requirement L<methods [4] - decode_record|Tie::FormA/methods [4] - decode_record>

Requirement L<methods [6] - get_record|Tie::FormA/methods [6] - get_record>

Requirement L<methods [7] - get_record|Tie::FormA/methods [7] - get_record>

=item Test Case L<4.1.5 Write lenient FormA|/4.1.5 Write lenient FormA>

Requirement L<format [1] - separator strings|Tie::FormA/format [1] - separator strings>

Requirement L<format [2] - separator escapes|Tie::FormA/format [2] - separator escapes>

Requirement L<format [3] - field names|Tie::FormA/format [3] - field names>

Requirement L<format [4] - field names|Tie::FormA/format [4] - field names>

Requirement L<format [5] - EON|Tie::FormA/format [5] - EON>

Requirement L<format [7] - Lenient EOD|Tie::FormA/format [7] - Lenient EOD>

Requirement L<methods [1] - encode_field|Tie::FormA/methods [1] - encode_field>

Requirement L<methods [3] - encode_record|Tie::FormA/methods [3] - encode_record>

Requirement L<methods [5] - put_record|Tie::FormA/methods [5] - put_record>

=item Test Case L<4.1.6 Read strict FormA|/4.1.6 Read strict FormA>

Requirement L<format [1] - separator strings|Tie::FormA/format [1] - separator strings>

Requirement L<format [2] - separator escapes|Tie::FormA/format [2] - separator escapes>

Requirement L<format [3] - field names|Tie::FormA/format [3] - field names>

Requirement L<format [4] - field names|Tie::FormA/format [4] - field names>

Requirement L<format [5] - EON|Tie::FormA/format [5] - EON>

Requirement L<format [6] - Strict EOD|Tie::FormA/format [6] - Strict EOD>

Requirement L<methods [2] - decode_field|Tie::FormA/methods [2] - decode_field>

Requirement L<methods [4] - decode_record|Tie::FormA/methods [4] - decode_record>

Requirement L<methods [6] - get_record|Tie::FormA/methods [6] - get_record>

Requirement L<methods [7] - get_record|Tie::FormA/methods [7] - get_record>

=item Test Case L<4.1.7 Write strict FormA|/4.1.7 Write strict FormA>

Requirement L<format [1] - separator strings|Tie::FormA/format [1] - separator strings>

Requirement L<format [2] - separator escapes|Tie::FormA/format [2] - separator escapes>

Requirement L<format [3] - field names|Tie::FormA/format [3] - field names>

Requirement L<format [4] - field names|Tie::FormA/format [4] - field names>

Requirement L<format [5] - EON|Tie::FormA/format [5] - EON>

Requirement L<format [6] - Strict EOD|Tie::FormA/format [6] - Strict EOD>

Requirement L<methods [1] - encode_field|Tie::FormA/methods [1] - encode_field>

Requirement L<methods [3] - encode_record|Tie::FormA/methods [3] - encode_record>

Requirement L<methods [5] - put_record|Tie::FormA/methods [5] - put_record>

=back 



=head1 6.0 NOTES

=head2 Construction of Words

The construction of the words "shall", "may" and "should"
shall[1] conform to United States (US) Departmart of Defense (DoD)
L<STD490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>
which is more precise and even consistent, at times, with
RFC 2119, http://www.ietf.org/rfc/rfc2119.txt
Binding requirements shall[2] be uniquely identified by
the construction "shall[\d+]" , where "\d+" is an unique number
for each paragraph(s) uniquely identified by a header.
The construction of commonly used words and phrasing
shall[3] conform to US DoD 
L<STD490A 3.2.3.5|Docs::US_DOD::STD490A/3.2.3.5 Commonly used words and phrasing.>
In accordance with US Dod L<STD490A 3.2.6|Docs::US_DOD::STD490A/3.2.6 Underlining.>,
requirments shall[4] not be emphazied by underlining and capitalization.
All of the requirements are important in obtaining
the desired performance.

Unless otherwise specified, in accordance with Software Diamonds' License, 
Software Diamonds shall[5] not be responsible for this program module conforming to all the
specified requirements, binding or otherwise.

=head2 Author

The author, holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 Copyright

copyright © 2004 SoftwareDiamonds.com

=head2 License

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code, modified or unmodified
shall[1] retain the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form shall[2]
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=item 3

In addition to condition (1) and (2),
commercial installation of a software product
with the binary or source code embedded in the
software product or a software product of
binary or source code, with or without modifications,
shall[3] visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://packages.softwarediamonds.com
and provide means for the installer to actively accept
the list of conditions; 
otherwise, the commerical activity,
as determined by Software Diamonds and
published at http://packages.softwarediamonds.com, 
shall[4] pay a license fee to
Software Diamonds and shall[5] make donations,
to open source repositories carrying
the source code.

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

=head1 2.0 REFERENCED DOCUMENTS (SEE ALSO)


=over 4

=item L<Tie::Layers|Tie::Layers>

=item L<Tie::CSV|Tie::CSV>

=item L<Tie::Eudora|Tie::Eudora>

=item L<Data::Query|Data::Query>

=item L<Software Test Description|Docs::US_DOD::STD>

=item L<Specification Practices|Docs::US_DOD::STD490A>

=back

=for html


=cut

#<-- /BLK -->

__DATA__

Use: Test::STDmakerA^
Type: Test^
Language: Perl^
SVD: Docs::Site_SVD::Tie::FormA^
Test_Name: Complete^
Test_Number: ^
Test_Index: ^

Test_Description:
This test verifies both the lenient
and strict formats of the 
C<Tie::FormA> program module.
^

File_Spec: Unix^
UUT: Tie::FormA^
Revision: -^
Version: ^
End_User: General Public^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
Test_Template: ^
Classification: None^
Temp: temp.pl^
Demo: FormA.d^
STD: FormA.pm^
Verify: FormA.t^


 T: 7^


 C:
    use File::Package;
    use File::SmartNL;
    use File::Spec;

    my $uut = 'Tie::FormA'; # Unit Under Test
    my $fp = 'File::Package';
    my $loaded;

    my (@fields);  # force context
    my $out_file = File::Spec->catfile('FormA','form1.txt');;
    unlink $out_file;

    my $lenient_in_file = File::Spec->catfile('FormA','lenient0.txt');
    my $strict_in_file = File::Spec->catfile('FormA','strict0.txt');
^


QC:
######
# Not needed for demo, so use the Quiet Code (QC) 
# 
my $lenient_expected_file = File::Spec->catfile('FormA','lenient2.txt');
my $strict_expected_file = File::Spec->catfile('FormA','lenient2.txt');

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

 N: Tie::FormA Version $Tie::FormA::VERSION loaded^
 A: $fp->is_package_loaded($uut)^
 E: 1^
ok: 3^

 N: Read lenient FormA^

 R:
     L<format [1] - separator strings|Tie::FormA/format [1] - separator strings>
     L<format [2] - separator escape|Tie::FormA/format [2] - separator escapes>
     L<format [3] - field names|Tie::FormA/format [3] - field names>
     L<format [4] - field names|Tie::FormA/format [4] - field names>
     L<format [5] - EON|Tie::FormA/format [5] - EON>
     L<format [7] - Lenient EOD|Tie::FormA/format [7] - Lenient EOD>
     L<methods [2] - decode_field|Tie::FormA/methods [2] - decode_field>
     L<methods [4] - decode_record|Tie::FormA/methods [4] - decode_record>
     L<methods [6] - get_record|Tie::FormA/methods [6] - get_record>
     L<methods [7] - get_record|Tie::FormA/methods [7] - get_record>
^


 C:
    tie *FORM, 'Tie::FormA';
    open FORM,'<',File::Spec->catfile($lenient_in_file);
    @fields = <FORM>;
    close FORM;
^

 A: [@fields]^
 E: [@test_data1]^
ok: 4^

 N: Write lenient FormA^

 R:
     L<format [1] - separator strings|Tie::FormA/format [1] - separator strings>
     L<format [2] - separator escapes|Tie::FormA/format [2] - separator escapes>
     L<format [3] - field names|Tie::FormA/format [3] - field names>
     L<format [4] - field names|Tie::FormA/format [4] - field names>
     L<format [5] - EON|Tie::FormA/format [5] - EON>
     L<format [7] - Lenient EOD|Tie::FormA/format [7] - Lenient EOD>
     L<methods [1] - encode_field|Tie::FormA/methods [1] - encode_field>
     L<methods [3] - encode_record|Tie::FormA/methods [3] - encode_record>
     L<methods [5] - put_record|Tie::FormA/methods [5] - put_record>
^


 C:
    open FORM, '>', $out_file;
    print FORM @fields;
    close FORM;
^

 A: File::SmartNL->fin($out_file)^
 E: File::SmartNL->fin($lenient_expected_file)^
ok: 5^

 N: Read strict FormA^

 R:
     L<format [1] - separator strings|Tie::FormA/format [1] - separator strings>
     L<format [2] - separator escapes|Tie::FormA/format [2] - separator escapes>
     L<format [3] - field names|Tie::FormA/format [3] - field names>
     L<format [4] - field names|Tie::FormA/format [4] - field names>
     L<format [5] - EON|Tie::FormA/format [5] - EON>
     L<format [6] - Strict EOD|Tie::FormA/format [6] - Strict EOD>
     L<methods [2] - decode_field|Tie::FormA/methods [2] - decode_field>
     L<methods [4] - decode_record|Tie::FormA/methods [4] - decode_record>
     L<methods [6] - get_record|Tie::FormA/methods [6] - get_record>
     L<methods [7] - get_record|Tie::FormA/methods [7] - get_record>
^


 C:
    tie *FORM, 'Tie::FormA';
    open FORM,'<',File::Spec->catfile($strict_in_file);
    @fields = <FORM>;
    close FORM;
^

 A: [@fields]^
 E: [@test_data1]^
ok: 6^

 N: Write strict FormA^

 R:
     L<format [1] - separator strings|Tie::FormA/format [1] - separator strings>
     L<format [2] - separator escapes|Tie::FormA/format [2] - separator escapes>
     L<format [3] - field names|Tie::FormA/format [3] - field names>
     L<format [4] - field names|Tie::FormA/format [4] - field names>
     L<format [5] - EON|Tie::FormA/format [5] - EON>
     L<format [6] - Strict EOD|Tie::FormA/format [6] - Strict EOD>
     L<methods [1] - encode_field|Tie::FormA/methods [1] - encode_field>
     L<methods [3] - encode_record|Tie::FormA/methods [3] - encode_record>
     L<methods [5] - put_record|Tie::FormA/methods [5] - put_record>
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


See_Also:
 
\=over 4

\=item L<Tie::Layers|Tie::Layers>

\=item L<Tie::CSV|Tie::CSV>

\=item L<Tie::Eudora|Tie::Eudora>

\=item L<Data::Query|Data::Query>

\=item L<Software Test Description|Docs::US_DOD::STD>

\=item L<Specification Practices|Docs::US_DOD::STD490A>

\=back
^


Notes:
\=head2 Construction of Words

The construction of the words "shall", "may" and "should"
shall[1] conform to United States (US) Departmart of Defense (DoD)
L<STD490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>
which is more precise and even consistent, at times, with
RFC 2119, http://www.ietf.org/rfc/rfc2119.txt
Binding requirements shall[2] be uniquely identified by
the construction "shall[\d+]" , where "\d+" is an unique number
for each paragraph(s) uniquely identified by a header.
The construction of commonly used words and phrasing
shall[3] conform to US DoD 
L<STD490A 3.2.3.5|Docs::US_DOD::STD490A/3.2.3.5 Commonly used words and phrasing.>
In accordance with US Dod L<STD490A 3.2.6|Docs::US_DOD::STD490A/3.2.6 Underlining.>,
requirments shall[4] not be emphazied by underlining and capitalization.
All of the requirements are important in obtaining
the desired performance.

Unless otherwise specified, in accordance with Software Diamonds' License, 
Software Diamonds shall[5] not be responsible for this program module conforming to all the
specified requirements, binding or otherwise.

\=head2 Author

The author, holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

\=head2 Copyright

copyright © 2004 SoftwareDiamonds.com

\=head2 License

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

\=over 4

\=item 1

Redistributions of source code, modified or unmodified
shall[1] retain the above copyright notice, this list of
conditions and the following disclaimer. 

\=item 2

Redistributions in binary form shall[2]
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

\=item 3

In addition to condition (1) and (2),
commercial installation of a software product
with the binary or source code embedded in the
software product or a software product of
binary or source code, with or without modifications,
shall[3] visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://packages.softwarediamonds.com
and provide means for the installer to actively accept
the list of conditions; 
otherwise, the commerical activity,
as determined by Software Diamonds and
published at http://packages.softwarediamonds.com, 
shall[4] pay a license fee to
Software Diamonds and shall[5] make donations,
to open source repositories carrying
the source code.

\=back

The construction of the word "shall[x]" is always mandatory 
and not merely directory and identifies each binding
requirement of this License. 
It is the responsibility of the licensee to
conform to all requirements.

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
