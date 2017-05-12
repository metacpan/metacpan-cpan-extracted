#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More tests => 41;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER          = 'BarnesNoble';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '9780571224814' => [
        [ 'is',     'isbn',         '9780571224814'             ],
        [ 'is',     'isbn10',       '0571224814'                ],
        [ 'is',     'isbn13',       '9780571224814'             ],
        [ 'is',     'ean13',        '9780571224814'             ],
        [ 'like',   'title',        qr!Touching from a Distance!],
        [ 'like',   'author',       qr!Curtis!                  ],
        [ 'is',     'publisher',    'Faber and Faber'           ],
        [ 'like',   'pubdate',      qr!\d+/\d+/\d+!             ],
        [ 'is',     'binding',      'Paperback'                 ],
        [ 'is',     'pages',        208                         ],
        [ 'is',     'width',        124                         ],
        [ 'is',     'height',       193                         ],
        [ 'is',     'depth',        20                          ],
        [ 'is',     'weight',       undef                       ],
        [ 'like',   'image_link',   qr|http://img\d+.imagesbn.com/p/\w+.JPG| ],
        [ 'like',   'thumb_link',   qr|http://img\d+.imagesbn.com/p/\w+.JPG| ],
        [ 'like',   'description',  qr|Joy Division|            ],
        [ 'like',   'book_link',    qr|\w+.barnesandnoble.com/.*?9780571224814| ]
    ],
    '9781452138459' => [
        [ 'is',     'isbn',         '9781452138459'             ],
        [ 'is',     'isbn10',       '1452138451'                ],
        [ 'is',     'isbn13',       '9781452138459'             ],
        [ 'is',     'ean13',        '9781452138459'             ],
        [ 'like',   'title',        qr!So This is Permanence: Joy Division Lyrics and Notebooks!    ],
        [ 'is',     'author',       'Ian Curtis, Deborah Curtis (Editor), Jon Savage (Editor)'      ],
        [ 'is',     'publisher',    'Chronicle Books LLC'       ],
        [ 'like',   'pubdate',      qr!\d+/\d+/\d+!             ],
        [ 'is',     'binding',      'Hardcover'                 ],
        [ 'is',     'pages',        undef                       ],
        [ 'is',     'width',        208                         ],
        [ 'is',     'height',       284                         ],
        [ 'is',     'depth',        27                          ],
        [ 'is',     'weight',       undef                       ],
        [ 'like',   'image_link',   qr|http://img\d+.imagesbn.com/p/\w+.JPG| ],
        [ 'like',   'thumb_link',   qr|http://img\d+.imagesbn.com/p/\w+.JPG| ],
        [ 'like',   'description',  qr|Joy Division|            ],
        [ 'like',   'book_link',    qr|\w+.barnesandnoble.com/.*?9781452138459| ]
    ],
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

# Code below removed as some testers appear to have badly configured
# Business::ISBN objects, as used by WWW::Scraper::ISBN :(
#
#    # this ISBN doesn't exist
#    my $isbn = "99999999990";
#    eval { $record = $scraper->search($isbn); };
#    if($@) {
#        like($@,qr/Invalid ISBN specified/);
#    } elsif($record->found) {
#        ok(0,'Unexpectedly found a non-existent book');
#    } else {
#        like($record->error,qr/Invalid ISBN specified|Failed to find that book|website appears to be unavailable/);
#    }

    for my $isbn (keys %tests) {
        eval { $record = $scraper->search($isbn) };
        my $error = $@ || $record->error || '';

        SKIP: {
            skip "Website unavailable [$error]", scalar(@{ $tests{$isbn} }) + 2   
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
