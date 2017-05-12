#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.01';   # automatically generated file
$DATE = '2004/05/29';


##### Demonstration Script ####
#
# Name: Eudora.d
#
# UUT: Tie::Eudora
#
# The module Test::STDmaker generated this demo script from the contents of
#
# t::Tie::Eudora 
#
# Don't edit this test script file, edit instead
#
# t::Tie::Eudora
#
#	ANY CHANGES MADE HERE TO THIS SCRIPT FILE WILL BE LOST
#
#       the next time Test::STDmaker generates this script file.
#
#

######
#
# The working directory is the directory of the generated file
#
use vars qw($__restore_dir__ @__restore_inc__ );

BEGIN {
    use Cwd;
    use File::Spec;
    use FindBin;

    ########
    # The working directory for this script file is the directory where
    # the test script resides. Thus, any relative files written or read
    # by this test script are located relative to this test script.
    #
    use vars qw( $__restore_dir__ );
    $__restore_dir__ = cwd();
    my ($vol, $dirs) = File::Spec->splitpath($FindBin::Bin,'nofile');
    chdir $vol if $vol;
    chdir $dirs if $dirs;

    #######
    # Pick up any testing program modules off this test script.
    #
    # When testing on a target site before installation, place any test
    # program modules that should not be installed in the same directory
    # as this test script. Likewise, when testing on a host with a @INC
    # restricted to just raw Perl distribution, place any test program
    # modules in the same directory as this test script.
    #
    use lib $FindBin::Bin;

    ########
    # Using Test::Tech, a very light layer over the module "Test" to
    # conduct the tests.  The big feature of the "Test::Tech: module
    # is that it takes expected and actual references and stringify
    # them by using "Data::Secs2" before passing them to the "&Test::ok"
    # Thus, almost any time of Perl data structures may be
    # compared by passing a reference to them to Test::Tech::ok
    #
    # Create the test plan by supplying the number of tests
    # and the todo tests
    #
    require Test::Tech;
    Test::Tech->import( qw(demo finish is_skip ok ok_sub plan skip 
                          skip_sub skip_tests tech_config) );

}

END {

    #########
    # Restore working directory and @INC back to when enter script
    #
    @INC = @lib::ORIG_INC;
    chdir $__restore_dir__;

}

print << 'MSG';

~~~~~~ Demonstration overview ~~~~~
 
The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

MSG

demo( "\ \ \ \ use\ File\:\:Package\;\
\ \ \ \ use\ File\:\:SmartNL\;\
\ \ \ \ use\ File\:\:Spec\;\
\ \ \ \ use\ Data\:\:Dumper\;\
\ \ \ \ \$Data\:\:Dumper\:\:Sortkeys\ \=\ 1\;\ \#\ dump\ hashes\ sorted\
\ \ \ \ \$Data\:\:Dumper\:\:Terse\ \=\ 1\;\ \#\ avoid\ Varn\ Variables\
\
\ \ \ \ my\ \$uut\ \=\ \'Tie\:\:Eudora\'\;\ \#\ Unit\ Under\ Test\
\ \ \ \ my\ \$fp\ \=\ \'File\:\:Package\'\;\
\ \ \ \ my\ \$snl\ \=\ \'File\:\:SmartNL\'\;\
\ \ \ \ my\ \$loaded\;\
\
\ \ \ \ my\ \(\@fields\)\;\ \ \#\ force\ context\
\
\ \ \ \ my\ \$mbx\ \=\ \'Eudora1\.mbx\'\;"); # typed in command           
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

    my $mbx = 'Eudora1.mbx'; # execution



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
^

Email:
sombody@compuserve.com
^

REMOTE_ADDR:
216.192.88.155
^

HTTP_USER_AGENT:
Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)
^

HTTP_REFERER:
http://www.spiderdiamonds.com/spider.htm
^

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
^

Email:
everybody@hotmail.com
^

Name:
Paul
^

REMOTE_ADDR:
24.165.157.193
^

HTTP_USER_AGENT:
Mozilla/4.0 (compatible; MSIE 5.5; Windows 98; Win 9x 4.90)
^

HTTP_REFERER:
http://stationary.merchantdiamonds.com/
^

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
^

Tutorial:
*~~* Better Health thru Biochemistry *~~*
^

REMOTE_ADDR:
81.26.160.109
^

HTTP_USER_AGENT:
Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)
^

HTTP_REFERER:
http://camera.merchantdiamonds.com/
^

'
          ]

); # execution

 

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
^

Email:
sombody@compuserve.com
^

REMOTE_ADDR:
216.192.88.155
^

HTTP_USER_AGENT:
Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)
^

HTTP_REFERER:
http://www.spiderdiamonds.com/spider.htm
^

'; # execution

 

print << "EOF";

 ##################
 # Load UUT
 # 
 
EOF

demo( "my\ \$errors\ \=\ \$fp\-\>load_package\(\$uut\,\ qw\(is_handle\ encode_field\ decode_field\
\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ encode_record\ decode_record\)\)\;"); # typed in command           
      my $errors = $fp->load_package($uut, qw(is_handle encode_field decode_field
                encode_record decode_record)); # execution



demo( "\$errors", # typed in command           
      $errors); # execution


print << "EOF";

 ##################
 # Tie::Eudora Version $Tie::Eudora::VERSION loaded
 # 
 
EOF

demo( "\$fp\-\>is_package_loaded\(\$uut\)", # typed in command           
      $fp->is_package_loaded($uut)); # execution


print << "EOF";

 ##################
 # Write Eudora Mailbox
 # 
 
EOF

demo( "\ \ \ \ tie\ \*MAILBOX\,\ \'Tie\:\:Eudora\'\;\
\ \ \ \ open\ MAILBOX\,\'\>\'\,\$mbx\;\
\ \ \ \ print\ MAILBOX\ \@test_data\;\
\ \ \ \ close\ MAILBOX\;"); # typed in command           
          tie *MAILBOX, 'Tie::Eudora';
    open MAILBOX,'>',$mbx;
    print MAILBOX @test_data;
    close MAILBOX; # execution



demo( "\$snl\-\>fin\(\$mbx\)", # typed in command           
      $snl->fin($mbx)); # execution


print << "EOF";

 ##################
 # Read Eudora Mailbox
 # 
 
EOF

demo( "\ \ \ \ open\ MAILBOX\,\'\<\'\,\$mbx\;\
\ \ \ \ \@fields\ \=\ \<MAILBOX\>\;\
\ \ \ \ close\ MAILBOX\;"); # typed in command           
          open MAILBOX,'<',$mbx;
    @fields = <MAILBOX>;
    close MAILBOX; # execution



      $snl->fout($actual,Dumper([@fields])); # execution

 

demo( "\[\@fields\]", # typed in command           
      [@fields]); # execution


print << "EOF";

 ##################
 # Object encode email fields
 # 
 
EOF

demo( "my\ \$eudora\ \=\ new\ Tie\:\:Eudora"); # typed in command           
      my $eudora = new Tie::Eudora; # execution



demo( "my\ \$email\ \=\ \$\{\$eudora\-\>encode_field\(\$test_data\[0\]\)\}", # typed in command           
      my $email = ${$eudora->encode_field($test_data[0])}); # execution


print << "EOF";

 ##################
 # Object decode email fields
 # 
 
EOF

demo( "\$eudora\-\>decode_field\(\\\$email\)", # typed in command           
      $eudora->decode_field(\$email)); # execution


print << "EOF";

 ##################
 # Subroutine encode email fields
 # 
 
EOF

demo( "\$email\ \=\ \$\{encode_field\(\$test_data\[0\]\)\}", # typed in command           
      $email = ${encode_field($test_data[0])}); # execution


print << "EOF";

 ##################
 # Subroutine decode email fields
 # 
 
EOF

demo( "decode_field\(\\\$email\)", # typed in command           
      decode_field(\$email)); # execution


        unlink $actual;
  unlink $mbx; # execution

 


=head1 NAME

Eudora.d - demostration script for Tie::Eudora

=head1 SYNOPSIS

 Eudora.d

=head1 OPTIONS

None.

=head1 COPYRIGHT

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

## end of test script file ##

=cut

