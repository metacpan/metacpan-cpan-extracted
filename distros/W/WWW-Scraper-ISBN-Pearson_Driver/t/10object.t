#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More tests => 40;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER          = 'Pearson';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '1932394508' => [
        [ 'is',     'isbn',         '9781932394504'     ],
        [ 'is',     'isbn10',       '1932394508'        ],
        [ 'is',     'isbn13',       '9781932394504'     ],
        [ 'is',     'ean13',        '9781932394504'     ],
        [ 'is',     'title',        'Minimal Perl'      ],
        [ 'is',     'author',       'Tim Maher'         ],
        [ 'is',     'publisher',    'Pearson Education' ],
        [ 'is',     'pubdate',      'Oct 2006'          ],
        [ 'is',     'binding',      'Paperback'         ],
        [ 'is',     'pages',        undef               ],
        [ 'is',     'width',        undef               ],
        [ 'is',     'height',       undef               ],
        [ 'is',     'weight',       undef               ],
        [ 'is',     'image_link',   'http://images.pearsoned-ema.com/jpeg/large/9781932394504.jpg' ],
        [ 'is',     'thumb_link',   'http://images.pearsoned-ema.com/jpeg/small/9781932394504.jpg' ],
        [ 'like',   'description',  qr|Most books make Perl unnecessarily hard to learn by attempting| ],
        [ 'like',   'book_link',    qr|http://.*?item=100000000120863| ]
    ],
    '9780672320675' => [
        [ 'is',     'isbn',         '9780672320675'     ],
        [ 'is',     'isbn10',       '0672320673'        ],
        [ 'is',     'isbn13',       '9780672320675'     ],
        [ 'is',     'ean13',        '9780672320675'     ],
        [ 'like',   'author',       qr/Clinton Pierce/  ],
        [ 'like',   'title',        qr!Perl Developer.*?Dictionary! ],
        [ 'is',     'publisher',    'Pearson Education' ],
        [ 'is',     'pubdate',      'Jul 2001'          ],
        [ 'is',     'binding',      'Paperback'         ],
        [ 'is',     'pages',        640                 ],
        [ 'is',     'width',        undef               ],
        [ 'is',     'height',       undef               ],
        [ 'is',     'weight',       undef               ],
        [ 'is',     'image_link',   'http://images.pearsoned-ema.com/jpeg/large/9780672320675.jpg'  ],
        [ 'is',     'thumb_link',   'http://images.pearsoned-ema.com/jpeg/small/9780672320675.jpg'  ],
        [ 'like',   'description',  qr|In addition to providing a complete syntax reference for all core Perl functions|    ],
        [ 'like',   'book_link',    qr|http://.*?item=246272| ]
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
        like($record->error,qr/Failed to find that book|website appears to be unavailable/);
    }

    for my $isbn (keys %tests) {
        eval { $record = $scraper->search($isbn); };
        if($@) {
            like($@,qr/Invalid ISBN specified/);
        }

        my $error  = $record->error || '';

        SKIP: {
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
