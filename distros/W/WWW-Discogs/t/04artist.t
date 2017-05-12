use strict;
use warnings;

use Test::Mock::LWP::Dispatch;
use HTTP::Response;
use FindBin qw( $Bin );
use File::Slurp qw( read_file );

use Test::More tests => 12;
use Test::Deep;

BEGIN { use_ok 'WWW::Discogs' }

my $rt = read_file("$Bin/../requests/artist.res");
my $response = HTTP::Response->parse($rt);
$mock_ua->map(
    'http://api.discogs.com/artist/Christian%20Morgenstern?releases=1',
    $response
);

my $client = new_ok('WWW::Discogs' => [], '$client');
my $artist = $client->artist(name => 'Christian Morgenstern', releases => 1);
isa_ok($artist, 'WWW::Discogs::Artist', '$artist');
isa_ok($artist, 'WWW::Discogs::HasMedia', '$artist');

is($artist->name, 'Christian Morgenstern', 'name');
is($artist->realname, "G\x{f6}tz-Christian Morgenstern", 'realname');

my @aliases = $artist->aliases;
cmp_deeply(\@aliases, bag('Bikini Machine, The',
                          'CHRS',
                          'Visco Space',), 'aliases');

my @namevariations = $artist->namevariations;
cmp_deeply(\@namevariations, bag( 'C. Morgenstern',
                                  'C.Morgenstern',
                                  'Ch. Morgenstern',
                                  "G\x{f6}tz - Christian Morgenstern",
                                  "G\x{f6}tz Christian Morgenstern",
                                  "G\x{f6}tz-Christian Morgenstern",
                                  'Goetz',
                                  'Goetz Christian Morgenstern',
                                  'Goetz-Christian Morgenstern',
                                  'Morgenstern',
                                  'O. Morgenstern',), 'namevariations');

like($artist->profile, qr/^Christian Morgenstern was born on the/, 'profile');

my @urls = $artist->urls;
cmp_deeply(\@urls, bag(), 'urls');

my @images = $artist->images(type => 'primary');
cmp_deeply(\@images,
           bag(
               {
                   uri150 => 'http://api.discogs.com/image/A-150-4292-003.jpg',
                   width  => 297,
                   type   => 'primary',
                   height => 428,
                   uri    => 'http://api.discogs.com/image/A-4292-003.jpg',
               }
           ), 'images');

my @releases = $artist->releases;
for (@releases) {
    if ($_->{id} == 6093) {
        cmp_deeply($_,
                   {
                       status => 'Accepted',
                       thumb  => 'http://api.discogs.com/image/R-150-6093-001.jpg',
                       format => '2xLP',
                       id     => 6093,
                       title  => 'Miscellaneous',
                       label  => 'Kanzleramt',
                       type   => 'release',
                       role   => 'Main',
                       year   => 1997,
                   }, 'releases');
    }
}
