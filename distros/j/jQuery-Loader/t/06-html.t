use strict;
use warnings;

use Test::More;
use Test::Deep;
plan qw/no_plan/;
use Directory::Scratch;
my $scratch = Directory::Scratch->new;
my $base = $scratch->base;
sub file { return $base->file(@_) }

use jQuery::Loader;

my $loader = jQuery::Loader->new_from_internet;

is($loader->html."\n", <<_END_);
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.2.6/jquery.js" type="text/javascript"></script>
_END_

$loader = jQuery::Loader->new_from_internet(filter => "min");
is($loader->html."\n", <<_END_);
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.2.6/jquery.min.js" type="text/javascript"></script>
_END_

SKIP: {
    $ENV{TEST_RELEASE} or skip "Not testing going out to the Internet";
    my $loader = jQuery::Loader->new_from_internet(cache => { uri => "http://localhost/assets/\%l", file => $base->subdir("htdocs/assets")->file("\%l") });
    is($loader->html."\n", <<_END_);
<script src="http://localhost/assets/jquery-1.2.6.js" type="text/javascript"></script>
_END_
    ok(-s $base->file(qw/htdocs assets jquery-1.2.6.js/));
}
