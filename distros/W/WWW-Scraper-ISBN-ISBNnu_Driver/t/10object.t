#!/usr/bin/perl -w
use strict;

use Test::More tests => 34;
use WWW::Scraper::ISBN;
use Data::Dumper;

###########################################################

my $DRIVER          = 'ISBNnu';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '057122055X' => [
        [ 'is',     'isbn',         '9780571220557'     ],
        [ 'is',     'isbn10',       '057122055X'        ],
        [ 'is',     'isbn13',       '9780571220557'     ],
        [ 'is',     'ean13',        '9780571220557'     ],
        [ 'like',   'title',        qr!The Never-Ending Days of Being Dead! ],
        [ 'is',     'author',       'Marcus Chown'      ],
        [ 'like',   'publisher',    qr|Faber|           ],
        [ 'is',     'pubdate',      'January 18, 2007'  ],
        [ 'is',     'pages',        '256'               ],
        [ 'is',     'binding',      'Hardcover'          ],
        [ 'like',   'description',  qr!Learn how the big bang may have been spawned!    ],
        [ 'like',   'book_link',    qr!http://isbn.nu/057122055X!                       ]
    ],
    '9780571239566' => [
        [ 'is',     'isbn',         '9780571239566'     ],
        [ 'is',     'isbn10',       '0571239560'        ],
        [ 'is',     'isbn13',       '9780571239566'     ],
        [ 'is',     'ean13',        '9780571239566'     ],
        [ 'like',   'title',        qr!Touching from a Distance!    ],
        [ 'is',     'author',       'Deborah Curtis'    ],
        [ 'like',   'publisher',    qr!(Macmillan|Faber \S+ Faber)! ],
        [ 'is',     'pubdate',      'October 4, 2007'   ],
        [ 'is',     'pages',        240                 ],
        [ 'is',     'width',        127                 ],
        [ 'is',     'height',       203                 ],
        [ 'is',     'depth',        19                  ],
        [ 'is',     'weight',       208                 ],
        [ 'is',     'binding',      'Paperback'         ],
        [ 'like',   'description',  qr!Ian Curtis left behind a legacy rich in artistic genius! ],
        [ 'like',   'book_link',    qr!http://isbn.nu/9780571239566!                            ]
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
    my $isbn = "1234512345";
    my $record;

    eval { $record = $scraper->search($isbn); };
    if($@) {
        like($@,qr/Invalid ISBN specified/);
    } elsif($record->found) {
        ok(0,'Unexpectedly found a non-existent book');
    } else {
        like($record->error,qr/Failed to find that book on|website appears to be unavailable/);
    }

    SKIP: {
        skip "Language not supported", $tests-2
            if($record && $record->error =~ /Language.*?not currently supported/);

        for my $isbn (keys %tests) {
            eval { $record = $scraper->search($isbn) };
            my $error = $@ || $record->error || '';

            SKIP: {
                skip "Language not supported", scalar(@{ $tests{$isbn} }) + 2   
                    if($error =~ /Language.*?not currently supported/);
                skip "Website unavailable", scalar(@{ $tests{$isbn} }) + 2   
                    if($error =~ /website appears to be unavailable/);
                skip "Book unavailable", scalar(@{ $tests{$isbn} }) + 2   
                    if($error =~ /Failed to find that book/ || !$record->found);

                unless($record->found) {
                    diag($record->error);
                }

                is($record->found,1);
                is($record->found_in,$DRIVER);

                my $fail = 0;
                my $book = $record->book;
                #diag("book=[".$book->{book_link}."]");
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
