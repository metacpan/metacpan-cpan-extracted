#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More tests => 35;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER          = 'Bookstore';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '9780007203055' => [
        [ 'is',     'isbn',         '9780007203055'             ],
        [ 'is',     'isbn10',       '0007203055'                ],
        [ 'is',     'isbn13',       '9780007203055'             ],
        [ 'is',     'ean13',        '9780007203055'             ],
        [ 'like',   'author',       qr/Ball, Simon/              ],
        [ 'like',   'title',        qr/Bitter Sea/              ],
        [ 'like',   'pubdate',      qr/2010/                    ],
        [ 'is',     'binding',      'Paperback'                 ],
        [ 'is',     'pages',        416                         ],
        [ 'like',   'depth',        qr/\d+/                     ],
        [ 'like',   'width',        qr/\d+/                     ],
        [ 'like',   'height',       qr/\d+/                     ],
        [ 'like',   'image_link',   qr|9780007203055.jpg|       ],
        [ 'like',   'thumb_link',   qr|9780007203055.jpg|       ],
        [ 'like',   'description',  qr|The Mediterranean Sea lies at the very heart of recent world history|    ],
        [ 'like',   'book_link',    qr|http://www.bookstore.co.uk/TBP.Direct/PurchaseProduct.*?9780007203055|   ]
    ],
    '0571313604' => [
        [ 'is',     'isbn',         '9780571313600'             ],
        [ 'is',     'isbn10',       '0571313604'                ],
        [ 'is',     'isbn13',       '9780571313600'             ],
        [ 'is',     'ean13',        '9780571313600'             ],
        [ 'is',     'title',        'Touching from a Distance'  ],
        [ 'is',     'author',       'Curtis, Deborah'           ],
        [ 'is',     'publisher',    'Faber & Faber'             ],
        [ 'is',     'pubdate',      '02/10/2014'                ],
        [ 'is',     'pages',        240                         ],
        [ 'like',   'image_link',   qr|9780571313600.jpg|       ],
        [ 'like',   'thumb_link',   qr|9780571313600.jpg|       ],
        [ 'like',   'description',  qr|Ian Curtis left behind a legacy rich in artistic genius|                 ],
        [ 'like',   'book_link',    qr|http://www.bookstore.co.uk/TBP.Direct/PurchaseProduct.*?9780571313600|   ]
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
    if($record && $record->found) {
        ok(0,'Unexpectedly found a non-existent book');
    } elsif($record) {
        like($record->error,qr/Invalid ISBN specified/);
    } else {
        like($@,qr/Invalid ISBN specified/);
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
