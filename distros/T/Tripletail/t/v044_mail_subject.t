#! perl -w

use strict;
use warnings;

use Test::More tests =>
  + 1
;
use Tripletail '/dev/null';

&test_mail_subject();

# -----------------------------------------------------------------------------
# test.
#
sub test_mail_subject
{
  my $mail = $TL->newMail();
  $mail->setHeader( Subject => 'TEST テスト TEST' );
  $mail->setBody( "test\r\n" );

  my $str = $mail->toStr;
  my ($subj) = $str =~ /(^Subject:.*\r\n( .*\r\n)*)/m;
  is($subj, "Subject: TEST\r\n =?ISO-2022-JP?B?GyRCJUYlOSVIGyhC?= TEST\r\n");
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
