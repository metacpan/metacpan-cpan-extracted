BEGIN { $ENV{TEST_SELENIUM} = 1 if $ENV{TEST_SELENIUM} }
use lib '.';
use t::Helper;

use Mojolicious::Lite;
get '/'    => 'index';
get '/app' => 'app';

my $t = t::Helper->t->setup_or_skip_all;

$t->set_window_size([1024, 768])->navigate_ok('/');

is $t->wait_for(0.2), $t, 'wait_for 0.2';

use Time::HiRes 'time';
my $t0 = time;

{
  local $TODO = 'these tests check that timeout works';
  $t->wait_for('[href="/"]:hidden',        {timeout => 0.5});
  $t->wait_for('[href="/hidden"]:visible', {timeout => 0.5});
}

ok time - $t0 > 0.7, 'timeout' or diag time - $t0;

$t->wait_for('[name="agree"]');
$t->wait_for('[name="agree"]:enabled');
$t->wait_for('[name="agree"]:selected');
$t->wait_for('[name="agree"]:enabled:selected');
$t->wait_for('[href="/"]:visible');
$t->wait_for('[href="/hidden"]:hidden');

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
  <a href="/not-found" class="logo">404</a>
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
