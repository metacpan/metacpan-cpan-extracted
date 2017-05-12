#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Digest::SHA1;

use WWW::Mailgun;

my $sha1 = Digest::SHA1->new;
$sha1->add(time);
$sha1->add(rand);

my $email = $sha1->hexdigest . '@testing.com';

my $mg = WWW::Mailgun->new({ 
    key => 'key-3ax6xnjp29jd6fds4gc373sgvjxteol0',
    domain => 'samples.mailgun.org'
});

my $unsub = $mg->unsubscribes('post',{address => $email, tag => '*'});
is($unsub->{address},$email,'New unsubscribe'),

$unsub = $mg->unsubscribes('get',$email);
is($unsub->{items}->[0]->{address},$email,'Unsubscription exists'),
is($unsub->{items}->[0]->{tag},'*','Tag looks right'),
is($unsub->{total_count},1,'Correct count'),

$unsub = $mg->unsubscribes('del',$email);
is($unsub->{address},$email,'Unsubscription does not exist'),

$unsub = $mg->unsubscribes('get',$email);
is($unsub->{total_count},0,'Correct count'),
