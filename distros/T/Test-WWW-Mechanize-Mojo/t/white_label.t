#!perl

use strict;
use warnings;

use Test::More tests => 4;

use Test::Mojo;
use Test::WWW::Mechanize::Mojo;

use lib './t/lib';
require MyMojjy;

use Encode qw();
use Test::WWW::Mechanize::Mojo;

my $root = "http://localhost";

my $t = Test::Mojo->new();
my $m = Test::WWW::Mechanize::Mojo->new( tester => $t,);

$m->host('foo.com');
# TEST
$m->get_ok('/host');
# TEST
$m->content_contains('Host: foo.com');

$m->clear_host;
# TEST
$m->get_ok('/host');
# TEST
$m->content_contains('Host: localhost') or diag $m->content;
