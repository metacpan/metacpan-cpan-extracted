#!/usr/bin/perl -w
use strict;

use lib './t';

use Data::Dumper;
use Test::More tests => 76;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER          = 'OpenLibrary';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '1558607013' => [
        [ 'is',     'isbn',         '9781558607019'                 ],
        [ 'is',     'isbn10',       '1558607013'                    ],
        [ 'is',     'isbn13',       '9781558607019'                 ],
        [ 'is',     'ean13',        '9781558607019'                 ],
        [ 'is',     'title',        'Higher-Order Perl'             ],
        [ 'is',     'author',       'Mark Jason Dominus'            ],
        [ 'is',     'publisher',    'Morgan Kaufmann'               ],
        [ 'is',     'pubdate',      'March 14, 2005'                ],
        [ 'is',     'binding',      'Paperback'                     ],
        [ 'is',     'pages',        600                             ],
        [ 'is',     'width',        190                             ],
        [ 'is',     'height',       233                             ],
        [ 'is',     'depth',        35                              ],
        [ 'is',     'weight',       1179                            ],
        [ 'is',     'image_link',   'https://covers.openlibrary.org/b/id/784249-L.jpg'    ],
        [ 'is',     'thumb_link',   'https://covers.openlibrary.org/b/id/784249-S.jpg'    ],
        [ 'is',     'book_link',    q|https://openlibrary.org/books/OL8606556M/Higher-Order_Perl| ]
    ],
    '9780571239566' => [
        [ 'is',     'isbn',         '9780571239566'                 ],
        [ 'is',     'isbn10',       '0571239560'                    ],
        [ 'is',     'isbn13',       '9780571239566'                 ],
        [ 'is',     'ean13',        '9780571239566'                 ],
        [ 'is',     'title',        'Touching from a Distance'      ],
        [ 'is',     'author',       'Deborah Curtis'                ],
        [ 'is',     'publisher',    'Faber and Faber'               ],
        [ 'is',     'pubdate',      'October 4, 2007'               ],
        [ 'is',     'binding',      'Paperback'                     ],
        [ 'is',     'pages',        240                             ],
        [ 'is',     'width',        127                             ],
        [ 'is',     'height',       195                             ],
        [ 'is',     'depth',        20                              ],
        [ 'is',     'weight',       221                             ],
        [ 'is',     'image_link',   'https://covers.openlibrary.org/b/id/2521251-L.jpg'    ],
        [ 'is',     'thumb_link',   'https://covers.openlibrary.org/b/id/2521251-S.jpg'    ],
        [ 'is',     'book_link',    q|https://openlibrary.org/books/OL10640818M/Touching_from_a_Distance| ]
    ],
    '9780596001735' => [
        [ 'is',     'isbn',         '9780596001735'         ],
        [ 'is',     'isbn10',       '0596001738'            ],
        [ 'is',     'isbn13',       '9780596001735'         ],
        [ 'is',     'ean13',        '9780596001735'         ],
        [ 'is',     'title',        'Perl Best Practices'   ],
        [ 'is',     'author',       'Damian Conway'         ],
        [ 'is',     'publisher',    q|O'Reilly Media, Inc.| ],
        [ 'is',     'pubdate',      'July 12, 2005'         ],
        [ 'is',     'binding',      undef                   ],
        [ 'is',     'pages',        542                     ],
        [ 'is',     'width',        undef                   ],
        [ 'is',     'height',       undef                   ],
        [ 'is',     'weight',       undef                   ],
        [ 'is',     'image_link',   'https://covers.openlibrary.org/b/id/388540-L.jpg'    ],
        [ 'is',     'thumb_link',   'https://covers.openlibrary.org/b/id/388540-S.jpg'    ],
        [ 'is',     'book_link',    q|https://openlibrary.org/books/OL7580925M/Perl_Best_Practices| ]
    ],
    '9780804736480' => [    # this should never been tested, as it doesn't exist in OpenLibrary
        [ 'is',     'isbn',         'failed'    ],
        [ 'is',     'isbn10',       'failed'    ],
        [ 'is',     'isbn13',       'failed'    ],
        [ 'is',     'ean13',        'failed'    ],
        [ 'is',     'title',        'failed'    ],
        [ 'is',     'author',       'failed'    ],
        [ 'is',     'publisher',    'failed'    ],
        [ 'is',     'pubdate',      'failed'    ],
        [ 'is',     'binding',      0           ],
        [ 'is',     'pages',        0           ],
        [ 'is',     'width',        0           ],
        [ 'is',     'height',       0           ],
        [ 'is',     'weight',       0           ],
        [ 'is',     'image_link',   'failed'    ],
        [ 'is',     'thumb_link',   'failed'    ],
        [ 'is',     'book_link',    q|failed|   ]
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
	my $isbn = "1122334455";
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
        eval { $record = $scraper->search($isbn) };
        my $error  = $@ || $record->error || '';

        unless($record) {
            diag("Failed to create record: $error");
        }

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
                if($test->[0] eq 'ok')          { ok(       $book->{$test->[1]},             ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'is')       { is(       $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'isnt')     { isnt(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'like')     { like(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'unlike')   { unlike(   $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); }

                $fail = 1   unless(defined $book->{$test->[1]} || ($test->[0] ne 'ok' && !defined $test->[2]));
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
