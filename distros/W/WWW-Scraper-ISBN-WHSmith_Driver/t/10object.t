#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More tests => 40;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER          = 'WHSmith';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '055255779X' => [
        [ 'is',     'isbn',         '9780552557795'                 ],
        [ 'is',     'isbn10',       '055255779X'                    ],
        [ 'is',     'isbn13',       '9780552557795'                 ],
        [ 'is',     'ean13',        '9780552557795'                 ],
        [ 'is',     'title',        'Nation'                        ],
        [ 'is',     'author',       'Terry Pratchett'               ],
        [ 'is',     'publisher',    undef                           ],
        [ 'is',     'pubdate',      '08/10/2009'                    ],
        [ 'is',     'binding',      'Paperback'                     ],
        [ 'is',     'pages',        '432'                           ],
        [ 'is',     'width',        undef                           ],
        [ 'is',     'height',       undef                           ],
        [ 'like',   'weight',       qr|^\d+$|                       ],
        [ 'is',     'image_link',   'http://btmedia.whsmith.co.uk/pws/client/images/catalogue/products/9780/55/2557795/xlarge/9780552557795_1.jpg' ],
        [ 'is',     'thumb_link',   'http://btmedia.whsmith.co.uk/pws/client/images/catalogue/products/9780/55/2557795/small/9780552557795_1.jpg' ],
        [ 'like',   'description',  qr|On the day the world ends|   ],
        [ 'is',     'book_link',    'http://www.whsmith.co.uk/pws/ProductDetails.ice?ProductID=9780552557795&keywords=9780552557795&redirect=true' ]
    ],
    '9780847834815' => [
        [ 'is',     'isbn',         '9780847834815'                 ],
        [ 'is',     'isbn10',       '0847834816'                    ],
        [ 'is',     'isbn13',       '9780847834815'                 ],
        [ 'is',     'ean13',        '9780847834815'                 ],
        [ 'is',     'title',        'Joy Division'                  ],
        [ 'is',     'author',       'Kevin Cummins, Bernard Sumner' ],
        [ 'is',     'publisher',    undef                           ],
        [ 'is',     'pubdate',      '01/10/2010'                    ],
        [ 'is',     'binding',      'Hardback'                      ],
        [ 'is',     'pages',         208                            ],
        [ 'is',     'width',        undef                           ],
        [ 'is',     'height',       undef                           ],
        [ 'like',   'weight',       qr|^\d+$|                       ],
        [ 'is',     'image_link',   'http://btmedia.whsmith.co.uk/pws/client/images/catalogue/products/9780/84/7834815/xlarge/9780847834815_1.jpg' ],
        [ 'is',     'thumb_link',   'http://btmedia.whsmith.co.uk/pws/client/images/catalogue/products/9780/84/7834815/small/9780847834815_1.jpg' ],
        [ 'like',   'description',  qr|The definitive look at one of the most iconic rock bands of all time| ],
        [ 'is',     'book_link',    'http://www.whsmith.co.uk/pws/ProductDetails.ice?ProductID=9780847834815&keywords=9780847834815&redirect=true' ]
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
	my $isbn = "0987654321";
    my $record;
    eval { $record = $scraper->search($isbn); };
    if($@) {
        like($@,qr/Invalid ISBN specified/);
    }
    elsif($record->found) {
        ok(0,'Unexpectedly found a non-existent book');
    } else {
		like($record->error,qr/Invalid ISBN specified|Failed to find that book|website appears to be unavailable/);
    }

    for my $isbn (keys %tests) {
        $record = $scraper->search($isbn);
        my $error  = $record->error || '';

        SKIP: {
            skip "Website unavailable", scalar(@{ $tests{$isbn} }) + 2   
                if($error =~ /website appears to be unavailable/);
            skip "Book unavailable", scalar(@{ $tests{$isbn} }) + 2   
                if($error =~ /Failed to find that book/);

            unless($record->found) {
                diag($record->error);
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
