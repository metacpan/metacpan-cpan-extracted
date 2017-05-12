#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More tests => 63;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER          = 'WordPower';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '1558607013' => [
        [ 'is',     'isbn',         '9781558607019'                 ],
        [ 'is',     'isbn10',       '1558607013'                    ],
        [ 'is',     'isbn13',       '9781558607019'                 ],
        [ 'is',     'ean13',        '9781558607019'                 ],
        [ 'is',     'title',        'Higher-Order Perl'             ],
        [ 'is',     'author',       'Mark Jason Dominus'            ],
        [ 'is',     'publisher',    'Morgan Kaufmann Publishers In' ],
        [ 'is',     'pubdate',      '10/12/2004'                    ],
        [ 'is',     'binding',      'Paperback'                     ],
        [ 'is',     'pages',        602                             ],
        [ 'is',     'width',        191                             ],
        [ 'is',     'height',       235                             ],
        [ 'is',     'depth',        undef                           ],
        [ 'is',     'weight',       1021                            ],
        [ 'is',     'image_link',   'http://images.word-power.co.uk/images/product_images/9781558607019.jpg'    ],
        [ 'is',     'thumb_link',   'http://images.word-power.co.uk/images/product_images/9781558607019.jpg'    ],
        [ 'like',   'description',  qr|Most Perl programmers were originally trained as C and Unix programmers,| ],
        [ 'is',     'book_link',    q|http://www.word-power.co.uk/books/higher-order-perl-I9781558607019/| ]
    ],
    '9780571313600' => [
        [ 'is',     'isbn',         '9780571313600'                 ],
        [ 'is',     'isbn10',       '571313604'                     ],  # should be '0571313604', but is() removes the leading zero
        [ 'is',     'isbn13',       '9780571313600'                 ],
        [ 'is',     'ean13',        '9780571313600'                 ],
        [ 'is',     'title',        'Touching from a Distance'      ],
        [ 'is',     'author',       'Deborah Curtis'                ],
        [ 'like',   'publisher',    qr|Faber \S+ Faber|             ],
        [ 'is',     'pubdate',      '02/10/2014'                    ],
        [ 'is',     'binding',      'Paperback'                     ],
        [ 'is',     'pages',        240                             ],
        [ 'is',     'width',        129                             ],
        [ 'is',     'height',       198                             ],
        [ 'is',     'depth',        undef                           ],
        [ 'is',     'weight',       207                             ],
        [ 'is',     'image_link',   'http://images.word-power.co.uk/images/product_images/9780571313600.jpg'    ],
        [ 'is',     'thumb_link',   'http://images.word-power.co.uk/images/product_images/9780571313600.jpg'    ],
        [ 'like',   'description',  qr|Ian Curtis left behind a legacy rich in artistic genius| ],
        [ 'is',     'book_link',    q|http://www.word-power.co.uk/books/touching-from-a-distance-I9780571313600/| ]
    ],
    '9780751830415' => [
        [ 'is',     'isbn',         '9780751830415'                 ],
        [ 'is',     'isbn10',       '751830410'                     ],  # should be '0751830410', but is() removes the leading zero
        [ 'is',     'isbn13',       '9780751830415'                 ],
        [ 'is',     'ean13',        '9780751830415'                 ],
        [ 'is',     'title',        'Geological Maps of England and Wales'  ],
        [ 'is',     'author',       undef                           ],  # no author
        [ 'like',   'publisher',    qr|British Geological Survey|   ],
        [ 'is',     'pubdate',      '01/01/1996'                    ],
        [ 'is',     'binding',      'Sheet map, folded'             ],
        [ 'is',     'pages',        undef                           ],
        [ 'is',     'width',        135                             ],
        [ 'is',     'height',       225                             ],
        [ 'is',     'depth',        undef                           ],
        [ 'is',     'weight',       651                             ],
        [ 'is',     'image_link',   'http://images.word-power.co.uk/images/product_images/9780751830415.jpg'    ],
        [ 'is',     'thumb_link',   'http://images.word-power.co.uk/images/product_images/9780751830415.jpg'    ],
        [ 'like',   'description',  qr|Shows the solid and drift geology together as the 'under-foot' geology|  ],
        [ 'is',     'book_link',    q|http://www.word-power.co.uk/books/geological-maps-of-england-and-wales-I9780751830415/| ]
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
	my $isbn = "0987654321";
    my $record;
    eval { $record = $scraper->search($isbn); };
    if($@) {
        like($@,qr/Invalid ISBN specified/);
    } elsif($record->found) {
        ok(0,'Unexpectedly found a non-existent book');
    } else {
		like($record->error,qr/Invalid ISBN specified|Failed to find that book|website appears to be unavailable/);
    }

    # this ISBN is now unavailable on the site
    $isbn = '9780571239566';
    eval { $record = $scraper->search($isbn); };
    if($@) {
        like($@,qr/Invalid ISBN specified/);
    } elsif($record->found) {
        ok(0,'Unexpectedly found a non-existent book');
    } else {
		like($record->error,qr/Invalid ISBN specified|Failed to find that book|website appears to be unavailable|Could not extract data/);
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
