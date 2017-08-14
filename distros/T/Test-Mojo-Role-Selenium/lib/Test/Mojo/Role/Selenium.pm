package Test::Mojo::Role::Selenium;
use Mojo::Base -base;
use Role::Tiny;

use Carp 'croak';
use File::Basename ();
use File::Spec;
use Mojo::Parameters;
use Mojo::Util 'encode';
use Selenium::Remote::WDKeys ();

use constant DEBUG => $ENV{MOJO_SELENIUM_DEBUG} || 0;

$ENV{TEST_SELENIUM} //= '0';
$ENV{MOJO_SELENIUM_BASE_URL} ||= $ENV{TEST_SELENIUM} =~ /^http/ ? $ENV{TEST_SELENIUM} : '';

our $VERSION = '0.10';

my $SCRIPT_NAME = File::Basename::basename($0);
my $SCREENSHOT  = 1;

has driver => sub {
  my $self = shift;
  my $args = $self->driver_args;
  my ($driver, $env) = split /\&/, +($ENV{MOJO_SELENIUM_DRIVER} || ''), 2;
  $env = Mojo::Parameters->new($env || '')->to_hash;
  $driver ||= $args->{driver_class} || 'Selenium::PhantomJS';
  eval "require $driver;1" or croak "require $driver: $@";
  warn "[Selenium] Using $driver\n" if DEBUG;
  $driver = $driver->new(%$args, %$env, ua => $self->ua);
  $driver->debug_on if DEBUG > 1;
  $driver->default_finder('css');
  $driver;
};

has driver_args          => sub { +{} };
has screenshot_directory => sub { File::Spec->tmpdir };
has screenshots          => sub { +[] };

has _live_base => sub {
  my $self = shift;
  return Mojo::URL->new($ENV{MOJO_SELENIUM_BASE_URL}) if $ENV{MOJO_SELENIUM_BASE_URL};
  $self->{live_port} = Mojo::IOLoop::Server->generate_port;
  return Mojo::URL->new("http://127.0.0.1:$self->{live_port}");
};

has _live_server => sub {
  my $self   = shift;
  my $app    = $self->app or croak 'Cannot start server without $t->app(...) set';
  my $server = Mojo::Server::Daemon->new(silent => DEBUG ? 0 : 1);

  Scalar::Util::weaken($self);
  $server->on(
    request => sub {
      my ($server, $tx) = @_;
      $self->tx($tx) if $tx->req->url->to_abs eq $self->_live_url;
    }
  );

  $server->app($app)->listen([$self->_live_base->to_string])
    ->start->ioloop->acceptor($server->acceptors->[0]);

  return $server;
};

has _live_url => sub { Mojo::URL->new };

sub active_element_is {
  my ($self, $selector, $desc) = @_;
  my $driver = $self->driver;
  my $active = $driver->get_active_element;
  my $el     = $self->_proxy(find_element => $selector);
  my $same   = $active && $el ? $driver->compare_elements($active, $el) : 0;

  return $self->_test('ok', $same, _desc($desc, "active element is $selector"));
}

sub capture_screenshot {
  my ($self, $path) = @_;
  $path = _screenshot_name($path ? "$path.png" : "%0-%t-%n.png");
  $path = File::Spec->catfile($self->screenshot_directory, $path);
  Test::More::diag("Saving screenshot to $path");
  $self->driver->capture_screenshot($path);
  push @{$self->screenshots}, $path;
  return $self;
}

sub click_ok {
  my ($self, $selector) = @_;
  my $el = $selector ? $self->_proxy(find_element => $selector) : $self->driver->get_active_element;
  my $err = 'no such element';

  if ($el) {
    eval { $self->driver->mouse_move_to_location(element => $el) } unless $el->is_displayed;
    $err = $@ || 'unable to click';
    $err = '' if $el->click;
  }

  return $self->_test('ok', !$err, _desc("click on $selector $err"));
}

sub current_url_is {
  my $self = shift;
  my $url  = $self->_live_abs_url(shift);

  return $self->_test('is', $self->driver->get_current_url,
    $url->to_string, _desc('exact match for current url'));
}

sub current_url_like {
  my ($self, $match, $desc) = @_;
  return $self->_test('like', $self->driver->get_current_url,
    $match, _desc($desc, 'current url is similar'));
}

sub element_is_displayed {
  my ($self, $selector, $desc) = @_;
  my $el = $self->_proxy(find_element => $selector);
  return $self->_test('ok', ($el && $el->is_displayed),
    _desc($desc, "element $selector is displayed"));
}

sub element_is_hidden {
  my ($self, $selector, $desc) = @_;
  my $el = $self->_proxy(find_element => $selector);
  return $self->_test('ok', ($el && $el->is_hidden), _desc($desc, "element $selector is hidden"));
}

sub go_back    { $_[0]->_proxy('go_back');    $_[0] }
sub go_forward { $_[0]->_proxy('go_forward'); $_[0] }

sub if_tx {
  my ($self, $method) = (shift, shift);

SKIP: {
    my $desc = ref $method ? '__SUB__' : $method;
    Test::More::skip("\$t->tx() is not defined ($desc)", 1) unless $self->tx;
    $self->$method(@_);
  }

  return $self;
}

sub live_element_count_is {
  my ($self, $selector, $count, $desc) = @_;
  my $els = $self->_proxy(find_elements => $selector);
  return $self->_test('is', int(@$els), $count,
    _desc($desc, qq{element count for selector "$selector"}));
}

sub live_element_exists {
  my ($self, $selector, $desc) = @_;
  $desc = _desc($desc, qq{element for selector "$selector" exists});
  return $self->_test('ok', $self->_proxy(find_element => $selector), $desc);
}

sub live_element_exists_not {
  my ($self, $selector, $desc) = @_;
  $desc = _desc($desc, qq{no element for selector "$selector"});
  return $self->_test('ok', !$self->_proxy(find_element => $selector), $desc);
}

sub live_text_is {
  my ($self, $selector, $value, $desc) = @_;
  return $self->_test(
    'is', $self->_element_data(get_text => $selector),
    $value, _desc($desc, qq{exact text for selector "$selector"})
  );
}

sub live_text_like {
  my ($self, $selector, $regex, $desc) = @_;
  return $self->_test(
    'like', $self->_element_data(get_text => $selector),
    $regex, _desc($desc, qq{similar text for selector "$selector"})
  );
}

sub live_value_is {
  my ($self, $selector, $value, $desc) = @_;
  return $self->_test(
    'is', $self->_element_data(get_value => $selector),
    $value, _desc($desc, qq{exact value for selector "$selector"})
  );
}

sub live_value_like {
  my ($self, $selector, $regex, $desc) = @_;
  return $self->_test(
    'like', $self->_element_data(get_value => $selector),
    $regex, _desc($desc, qq{similar value for selector "$selector"})
  );
}

sub navigate_ok {
  my $self = shift;
  my $url  = $self->_live_abs_url(shift);
  my ($desc, $err);

  $self->tx(undef)->_live_url($url);
  $self->_live_server if $self->{live_port};    # Make sure server is running
  $self->driver->get($url->to_string);

  if ($self->tx) {
    $desc = "navigate to $url";
    $err  = $self->tx->error;
    Test::More::diag($err->{message}) if $err and $err->{message};
  }
  else {
    $desc = "navigate to $url (\$t->tx() is not set)";
  }

  return $self->_test('ok', !$err, _desc($desc));
}

sub new {
  my $self = shift->SUPER::new;
  $self->ua(Test::Mojo::Role::Selenium::UserAgent->new->ioloop(Mojo::IOLoop->singleton));
  return $self if $ENV{MOJO_SELENIUM_BASE_URL};
  return $self unless my $app = shift;
  return $self->app(ref $app ? $app : Mojo::Server->new->build_app($app));
}

sub refresh { $_[0]->_proxy('refresh'); $_[0] }

sub send_keys_ok {
  my ($self, $selector, $keys, $desc) = @_;
  my $el = $selector ? $self->_proxy(find_element => $selector) : $self->driver->get_active_element;

  $selector ||= 'active element';
  $keys = [ref $keys ? $keys : split //, $keys] unless ref $keys eq 'ARRAY';

  for (@$keys) {
    my $key = ref $_ ? Selenium::Remote::WDKeys::KEYS()->{$$_} : $_;
    croak "Invalid key '@{[ref $_ ? $$_ : $_]}'" unless defined $key;
    $_ = $key;
  }

  if ($el) {
    eval {
      for my $key (@$keys) {
        warn "[Selenium] send_keys $selector <- @{[Mojo::Util::url_escape($key)]}\n" if DEBUG;
        $el->send_keys($key);
      }
      1;
    } or do {
      Test::More::diag($@);
      $el = undef;
    };
  }

  return $self->_test('ok', $el, _desc($desc, "keys sent to $selector"));
}

sub set_window_size {
  my ($self, $size, $desc) = @_;
  $self->driver->set_window_size(reverse @$size);
  return $self;
}

sub setup_or_skip_all {
  my $self = shift;

  local $@;
  Test::More::plan(skip_all => $@ || 'TEST_SELENIUM=1 or TEST_SELENIUM=http://...')
    unless $ENV{TEST_SELENIUM} and eval { $self->driver };

  $ENV{MOJO_SELENIUM_BASE_URL} ||= $ENV{TEST_SELENIUM} if $ENV{TEST_SELENIUM} =~ /^http/;

  return $self;
}

sub submit_ok {
  my ($self, $selector, $desc) = @_;
  my $el = $self->_proxy(find_element => $selector);
  $el->submit if $el;
  return $self->_test('ok', $el, _desc($desc, "click on $selector"));
}

sub toggle_checked_ok {
  my ($self, $selector) = @_;
  my $el = $self->_proxy(find_element => $selector);

  if ($el) {
    if ($el->is_displayed) {
      $el->click;
    }
    else {
      my $sel = $selector;
      $sel =~ s!"!\\"!g;
      $self->driver->execute_script(
        qq[var el=document.querySelector("$sel");el.setAttribute("checked", !el.getAttribute("checked"))]
      );
    }
  }

  return $self->_test('ok', $el, _desc("click on $selector"));
}

sub wait_for {
  my ($self, $arg, $desc) = @_;
  my @checks;

  return $self->wait_until(sub {0}, {skip => 1, timeout => $arg})
    if Scalar::Util::looks_like_number($arg);


  $desc ||= "waited for element $arg";
  push @checks, 'is_displayed' if $arg =~ s!:visible\b!!;
  push @checks, 'is_enabled'   if $arg =~ s!:enabled\b!!;
  push @checks, 'is_hidden'    if $arg =~ s!:hidden\b!!;
  push @checks, 'is_selected'  if $arg =~ s!:selected\b!!;

  return $self->wait_until(
    sub {
      my $e = $_->find_element($arg);
      return $e && @checks == grep { $e->$_ } @checks;
    },
    {desc => $desc},
  );
}

sub wait_until {
  my ($self, $cb, $args) = @_;
  my $ioloop = $self->ua->ioloop;
  my $t0     = time;
  my ($ok, @tid);

  $args->{timeout}  ||= $ENV{MOJO_SELENIUM_WAIT_TIMEOUT}  || 60;
  $args->{interval} ||= $ENV{MOJO_SELENIUM_WAIT_INTERVAL} || 0.5;

  $ioloop->delay(
    sub {
      my $next = shift->begin;
      push @tid, $ioloop->timer($args->{timeout}, $next);
      push @tid, $ioloop->recurring(
        $args->{interval},
        sub {
          $next->(1, 1) if eval { local $_ = $self->driver; $self->$cb($args) };
          Test::More::diag("[Selenium] wait_until: $@") if $@ and ($args->{debug} or DEBUG);
        }
      );
    },
    sub {
      $ok = $_[1];
      $ioloop->remove($_) for @tid;
    },
  )->wait;

  return $self if $args->{skip};
  return $self->_test('ok', $ok, _desc($args->{desc} || "waited for @{[time - $t0]}s"));
}

sub window_size_is {
  my ($self, $exp, $desc) = @_;
  my $size = $self->driver->get_window_size;

  return $self->_test('is_deeply', [@$size{qw(width height)}],
    $exp, _desc($desc, "window size is $exp->[0]x$exp->[1]"));
}

sub _desc { encode 'UTF-8', shift || shift }

sub _live_abs_url {
  my $self = shift;
  my $url  = Mojo::URL->new(shift);

  unless ($url->is_abs) {
    my $base = $self->_live_base;
    $url->scheme($base->scheme)->host($base->host)->port($base->port);
  }

  return $url;
}

sub _proxy {
  my ($self, $method) = (shift, shift);
  my $res = eval { $self->driver->$method(@_) };
  warn $@ if DEBUG and $@;
  return $res;
}

sub _element_data {
  my ($self, $method) = (shift, shift);
  my $el = $self->_proxy(find_element => shift);
  return $el ? $el->$method : '';
}

sub _screenshot_name {
  local $_ = shift;
  s!\%0\b!{$SCRIPT_NAME}!ge;
  s!\%n\b!{sprintf '%04s', $SCREENSHOT++}!ge;
  s!\%t\b!{$^T}!ge;
  return $_;
}

package    # hide from pause
  Test::Mojo::Role::Selenium::UserAgent;
use Mojo::Base 'Mojo::UserAgent';

use constant DEBUG => $ENV{MOJO_SELENIUM_DEBUG} || 0;

sub request {
  my ($ua, $req) = @_;
  my $method = uc($req->method || 'get');
  my $tx = $ua->build_tx($method, $req->uri->as_string, {$req->headers->flatten}, $req->content);
  my $done;

  warn "[Selenium] $method @{[$req->uri->as_string]}\n" if DEBUG;

  # This is super ugly and need to be implemented differently,
  # but I'm not sure how to implement wait_until() without this
  # one_tick() hack.
  if ($ua->ioloop->is_running) {
    $ua->start($tx, sub { $done = 1 });
    $ua->ioloop->reactor->one_tick until $done;
  }
  else {
    $ua->start($tx);
  }

  return HTTP::Response->parse($tx->res->to_string);
}

# Should not say "... during global destruction."
# sub DESTROY { warn 'no circular refs?' }

1;

=encoding utf8

=head1 NAME

Test::Mojo::Role::Selenium - Test::Mojo in a real browser

=head1 SYNOPSIS

=head2 External app

  use Mojo::Base -strict;
  use Test::Mojo::WithRoles "Selenium";
  use Test::More;

  $ENV{MOJO_SELENIUM_DRIVER} ||= 'Selenium::Chrome';

  my $t = Test::Mojo::WithRoles->new->setup_or_skip_all;

  $t->navigate_ok('/perldoc')
    ->live_text_is('a[href="#GUIDES"]' => 'GUIDES');

  $t->driver->execute_script(qq[document.querySelector("form").removeAttribute("target")]);
  $t->element_is_displayed("input[name=q]")
    ->send_keys_ok("input[name=q]", ["render", \"return"]);

  $t->wait_until(sub { $_->get_current_url =~ qr{q=render} })
    ->live_value_is("input[name=search]", "render");

  done_testing;

=head2 Internal app

  use Mojo::Base -strict;
  use Test::Mojo::WithRoles "Selenium";
  use Test::More;

  my $t = Test::Mojo::WithRoles->new("MyApp")->setup_or_skip_all;

  # All the standard Test::Mojo methods are available
  ok $t->isa("Test::Mojo");
  ok $t->does("Test::Mojo::Role::Selenium");

  $t->navigate_ok("/")
    ->status_is(200)
    ->header_is("Server" => "Mojolicious (Perl)")
    ->text_is("div#message" => "Hello!")
    ->live_text_is("div#message" => "Hello!")
    ->live_element_exists("nav")
    ->element_is_displayed("nav")
    ->active_element_is("input[name=q]")
    ->send_keys_ok("input[name=q]", "Mojo")
    ->capture_screenshot;

  $t->submit_ok("form")
    ->status_is(200)
    ->current_url_like(qr{q=Mojo})
    ->live_element_exists("input[name=q][value=Mojo]");

  $t->click_ok("nav a.logo")->status_is(200);

  done_testing;

=head1 DESCRIPTION

L<Test::Mojo::Role::Selenium> is a role that extends L<Test::Mojo> with
additional methods which checks behaviour in a browser. All the heavy lifting
is done by L<Selenium::Remote::Driver>.

Some of the L<Selenium::Remote::Driver> methods are available directly in this
role, while the rest are available through the object held by the L</driver>
attribute. Please let me know if you think more tests or methods should be
provided directly by L<Test::Mojo::Role::Selenium>.

This role is EXPERIMENTAL and subject to change.

=head1 OPTIONAL DEPENDENCIES

L<Selenium::Remote::Driver> require some external dependencies to work. Here
are a quick intro to install some of the dependencies to make this module work.

=over 2

=item * L<Selenium::Chrome>

  # macOS
  $ brew install chromedriver

  # Ubuntu
  $ sudo apt-get install chromium-chromedriver

  # Run tests
  $ MOJO_SELENIUM_DRIVER=Selenium::Chrome prove -l

=item * L<Selenium::PhantomJS>

  # macOS
  $ brew install phantomjs

  # Ubuntu
  $ sudo apt-get install phantomjs

  # Run tests
  $ MOJO_SELENIUM_DRIVER=Selenium::PhantomJS prove -l

=back

=head1 CAVEAT

L<Test::Mojo/tx> is only populated by this role, if the initial request is done
by passing a relative path to L</navigate_ok>. This means that methods such as
L<Test::Mojo/header_is> will not work as expected (probably fail completely) if
L</navigate_ok> is issued with an absolute path like L<http://mojolicious.org>.

=head1 ENVIRONMENT VARIABLES

=head2 MOJO_SELENIUM_BASE_URL

Setting this variable will make this test send the requests to a remote server,
instead of starting a local server. Note that this will disable L<Test::Mojo>
methods such as L</status_is>, since L<Test::Mojo/tx> will not be set. See
also L</CAVEAT>.

=head2 MOJO_SELENIUM_DRIVER

This variable can be set to a classname, such as L<Selenium::Chrome> or
L<Selenium::PhantomJS>, which will force the selenium driver. It can also be
used to pass on arguments to the driver's constructor. Example:

  MOJO_SELENIUM_DRIVER='Selenium::Remote::Driver&browser_name=firefox&port=4444'

The arguments will be read using L<Mojo::Parameters/parse>, which means they
follow standard URL format rules.

=head1 ATTRIBUTES

=head2 driver

  $driver = $self->driver;

An instance of L<Selenium::Remote::Driver>.

=head2 driver_args

  $hash = $self->driver_args;
  $self = $self->driver_args({driver_class => "Selenium::PhantomJS"});

Used to set args passed on to the L</driver> on construction time. In addition,
a special key "driver_class" can be set to use another driver class, than the
default L<Selenium::PhantomJS>.

Note that the environment variavble C<MOJO_SELENIUM_DRIVER> can also be used to
override the driver class.

=head2 screenshot_directory

  $path = $self->screenshot_directory;
  $self = $self->screenshot_directory(File::Spec->tmpdir);

Where screenshots are saved.

=head2 screenshots

  $array = $self->screenshots;

Holds an array ref with paths to all the screenshots taken with
L</capture_screenshot>.

=head2 toggle_checked_ok

  $self = $self->toggle_checked_ok("input[name=human]");

Used to toggle the "checked" attribute either with a click event or fallback to
javascript.

TODO: The implementation might change in the future.

=head1 METHODS

=head2 active_element_is

  $self = $self->active_element_is("input[name=username]");

Checks that the current active element on the page match the selector.

=head2 capture_screenshot

  $self = $self->capture_screenshot;
  $self = $self->capture_screenshot("%t-page-x");
  $self = $self->capture_screenshot("%0-%t-%n"); # default

Capture screenshot to L</screenshot_directory> with filename specified by the
input format. The format supports these special strings:

  Format | Description
  -------|----------------------
  %t     | Start time for script
  %0     | Name of script
  %n     | Auto increment

=head2 click_ok

  $self = $self->click_ok("a");
  $self = $self->click_ok;

Click on an element matching the selector or click on the currently active
element.

=head2 current_url_is

  $self = $self->current_url_is("http://mojolicious.org/");
  $self = $self->current_url_is("/whatever");

Test the current browser URL against an absolute URL. A relative URL will be
converted to an absolute URL, using L</MOJO_SELENIUM_BASE_URL>.

=head2 current_url_like

  $self = $self->current_url_like(qr{/whatever});

Test the current browser URL against a regex.

=head2 element_is_displayed

  $self = $self->element_is_displayed("nav");

Test if an element is displayed on the web page.

See L<Selenium::Remote::WebElement/is_displayed>.

=head2 element_is_hidden

  $self = $self->element_is_hidden("nav");

Test if an element is hidden on the web page.

See L<Selenium::Remote::WebElement/is_hidden>.

=head2 go_back

  $self = $self->go_back;

Equivalent to hitting the back button on the browser.

See L<Selenium::Remote::Driver/go_back>.

=head2 go_forward

  $self = $self->go_forward;

Equivalent to hitting the forward button on the browser.

See L<Selenium::Remote::Driver/go_forward>.

=head2 if_tx

  $self = $self->if_tx(sub { ... }, @args);
  $self = $self->if_tx($method, @args);

Call either a code ref or a method on C<$self> if L<Test::Mojo/tx> is defined.
C<tx()> is undefined if L</navigate_ok> is called on an external resource.

Examples:

  $self->if_tx(status_is => 200);

=head2 live_element_count_is

  $self = $self->live_element_count_is("a", 12);

Checks that the selector finds the correct number of elements in the browser.

See L<Test::Mojo/element_count_is>.

=head2 live_element_exists

  $self = $self->live_element_exists("div.content");

Checks that the selector finds an element in the browser.

See L<Test::Mojo/element_exists>.

=head2 live_element_exists_not

  $self = $self->live_element_exists_not("div.content");

Checks that the selector does not find an element in the browser.

  $self = $self->live_element_exists("div.foo");

See L<Test::Mojo/element_exists_not>.

=head2 live_text_is

  $self = $self->live_text_is("div.name", "Mojo");

Checks text content of the CSS selectors first matching HTML element in the
browser matches the given string.

=head2 live_text_like

  $self = $self->live_text_is("div.name", qr{Mojo});

Checks text content of the CSS selectors first matching HTML element in the
browser matches the given regex.

=head2 live_value_is

  $self = $self->live_value_is("div.name", "Mojo");

Checks value of the CSS selectors first matching HTML element in the browser
matches the given string.

=head2 live_value_like

  $self = $self->live_value_like("div.name", qr{Mojo});

Checks value of the CSS selectors first matching HTML element in the browser
matches the given regex.

=head2 navigate_ok

  $self = $self->navigate_ok("/");
  $self = $self->navigate_ok("http://mojolicious.org/");

Open a browser window and go to the given location.

=head2 new

  $self = $class->new;
  $self = $class->new($app);

Same as L<Test::Mojo/new>, but will not build C<$app> if
L</MOJO_SELENIUM_BASE_URL> is set.

=head2 refresh

  $self = $self->refresh;

Equivalent to hitting the refresh button on the browser.

See L<Selenium::Remote::Driver/refresh>.

=head2 send_keys_ok

  $self->send_keys_ok("input[name=name]", ["web", \"space", "framework"]);
  $self->send_keys_ok(undef, [\"return"]);

Used to send keys to a given element. Scalar refs will be sent as
L<Selenium::Remote::WDKeys> strings. Passing in C<undef> as the first argument
will cause the keys to be sent to the currently active element.

List of some of the special keys:

=over 2

=item * alt, control, shift

=item * right_arrow, down_arrow, left_arrow, up_arrow

=item * backspace, clear, delete, enter, return, escape, space, tab

=item * f1, f2, ..., f12

=item * command_meta, pause

=back

=head2 set_window_size

  $self = $self->set_window_size([$width, $height]);
  $self = $self->set_window_size([375, 667]);

Set the browser window size.

=head2 setup_or_skip_all

  $self = $self->setup_or_skip_all;

Will L<skip all#Test::More/skip_all> tests unless C<TEST_SELENIUM> is set and
and L</driver> can be built.

Will also set L</MOJO_SELENIUM_BASE_URL> if C<TEST_SELENIUM> looks like a URL.

=head2 submit_ok

  $self = $self->submit_ok("form");

Submit a form, either by selector or the current active form.

See L<Selenium::Remote::WebElement/submit>.

=head2 wait_for

  $self = $self->wait_for(0.2);
  $self = $self->wait_for('[name="agree"]', "test description");
  $self = $self->wait_for('[name="agree"]:enabled');
  $self = $self->wait_for('[name="agree"]:selected');
  $self = $self->wait_for('[href="/"]:visible');
  $self = $self->wait_for('[href="/hidden"]:hidden');

Simpler version of L</wait_for> for the most common use cases:

=over 2

=item Number

Allows the browser and server to run for a given interval in seconds. This is
useful if you want the browser to receive data from the server or simply let
C<setTimeout()> in JavaScript run.

=item String

Wait for an element matching the CSS selector with some additional modifiers:
L<:enabled|Selenium::Remote::WebElement#is_enabled>,
L<:hidden|Selenium::Remote::WebElement#is_hidden>,
L<:selected|Selenium::Remote::WebElement#is_selected> and
L<:visible|Selenium::Remote::WebElement#is_displayed>.

Check out L<Selenium::Remote::WebElement> for details about the modifiers.

=back

=head2 wait_until

  $self = $self->wait_until(sub { my $self = shift; return 1 }, \%args);
  $self = $self->wait_until(sub { $_->get_current_url =~ /foo/ }, \%args);

  # Use it as a sleep(0.8)
  $self = $self->wait_until(sub { 0 }, {timeout => 0.8, skip => 1});

Start L<Mojo::IOLoop> and run it until the callback returns true. Note that
C<$_[0]> is C<$self> and C<$_> is L</driver>. C<%args> is optional, but can
contain these values:

  {
    interval => $seconds, # Default: 0.5
    timeout  => $seconds, # Default: 60
    skip     => $bool,    # Default: 0
  }

=head2 window_size_is

  $self = $self->window_size_is([$width, $height]);
  $self = $self->window_size_is([375, 667]);

Test if window has the expected width and height.

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Test::Mojo>.

L<Selenium::Remote::Driver>

=cut
