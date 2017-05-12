#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More tests => 50;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER          = 'PickABook';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '1558607013' => [
        [ 'is',     'isbn',         '9781558607019'     ],
        [ 'is',     'isbn10',       '1558607013'        ],
        [ 'is',     'isbn13',       '9781558607019'     ],
        [ 'is',     'ean13',        '9781558607019'     ],
        [ 'is',     'title',        'Higher-Order Perl' ],
        [ 'is',     'author',       'Mark Jason Dominus'            ],
        [ 'is',     'publisher',    'Elsevier Science & Technology' ],
        [ 'is',     'pubdate',      '10 December, 2004' ],
        [ 'is',     'binding',      'Paperback'         ],
        [ 'is',     'pages',        '602'               ],
        [ 'is',     'image_link',   'http://www.pickabook.co.uk/CoverImages/2008_2_22_41\9781558607019.jpg' ],
        [ 'is',     'thumb_link',   'http://www.pickabook.co.uk/CoverImages/2008_2_22_41\9781558607019.jpg' ],
        [ 'like',   'description',  qr|Most Perl programmers were originally trained as C and Unix programmers,| ],
        [ 'is',     'book_link',    'http://www.pickabook.co.uk/9781558607019.aspx?ToSearch=TRUE' ]
    ],
    '0552557803' => [
        [ 'is',     'isbn',         '9780552557801'     ],
        [ 'is',     'isbn10',       '0552557803'        ],
        [ 'is',     'isbn13',       '9780552557801'     ],
        [ 'is',     'ean13',        '9780552557801'     ],
        [ 'is',     'title',        'Nation'            ],
        [ 'is',     'author',       'Terry Pratchett'   ],
        [ 'is',     'publisher',    'Random House Children\'s Books'    ],
        [ 'is',     'pubdate',      '1 October, 2020'   ],
        [ 'is',     'binding',      'Paperback'         ],
        [ 'is',     'image_link',   'http://www.pickabook.co.uk/CoverImages/nojacket.gif'   ],
        [ 'is',     'thumb_link',   'http://www.pickabook.co.uk/CoverImages/nojacket.gif'   ],
        [ 'like',   'description',  qr|Finding himself alone on a desert island|            ],
        [ 'is',     'book_link',    'http://www.pickabook.co.uk/9780552557801.aspx?ToSearch=TRUE' ]
    ],
    '9780571224814' => [
        [ 'is',     'isbn',         '9780571224814'     ],
        [ 'is',     'isbn10',       '0571224814'        ],
        [ 'is',     'isbn13',       '9780571224814'     ],
        [ 'is',     'ean13',        '9780571224814'     ],
        [ 'is',     'title',        'Touching From A Distance'  ],
        [ 'is',     'author',       'Ian Curtis, Deborah Curtis'    ],
        [ 'is',     'publisher',    'Faber And Faber'   ],
        [ 'is',     'pubdate',      '17 February, 2005' ],
        [ 'is',     'binding',      'Paperback'         ],
        [ 'is',     'pages',        240                 ],
        [ 'is',     'image_link',   'http://www.pickabook.co.uk/CoverImages/0367\03679eb1.JPG'  ],
        [ 'is',     'thumb_link',   'http://www.pickabook.co.uk/CoverImages/0367\03679eb1.JPG'  ],
        [ 'like',   'description',  qr|Ian Curtis left behind a legacy rich in artistic genius| ],
        [ 'is',     'book_link',    'http://www.pickabook.co.uk/9780571224814.aspx?ToSearch=TRUE' ]
    ],
);

my $tests = 0;
for my $isbn (keys %tests) { $tests += scalar( @{ $tests{$isbn} } ) + 2 }

###########################################################

my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

SKIP: {
	skip "Can't see a network connection", $tests+2   if(pingtest($CHECK_DOMAIN));

	$scraper->drivers($DRIVER);

    # this ISBN doesn't exist
	my $isbn = "098765432X";
    my $record;
    eval { $record = $scraper->search($isbn); };
    if($@) {
        like($@,qr/Invalid ISBN specified/);
    } elsif($record->found) {
        ok(0,'Unexpectedly found a non-existent book');
        my $error  = $record->error || '';
        diag("error=[".Dumper($error)."]");
        my $book = $record->book;
        diag("book=[".Dumper($book)."]");
    } else {
		like($record->error,qr/Invalid ISBN specified|Failed to find that book|website appears to be unavailable/);
    }

    # this ISBN isn't available
	$isbn = "9780571239566";
    eval { $record = $scraper->search($isbn); };
    if($@) {
        like($@,qr/Invalid ISBN specified/);
    } elsif($record->found) {
        ok(0,'Unexpectedly found a non-existent book');
        my $error  = $record->error || '';
        diag("error=[".Dumper($error)."]");
        my $book = $record->book;
        diag("book=[".Dumper($book)."]");
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
