#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 23;
BEGIN { use_ok('Zeal::Feed') };

my $feed = Zeal::Feed->new_from_file('t/feed.xml');
is $feed->version, '1.2.3', 'feed version is 1.2.3';
my @urls = sort $feed->urls;
my $url_re = qr,^http://srv[12]\.example\.com/feed\.tar\.gz$,;
like $urls[$_-1], $url_re, "feed url $_ is correct" for 1, 2;
like $feed->url, $url_re, 'feed random url is correct';

use File::Temp qw/tempdir/;

sub test_unpack {
	my ($arch) = @_;
	my $dir = tempdir 'zeal-testXXXX', TMPDIR => 1, CLEANUP => 1;
	note "Testing unpack of $arch";
	Zeal::Feed::_unpack_tar_to_dir($arch, $dir);
	ok -d "$dir/a.docset", 'Root directory of unpacked docset exists';
	ok -f "$dir/a.docset/Contents/Info.plist", 'Info.plist exists';
}

note "Testing unpack with default tar";
test_unpack $_ for 't/a.tar', 't/a.tar.gz', 't/a.tar.bz2';
note "Testing unpack with Archive::Tar by env variable";
$ENV{ZEAL_USE_INTERNAL_TAR} = 1;
test_unpack $_ for 't/a.tar', 't/a.tar.gz', 't/a.tar.bz2';
note "Testing unpack with Archive::Tar by clearing PATH";
$ENV{ZEAL_USE_INTERNAL_TAR} = 0;
$ENV{PATH} = '';
test_unpack $_ for 't/a.tar', 't/a.tar.gz', 't/a.tar.bz2';
