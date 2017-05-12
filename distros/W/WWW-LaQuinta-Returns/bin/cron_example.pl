#!/usr/bin/perl

use strict;
use warnings;

use DBM::Deep;
use MIME::Lite;
use WWW::LaQuinta::Returns;

# Replace these with your own values
my $account  = 'W123456';
my $password = 'opensesame';
my $db_file  = 'lq.db';
my $email    = 'youremailhere@yourdomainhere.com';

my $lq = WWW::LaQuinta::Returns->new(
    account  => $account,
    password => $password,
);

my $points     = $lq->balance;
my $db         = DBM::Deep->new($db_file);
my $old_points = $db->get('points') || 0;

if ($old_points)
{
    my $difference = $points - $old_points;
    if ($difference) {
        my $mail = MIME::Lite->new(
            From    => $email,
            To      => $email,
            Subject => 'La Quinta Balance Change',
            Data    => "Your La Quinta Returns balance has been adjusted by $difference",
        );

        $mail->send;
    }
}

$db->put(points => $points);

