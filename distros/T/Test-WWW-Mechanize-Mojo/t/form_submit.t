#!perl

use strict;
use warnings;

use Test::More tests => 5;

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
$m->get_ok("$root/form");
# TEST
is( $m->ct, "text/html" );
# TEST
$m->title_is("Form test");

my $email = "sophie\@hello.tld";

# $t->post_ok("/form-submit",
#    { 'Content-Type' => 'application/x-www-form-urlencoded'} ,
#    'email=shlomif'
# );

$m->submit_form_ok(
    {
        form_id => "register",
        fields =>
        {
            email => $email,
        },
    },
    "Was able to submit form.",
);

# TEST
$m->content_like(
    qr{Your email is \Q$email\E}
);

