#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More;
use WWW::Scraper::ISBN;
use WWW::Scraper::ISBN::ISBNdb_Driver;

###########################################################

my $access_key = WWW::Scraper::ISBN::ISBNdb_Driver::_get_key();
#my $apiversion = WWW::Scraper::ISBN::ISBNdb_Driver::_set_version('v1');

if( $access_key ) {
  plan tests => 95;
} else {
  plan skip_all => 'no isbndb.com access key provided';
}

###########################################################

my $DRIVER          = 'ISBNdb';
my $CHECK_DOMAIN    = 'isbndb.com';

###########################################################

my %tests = (
    '9781600330209' => [    # paperback, with dimensions
        [ 'is',     'isbn',         '9781600330209'                 ],
        [ 'is',     'isbn10',       '1600330207'                    ],
        [ 'is',     'isbn13',       '9781600330209'                 ],
        [ 'is',     'ean13',        '9781600330209'                 ],
        [ 'like',   'title',        qr!Learning Perl!               ],
        [ 'like',   'author',       qr!brian d foy; Schwartz, Randal L.; Tom Phoenix!   ],
        [ 'is',     'publisher',    q!O'Reilly Media!               ],
        [ 'like',   'pubdate',      qr/2005-07-01$/                 ],
        [ 'is',     'dewey',        '005'                           ],
        [ 'is',     'binding',      'Paperback'                     ],
        [ 'is',     'pages',        4                               ],
        [ 'is',     'width',        177                             ],
        [ 'is',     'height',       233                             ],
        [ 'is',     'depth',        22                              ],
        [ 'is',     'weight',       589                             ],
        [ 'is',     'description',  undef                           ],
        [ 'like',   'book_link',    qr!http://isbndb.com/api/books.xml\?access_key=[a-zA-Z0-9]+&index1=isbn&results=details&value1=9781600330209! ]
    ],
    '9780585030609' => [   # ebook
        [ 'is',     'isbn',         '9780585030609'                 ],
        [ 'is',     'isbn10',       '058503060X'                    ],
        [ 'is',     'isbn13',       '9780585030609'                 ],
        [ 'is',     'ean13',        '9780585030609'                 ],
        [ 'like',   'title',        qr!Learning Perl!               ],
        [ 'like',   'author',       qr!Christiansen, Tom; Schwartz, Randal L.!   ],
        [ 'is',     'publisher',    q!O'Reilly & Associates!        ],
        [ 'like',   'pubdate',      qr/1997$/                       ],
        [ 'is',     'dewey',        ''                              ],
        [ 'is',     'binding',      'eBook'                         ],
        [ 'is',     'pages',        269                             ],
        [ 'is',     'width',        undef                           ],
        [ 'is',     'height',       undef                           ],
        [ 'is',     'depth',        undef                           ],
        [ 'is',     'weight',       undef                           ],
        [ 'is',     'description',  undef                           ],
        [ 'like',   'book_link',    qr!http://isbndb.com/api/books.xml\?access_key=[a-zA-Z0-9]+&index1=isbn&results=details&value1=9780585030609! ]
    ],
    '0071391401' => [    # unusual binding
        [ 'is',     'isbn',         '9780071391405'                 ],
        [ 'is',     'isbn10',       '0071391401'                    ],
        [ 'is',     'isbn13',       '9780071391405'                 ],
        [ 'is',     'ean13',        '9780071391405'                 ],
        [ 'is',     'author',       'Harrison, Tinsley Randolph; Dennis L. Kasper'  ],
        [ 'like',   'title',        qr!Harrison's principles of internal medicine!  ],
        [ 'like',   'publisher',    qr/McGraw-Hill Medical Publishing Division/     ],
        [ 'like',   'pubdate',      qr/2005$/                       ],
        [ 'is',     'dewey',        '616'                           ],
        [ 'is',     'binding',      '(set)'                         ],
        [ 'is',     'pages',        128                             ],
        [ 'is',     'width',        undef                           ],
        [ 'is',     'height',       undef                           ],
        [ 'is',     'depth',        undef                           ],
        [ 'is',     'weight',       undef                           ],
        [ 'is',     'description',  undef                           ],
        [ 'like',   'book_link',    qr!http://isbndb.com/api/books.xml\?access_key=[a-zA-Z0-9]+&index1=isbn&results=details&value1=0071391401! ]
    ],
    '0070480745' => [    # has summary
        [ 'is',     'isbn',         '9780070480742'                 ],
        [ 'is',     'isbn10',       '0070480745'                    ],
        [ 'is',     'isbn13',       '9780070480742'                 ],
        [ 'is',     'ean13',        '9780070480742'                 ],
        [ 'is',     'author',       q!O'Neil, William J.!           ],
        [ 'like',   'title',        qr!How to Make Money in Stocks! ],
        [ 'like',   'publisher',    qr/McGraw-Hill Companies, The/  ],
        [ 'like',   'pubdate',      qr/1994$/                       ],
        [ 'is',     'dewey',        ''                              ],
        [ 'is',     'binding',      'Paperback'                     ],
        [ 'is',     'pages',        undef                           ],  # 640 on website
        [ 'is',     'width',        undef                           ],
        [ 'is',     'height',       undef                           ],
        [ 'is',     'depth',        undef                           ],
        [ 'is',     'weight',       undef                           ],
        [ 'is',     'description',  undef                           ],  # not API v1
        [ 'like',   'book_link',    qr!http://isbndb.com/api/books.xml\?access_key=[a-zA-Z0-9]+&index1=isbn&results=details&value1=0070480745! ]
    ],
    '9780141021621' => [    # missing publisher data - see RT#48005
        [ 'is',     'isbn10',       '0141021624'                    ],
        [ 'is',     'isbn13',       '9780141021621'                 ],
        [ 'is',     'author',       ''                              ],
        [ 'like',   'title',        qr!Skeleton Coast \(Oregon Files 4\)! ],
        [ 'is',     'publisher',    ''                              ],
        [ 'is',     'pubdate',      ''                              ],
        [ 'is',     'dewey',        ''                              ],
        [ 'is',     'binding',      'Paperback'                     ],
        [ 'is',     'pages',        6                               ],
        [ 'is',     'width',        111                             ],
        [ 'is',     'height',       182                             ],
        [ 'is',     'depth',        40                              ],
        [ 'is',     'weight',       317                             ],
        [ 'is',     'description',  undef                           ],  # not API v1
        [ 'like',   'book_link',    qr!http://isbndb.com/api/books.xml\?access_key=[a-zA-Z0-9]+&index1=isbn&results=details&value1=9780141021621! ]
    ],
);

###########################################################

my $tests = 1;
for my $isbn (keys %tests) { $tests += scalar( @{ $tests{$isbn} } ) + 2}

my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

SKIP: {
	skip "Can't see a network connection", $tests   if(pingtest($CHECK_DOMAIN));

	$scraper->drivers($DRIVER);

    my $isbn = '0-07-048074-5';
    my $record;

    eval { $record = $scraper->search($isbn); };
    if($record && $record->found) {
        ok(0,'Unexpectedly found a non-existent book');
    } elsif($record) {
        like($record->error,qr/Invalid ISBN specified/);
    } else {
        like($@,qr/Invalid ISBN specified/);
    }

    for $isbn (keys %tests) {
        eval { $record = $scraper->search($isbn) };
        my $error = $@ || $record->error || '';

        unless($record && $record->found) {
            diag("Failed to create record: $error");
            next;
        }

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
                if($test->[1] eq 'book_link') {
                    # obscure tester's access key 
                    $book->{$test->[1]} =~ s/$access_key/accesskey/g;
                }

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
