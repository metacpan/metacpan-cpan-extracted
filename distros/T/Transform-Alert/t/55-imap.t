#use sanity;
use Test::Most (
   $ENV{TATEST_IMAP_JSONY} && $ENV{TATEST_SMTP_JSONY} && $ENV{TATEST_EMAIL_ADDY} ?
      (tests => 36) :
      (skip_all => 'Set $ENV{TATEST_IMAP_JSONY}, _SMTP_JSONY, and _EMAIL_ADDY to run this test.  (WARNING: This will read/move mail in that IMAP box!)')
);
use Path::Class;
use lib dir(qw{ t lib })->stringify;
use TestDaemon;

TestDaemon->email_test('imap');
