use strict;
use warnings FATAL => 'all';

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %config = (
    NAME           => 'Test::Email',
    VERSION_FROM   => 'lib/Test/Email.pm', # finds $VERSION
    PREREQ_PM      => {
        'Mail::POP3Client' => 0,
        'MIME::Parser'     => 0,
        'MIME::Entity'     => 0,
        'Test::Builder'    => 0,
        'Mail::Sendmail'   => 0, # for tests
    },
    ABSTRACT_FROM  => 'lib/Test/Email.pm',
    AUTHOR         => 'James Tolley <james@cpan.org>',
    test           => { TESTS => 't/05_email.t' },
);

# find out about running tests for POP3
if (! exists $ENV{TEST_POP3_HOST}) {
    print "\nTo run tests for Test::POP3, set ".
        "the following environment variables:\n".
        "TEST_POP3_HOST, TEST_POP3_USER, TEST_POP3_PASS, ".
        "TEST_POP3_SMTP, and TEST_POP3_EMAIL.\n".
        "Then run this script again.\n\n";

    sleep 5;
}
else {
    $config{test}->{TESTS} = join ' ', glob 't/*.t';
}

WriteMakefile(%config);

