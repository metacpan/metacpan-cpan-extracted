#!perl

use strict;
use warnings;

use Test::More tests => 25;

use Test::Mojo;
use Test::WWW::Mechanize::Mojo;

use lib './t/lib';
require MyMojjy;

use Encode qw();
use Test::WWW::Mechanize::Mojo;

my $root = "http://localhost";

my $t = Test::Mojo->new();
my $m = Test::WWW::Mechanize::Mojo->new( autocheck => 0, tester => $t,);

# TEST
$m->get_ok("$root/");
# TEST
is( $m->ct, "text/html" );
# TEST
$m->title_is("Root");
# TEST
$m->content_contains("This is the root page");

# TEST
$m->follow_link_ok( { text => 'Hello' } );
# TEST
is( $m->base, "http://localhost/hello/" );
# TEST
is( $m->ct,   "text/html" );
# TEST
$m->title_is("Hello");
my $bytes = "Hi there! ☺";
my $chars = Encode::decode( 'utf-8', $bytes );
# TEST
$m->content_contains( $chars, qq{content contains "$bytes"});

#use Devel::Peek; Dump $m->content;
#Dump(Encode::decode('utf-8', "Hi there! ☺"));
#exit;

# TEST
$m->get_ok("/");
# TEST
is( $m->ct, "text/html" );
# TEST
$m->title_is("Root");
# TEST
$m->content_contains("This is the root page");

# TEST
$m->get_ok("http://example.com/");
# TEST
is( $m->ct, "text/html" );
# TEST
$m->title_is("Root");
# TEST
$m->content_contains("This is the root page");

# TEST
$m->get_ok("/hello/");
# TEST
is( $m->ct, "text/html" );
# TEST
$m->title_is("Hello");
# TEST
$m->content_contains( $chars, qq{content contains "$bytes"});

# TEST
$m->get_ok('/with-params?one=foo&two=bar');
# TEST
$m->content_contains("[foo]{bar}", "Get params are OK.");

# TEST
$m->get_ok('/with-params?one=sophie&two=jack');
# TEST
$m->content_contains("[sophie]{jack}", "Get params (#2) are OK.");

=begin remmed_out

SKIP: {
    eval { require Compress::Zlib; };
    skip "Compress::Zlib needed to test gzip encoding", 4 if $@;
    #===TEST
    $m->get_ok("$root/gzipped/");
    #===TEST
    is( $m->ct, "text/html" );
    #===TEST
    $m->title_is("Hello");
    #==TEST
    $m->content_contains( $chars, qq{content contains "$bytes"});
}

=end remmed_out

=cut

