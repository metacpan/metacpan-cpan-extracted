#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(lib ../lib);
use Test::WWW::Mechanize::MultiMech;

my $mech = Test::WWW::Mechanize::MultiMech->new(
    users   => [
        admin       => { pass => 'adminpass',   },
        super       => { pass => 'superpass',   },
        clerk       => { pass => 'clerkpass',   },
        shipper     => {
            login => 'shipper@system.com',
            pass => 'shipperpass',
        },
    ],
);

$mech->login(
    login_page => 'http://myapp.com/',
    form_id => 'login_form',
    fields => {
        login => \'LOGIN',
        pass  => \'PASS',
    },
);

$mech         ->text_contains('MyApp.com User Interface');
$mech->admin  ->text_contains('Administrator Panel');
$mech->shipper->text_lacks('We should not tell shippers about the cake');

$mech         ->add_user('guest');
$mech         ->get_ok('/user-info');
$mech->guest  ->text_contains('You must be logged in to view this page');
$mech         ->remove_user('guest');

$mech         ->text_contains('Your user information'  );
$mech->admin  ->text_contains('You are an admin user!' );
$mech->super  ->text_contains('You are a super user!'  );
$mech->clerk  ->text_contains('You are a clerk user!'  );




