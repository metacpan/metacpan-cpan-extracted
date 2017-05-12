#!/usr/bin/perl 

use strict;
use warnings;
use Test::More tests => 3;
use Test::Mail;

my $tm = Test::Mail->new(logfile => "/tmp/testmail.log");
$tm->accept();

=head2 newsletter

Tests for our weekly newsletter email.

=cut

sub newsletter {
    my ($self) = @_;
    like($self->header("Subject"), qr/Newsletter/,
        "Subject contains 'Newsletter'");
    is($self->header("Reply-To"), 'noreply@example.com',
        "No-reply address");
}

