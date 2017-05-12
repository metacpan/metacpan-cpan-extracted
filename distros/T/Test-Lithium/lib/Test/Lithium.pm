package Test::Lithium;

use strict;
use warnings;

use Time::HiRes qw/sleep/;
use YAML::XS qw/LoadFile/;
use MIME::Base64;
use Test::More;
use Test::Builder;
use Lithium::WebDriver;
use Lithium::WebDriver::Utils;
use Lithium::WebDriver::Phantom;

our $VERSION = "1.0.0";

use base 'Exporter';
our @EXPORT = qw/
	TEST_WEBDRIVER
	configure_webdriver
	start_webdriver
	stop_webdriver
	webdriver_driver

	wait_for_it
	new_window close_window
	visit refresh
	address_bar
	maximize
	resize
	wait_for_page

	focus_window
	focus_frame
	wait_for_window
	window_titles
	title

	text html value source
	get_text location
	attribute
	runjs

	present visible
	is_present isnt_present
	is_visible isnt_visible

	until_present until_not_present
	until_visible until_not_visible

	wait_until_present wait_until_not_present
	wait_until_visible wait_until_not_visible

	type
	click click_at
	mouseover
	check uncheck
	dropdown dropdown_options

	xpath_count

	freeze thaw

	update_windows
	relaxed_window_updates strict_window_updates

	alert_text
	type_alert
	cancel_alert
	confirm_alert
	screenshot
	dev_pause

/;

END {
	stop_webdriver();
}

# Hardcoded global default
my $TIMEOUT = 3;

my $T = Test::Builder->new;
my $DEFAULT_CONFIG = {
	host     => 'localhost',
	port     => '4444',
	browser  => 'googlechrome',
	platform => 'LINUX',
	protocol => "http",
	VERSION  => $VERSION,
};
my $DRIVER;
my $FROZEN_JS;

####################################################

sub _config
{
	my (%config) = @_;
	my $default = {%$DEFAULT_CONFIG};
	if ($ENV{HOME} and -f "$ENV{HOME}/.webdriverrc") {
		eval {
			my $rc = YAML::XS::LoadFile("$ENV{HOME}/.webdriverrc");
			$default->{$_} = $rc->{$_} for keys %$rc;
			1;
		} or $T->note("Failed to parse $ENV{HOME}/.webdriverrc: $@");
	}

	for (keys %$default) {
		next if defined $config{$_};
		$config{$_} = $default->{$_};
	}
	$config{site}     = $ENV{WEBDRIVER_TARGET} if $ENV{WEBDRIVER_TARGET};
	$config{platform} = uc $ENV{PLATFORM} if $ENV{PLATFORM};
	$config{browser}  = $ENV{BROWSER} if
		   $ENV{BROWSER} && (
		   $ENV{BROWSER} eq 'chrome'
		|| $ENV{BROWSER} eq 'phantomjs'
		|| $ENV{BROWSER} eq 'firefox');
	$ENV{DEBUG} = $config{debug} if $config{debug};
	$TIMEOUT = $ENV{TIMEOUT} if $ENV{TIMEOUT};
	\%config;
}

####################################################

sub TEST_WEBDRIVER
{
	   $ENV{VIMRUNTIME}        # jhunt's ';t' trick...
	|| $ENV{TEST_WEBDRIVER};
}

sub webdriver_driver
{
	return $DRIVER;
}

sub configure_webdriver
{
	$DEFAULT_CONFIG = {@_};
}

sub stop_webdriver
{
	return unless $DRIVER;
	$T->note("Disconnecting from webdriver");
	$DRIVER->disconnect;
	$DRIVER = undef;
}

sub start_webdriver
{
	stop_webdriver;
	my %cfg = %{_config(@_)};
	if ($cfg{browser} =~ m/phantomjs/) {
		debug "Starting phantom specific driver";
		$DRIVER = Lithium::WebDriver::Phantom->new(%cfg);
	} else {
		debug "Starting the default driver";
		$DRIVER = Lithium::WebDriver->new(%cfg);
	}
	$T->ok($DRIVER->connect(),
		"Driver, connecting to Driver at: "
		.$DRIVER->{host}." and opening $cfg{site}");
}

####################################################

sub wait_for_it
{
	my ($code, $timeout, $msg) = @_;
	$msg ||= "Waiting for condition to be met";
	$T->ok($DRIVER->wait_for_it($code, $timeout), $msg);
}

sub new_window
{
	my ($url, $name, $msg, $timeout) = @_;
	$T->ok($DRIVER->open_window(
			url     => $url,
			timeout => $timeout || $TIMEOUT,
			name    => $name || $url),
		$msg || "Opening url [$url] in a new window");
}

sub close_window
{
	my ($method, $value, $msg, $timeout) = @_;
	$T->ok($DRIVER->close_window(
			method  => $method,
			value   => $value,
			timeout => $timeout || $TIMEOUT),
		$msg || "Closing window [".($value||"current")."] by method [".($method||"default")."]");
}

sub visit
{
	my ($url, $msg, $timeout) = @_;
	$T->ok($DRIVER->open(
			url     => $url,
			timeout => $timeout || $TIMEOUT),
		$msg || "Opening url [$url] in the current window");
}

sub wait_for_page
{
	$DRIVER->_wait_for_page(
		timeout => $_[0]
	);
}

sub refresh
{
	my ($msg, $timeout) = @_;
	$T->ok($DRIVER->refresh(timeout => $timeout || $TIMEOUT),
		$msg || "Refreshing the current window");
}

sub focus_window
{
	my ($method, $value, $msg, $timeout) = @_;
	$T->ok($DRIVER->select_window(
			method  => $method  || 'first',
			value   => $value   || 'first',
			timeout => $timeout || $TIMEOUT),
		$msg || "Switching to window [".($value||"first")."] by method [".($method||"default")."]");
}

sub focus_frame
{
	my ($select, $msg, $timeout) = @_;
	$T->ok($DRIVER->frame(
			selector => $select  || 'default',
			timeout  => $timeout || $TIMEOUT),
		$msg || "Switching to frame [$select]");
}

sub attribute
{
	my ($selector, $attribute, $msg, $timeout) = @_;
	my $attr = $DRIVER->attribute(
			selector => $selector,
			attr     => $attribute,
			timeout  => $timeout || $TIMEOUT);
	$T->isnt_eq($attr, undef, $msg || "[$selector] getting [$attribute]");
	return $attr;
}

sub location
{
	my ($selector, $x, $y, $timeout) = @_;
	my ($x_get, $y_get) = $DRIVER->attribute(
			selector => $selector,
			attr     => 'location',
			timeout  => $timeout || $TIMEOUT);
	if (defined $x && defined $y) {
		$T->is_eq($x_get, $x, "[$selector] X ($x_get) should match given coordinate $x.");
		$T->is_eq($y_get, $y, "[$selector] Y ($y_get) should match given coordinate $y.");
	}
	return ($x_get, $y_get);
}

sub present { $DRIVER->present(@_); }
sub visible { $DRIVER->visible(@_); }

no warnings 'once';
for my $sub (qw/present visible/) {
	no strict 'refs';
	my $isnt   = "isnt_$sub";
	my $is     = "is_$sub";
	my $until  = "until_$sub";
	my $untlnt = "until_not_$sub";
	*$is    = sub {
		my $msg = $_->[1] || "[$_[0]] should be $sub";
		$T->ok($sub->($_[0]), $msg);
	};
	*$isnt  = sub {
		my $msg = $_->[1] || "[$_[0]] should NOT be $sub";
		$T->ok(!$sub->($_[0]), $msg);
	};
	*$until  = sub {
		my ($sel, $timeout, $msg)=  @_;
		$timeout ||= $TIMEOUT;
		$msg     ||= "[$_[0]] waiting [$timeout s] until $sub";
		$T->ok($DRIVER->wait_for_it(
				sub { $sub->($sel); },
				$timeout,
			),
			$msg);
	};
	*$untlnt = sub {
		my ($sel, $timeout, $msg) = @_;
		$timeout ||= $TIMEOUT;
		$msg     ||= "[$sel] waiting [$timeout s] until NOT $sub";
		$T->ok($DRIVER->wait_for_it(
				sub { !$sub->($sel); },
				$timeout,
			),
			$msg);
	};
}
*wait_until_present = \&until_present;
*wait_until_not_present = \&until_not_present;
*wait_until_visible = \&until_visible;
*wait_until_not_visible = \&until_not_visible;

for my $sub (qw/text value html/) {
	no strict 'refs';
	*$sub = sub {
		my ($selector, $msg, $timeout) = @_;
		$timeout ||= $TIMEOUT;
		my $val;
		$T->ok($DRIVER->wait_for_it(
				sub {
					$val = $DRIVER->$sub($selector);
					return defined $val;
				},
				$timeout,
			),
			$msg || "[$selector] getting $sub",
		);
		return $val;
	};
}
*get_text = \&text;
use warnings 'once';

sub type
{
	my ($selector, $value, $msg, $timeout) = @_;
	$T->ok($DRIVER->type(
			selector => $selector,
			value    => $value,
			clear    => 1,
			timeout  => $timeout || $TIMEOUT),
		$msg || "[$selector] typing $value into");
}

sub click
{
	my ($selector, $msg, $timeout) = @_;
	if (until_visible($selector), "Ensuring [$selector] is visible to click on") {
		$T->ok($DRIVER->click(
				selector => $selector,
				timeout  => $timeout || $TIMEOUT),
			$msg || "[$selector] clicking");
	}
}

sub click_at
{
	my ($selector, $x, $y, $msg, $timeout) = @_;
	$msg ||= "[$selector] clicking \@($x, $y)" if $x && $y;
	$msg ||= "[$selector] clicking \@(center)";
	$T->ok($DRIVER->click(
			selector => $selector,
			x => $x, y => $y,
			timeout => $timeout || $TIMEOUT),
		$msg);
}

sub mouseover
{
	my ($selector, $msg, $timeout) = @_;
	$msg ||= "[$selector] mousing over";
	$T->ok($DRIVER->mouseover(
			selector => $selector,
			timeout  => $timeout || $TIMEOUT),
		$msg);
}

sub check
{
	my ($selector, $msg, $timeout) = @_;
	if (until_visible($selector), "Ensuring [$selector] is visible to click on") {
		$T->ok($DRIVER->check(selector => $selector, timeout => $timeout || $TIMEOUT),
			$msg || "[$selector] check-boxing");
	}
}

sub uncheck
{
	my ($selector, $msg, $timeout) = @_;
	if (until_visible($selector), "Ensuring [$selector] is visible to click on") {
		$T->ok($DRIVER->uncheck(
				selector => $selector,
				timeout  => $timeout || $TIMEOUT),
			$msg || "[$selector] uncheck-boxing");
	}
}

sub dropdown
{
	my ($selector, $value, %opts) = @_;
	$opts{method} ||= 'label';
	$T->ok($DRIVER->dropdown(
			selector => $selector,
			method   => $opts{method},
			value    => $value,
			timeout  => $opts{timeout} || $TIMEOUT),
		$opts{msg} || "[$selector] setting value of dropdown ($opts{method}=$value)");
}

sub dropdown_options
{
	my ($selector, %opts) = @_;
	my @options = $DRIVER->dropdown(
		selector => $selector,
		method   => $opts{data} || 'label',
		timeout  => $opts{timeout} || $TIMEOUT);
	isnt(\@options, undef, $opts{msg} || "[$selector] getting options for dropdown");
	return @options;
}

sub xpath_count
{
	my ($selector, $msg, $timeout) = @_;

	# Driver xpath_count returns undef if the element isn't found
	my $count = $DRIVER->xpath_count(
		selector => $selector,
		timeout  => $timeout || $TIMEOUT);
	isnt($count, undef, $msg || "[$selector] child elements count");
	return $count;
}

sub runjs
{
	my ($js, $msg, $timeout) = @_;
	$msg ||= "Executing javascript [$js]";
	my $script_ret = $DRIVER->run(js => $js, timeout => $timeout || $TIMEOUT);
	$T->isnt_eq($script_ret, undef, $msg);
	return $script_ret;
}

sub update_windows
{
	$DRIVER->update_windows();
	$T->note("Window list updated");
}

sub strict_window_updates
{
	$DRIVER->window_tracking('strict');
	$T->note("Window tracking is set to 'strict'");
}

sub relaxed_window_updates
{
	$DRIVER->window_tracking("noop");
	$T->note("Window tracking is set to 'relaxed'");
}

sub freeze
{
	my $has_hook = runjs ("return (function () {
		try {
			if (typeof(window.synacor.testing.freeze) !== 'undefined') {
				return 1;
		} else {
				return 0;
			}
		} catch(err) {
			return 0;
		}
	})();", "Testing for the freeze hook");
	$T->ok($has_hook, "The page must have the freeze hook");
	return 0 unless $has_hook;
	if (!$FROZEN_JS) {
		runjs("window.synacor.testing.freeze()", "Pausing the browser's JS execution");
		$FROZEN_JS = 1;
	} else {
		$T->note("JS already paused");
	}
}

sub thaw
{
	my $has_hook = runjs ("return (function () {
		try {
			if (typeof(window.synacor.testing.thaw) !== 'undefined') {
				return 1;
		} else {
				return 0;
			}
		} catch(err) {
			return 0;
		}
	})();", "Testing for the thaw hook");
	$T->ok($has_hook, "The page must have the thaw hook");
	return 0 unless $has_hook;
	if($FROZEN_JS) {
		$FROZEN_JS = 0;
		runjs("window.synacor.testing.thaw()", "Continuing the browser's JS execution");
	} else {
		$T->note("JS already running");
	}
}

sub resize
{
	my ($x, $y, $msg, $timeout) = @_;
	$x ||= 1920;
	$y ||= 1080;
	$T->ok($DRIVER->window_size(x => $x, y => $y, timeout => $timeout || $TIMEOUT),
		$msg || "Setting size of the current window to x [$x] by y [$y]");
}

sub maximize
{
	$T->note("Maximizing the current window");
	$DRIVER->maximize();
}

sub address_bar
{
	my $url = $DRIVER->url();
	$T->note("The url of the current window is: $url");
	$url;
}

sub source
{
	$T->note("Getting the html source of the current window");
	$DRIVER->source();
}

sub window_titles
{
	$T->note("Getting array of window names");
	$DRIVER->window_names();
}

sub title
{
	$T->note("Getting the title of the current window");
	$DRIVER->title();
}

sub confirm_alert
{
	my ($msg) = @_;
	$msg ||= "Confirming alertbox";
	$T->ok($DRIVER->confirm, $msg);
}

sub cancel_alert
{
	my ($msg) = @_;
	$msg ||= "Canceling alertbox";
	$T->ok($DRIVER->cancel, $msg);
}

sub alert_text
{
	my ($msg) = @_;
	$msg ||= "Retrieving alert text";
	my ($state, $text) = $DRIVER->alert_text();
	$T->ok($state, $msg);
	return $text;
}

sub type_alert
{
	my ($string, $msg) = @_;
	$msg ||= "Setting alert text";
	$string = "" unless defined $string;
	my ($state, $text) = $DRIVER->alert_text($string);
	$T->ok($state, $msg);
}

sub screenshot
{
	my ($fn, $msg) = @_;
	$T->note($msg || "Saving screenshot of the current window to file name [$fn]");
	$DRIVER->screenshot($fn);
}

sub dev_pause
{
	my ($msg) = @_;
	print STDERR "$msg\n" if $msg;
	print STDERR "PAUSED (press Enter to continue)\n";
	<STDIN>;
}

=head1 NAME

Test::Lithium - Selenium Tests in Perl!

=head1 DESCRIPTION

Test::Lithium provides an easy-to-use framework for writing
automated, browser-based tests in Perl, and then running them against a
Selenium grid/hub, a standalone browser or standalone headless browser, read;
phantomjs's ghostdriver.

Coupled with Synacor::Test::Catalyst, you have a powerful test framework,
to ensure quality compliance of your frontend.

Or, combined with a check framework and phantomjs selenium hub, a dynamic,
and wieldy synthetic monitoring enviroment.

=head2 CONNECTING

The first thing you'll want to do is connect up to a Selenium grid:

    #!perl
    use Test::More;
    use Test::Lithium;

    configure_webdriver(
        host    => 'localhost',
        port    => 6789,
        browser => 'firefox',
        site    => 'http://www.google.com',
    );

    start_webdriver;

The B<start_webdriver> call will try to connect to the grid (in the example,
localhost:6789), for up to 30 seconds before calling BAIL_OUT and
terminating the test.

You can skip the call to B<configure_webdriver>, in which case sane defaults
will be used.

If you have a ~/.webdriverrc file, it is read in (as a YAML file) and used as
the configuration, as if you had called B<configure_webdriver>.  This is the
preferred method of configuring Selenium.

=head2 Testing

Once you're hooked up to the grid, it's time to start writing some tests!

    #!perl
    use Test::More;
    use Test::Lithium;

    start_webdriver; # using ~/.webdriverrc
    visit '/';
    maximize;

    click '#go';
    wait_until_present 'div ul.results', "Waiting for results";
    is_visible '#go-again', "The go-again button should be visible";

    stop_webdriver;
    done_testing;

This test visits the root of the site, then maximizes the window.  This
helps immensely with troubleshooting and debugging of failed tests.

Once its all loaded, the HTML element with an ID of C<go> (using CSS selector
syntax, C<#go>) will be clicked.

The B<wait_until_present> line spins for up to 30 seconds, waiting for the target
elements to be present in the DOM (although not necessarily visible).

Finally, B<is_visible> checks to see that an element with an ID of
C<go-again> is present in the DOM and visible.  If either of those two
assertions fail, the test will fail.

When you are all done with your Selenium session, you should disconnect, via
B<stop_webdriver>, to ensure that resources on the grid get freed properly
(Selenium can be a bit of a pain if you don't).

=head2 SKIPPING TESTS

When it comes time to run unit tests outside of your local environment (say
on a shared CI build box) you probably don't want to run the full gamut of
Selenium tests.  You may not even have access to a grid from CI!

Using Test::More's B<plan skip_all> feature, you can safely skip each of
your Selenium tests based on the value returned by B<TEST_WEBDRIVER>, which
ensures that a suitable environment is available:

    #!perl
    use Test::More;
    use Test::Lithium;

    plan skip_all => 'skipping Selenium browser-based tests'
        unless TEST_WEBDRIVER;

=head1 FUNCTIONS

=head2 configure_webdriver(%opts)

Configure the connection to the Selenium grid.

The following options are currently understood:

=over

=over

=item B<host>

The IP address or hostname of the box running the Selenium grid.  This is
not necessarily the same as the machine running the browser.

=item B<port>

TCP port of the Selenium grid server.

=item B<browser>

Name of the browser type to request for the session.

=item B<site>

The base URL to use for all unqualified page requests (i.e. where is C</>?)

Note that if you use Synacor::Test::Catalyst, you don't have to set this one
explicitly; B<start_catalyst()> will wire you up to the correct endpoint out
of the box.

=back

=back

All options must be specified.

=head2 start_webdriver()

Connect to the Selenium grid and initiate a new testing session.

=head2 stop_webdriver()

Shut down and disconnect from the Selenium grid, or webdriver server.

=head2 webdriver_driver()

Returns a reference to the web driver used for testing, in case
you need to inspect it or otherwise use it directly.

=head2 TEST_WEBDRIVER()

Test shim to skip tests in a testing plan. see above for example.

=head2 new_window($url, $name, $timeout, $msg)

Create a new window, opened to $url.  The window name will be $name.

=head2 close_window()

Close the current window.  Useful when combined with new_window.

=head2 update_windows()

Force update the local window list, this facilitates window titles and order
are maintained locally to ensure consistency. This function is not needed
if strict windows updates are enabled.

=head2 relaxed_window_updates()

Disabled the automatic window updating to improve performance.

=head2 strict_window_updates()

Increase the granularity of window ordering and names to facility finding and
or closing windows.

=head2 visit($page, $timeout, $msg)

This function does not run any test assertions.

=head2 refresh($msg)

Refresh the current window.

=head2 address_bar()

Retrieve the value of the address bar, the current location.

=over

Returns the current window's url.

=back

This function does not run any test assertions.

=head2 focus_window($type => $value)

Select and focus a named or numbered window:

    focus_window name => 'popup33';
    focus_window number => 1;       # first popup

=head2 focus_frame($selector, $timeout, $msg)

Change the CSS element search scope by selecting an iframe by css selector, default
(original page/context).
When switching frames, the entire DOM context is switched to the newly selected iframe.
You will have to reset your context to go to select any elements outside of the current iframe.

=head2 maximize($window)

Maximize the named window, or the currently selected / focused window (if
$window is undefined).

=head2 wait_for_page($timeout)

After a page-load operation, wait for the page to finish loading, up to
$timeout seconds.  Default $timeout is 30 seconds.

Be careful to only call this method after a page-load operation, like
clicking on a link that will load a new page.

=head2 wait_until_present($selector, $timeout, $msg)

Wait, for up to $timeout seconds, until the target element exists in the
DOM.  Default $timeout is 30 seconds.

=head2 until_present($selector, $timeout, $msg)

Alias for wait_until_present

=head2 wait_until_not_present($selector, $timeout, $msg)

Wait, for up to $timeout seconds, until the target element no longer exists
in the DOM.  Default $timeout is 30 seconds.

=head2 until_not_present($selector, $timeout, $msg)

Alias for wait_until_not_present

=head2 wait_until_visible($selector, $timeout, $msg)

Wait, for up to $timeout seconds, until the target element exists in the DOM
and is visible.  Default $timeout is 30 seconds.

=head2 until_visible($selector, $timeout, $msg)

Alias for wait_until_visible

=head2 wait_until_not_visible($selector, $timeout, $msg)

Wait, for up to $timeout seconds, until the target element exists in the DOM
but is not visible.  Default $timeout is 30 seconds.

=head2 until_not_visible($selector, $timeout, $msg)

Alias for wait_until_not_visible

=head2 present($selector)

Returns a boolean indicating whether the given CSS selector is present in the DOM.

=head2 is_present($selector, $msg)

Assert that the targeted element does not exist in the DOM.

=head2 isnt_present($selector, $msg)

Assert that the targeted element exists in the DOM.

=head2 visible($selector)

Returns a boolean indicating whether the given CSS selector is present in the DOM
and is visible.

=head2 is_visible($selector, $msg)

Assert that the targeted element exists in the DOM and is visible.

=head2 isnt_visible($selector, $msg)

Assert that the targeted element exists in the DOM but is not visible.

=head2 text($selector)

Retrieve the inner text of the targeted element.

Note: B<wait_until_present> will be called on B<$selector>, implicitly.

=head2 get_text($selector)

Alias function for text

=head2 value($selector)

Retrieve the form field value of the targeted element.

=head2 attribute($selector, $attribute)

Retrieve the attribute from a targeted element.

Note: B<wait_until_present> will be called on B<$selector>, implicitly.

=head2 html($selector)

Retrieve the inner HTML of the targeted element, via Javascript.

Note: B<wait_until_present> will be called on B<$selector>, implicitly.

=head2 location($selector, $x, $y, %timeout)

Retrieve the x and y coordinantes of the targeted element.

Note: B<wait_until_present> will be called on B<$selector>, implicitly.


=head2 runjs($code)

Run arbitrary Javascript in the currently selected window.  All code will
have C<window.> prepended to it (effectively).  This still alows calls like
jQuery selectors and simple function calls, but doesn't allow some syntax.

This function does not run any test assertions.

=head2 freeze

Pause the client side javascript application, for ease of finding DOM elements and
other necessities.

The function that is run is:
  window.synacor.testing.freeze()

This function must return 1 upon success, and 0 upon failure (if it is unable to freeze).

=head2 thaw

Un-freeze/continue running the client side javascript with:
   window.synacor.testing.thaw()

This function must return 1 upon success, and 0 upon failure (if it is unable to thaw).

=head2 type($selector, $value, $msg)

Enter B<$value> into the targeted input field.

=head2 click($selector, $msg)

Click on the targeted $selector.

=head2 click_at($selector, $x, $y, $msg)

Initiate a click inside of the B<$selector> element, using ($x, $y) as
coordinates relative to the upper-left hand corner of the element.

=head2 mouseover($selector, $msg)

Fire the C<mouseover> event on B<$selector>

=head2 check($selector, $msg)

Check the targeted checkbox.

=head2 uncheck($selector, $msg)

Uncheck the targeted checkbox.

=head2 dropdown($selector, %opts)

Select the dropdown option with the given label (not the value).

Opts can be any of:

=over

=item method

Method to use for identifying values ('value', or 'label'). Defaults to 'label'.

=item timeout

Timeout for finding/selecting the dropdown.

=item msg

Message to use for test output.

=back

=head2 dropdown_options($selector, %opts)

Retrieve the list of labels from the given SELECT element, as a list.

Options can be any of:

=over

=item data

Type of dropdown values to return (either 'label', or 'value'). Defaults to 'label'.

=item timeout

Timeout for finding the dropdown and getting its values.

=item msg

Message to usefor test output.

=back

=head2 xpath_count($selector)

Count how many elements match the xpath selector.

This function does not run any test assertions.

=head2 dev_pause($msg)

Pause the entire test, until someone presses enter at the console.  This is
useful for troubleshooting / debugging failing tests, since it lets you
interact with the browser on the Selenium node.

If given, $msg will be printed out as a diagnostic, to remind you why you
pasused.  In any case, the message "PAUSED (press Enter to continue)" will
be printed as a diagnostic.

This function does not run any test assertions.

=head2 screenshot($fn, $msg)

Take a screenshot of the currently selected window and save it to $fn.

An optional message can be provided by the second argument, which will be
printed to screen as a TAP diagnostic message.

=head2 resize($x, $y, $msg, $timeout)

Change the size of the currently active window. parameters are X size, Y size, the message and timeout
all parameters are optional, X and Y default to HD (1920x1080) and Timeout is set to the global timeout
of 3 seconds. The default message is sensible.

=head2 source

Returns the current source code of the active window.

=head2 wait_for_window

Wait for the currently active window to finish loading. IE the native javascript function of document.ready
to return "complete"

=head2 window_titles

Get an array of window titles.

=over

Returns an array of window titles in order the were opened

=back

=head2 title

Returns the active window's title.

=head2 wait_for_it

Takes a code ref and timeout, and waits for that coderef to return true,
or for the timeout to expire. This is a test assertion, so if timeout expires,
the test will fail.

=head2 alert_text($test_name)

Retrieves the text of an alert dialog.

=head2 type_alert($text, $test_name)

Sets the javascript alert() text.

=head2 cancel_alert($test_name)

Cancels an alert() dialog prompted by javascript.

=head2 confirm_alert($test_name)

Confirms an alert() dialog prompted by javascript.

=head1 AUTHOR

Written by  Dan Molik C<< <dan at d3fy dot net> >>
           James Hunt C<< <james at jameshunt dot us> >>
=cut

1;
