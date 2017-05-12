use Mojo::Base -strict;
use Test::Mojo::WithRoles 'Selenium';
use Test::More;

$ENV{MOJO_SELENIUM_DRIVER} ||= 'Selenium::Chrome';
plan skip_all => 'TEST_SELENIUM=http://mojolicious.org'
  unless $ENV{TEST_SELENIUM} and $ENV{TEST_SELENIUM} =~ /^http/;

my $t = Test::Mojo::WithRoles->new->setup_or_skip_all;

$t->set_window_size([1024, 768]);

$t->navigate_ok('/perldoc')->live_text_is('a[href="#GUIDES"]' => 'GUIDES')
  ->element_is_displayed("a");

$t->driver->execute_script(qq[document.querySelector("form").removeAttribute("target")]);
$t->element_is_displayed("input[name=q]")->send_keys_ok("input[name=q]", ["render", \"return"]);

$t->wait_until(sub { $_->get_current_url =~ /q=render/ });
$t->if_tx(status_is => 200)->live_value_is("input[name=search]", "render");

eval { $t->status_is(200) };
like $@, qr{undefined value}, 'cannot call Test::Mojo methods on external results';

done_testing;
