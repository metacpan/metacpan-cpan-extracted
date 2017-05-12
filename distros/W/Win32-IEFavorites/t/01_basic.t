use strict;
use Test::More tests => 5;

use Win32::IEFavorites;

my $folder = Win32::IEFavorites->folder;
ok($folder, qq{Your IE's favorites folder is $folder});

my @items = Win32::IEFavorites->find();
ok(scalar @items, q{Your IE has some favorites});

my $url = $items[0]->url;
ok($url, qq{Your first favorite's url is $url});

my $modified = $items[0]->modified;
ok($modified, qq{Your first favorite's modified is $modified});

my $year = $items[0]->modified->year;
ok($year, qq{Your first favorite's modified year is $year});
