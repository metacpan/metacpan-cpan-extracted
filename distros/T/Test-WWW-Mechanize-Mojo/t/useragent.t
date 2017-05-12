#!perl

use strict;
use warnings;

use Test::More tests => 2;

use Test::Mojo;
use Test::WWW::Mechanize::Mojo;

use lib './t/lib';
require MyMojjy;

use Encode qw();

use Test::WWW::Mechanize::Mojo;

my $root = "http://localhost";
my $agent = 'TestAgent/1.0';
my $t = Test::Mojo->new();
my $m = Test::WWW::Mechanize::Mojo->new(agent => $agent, tester => $t,);

$m->get_ok("$root/user_agent");
$m->title_is($agent, "title is correct: $agent");
