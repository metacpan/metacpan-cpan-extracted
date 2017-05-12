#!/usr/bin/perl -w
use strict;
use Test::More tests => 4;
# use Text::Authinfo;

BEGIN {
    $ENV{PERL_TEXT_AUTHINFO} = 0;
    use_ok "Text::Authinfo";
    plan skip_all => "Cannot load Text::Authfino" if $@;
}

my $ai = Text::Authinfo->new('t/_authinfofile');
my $readCorrectFile = $ai->readauthinfo();
ok($readCorrectFile == 1);
my $pw = $ai->getauth('m1','me@example.com','9999');
ok($pw eq 'h1th3r3');
my $badpw = $ai->getauth('m2','me@example.com','9999');
ok(!defined($badpw));
