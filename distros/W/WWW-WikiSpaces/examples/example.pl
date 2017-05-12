#!/usr/bin/perl -w

use strict;
use WWW::WikiSpaces;

my $user = 'user';
my $pass = 'pass';
my $home = 'test';

my $ws = new WWW::WikiSpaces($home, $user, $pass);
$ws->post('My short title', 'My big <b>text</b>');
