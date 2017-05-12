#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 2;
use lib 't/lib';
use Test::WWW::Mechanize::Catalyst 'Catty';

my $root = "http://localhost";

my $m = Test::WWW::Mechanize::Catalyst->new;
$m->get_ok("$root/bad_content_encoding/");

# per https://rt.cpan.org/Ticket/Display.html?id=36442
$m->content_contains('foo');
