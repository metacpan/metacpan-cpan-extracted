BEGIN { $ENV{TEST_SELENIUM} = 1 if $ENV{TEST_SELENIUM} }
use Mojo::Base -strict;
use Test::Mojo::WithRoles 'Selenium';
use Test::More;

use Mojolicious::Lite;
get '/'    => 'index';
get '/app' => 'app';

my $t = Test::Mojo::WithRoles->new->setup_or_skip_all;

$t->driver_args({driver_class => 'Selenium::Chrome'});

$t->set_window_size([1024, 768])->navigate_ok('/')->if_tx(status_is => 200)
  ->text_is('a.logo' => 'Logo')->live_text_is('a.logo' => 'Logo')->live_element_exists('nav')
  ->element_is_displayed('nav')->element_is_hidden('a[href="/hidden"]')
  ->active_element_is('input[name=q]')->send_keys_ok('input[name=q]', 'Mojo');

$t->window_size_is([1024, 768])->submit_ok('form')->status_is(200)
  ->current_url_like(qr{\bq=Mojo\b})->live_element_exists('input[name=q][value=Mojo]')
  ->live_element_exists_not('abbr')->live_text_like('a.logo', qr{logo}i);

$t->click_ok('nav a.logo')->status_is(200)->live_element_count_is('a', 3);

$t->navigate_ok('/not-found')->status_is(404)->current_url_is('/not-found')
  ->refresh->go_back->go_forward;

$t->capture_screenshot('foo');
ok unlink(File::Spec->catfile($t->screenshot_directory, 'foo.png')), 'deleted foo screenshot';

$t->capture_screenshot;
my $script = File::Basename::basename($0);
like $t->screenshots->[-1], qr{$script-$^T-0001\.png$}, 'got screenshot';
ok unlink(@{$t->screenshots}), 'deleted captured screenshots';

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
  %= text_field 'q'
% end
%= javascript '/app.js'
</body>
@@ app.js.ep
document.querySelector("input").focus();
