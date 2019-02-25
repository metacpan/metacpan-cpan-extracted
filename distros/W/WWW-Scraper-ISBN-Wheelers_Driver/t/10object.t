#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More tests => 40;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER          = 'Wheelers';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '0847834816' => [
        [ 'is',     'isbn',         '9780847834815'                     ],
        [ 'is',     'isbn10',       '0847834816'                        ],
        [ 'is',     'isbn13',       '9780847834815'                     ],
        [ 'is',     'ean13',        '9780847834815'                     ],
        [ 'is',     'title',        'Joy Division'                      ],
        [ 'is',     'author',       'Kevin Cummins'                     ],
        [ 'like',   'publisher',    qr|Rizzoli International|           ],
        [ 'is',     'pubdate',      '26 October 2010'                   ],
        [ 'like',   'binding',      qr/Hardback/                        ],
        [ 'is',     'pages',        208                                 ],
        [ 'is',     'width',        241                                 ],
        [ 'is',     'height',       302                                 ],
        [ 'is',     'weight',       1397                                ],
        [ 'is',     'image_link',   'https://r.wheelers.co/bk/large/978084/9780847834815.jpg' ],
        [ 'is',     'thumb_link',   'https://r.wheelers.co/bk/small/978084/9780847834815.jpg' ],
        [ 'like',   'description',  qr|Joy Division pioneered a genre of music|               ],
        [ 'like',   'book_link',    qr|https://www.wheelers.co.nz/books/9780847834815-|       ]
    ],
    '9780826415493' => [
        [ 'is',     'isbn',         '9780826415493'                     ],
        [ 'is',     'isbn10',       '0826415490'                        ],
        [ 'is',     'isbn13',       '9780826415493'                     ],
        [ 'is',     'ean13',        '9780826415493'                     ],
        [ 'like',   'author',       qr/Chris Ott/                       ],
        [ 'is',     'title',        q|Joy Division's Unknown Pleasures| ],
        [ 'is',     'publisher',    'Bloomsbury Publishing PLC'         ],
        [ 'is',     'pubdate',      '31 March 2004'                     ],
        [ 'is',     'binding',      'Paperback'                         ],
        [ 'is',     'pages',        128                                 ],
        [ 'is',     'width',        128                                 ],
        [ 'is',     'height',       178                                 ],
        [ 'is',     'weight',       136                                 ],
        [ 'is',     'image_link',   'https://r.wheelers.co/bk/large/978082/9780826415493.jpg' ],
        [ 'is',     'thumb_link',   'https://r.wheelers.co/bk/small/978082/9780826415493.jpg' ],
        [ 'like',   'description',  qr|33 1/3 is a new series of short books|                 ],
        [ 'like',   'book_link',    qr|https://www.wheelers.co.nz/books/9780826415493-|       ]
    ],
);

my $tests = 0;
for my $isbn (keys %tests) { $tests += scalar( @{ $tests{$isbn} } ) + 2 }


###########################################################

my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

SKIP: {
    skip "Can't see a network connection", $tests+1   if(pingtest($CHECK_DOMAIN));

    $scraper->drivers($DRIVER);

    # this ISBN doesn't exist
    my $isbn = "1234567890";
    my $record;
    eval { $record = $scraper->search($isbn); };
    if($@) {
        like($@,qr/Invalid ISBN specified/);
    }
    elsif($record->found) {
        ok(0,'Unexpectedly found a non-existent book');
    } else {
        like($record->error,qr/Failed to find that book on Wheelers website|website appears to be unavailable/);
    }

    for my $isbn (keys %tests) {
        eval { $record = $scraper->search($isbn) };
        my $error = $@ || $record->error || '';

        SKIP: {
            skip "Website unavailable", scalar(@{ $tests{$isbn} }) + 2   
                if($error =~ /website appears to be unavailable/);
            skip "Book unavailable", scalar(@{ $tests{$isbn} }) + 2   
                if($error =~ /Failed to find that book/ || !$record->found);

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
