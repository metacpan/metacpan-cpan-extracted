#!/usr/bin/perl
use warnings;
use strict;
use lib 'lib';
use Test::More;
use Test::Exception;
use WebService::VaultPress::Partner::Request::GoldenTicket;

ok my $vp = WebService::VaultPress::Partner::Request::GoldenTicket->new(
    email => 'alan.shore@gmail.com',
    fname => 'Alan',
    lname => 'Shore',
), "Creating A Golden Ticket Request Object";

is $vp->email, 'alan.shore@gmail.com', "Request Email Matched";
is $vp->fname, 'Alan', "Request First Name Matches";
is $vp->lname, 'Shore', "Request Last Name Matches";

dies_ok sub { 
    WebService::VaultPress::Partner::Request::GoldenTicket->new(
        fname => 'Alan',
        lname => 'Shore',
    );
}, "Request Requires Email";

dies_ok sub { 
    WebService::VaultPress::Partner::Request::GoldenTicket->new(
        email => 'alan.shore@gmail.com',
        lname => 'Shore',
    );
}, "Request Requires First Name";

dies_ok sub { 
    WebService::VaultPress::Partner::Request::GoldenTicket->new(
        email => 'alan.shore@gmail.com',
        fname => 'Alan',
    );
}, "Request Requires Last Name";

done_testing;
