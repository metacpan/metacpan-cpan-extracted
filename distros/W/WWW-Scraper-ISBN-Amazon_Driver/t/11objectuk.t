#!/usr/bin/perl -w
use strict;

use Test::More tests => 48;
use WWW::Scraper::ISBN;
use Data::Dumper;

###########################################################

my $DRIVER          = 'AmazonUK';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '0201795264' => [
        [ 'is',     'isbn',         '9780201795264'                 ],
        [ 'like',   'isbn10',       qr!020179526!                   ],  # Amazon have a broken ISBN-10 field!
        [ 'is',     'isbn13',       '9780201795264'                 ],
        [ 'is',     'ean13',        '9780201795264'                 ],
        [ 'like',   'title',        qr!Perl Medic!                  ],
        [ 'like',   'author',       qr!Peter.*Scott!                ],
        [ 'is',     'publisher',    'Addison Wesley'                ],
        [ 'like',   'pubdate',      qr/2004$/                       ],  # this date fluctuates throughout Mar/Apr 2004!
        [ 'is',     'binding',      'Paperback'                     ],
        [ 'is',     'pages',        336                             ],
        [ 'like',   'width',        qr/^\d+/                        ],
        [ 'like',   'height',       qr/^\d+/                        ],
        [ 'like',   'depth',        qr/^\d+/                        ],
        [ 'is',     'weight',       undef                           ],
        [ 'like',   'image_link',   qr!^http://ecx.images-amazon.co!],
        [ 'like',   'thumb_link',   qr!^http://ecx.images-amazon.co!],
        [ 'like',   'description',  qr|Cure whatever ails your Perl code| ],
        [ 'like',   'book_link',    qr!^http://www.amazon.co.uk/(Perl-Medic|.*?field-keywords=(0201795264|9780201795264))! ]
    ],
    '9780672320675' => [
        [ 'is',     'isbn',         '9780672320675'                 ],
        [ 'like',   'isbn10',       qr!067232067!                   ],  # Amazon have a broken ISBN-10 field!
        [ 'is',     'isbn13',       '9780672320675'                 ],
        [ 'is',     'ean13',        '9780672320675'                 ],
        [ 'is',     'author',       'Clinton Pierce'                ],
        [ 'like',   'title',        qr!Perl Developer.*?Dictionary! ],
        [ 'like',   'publisher',    qr/^Sams/                       ],  # publisher name changes!
        [ 'like',   'pubdate',      qr/2001$/                       ],  # this dates fluctuates throughout Jul 2001!
        [ 'is',     'binding',      'Paperback'                     ],
        [ 'is',     'pages',        640                             ],
        [ 'like',   'width',        qr/^\d+/                        ],
        [ 'like',   'height',       qr/^\d+/                        ],
        [ 'like',   'depth',        qr/^\d+/                        ],
        [ 'is',     'weight',       undef                           ],
        [ 'like',   'image_link',   qr!^http://ecx.images-amazon.co!],
        [ 'like',   'thumb_link',   qr!^http://ecx.images-amazon.co!],
        [ 'like',   'description',  qr|Perl Developer's Dictionary is a complete|                            ],
        [ 'like',   'book_link',    qr!^http://www.amazon.co.uk/(Perl-Developers-Dictionary|.*?field-keywords=(0672320673|9780672320675))! ]
    ],

    '9781408307557' => [
        [ 'is',     'pages',        48                          ],
        [ 'like',   'width',        qr/^\d+/                    ],
        [ 'like',   'height',       qr/^\d+/                    ],
        [ 'like',   'depth',        qr/^\d+/                    ],
        [ 'is',     'weight',       undef                       ],
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

    for my $isbn (keys %tests) {
        my $record = $scraper->search($isbn);
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
