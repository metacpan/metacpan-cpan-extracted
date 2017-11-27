BEGIN { $ENV{TEST_SELENIUM} = 1 if $ENV{TEST_SELENIUM} }
use Mojo::Base -strict;
use Test::Mojo::WithRoles 'Selenium';
use Test::More;

use Mojolicious::Lite;
get '/'    => 'index';
get '/app' => 'app';

my $t = Test::Mojo::WithRoles->new->setup_or_skip_all;

$t->navigate_ok('/');
$t->live_element_exists({class => 'logo'});
$t->live_element_exists({id    => 'not_found'});
$t->live_element_exists({link  => '/hidden'});
$t->live_element_exists({name  => 'agree'});
$t->live_element_exists({xpath => q,//input[@name='agree'],});

done_testing;

__DATA__
@@ index.html.ep
<!DOCTYPE html>
<html>
<head>
  <title>test title</title>
</head>
<body>
<nav>
  <a href="/" class="logo">Logo</a>
  <a href="/not-found" class="logo" id="not_found">404</a>
  <a href="/hidden" style="display:none">Hidden</a>
</nav>
%= form_for '', begin
  %= check_box 'agree'
% end
%= javascript '/app.js'
</body>
@@ app.js.ep
setTimeout(function() {
  document.querySelector('[name="agree"]').click();
}, 1000);
