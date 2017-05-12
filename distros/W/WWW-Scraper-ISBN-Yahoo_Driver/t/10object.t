#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More tests => 19;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER          = 'Yahoo';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '0307474275' => [
        [ 'is',     'isbn',         '9780307474278'                 ],
        [ 'is',     'isbn10',       '0307474275'                    ],
        [ 'is',     'isbn13',       '9780307474278'                 ],
        [ 'is',     'ean13',        '9780307474278'                 ],
        [ 'is',     'title',        'The Da Vinci Code'             ],
        [ 'is',     'author',       undef                           ],
        [ 'is',     'publisher',    undef                           ],
        [ 'is',     'pubdate',      undef                           ],
        [ 'is',     'binding',      undef                           ],
        [ 'is',     'pages',        undef                           ],
        [ 'is',     'width',        undef                           ],
        [ 'is',     'height',       undef                           ],
        [ 'is',     'weight',       undef                           ],
        [ 'like',   'image_link',   qr!https://ec.yimg.com!         ],
        [ 'like',   'thumb_link',   qr!https://ec.yimg.com!         ],
        [ 'like',   'book_link',    qr|https://us.lrd.yahoo.com|    ]
    ],
);

my %alternate = (
    '0307474275' => {
        'author'    => 'Dan Brown',
        'publisher' => 'Random House',
        'pubdate'   => '2009',
        'binding'   => 'Paperback'
    }
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

    for my $isbn (keys %tests) {
        eval { $record = $scraper->search($isbn) };
        my $error = $@ || $record->error || '';

        diag("error=$error")    if($error);

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

                if(defined $book->{$test->[1]} && $alternate{$isbn}{$test->[1]}) {
                    $test->[2] = $alternate{$isbn}{$test->[1]};
                }

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
