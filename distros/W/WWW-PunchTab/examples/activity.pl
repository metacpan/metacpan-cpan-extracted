#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use WWW::PunchTab;
use Data::Dumper;

my $pt = WWW::PunchTab->new(
    domain     => 'fayland.org',
    access_key => 'f4f8290698320a98b1044615e722af79',
    client_id  => '1104891876',
    secret_key => 'ed73f70966dd10b7788b8f7953ec1d07',
);

print $pt->sso_auth_js(
    {
        'id'         => '2',
        'first_name' => 'Fayland',
        'last_name'  => 'Lam',
        'email'      => 'fayland@gmail.com'
    }
) or die $pt->errstr;

# my $user = $pt->user() or die $pt->errstr;

# my $x = $pt->create_activity('like', 400) or die $pt->errstr; # like with 400 points
# print Dumper(\$x);

# my $auth_status = $pt->auth_status;

# my $activity = $pt->activity() or die $pt->errstr;
# print Dumper(\$activity);

#my $leaderboard = $pt->leaderboard() or die $pt->errstr;
#print Dumper(\$leaderboard);

#my $reward = $pt->reward() or die $pt->errstr;
#print Dumper(\$reward);

1;
