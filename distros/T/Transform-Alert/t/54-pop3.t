use sanity;
use Test::Most (
   $ENV{TATEST_POP3_JSONY} && $ENV{TATEST_SMTP_JSONY} && $ENV{TATEST_EMAIL_ADDY} ?
      (tests => 36) :
      (skip_all => 'Set $ENV{TATEST_POP3_JSONY}, _SMTP_JSONY, and _EMAIL_ADDY to run this test.  (WARNING: This will delete all mail in that POP3 box!)')
);
use Path::Class;
use lib dir(qw{ t lib })->stringify;
use TestDaemon;

TestDaemon->email_test('pop3');
