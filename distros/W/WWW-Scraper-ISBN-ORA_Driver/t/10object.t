#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More tests => 20;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER          = 'ORA';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '9780596001735' => [
        [ 'is',     'isbn',         '9780596001735'         ],
        [ 'is',     'isbn10',       '0596001738'            ],
        [ 'is',     'isbn13',       '9780596001735'         ],
        [ 'is',     'ean13',        '9780596001735'         ],
        [ 'is',     'title',        'Perl Best Practices'   ],
        [ 'is',     'author',       'Damian Conway'         ],
        [ 'is',     'publisher',    q!O'Reilly Media!       ],
        [ 'like',   'pubdate',      qr/Jul. \d{2}, 2005/    ],
        [ 'is',     'binding',      undef                   ],
        [ 'is',     'pages',        '544'                   ],
        [ 'is',     'width',        undef                   ],
        [ 'is',     'height',       undef                   ],
        [ 'is',     'weight',       undef                   ],
        [ 'like',   'image_link',   qr|http://\w+.oreilly.com/images/9780596001735/sm.gif| ],
        [ 'like',   'thumb_link',   qr|http://\w+.oreilly.com/images/9780596001735/sm.gif| ],
        [ 'like',   'description',  qr|Perl Best Practices offers a collection of 256 guidelines| ],
        [ 'like',   'book_link',    qr|http://shop.oreilly.com/product/\d+\.do| ]
    ]
);

my $tests = 0;
for my $isbn (keys %tests) { $tests += scalar( @{ $tests{$isbn} } ) + 2 }

###########################################################

my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

SKIP: {
	skip "Can't see a network connection", $tests   if(pingtest($CHECK_DOMAIN));

	$scraper->drivers($DRIVER);

    my $record;
    for my $isbn (keys %tests) {
        eval { $record = $scraper->search($isbn) };
        my $error = $@ || $record->error || '';

        SKIP: {
            skip "Website unavailable", scalar(@{ $tests{$isbn} }) + 2   
                if($error =~ /website appears to be unavailable/);
            skip "Book unavailable", scalar(@{ $tests{$isbn} }) + 2   
                if($error =~ /Failed to find that book/);

            unless($record && $record->found) {
                diag("error=$error, record error=".$record->error);
            }

            is($record->found,1);
            is($record->found_in,$DRIVER);

            my $fail = 0;
            my $book = $record->book;
            for my $test (@{ $tests{$isbn} }) {
                if($test->[0] eq 'ok')          { $fail += ! ok(       $book->{$test->[1]},             ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'is')       { $fail += ! is(       $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'isnt')     { $fail += ! isnt(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'like')     { $fail += ! like(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'unlike')   { $fail += ! unlike(   $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); }
            }

            diag("book=[".Dumper($book)."]")    if($fail);
        }
    }
}

###########################################################

# crude, but it'll hopefully do ;)
sub pingtest {
    my $domain = shift or return 0;
    my $cmd =   $^O =~ /solaris/i                           ? "ping -s $domain 56 1" :
                $^O =~ /cygwin/i                            ? "ping $domain 56 1" : # ping [ -dfqrv ] host [ packetsize [ count [ preload ]]]
                $^O =~ /dos|os2|mswin32|netware/i           ? "ping -n 1 $domain "
                                                            : "ping -c 1 $domain >/dev/null 2>&1";

    eval { system($cmd) }; 
    if($@) {                # can't find ping, or wrong arguments?
        diag($@);
        return 1;
    }

    my $retcode = $? >> 8;  # ping returns 1 if unable to connect
    return $retcode;
}
