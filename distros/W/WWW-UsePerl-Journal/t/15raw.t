#!/usr/bin/perl -w
use strict;

use Test::More tests => 2;
use WWW::UsePerl::Journal;

my $j = WWW::UsePerl::Journal->new('testuser');

SKIP: {
	skip "Can't see a network connection", 2	unless($j->connected);

    {
        $j = WWW::UsePerl::Journal->new('russell');

        my $content;
        eval { $content = $j->raw('2376') };
        diag( "WUJERR: no content for russell/2376 [$@]")    if($@ || !$content);

        like($content,qr/html/i,'... contains html content');
        like($content,qr/Read\s+only\s+at\s+the\s+moment/i,'... contains known text');
    }
}

