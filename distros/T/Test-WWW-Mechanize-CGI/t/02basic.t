#!perl

use strict;
use warnings;

use Test::More tests => 3;

use CGI;
use Test::WWW::Mechanize::CGI;

my $mech = Test::WWW::Mechanize::CGI->new;
$mech->cgi( sub {

    my $q = CGI->new;

    print $q->header,
          $q->start_html('Hello World'),
          $q->h1('Hello World'),
          $q->end_html;
});

$mech->get_ok('http://localhost/');
$mech->title_is('Hello World');
$mech->content_contains('Hello World');
