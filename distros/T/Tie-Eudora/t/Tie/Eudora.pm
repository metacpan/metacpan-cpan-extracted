#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  t::Tie::Eudora;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.01';
$DATE = '2004/05/29';
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

 - Software Test Description for Tie::Eudora

=head1 TITLE PAGE

 Detailed Software Test Description (STD)

 for

 Perl Tie::Eudora Program Module

 Revision: -

 Version: 

 Date: 2004/05/29

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
requirements of Perl Program Module (PM) L<Tie::Eudora|Tie::Eudora>
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

 T: 9^

=head2 ok: 1


  C:
     use File::Package;
     use File::SmartNL;
     use File::Spec;
     use Data::Dumper;
     $Data::Dumper::Sortkeys = 1; # dump hashes sorted
     $Data::Dumper::Terse = 1; # avoid Varn Variables
     my $uut = 'Tie::Eudora'; # Unit Under Test
     my $fp = 'File::Package';
     my $snl = 'File::SmartNL';
     my $loaded;
     my (@fields);  # force context
     my $mbx = 'Eudora1.mbx';
 ^

 QC:
 ######
 # Not needed for demo, so use the Quiet Code (QC) 
 # 
 my $expected_file = 'Eudora2.mbx';
 my $actual = 'Eudora1.txt';
 unlink $actual;
 unlink $mbx;
 my @test_data = (
           [
             'X-Pickup-Date',
             'Wed Jul 24 20:20:19 2002',
             'X-Persona',
             '<support@SoftwareDiamonds.com>',
             'Return-Path',
             'somebody@compuserve.com',
             'Delivered-To',
             'support@SoftwareDiamonds.com',
             'Received',
             '(qmail 7321 invoked from network); 24 Jul 2002 17:26:21 -0000',
             'Received',
             'from unknown (HELO mail.hbhosting.com) (66.28.88.4)
   by mail.ixpres.com with SMTP; 24 Jul 2002 17:26:21 -0000',
             'Received',
             '(qmail 17747 invoked by uid 89); 24 Jul 2002 17:38:56 -0000',
             'Delivered-To',
             'softwarediamonds.com-support@softwarediamonds.com',
             'Received',
             '(qmail 17745 invoked from network); 24 Jul 2002 17:38:56 -0000',
             'Received',
             'from unknown (HELO compuserve.com) (66.28.118.5)
   by 66.28.88.9 with SMTP; 24 Jul 2002 17:38:56 -0000',
             'X-Mailer',
             'SoftwareDiamonds.com/software/ Inetdia::sdmailit sdmailit() 1.0.005 May 9, 2002',
             'Date',
             'Wed, 24 Jul 2002 12:30:37 -0500',
             'To',
             'support@SoftwareDiamonds.com',
             'From',
             'somebody@compuserve.com',
             'Subject',
             '*~~* Software Diamonds sdform.pl *~~*',
             'X-Body',
             'Comments:
 i read an interesting article many years ago about the effects of drugs on spiders in National Geographic Magazine. %0Ait showed webs woven by spiders ""under the influence.""  spiders high on marijuana wove bad webs; spiders on LSD wove exceptionally geometrical webs.%0Aanyone know how i can locate the date of and issue this appeared in?%0A %0Amany thanks in advance to someone who has walked at least a mile in my shoes.
 ^^
 Email:
 sombody@compuserve.com
 ^^
 REMOTE_ADDR:
 216.192.88.155
 ^^
 HTTP_USER_AGENT:
 Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)
 ^^
 HTTP_REFERER:
 http://www.spiderdiamonds.com/spider.htm
 ^^
 '
           ],
           [
             'X-Pickup-Date',
             'Wed Sep 25 21:49:29 2002',
             'X-Persona',
             '<support@SoftwareDiamonds.com>',
             'Return-Path',
             '<everybody@hotmail.com>',
             'Delivered-To',
             'support@SoftwareDiamonds.com',
             'Received',
             '(qmail 24171 invoked from network); 25 Sep 2002 20:59:11 -0000',
             'Received',
             'from unknown (HELO mail.hbhosting.com) (66.28.88.4)
   by mail.ixpres.com with SMTP; 25 Sep 2002 20:59:11 -0000',
             'Received',
             '(qmail 75277 invoked by uid 89); 25 Sep 2002 21:10:22 -0000',
             'Delivered-To',
             'softwarediamonds.com-support@softwarediamonds.com',
             'Received',
             '(qmail 75275 invoked from network); 25 Sep 2002 21:10:22 -0000',
             'Received',
             'from unknown (HELO hotmail.com) (66.28.118.5)
   by 66.28.88.9 with SMTP; 25 Sep 2002 21:10:22 -0000',
             'X-Mailer',
             'SoftwareDiamonds.com/software/ Inetdia::sdmailit sdmailit() 1.0.005 May 9, 2002',
             'Date',
             'Wed, 25 Sep 2002 16:06:27 -0500',
             'To',
             'support@SoftwareDiamonds.com',
             'From',
             'everybody@hotmail.com',
             'Subject',
             '*~~* Software Diamonds sdform.pl *~~*',
             'X-Body',
             '
 Comments:
 Can I order a personalized stamp pad (name and address??
 ^^
 Email:
 everybody@hotmail.com
 ^^
 Name:
 Paul
 ^^
 REMOTE_ADDR:
 24.165.157.193
 ^^
 HTTP_USER_AGENT:
 Mozilla/4.0 (compatible; MSIE 5.5; Windows 98; Win 9x 4.90)
 ^^
 HTTP_REFERER:
 http://stationary.merchantdiamonds.com/
 ^^
 '
           ],
           [
             'X-Pickup-Date',
             'Tue Dec 31 10:19:58 2002',
             'X-Persona',
             '<support@SoftwareDiamonds.com>',
             'Return-Path',
             '<girl@hotmail.com>',
             'Delivered-To',
             'support@SoftwareDiamonds.com',
             'Received',
             '(qmail 6236 invoked from network); 31 Dec 2002 09:04:00 -0000',
             'Received',
             'from one.nospam.ixpres.com (216.240.160.191)
   by mail.ixpres.com with SMTP; 31 Dec 2002 09:04:00 -0000',
             'Received',
             '(qmail 18721 invoked by uid 106); 30 Dec 2002 10:03:56 -0000',
             'Received',
             'from unknown (HELO mail.hbhosting.com) (66.28.88.4)
   by one.nospam.ixpres.com with SMTP; 30 Dec 2002 10:03:55 -0000',
             'Received',
             '(qmail 91583 invoked by uid 89); 31 Dec 2002 09:05:52 -0000',
             'Received',
             '(qmail 91581 invoked from network); 31 Dec 2002 09:05:52 -0000',
             'Received',
             'from unknown (HELO hotmail.com) (66.28.118.5)
   by zeus with SMTP; 31 Dec 2002 09:05:52 -0000',
             'X-Spam-Status',
             'No, hits=2.9 required=8.0 source=66.28.88.4 from=janigeorg@hotmail.com addr=1',
             'Delivered-To',
             'softwarediamonds.com-support@softwarediamonds.com',
             'X-Mailer',
             'SoftwareDiamonds.com/software/ Inetdia::sdmailit sdmailit() 1.0.005 May 9, 2002',
             'Date',
             'Tue, 31 Dec 2002 03:20:52 -0600',
             'To',
             'support@SoftwareDiamonds.com',
             'From',
             'girl@hotmail.com',
             'Subject',
             '*~~* Software Diamonds sdform.pl *~~*',
             'X-Qmail-Scanner-Message-ID',
             '<104124263551318713@one.nospam.ixpres.com>',
             'X-AntiVirus',
             'checked by Vexira MailArmor (version: 2.0.1.6; VAE: 6.17.0.2; VDF: 6.17.0.10; host: one.nospam.ixpres.com)',
             'X-Body',
             '
 Email:
 girl@hotmail.com
 ^^
 Tutorial:
 *~~* Better Health thru Biochemistry *~~*
 ^^
 REMOTE_ADDR:
 81.26.160.109
 ^^
 HTTP_USER_AGENT:
 Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)
 ^^
 HTTP_REFERER:
 http://camera.merchantdiamonds.com/
 ^^
 '
           ]
 );
 ^

 QC:
 my $expected1 = 
 'X-Pickup-Date: Wed Jul 24 20:20:19 2002
 X-Persona: <support@SoftwareDiamonds.com>
 Return-Path: somebody@compuserve.com
 Delivered-To: support@SoftwareDiamonds.com
 Received: (qmail 7321 invoked from network); 24 Jul 2002 17:26:21 -0000
 Received: from unknown (HELO mail.hbhosting.com) (66.28.88.4)
   by mail.ixpres.com with SMTP; 24 Jul 2002 17:26:21 -0000
 Received: (qmail 17747 invoked by uid 89); 24 Jul 2002 17:38:56 -0000
 Delivered-To: softwarediamonds.com-support@softwarediamonds.com
 Received: (qmail 17745 invoked from network); 24 Jul 2002 17:38:56 -0000
 Received: from unknown (HELO compuserve.com) (66.28.118.5)
   by 66.28.88.9 with SMTP; 24 Jul 2002 17:38:56 -0000
 X-Mailer: SoftwareDiamonds.com/software/ Inetdia::sdmailit sdmailit() 1.0.005 May 9, 2002
 Date: Wed, 24 Jul 2002 12:30:37 -0500
 To: support@SoftwareDiamonds.com
 From: somebody@compuserve.com
 Subject: *~~* Software Diamonds sdform.pl *~~*
 Comments:
 i read an interesting article many years ago about the effects of drugs on spiders in National Geographic Magazine. %0Ait showed webs woven by spiders ""under the influence.""  spiders high on marijuana wove bad webs; spiders on LSD wove exceptionally geometrical webs.%0Aanyone know how i can locate the date of and issue this appeared in?%0A %0Amany thanks in advance to someone who has walked at least a mile in my shoes.
 ^^
 Email:
 sombody@compuserve.com
 ^^
 REMOTE_ADDR:
 216.192.88.155
 ^^
 HTTP_USER_AGENT:
 Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)
 ^^
 HTTP_REFERER:
 http://www.spiderdiamonds.com/spider.htm
 ^^
 '
 ^
 VO: ^
  N: UUT not loaded^
  A: $loaded = $fp->is_package_loaded($uut)^
 SE:  ''^
 ok: 1^

=head2 ok: 2

  N: Load UUT^

  C:
 my $errors = $fp->load_package($uut, qw(is_handle encode_field decode_field
                 encode_record decode_record));
 ^
  A: $errors^
 SE: ''^
 ok: 2^

=head2 ok: 3

  N: Tie::Eudora Version $Tie::Eudora::VERSION loaded^
  A: $fp->is_package_loaded($uut)^
  E: 1^
 ok: 3^

=head2 ok: 4

  N: Write Eudora Mailbox^
  R: L<Eudora Mailbox Format|Tie::Eudora/Eudora Mailbox Format>^

  C:
     tie *MAILBOX, 'Tie::Eudora';
     open MAILBOX,'>',$mbx;
     print MAILBOX @test_data;
     close MAILBOX;
 ^
  A: $snl->fin($mbx)^
  E: $snl->fin($expected_file)^
 ok: 4^

=head2 ok: 5

  N: Read Eudora Mailbox^
  R: L<Eudora Mailbox Lossless|Tie::Eudora/Eudora Mailbox Lossless>^

  C:
     open MAILBOX,'<',$mbx;
     @fields = <MAILBOX>;
     close MAILBOX;
 ^
 QC: $snl->fout($actual,Dumper([@fields]))^
  A: [@fields]^
  E: [@test_data]^
 ok: 5^

=head2 ok: 6

  N: Object encode email fields^
  R: L<RFC822 Email Format|Tie::Eudora/RFC822 Email Format>^
  C: my $eudora = new Tie::Eudora^
  A: my $email = ${$eudora->encode_field($test_data[0])}^
  E: $expected1^
 ok: 6^

=head2 ok: 7

  N: Object decode email fields^
  R: L<RFC822 Email Lossless|Tie::Eudora/RFC822 Email Lossless>^
  A: $eudora->decode_field($email)^
  E: $test_data[0]^
 ok: 7^

=head2 ok: 8

  N: Subroutine encode email fields^
  R: L<RFC822 Email Format|Tie::Eudora/RFC822 Email Format>^
  A: $email = ${encode_field($test_data[0])}^
  E: $expected1^
 ok: 8^

=head2 ok: 9

  N: Subroutine decode email fields^
  R: L<RFC822 Email Lossless|Tie::Eudora/RFC822 Email Lossless>^
  A: decode_field($email)^
  E: $test_data[0]^
 ok: 9^



#######
#  
#  5. REQUIREMENTS TRACEABILITY
#
#

=head1 REQUIREMENTS TRACEABILITY

  Requirement                                                      Test
 ---------------------------------------------------------------- ----------------------------------------------------------------
 L<Eudora Mailbox Format|Tie::Eudora/Eudora Mailbox Format>       L<t::Tie::Eudora/ok: 4>
 L<Eudora Mailbox Lossless|Tie::Eudora/Eudora Mailbox Lossless>   L<t::Tie::Eudora/ok: 5>
 L<RFC822 Email Format|Tie::Eudora/RFC822 Email Format>           L<t::Tie::Eudora/ok: 6>
 L<RFC822 Email Format|Tie::Eudora/RFC822 Email Format>           L<t::Tie::Eudora/ok: 8>
 L<RFC822 Email Lossless|Tie::Eudora/RFC822 Email Lossless>       L<t::Tie::Eudora/ok: 7>
 L<RFC822 Email Lossless|Tie::Eudora/RFC822 Email Lossless>       L<t::Tie::Eudora/ok: 9>


  Test                                                             Requirement
 ---------------------------------------------------------------- ----------------------------------------------------------------
 L<t::Tie::Eudora/ok: 4>                                          L<Eudora Mailbox Format|Tie::Eudora/Eudora Mailbox Format>
 L<t::Tie::Eudora/ok: 5>                                          L<Eudora Mailbox Lossless|Tie::Eudora/Eudora Mailbox Lossless>
 L<t::Tie::Eudora/ok: 6>                                          L<RFC822 Email Format|Tie::Eudora/RFC822 Email Format>
 L<t::Tie::Eudora/ok: 7>                                          L<RFC822 Email Lossless|Tie::Eudora/RFC822 Email Lossless>
 L<t::Tie::Eudora/ok: 8>                                          L<RFC822 Email Format|Tie::Eudora/RFC822 Email Format>
 L<t::Tie::Eudora/ok: 9>                                          L<RFC822 Email Lossless|Tie::Eudora/RFC822 Email Lossless>


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

=item 3

Commercial installation of the binary or source
must visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://softwarediamonds.com
and provide means
for the installer to actively accept
the list of conditions; 
otherwise, a license fee must be paid to
Softwareware Diamonds.

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


=over 4

=item L<Tie::Layers|Tie::Layers>

=item L<Tie::FormA|Tie::FormA>

=item L<Tie::Eudora|Tie::CSV>

=item L<Data::Query|Data::Query>

=back

=back

=for html


=cut

__DATA__

Name: ^
File_Spec: Unix^
UUT: Tie::Eudora^
Revision: -^
Version: ^
End_User: General Public^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
STD2167_Template: ^
Detail_Template: ^
Classification: None^
Temp: temp.pl^
Demo: Eudora.d^
Verify: Eudora.t^


 T: 9^


 C:
    use File::Package;
    use File::SmartNL;
    use File::Spec;
    use Data::Dumper;
    $Data::Dumper::Sortkeys = 1; # dump hashes sorted
    $Data::Dumper::Terse = 1; # avoid Varn Variables

    my $uut = 'Tie::Eudora'; # Unit Under Test
    my $fp = 'File::Package';
    my $snl = 'File::SmartNL';
    my $loaded;

    my (@fields);  # force context

    my $mbx = 'Eudora1.mbx';
^


QC:
######
# Not needed for demo, so use the Quiet Code (QC) 
# 
my $expected_file = 'Eudora2.mbx';
my $actual = 'Eudora1.txt';
unlink $actual;
unlink $mbx;

my @test_data = (
          [
            'X-Pickup-Date',
            'Wed Jul 24 20:20:19 2002',
            'X-Persona',
            '<support@SoftwareDiamonds.com>',
            'Return-Path',
            'somebody@compuserve.com',
            'Delivered-To',
            'support@SoftwareDiamonds.com',
            'Received',
            '(qmail 7321 invoked from network); 24 Jul 2002 17:26:21 -0000',
            'Received',
            'from unknown (HELO mail.hbhosting.com) (66.28.88.4)
  by mail.ixpres.com with SMTP; 24 Jul 2002 17:26:21 -0000',
            'Received',
            '(qmail 17747 invoked by uid 89); 24 Jul 2002 17:38:56 -0000',
            'Delivered-To',
            'softwarediamonds.com-support@softwarediamonds.com',
            'Received',
            '(qmail 17745 invoked from network); 24 Jul 2002 17:38:56 -0000',
            'Received',
            'from unknown (HELO compuserve.com) (66.28.118.5)
  by 66.28.88.9 with SMTP; 24 Jul 2002 17:38:56 -0000',
            'X-Mailer',
            'SoftwareDiamonds.com/software/ Inetdia::sdmailit sdmailit() 1.0.005 May 9, 2002',
            'Date',
            'Wed, 24 Jul 2002 12:30:37 -0500',
            'To',
            'support@SoftwareDiamonds.com',
            'From',
            'somebody@compuserve.com',
            'Subject',
            '*~~* Software Diamonds sdform.pl *~~*',
            'X-Body',
            'Comments:
i read an interesting article many years ago about the effects of drugs on spiders in National Geographic Magazine. %0Ait showed webs woven by spiders ""under the influence.""  spiders high on marijuana wove bad webs; spiders on LSD wove exceptionally geometrical webs.%0Aanyone know how i can locate the date of and issue this appeared in?%0A %0Amany thanks in advance to someone who has walked at least a mile in my shoes.
^^

Email:
sombody@compuserve.com
^^

REMOTE_ADDR:
216.192.88.155
^^

HTTP_USER_AGENT:
Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)
^^

HTTP_REFERER:
http://www.spiderdiamonds.com/spider.htm
^^

'
          ],

          [
            'X-Pickup-Date',
            'Wed Sep 25 21:49:29 2002',
            'X-Persona',
            '<support@SoftwareDiamonds.com>',
            'Return-Path',
            '<everybody@hotmail.com>',
            'Delivered-To',
            'support@SoftwareDiamonds.com',
            'Received',
            '(qmail 24171 invoked from network); 25 Sep 2002 20:59:11 -0000',
            'Received',
            'from unknown (HELO mail.hbhosting.com) (66.28.88.4)
  by mail.ixpres.com with SMTP; 25 Sep 2002 20:59:11 -0000',
            'Received',
            '(qmail 75277 invoked by uid 89); 25 Sep 2002 21:10:22 -0000',
            'Delivered-To',
            'softwarediamonds.com-support@softwarediamonds.com',
            'Received',
            '(qmail 75275 invoked from network); 25 Sep 2002 21:10:22 -0000',
            'Received',
            'from unknown (HELO hotmail.com) (66.28.118.5)
  by 66.28.88.9 with SMTP; 25 Sep 2002 21:10:22 -0000',
            'X-Mailer',
            'SoftwareDiamonds.com/software/ Inetdia::sdmailit sdmailit() 1.0.005 May 9, 2002',
            'Date',
            'Wed, 25 Sep 2002 16:06:27 -0500',
            'To',
            'support@SoftwareDiamonds.com',
            'From',
            'everybody@hotmail.com',
            'Subject',
            '*~~* Software Diamonds sdform.pl *~~*',
            'X-Body',
            '
Comments:
Can I order a personalized stamp pad (name and address??
^^

Email:
everybody@hotmail.com
^^

Name:
Paul
^^

REMOTE_ADDR:
24.165.157.193
^^

HTTP_USER_AGENT:
Mozilla/4.0 (compatible; MSIE 5.5; Windows 98; Win 9x 4.90)
^^

HTTP_REFERER:
http://stationary.merchantdiamonds.com/
^^

'
          ],
          [
            'X-Pickup-Date',
            'Tue Dec 31 10:19:58 2002',
            'X-Persona',
            '<support@SoftwareDiamonds.com>',
            'Return-Path',
            '<girl@hotmail.com>',
            'Delivered-To',
            'support@SoftwareDiamonds.com',
            'Received',
            '(qmail 6236 invoked from network); 31 Dec 2002 09:04:00 -0000',
            'Received',
            'from one.nospam.ixpres.com (216.240.160.191)
  by mail.ixpres.com with SMTP; 31 Dec 2002 09:04:00 -0000',
            'Received',
            '(qmail 18721 invoked by uid 106); 30 Dec 2002 10:03:56 -0000',
            'Received',
            'from unknown (HELO mail.hbhosting.com) (66.28.88.4)
  by one.nospam.ixpres.com with SMTP; 30 Dec 2002 10:03:55 -0000',
            'Received',
            '(qmail 91583 invoked by uid 89); 31 Dec 2002 09:05:52 -0000',
            'Received',
            '(qmail 91581 invoked from network); 31 Dec 2002 09:05:52 -0000',
            'Received',
            'from unknown (HELO hotmail.com) (66.28.118.5)
  by zeus with SMTP; 31 Dec 2002 09:05:52 -0000',
            'X-Spam-Status',
            'No, hits=2.9 required=8.0 source=66.28.88.4 from=janigeorg@hotmail.com addr=1',
            'Delivered-To',
            'softwarediamonds.com-support@softwarediamonds.com',
            'X-Mailer',
            'SoftwareDiamonds.com/software/ Inetdia::sdmailit sdmailit() 1.0.005 May 9, 2002',
            'Date',
            'Tue, 31 Dec 2002 03:20:52 -0600',
            'To',
            'support@SoftwareDiamonds.com',
            'From',
            'girl@hotmail.com',
            'Subject',
            '*~~* Software Diamonds sdform.pl *~~*',
            'X-Qmail-Scanner-Message-ID',
            '<104124263551318713@one.nospam.ixpres.com>',
            'X-AntiVirus',
            'checked by Vexira MailArmor (version: 2.0.1.6; VAE: 6.17.0.2; VDF: 6.17.0.10; host: one.nospam.ixpres.com)',
            'X-Body',
            '
Email:
girl@hotmail.com
^^

Tutorial:
*~~* Better Health thru Biochemistry *~~*
^^

REMOTE_ADDR:
81.26.160.109
^^

HTTP_USER_AGENT:
Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)
^^

HTTP_REFERER:
http://camera.merchantdiamonds.com/
^^

'
          ]

);
^


QC:
my $expected1 = 
'X-Pickup-Date: Wed Jul 24 20:20:19 2002
X-Persona: <support@SoftwareDiamonds.com>
Return-Path: somebody@compuserve.com
Delivered-To: support@SoftwareDiamonds.com
Received: (qmail 7321 invoked from network); 24 Jul 2002 17:26:21 -0000
Received: from unknown (HELO mail.hbhosting.com) (66.28.88.4)
  by mail.ixpres.com with SMTP; 24 Jul 2002 17:26:21 -0000
Received: (qmail 17747 invoked by uid 89); 24 Jul 2002 17:38:56 -0000
Delivered-To: softwarediamonds.com-support@softwarediamonds.com
Received: (qmail 17745 invoked from network); 24 Jul 2002 17:38:56 -0000
Received: from unknown (HELO compuserve.com) (66.28.118.5)
  by 66.28.88.9 with SMTP; 24 Jul 2002 17:38:56 -0000
X-Mailer: SoftwareDiamonds.com/software/ Inetdia::sdmailit sdmailit() 1.0.005 May 9, 2002
Date: Wed, 24 Jul 2002 12:30:37 -0500
To: support@SoftwareDiamonds.com
From: somebody@compuserve.com
Subject: *~~* Software Diamonds sdform.pl *~~*

Comments:
i read an interesting article many years ago about the effects of drugs on spiders in National Geographic Magazine. %0Ait showed webs woven by spiders ""under the influence.""  spiders high on marijuana wove bad webs; spiders on LSD wove exceptionally geometrical webs.%0Aanyone know how i can locate the date of and issue this appeared in?%0A %0Amany thanks in advance to someone who has walked at least a mile in my shoes.
^^

Email:
sombody@compuserve.com
^^

REMOTE_ADDR:
216.192.88.155
^^

HTTP_USER_AGENT:
Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)
^^

HTTP_REFERER:
http://www.spiderdiamonds.com/spider.htm
^^

'
^

VO: ^
 N: UUT not loaded^
 A: $loaded = $fp->is_package_loaded($uut)^
SE:  ''^
ok: 1^

 N: Load UUT^

 C:
my $errors = $fp->load_package($uut, qw(is_handle encode_field decode_field
                encode_record decode_record));
^

 A: $errors^
SE: ''^
ok: 2^

 N: Tie::Eudora Version $Tie::Eudora::VERSION loaded^
 A: $fp->is_package_loaded($uut)^
 E: 1^
ok: 3^

 N: Write Eudora Mailbox^
 R: L<Eudora Mailbox Format|Tie::Eudora/Eudora Mailbox Format>^

 C:
    tie *MAILBOX, 'Tie::Eudora';
    open MAILBOX,'>',$mbx;
    print MAILBOX @test_data;
    close MAILBOX;
^

 A: $snl->fin($mbx)^
 E: $snl->fin($expected_file)^
ok: 4^

 N: Read Eudora Mailbox^
 R: L<Eudora Mailbox Lossless|Tie::Eudora/Eudora Mailbox Lossless>^

 C:
    open MAILBOX,'<',$mbx;
    @fields = <MAILBOX>;
    close MAILBOX;
^

QC: $snl->fout($actual,Dumper([@fields]))^
 A: [@fields]^
 E: [@test_data]^
ok: 5^

 N: Object encode email fields^
 R: L<RFC822 Email Format|Tie::Eudora/RFC822 Email Format>^
 C: my $eudora = new Tie::Eudora^
 A: my $email = ${$eudora->encode_field($test_data[0])}^
 E: $expected1^
ok: 6^

 N: Object decode email fields^
 R: L<RFC822 Email Lossless|Tie::Eudora/RFC822 Email Lossless>^
 A: $eudora->decode_field(\$email)^
 E: $test_data[0]^
ok: 7^

 N: Subroutine encode email fields^
 R: L<RFC822 Email Format|Tie::Eudora/RFC822 Email Format>^
 A: $email = ${encode_field($test_data[0])}^
 E: $expected1^
ok: 8^

 N: Subroutine decode email fields^
 R: L<RFC822 Email Lossless|Tie::Eudora/RFC822 Email Lossless>^
 A: decode_field(\$email)^
 E: $test_data[0]^
ok: 9^


QC:
  unlink $actual;
  unlink $mbx;
^



See_Also:
 
\=over 4

\=item L<Tie::Layers|Tie::Layers>

\=item L<Tie::FormA|Tie::FormA>

\=item L<Tie::Eudora|Tie::CSV>

\=item L<Data::Query|Data::Query>

\=back
^


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

\=item 3

Commercial installation of the binary or source
must visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://softwarediamonds.com
and provide means
for the installer to actively accept
the list of conditions; 
otherwise, a license fee must be paid to
Softwareware Diamonds.

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
