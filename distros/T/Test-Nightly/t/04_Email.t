#!/usr/bin/perl -w

use lib qw( ./blib/lib ../blib/lib );

use strict;
use Test::More tests => 5;

#==================================================
# Check that module loads
#==================================================

BEGIN { use_ok( 'Test::Nightly::Email' ) };

my @test_methods = qw(new email);

#==================================================
# Check module methods
#==================================================
can_ok('Test::Nightly::Email', @test_methods);

my $test_obj1 = Test::Nightly::Email->new();

my $subject = 'This is a test subject';

$test_obj1->email({
	subject	=> $subject
});

#==================================================
# Check default mailer is Sendmail
#==================================================

ok($test_obj1->mailer() eq 'Sendmail', 'email() - When nothing is supplied for mailer, the default mailer is set to Sendmail');

#==================================================
# Check default content_type is 'text/html'
#==================================================

ok($test_obj1->content_type() eq 'text/html', 'email() - When nothing is supplied for content_type, the default is set to text/html');

#==================================================
# Check the subject is set
#==================================================

ok($test_obj1->subject() eq $subject, 'email() - As expected, subject is "'.$subject.'"');

