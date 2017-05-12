#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More tests => 20;
use WWW::Scraper::ISBN::AmazonUK_Driver;

use lib qw(t/lib);
use Fake::Mechanize;

###########################################################

my $DRIVER          = 'AmazonUK';

my %tests = (
    'empty-fields.html' => [
        [ 'is',     'isbn',         undef                           ],
    ],
    'all-fields-uk.html' => [
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
        [ 'is',     'weight',       453                             ],
        [ 'like',   'image_link',   qr!^http://ecx.images-amazon.co!],
        [ 'like',   'thumb_link',   qr!^http://ecx.images-amazon.co!],
        [ 'like',   'description',  qr|Perl Developer's Dictionary is a complete|                            ],
        [ 'like',   'book_link',    qr!all-fields-uk!               ]
    ]
);

###########################################################

my $tests = 0;
for my $isbn (keys %tests) { $tests += scalar( @{ $tests{$isbn} } ) + 2 }

###########################################################

my $scraper = WWW::Scraper::ISBN::AmazonUK_Driver->new();
isa_ok($scraper,'WWW::Scraper::ISBN::AmazonUK_Driver');

{
    for my $file (keys %tests) {
        my $mech = Fake::Mechanize->new({ file => $file });

        my $book = $scraper->_parse($mech);

        if($file eq 'empty-fields.html') {
            is($book,0,'.. no book data returned');

        } else {
            for my $test (@{ $tests{$file} }) {
                if($test->[0] eq 'ok')          { ok(       $book->{$test->[1]},             ".. '$test->[1]' found [$file]"); } 
                elsif($test->[0] eq 'is')       { is(       $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$file]"); } 
                elsif($test->[0] eq 'isnt')     { isnt(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$file]"); } 
                elsif($test->[0] eq 'like')     { like(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$file]"); } 
                elsif($test->[0] eq 'unlike')   { unlike(   $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$file]"); }
            }
        }
    }
}
