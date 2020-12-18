#!perl

use Mojolicious::Lite;
get '/' => 'index';

use Test::More;
use Test::Mojo::WithRoles 'DOMinizer';
use Scalar::Util qw/refaddr/;

my $t = Test::Mojo::WithRoles->new;
$t->get_ok('/')->status_is(200)->in_DOM(sub {
    my ($dom, $given_t) = @_;
    is $dom->at('#test1')->find('span')->[1]->all_text, 'pass',
        'in_DOM appears to have right DOM in $_[0]';
    is   $_->at('#test1')->find('span')->[1]->all_text, 'pass',
        'in_DOM appears to have right DOM in $_';
    is refaddr($given_t), refaddr($t), '$_[1] contains exact Test::Mojo obj'
})->get_ok('/?test2=1')->in_DOM(sub {
    is $_->at('#test2')->all_text, 'pass', 'returning non Test::More works';
    Test::Mojo::WithRoles->new->get_ok('/?test3=1')
})->element_exists('#test3', 'we can return different Test::Mojos');

done_testing;

__DATA__

@@index.html.ep

<!DOCTYPE html>
<html lang="en">
<meta charset="utf-8">
<title>42</title>
<div id="test1"><span>fail</span><span class="match">pass</span></div>

% if (param 'test2') {
  <div id="test2">pass</div>
% }
% if (param 'test3') {
  <div id="test3">pass</div>
% }
