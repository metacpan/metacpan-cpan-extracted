#!/usr/bin/env perl
use Mojo::Base -strict;
use Test2::API qw(intercept);
use Test2::V0 -target => 'Test2::MojoX';
use Test2::Tools::Tester qw(facets);

use Mojolicious::Lite;

my $t = Test2::MojoX->new;
my $assert_facets;

## header_exists
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->header_exists('server');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'header "server" exists';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->header_exists('unknown');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'header "unknown" exists';
ok !$assert_facets->[1]->pass;

## header_exists_not
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->header_exists_not('unknown');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'no "unknown" header';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->header_exists_not('server');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'no "server" header';
ok !$assert_facets->[1]->pass;

## header_is
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->header_is('server' => 'Mojolicious (Perl)');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'server: Mojolicious (Perl)';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->header_is('server' => 'Django (Python)');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'server: Django (Python)';
ok !$assert_facets->[1]->pass;

## header_isnt
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->header_isnt('server' => 'Django (Python)');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'not server: Django (Python)';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->header_isnt('server' => 'Mojolicious (Perl)');
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'not server: Mojolicious (Perl)';
ok !$assert_facets->[1]->pass;

## header_like
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->header_like('server' => qr/Mojo/);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'server is similar';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->header_like('server' => qr/Django/);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'server is similar';
ok !$assert_facets->[1]->pass;

## header_unlike
$assert_facets = facets assert => intercept {
  $t->get_ok('/')->header_unlike('server' => qr/Django/);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'server is not similar';
ok $assert_facets->[1]->pass;

$assert_facets = facets assert => intercept {
  $t->get_ok('/')->header_unlike('server' => qr/Mojo/);
};
is @$assert_facets, 2;
is $assert_facets->[1]->details, 'server is not similar';
ok !$assert_facets->[1]->pass;

done_testing;
