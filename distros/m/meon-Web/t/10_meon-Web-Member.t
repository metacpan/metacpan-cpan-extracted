#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More 'no_plan';
#use Test::More tests => 10;
use Test::Differences;
use Test::Exception;

use FindBin qw($Bin);
use lib "$Bin/lib";

use File::Temp 'tempdir';
use Path::Class 'dir','file';

BEGIN {
    use_ok ( 'meon::Web::Member' ) or exit;
}

my $tmp_dir = tempdir( CLEANUP => 1 );
dir($tmp_dir, 'usr01')->mkpath;

exit main();

sub main {
    register_user();
    find_user_by_email();
    reset_password();
    set_member_meta_array();
    member_user();
    member_expires();
    return 0;
}

sub set_member_meta_array {
    my $member = meon::Web::Member->find_by_email(
        members_folder => $tmp_dir,
        email          => 'email@email.email',
    );
    $member->set_member_meta('languages', [qw(en de)]);
    $member->store;

    my $member2 = meon::Web::Member->find_by_email(
        members_folder => $tmp_dir,
        email          => 'email@email.email',
    );

    is_deeply(
        $member2->get_member_meta('languages'),
        [qw(en de)],
        'set member meta array',
    );
}

sub reset_password {
    my $member = meon::Web::Member->find_by_email(
        members_folder => $tmp_dir,
        email          => 'email@email.email',
    );
    ok($member, 'found member by email');
    $member->set_token;

    my $token_string = $member->get_member_meta('token');

    my $member2 = meon::Web::Member->find_by_token(
        members_folder => $tmp_dir,
        token          => $token_string,
    );
    ok($member2, 're-found member by token '.$token_string);
    ok(!$member2->valid_token($token_string), 'invalid token after usage');

    $member->set_token;
    $token_string = $member->get_member_meta('token');
    $member2->set_member_meta('token-valid',DateTime->now->subtract(hours => 4));
    ok(!$member2->valid_token($token_string), 'no more valid token');
}

sub find_user_by_email {
    my $non_existing_member = meon::Web::Member->find_by_email(
        members_folder => $tmp_dir,
        email          => 'non-existing@email.email',
    );
    ok(!$non_existing_member, 'not found member by email');

    my $member = meon::Web::Member->find_by_email(
        members_folder => $tmp_dir,
        email          => 'email@email.email',
    );
    ok($member, 'found member by email');
}

sub register_user {
    my $member = meon::Web::Member->new(
        members_folder => $tmp_dir,
        username       => 'usr01',
    );
    $member->create(
        name    => 'somename',
        email   => 'name <email@email.email>',
        address => "street 12\nwien",
        lat     => '48.123',
        lng     => '16.321',
        registration_form => '<email && content>',
    );


    my $usr01_slurp = file($tmp_dir, 'usr01','index.xml')->slurp.'';
    $usr01_slurp =~ m{<created>(.+?)</created>};
    my $created = $1;
    eq_or_diff(
        $usr01_slurp,
        usr01_content($created),
        'check user xml file content',
    );
}

sub member_user {
    my $member = meon::Web::Member->new(
        members_folder => $tmp_dir,
        username       => 'usr01',
    );
    my $user = $member->user;
    is($user->status, 'registration-pending', 'user status "registration-pending"');
}

sub member_expires {
    my $member = meon::Web::Member->new(
        members_folder => $tmp_dir,
        username       => 'usr01',
    );
    ok(!$member->expires, 'no expires set');
    $member->extend_expiration_by_1y;
    is($member->expires, DateTime->now->add('years' => 1)->strftime('%Y-%m-%dT00:00:00'), 'expires +1y');
}

sub usr01_content {
    my ($created) = @_;
    return qq{<?xml version="1.0" encoding="UTF-8"?>
<page xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns="http://web.meon.eu/" xmlns:w="http://web.meon.eu/">

<meta>
    <title>somename</title>
    <user xmlns="http://search.cpan.org/perldoc?Catalyst%3A%3AAuthentication%3A%3AStore%3A%3AUserXML">
        <status>registration-pending</status>
        <username>usr01</username>
        <password>***DISABLED***</password>
    </user>
</meta>

<content><div xmlns="http://www.w3.org/1999/xhtml">
<w:member-profile xmlns="http://web.meon.eu/">
    <dir-listing path="archive/"/>
    <public-listing>1</public-listing>
    <full-name>somename</full-name>
    <email>name &lt;email\@email.email&gt;</email>
    <sex/>
    <email-validated>0</email-validated>
    <created>$created</created>
    <address>street 12
wien</address>
    <lat>48.123</lat>
    <lng>16.321</lng>
    <registration-form>&lt;email &amp;&amp; content&gt;</registration-form>
</w:member-profile>
</div></content>

</page>
};
}
