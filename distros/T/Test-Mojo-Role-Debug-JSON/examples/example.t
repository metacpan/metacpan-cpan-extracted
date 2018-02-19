#!perl

use Mojolicious::Lite;
get '/' => 'index';

use Test::More;
use Test::Mojo::WithRoles 'Debug';
my $t = Test::Mojo::WithRoles->new;

$t->get_ok('/')
  ->text_is(title => 'Slartibartfast')
  ->d;

done_testing();

__DATA__

@@index.html.ep

<!DOCTYPE html>
<html lang="en">
<meta charset="utf-8">
<title>42</title>


