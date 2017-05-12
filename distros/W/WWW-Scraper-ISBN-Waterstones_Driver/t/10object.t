#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More tests => 35;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER          = 'Waterstones';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '1558607013' => [
        [ 'is',     'isbn',         '9781558607019'                 ],
        [ 'is',     'isbn10',       '1558607013'                    ],
        [ 'is',     'isbn13',       '9781558607019'                 ],
        [ 'is',     'ean13',        '9781558607019'                 ],
        [ 'is',     'title',        'Higher-Order Perl'             ],
        [ 'is',     'author',       'Mark Jason Dominus'            ],
        [ 'is',     'publisher',    'Elsevier Science & Technology' ],
        [ 'is',     'pubdate',      '10/12/2004'                    ],
        [ 'is',     'binding',      'Paperback'                     ],
        [ 'is',     'pages',        undef                           ],
        [ 'like',   'image_link',   qr|9781558607019\.jpg$|         ],
        [ 'like',   'thumb_link',   qr|9781558607019\.jpg$|         ],
        [ 'like',   'description',  qr|Most Perl programmers were originally trained as C and Unix programmers,| ],
        [ 'is',     'book_link',    'https://www.waterstones.com/book/higher-order-perl/mark-jason-dominus/9781558607019' ]
    ],
    '9780571239566' => [
        [ 'is',     'isbn',         '9780571239566'                 ],
        [ 'is',     'isbn10',       '0571239560'                    ],
        [ 'is',     'isbn13',       '9780571239566'                 ],
        [ 'is',     'ean13',        '9780571239566'                 ],
        [ 'is',     'title',        'Touching from a Distance'      ],
        [ 'is',     'author',       'Deborah Curtis'                ],
        [ 'is',     'publisher',    'Faber & Faber'                 ],
        [ 'is',     'pubdate',      '04/10/2007'                    ],
        [ 'is',     'binding',      'Paperback'                     ],
        [ 'is',     'pages',        undef                           ],
        [ 'like',   'image_link',   qr|9780571239566\.jpg$|         ],
        [ 'like',   'thumb_link',   qr|9780571239566\.jpg$|         ],
        [ 'like',   'description',  qr|Ian Curtis left behind a legacy rich in artistic genius| ],
        [ 'is',     'book_link',    'https://www.waterstones.com/book/touching-from-a-distance/deborah-curtis/9780571239566' ]
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
		like($record->error,qr/Invalid ISBN specified|Failed to find that book|website appears to be unavailable|Could not extract data/);
    }

    # this ISBN is now out of print
    $isbn = '9780521420365';
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
        my $error = $@ || $record->error || '';

        SKIP: {
            skip "Website unavailable", scalar(@{ $tests{$isbn} }) + 2   
                if($error =~ /website appears to be unavailable|website has crashed/);
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
