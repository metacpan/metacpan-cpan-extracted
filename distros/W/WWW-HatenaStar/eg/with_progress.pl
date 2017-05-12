#!/usr/bin/perl

# http://subtech.g.hatena.ne.jp/otsune/20081230/hatenastar

use strict;
use warnings;

use Config::Pit;
use Getopt::Long;
use Term::ProgressBar;
use WWW::HatenaStar;

my $count = 100;
my $uri = 'http://ugomemo.hatena.ne.jp/0B3D19604CE04B2F@DSi/movie/E04B2F_08720FF94B42A_002';
GetOptions(
    'count=i' => \$count, 
    'uri=s'   => \$uri, 
) or die "Usage: $0 -c count -u 'http://example.com/'";
Getopt::Long::Configure("bundling");

my $config = pit_get("hatena.ne.jp", require => {
    "username" => "your username on hatena",
    "password" => "your password on hatena"
});

my $star = WWW::HatenaStar->new({ config => $config });
my $term;
my $res = $star->stars({
    uri => $uri,
    count => $count,
}, {
    callback => sub {
        my ($cur, $max) = @_;
        unless ($term) {
            $term = Term::ProgressBar->new($max);
        }
        $term->update($cur);
    }
});

unless($res) {
    die "WWW::HatenaStar complains : " . $star->error;
}
