#!/home/ben/software/install/bin/perl
use warnings;
use strict;
# This example demonstrates use with the Test::More testing framework.
use Test::More;
use WWW::CheckGzip;
my $wc = WWW::CheckGzip->new (\& mycheck);
$wc->check ('http://www.piedpiper.com');
done_testing ();
exit;

sub mycheck
{
    my ($ok, $message) = @_;
    ok ($ok, $message);
}
