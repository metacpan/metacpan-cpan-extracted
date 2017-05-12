#!/usr/bin/env perl
use warnings;
use strict;
use 5.10.0;
use Plack::Util;
use Test::WWW::Mechanize::PSGI;
use Test::More;
my $iterations = shift // 1;
my $mech =
  Test::WWW::Mechanize::PSGI->new(app => Plack::Util::load_psgi('dancr.pl'));
$dip::dip && $dip::dip->();

for my $iteration (1 .. $iterations) {

    # get main page
    $mech->get_ok('/');
    is $mech->ct, 'text/html', 'text/html';
    $mech->title_is('Dancr');
    $mech->text_contains('log in');

    # get login page
    $mech->get_ok('/login');
    is $mech->ct, 'text/html', 'text/html';

    # fail to log in
    $mech->post_ok('/login', { username => 'wrong', password => 'wrong' });
    $mech->text_contains('Invalid username');

    # log in
    $mech->post_ok('/login', { username => 'admin', password => 'password' });
    $mech->text_contains('You are logged in');

    # post new message
    $mech->post_ok('/add',
        { title => "Title $iteration", text => "Text $iteration" });
    $mech->text_contains('New entry posted!');

    # log out
    $mech->follow_link(text => 'log out');
    $mech->text_contains('You are logged out');
}
done_testing;
