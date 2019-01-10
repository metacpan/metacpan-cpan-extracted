# NAME

Test::Mojo::Role::Selenium - Test::Mojo in a real browser

# SYNOPSIS

## External app

    use Mojo::Base -strict;
    use Test::More;

    $ENV{MOJO_SELENIUM_BASE_URL} ||= 'http://mojolicious.org';
    $ENV{MOJO_SELENIUM_DRIVER}   ||= 'Selenium::Chrome';

    my $t = Test::Mojo->with_roles("+Selenium")->new->setup_or_skip_all;

    $t->navigate_ok('/perldoc')
      ->live_text_is('a[href="#GUIDES"]' => 'GUIDES');

    $t->driver->execute_script(qq[document.querySelector("form").removeAttribute("target")]);
    $t->element_is_displayed("input[name=q]")
      ->send_keys_ok("input[name=q]", ["render", \"return"]);

    $t->wait_until(sub { $_->get_current_url =~ qr{q=render} })
      ->live_value_is("input[name=search]", "render");

    done_testing;

## Internal app

    use Mojo::Base -strict;
    use Test::More;

    my $t = Test::Mojo->with_roles("+Selenium")->new("MyApp")->setup_or_skip_all;

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

# DESCRIPTION

[Test::Mojo::Role::Selenium](https://metacpan.org/pod/Test::Mojo::Role::Selenium) is a role that extends [Test::Mojo](https://metacpan.org/pod/Test::Mojo) with
additional methods which checks behaviour in a browser. All the heavy lifting
is done by [Selenium::Remote::Driver](https://metacpan.org/pod/Selenium::Remote::Driver).

Some of the [Selenium::Remote::Driver](https://metacpan.org/pod/Selenium::Remote::Driver) methods are available directly in this
role, while the rest are available through the object held by the ["driver"](#driver)
attribute. Please create an issue if you think more tests or methods should be
provided directly by [Test::Mojo::Role::Selenium](https://metacpan.org/pod/Test::Mojo::Role::Selenium).

# OPTIONAL DEPENDENCIES

[Selenium::Remote::Driver](https://metacpan.org/pod/Selenium::Remote::Driver) require some external dependencies to work. Here
are a quick intro to install some of the dependencies to make this module work.

- [Selenium::Chrome](https://metacpan.org/pod/Selenium::Chrome)

        # macOS
        $ brew install chromedriver

        # Ubuntu
        $ sudo apt-get install chromium-chromedriver

        # Run tests
        $ MOJO_SELENIUM_DRIVER=Selenium::Chrome prove -l

# CAVEAT

["tx" in Test::Mojo](https://metacpan.org/pod/Test::Mojo#tx) is only populated, if the request went through an ["Internal app"](#internal-app).
This means that methods such as ["header\_is" in Test::Mojo](https://metacpan.org/pod/Test::Mojo#header_is) will not work or
probably fail completely when testing an ["External app"](#external-app).

# ENVIRONMENT VARIABLES

## MOJO\_SELENIUM\_BASE\_URL

Setting this variable will make this test send the requests to a remote server,
instead of starting a local server. Note that this will disable [Test::Mojo](https://metacpan.org/pod/Test::Mojo)
methods such as ["status\_is"](#status_is), since ["tx" in Test::Mojo](https://metacpan.org/pod/Test::Mojo#tx) will not be set. See
also ["CAVEAT"](#caveat).

This variable will get the value of ["TEST\_SELENIUM"](#test_selenium) if it looks like a URL.

## MOJO\_SELENIUM\_TEST\_HOST

In some cases you may want to override the host of your test server, when
running Selenium on a separate server or in a pod-style networking environment
this still retains the automatically generated port. This will not disable the
[Test::Mojo](https://metacpan.org/pod/Test::Mojo) methods.

## MOJO\_SELENIUM\_DRIVER

This variable can be set to a classname, such as [Selenium::Chrome](https://metacpan.org/pod/Selenium::Chrome) which will
force the selenium driver. It can also be used to pass on arguments to the
driver's constructor. Example:

    MOJO_SELENIUM_DRIVER='Selenium::Remote::Driver&browser_name=firefox&port=4444'

The arguments will be read using ["parse" in Mojo::Parameters](https://metacpan.org/pod/Mojo::Parameters#parse), which means they
follow standard URL format rules.

## TEST\_SELENIUM

This variable must be set to a true value for ["setup\_or\_skip\_all"](#setup_or_skip_all) to not skip
this test. Will also set ["MOJO\_SELENIUM\_BASE\_URL"](#mojo_selenium_base_url) if it looks like an URL.

# ATTRIBUTES

## driver

    $driver = $self->driver;

An instance of [Selenium::Remote::Driver](https://metacpan.org/pod/Selenium::Remote::Driver).

## driver\_args

    $hash = $self->driver_args;
    $self = $self->driver_args({driver_class => "Selenium::Chrome"});

Used to set args passed on to the ["driver"](#driver) on construction time. In addition,
a special key "driver\_class" can be set to use another driver class, than the
default.

Note that the environment variavble `MOJO_SELENIUM_DRIVER` can also be used to
override the driver class.

## screenshot\_directory

    $path = $self->screenshot_directory;
    $self = $self->screenshot_directory(File::Spec->tmpdir);

Where screenshots are saved.

## screenshots

    $array = $self->screenshots;

Holds an array ref with paths to all the screenshots taken with
["capture\_screenshot"](#capture_screenshot).

# METHODS

## active\_element\_is

    $self = $self->active_element_is("input[name=username]");

Checks that the current active element on the page match the selector.

## capture\_screenshot

    $self = $self->capture_screenshot;
    $self = $self->capture_screenshot("%t-page-x");
    $self = $self->capture_screenshot("%0-%t-%n"); # default

Capture screenshot to ["screenshot\_directory"](#screenshot_directory) with filename specified by the
input format. The format supports these special strings:

    Format | Description
    -------|----------------------
    %t     | Start time for script
    %0     | Name of script
    %n     | Auto increment

## click\_ok

    $self = $self->click_ok("a");
    $self = $self->click_ok;

Click on an element matching the selector or click on the currently active
element.

## current\_url\_is

    $self = $self->current_url_is("http://mojolicious.org/");
    $self = $self->current_url_is("/whatever");

Test the current browser URL against an absolute URL. A relative URL will be
converted to an absolute URL, using ["MOJO\_SELENIUM\_BASE\_URL"](#mojo_selenium_base_url).

## current\_url\_like

    $self = $self->current_url_like(qr{/whatever});

Test the current browser URL against a regex.

## element\_is\_displayed

    $self = $self->element_is_displayed("nav");

Test if an element is displayed on the web page.

See ["is\_displayed" in Selenium::Remote::WebElement](https://metacpan.org/pod/Selenium::Remote::WebElement#is_displayed).

## element\_is\_hidden

    $self = $self->element_is_hidden("nav");

Test if an element is hidden on the web page.

See ["is\_hidden" in Selenium::Remote::WebElement](https://metacpan.org/pod/Selenium::Remote::WebElement#is_hidden).

## go\_back

    $self = $self->go_back;

Equivalent to hitting the back button on the browser.

See ["go\_back" in Selenium::Remote::Driver](https://metacpan.org/pod/Selenium::Remote::Driver#go_back).

## go\_forward

    $self = $self->go_forward;

Equivalent to hitting the forward button on the browser.

See ["go\_forward" in Selenium::Remote::Driver](https://metacpan.org/pod/Selenium::Remote::Driver#go_forward).

## if\_tx

    $self = $self->if_tx(sub { ... }, @args);
    $self = $self->if_tx($method, @args);

Call either a code ref or a method on `$self` if ["tx" in Test::Mojo](https://metacpan.org/pod/Test::Mojo#tx) is defined.
`tx()` is undefined if ["navigate\_ok"](#navigate_ok) is called on an external resource.

Examples:

    $self->if_tx(status_is => 200);

## live\_element\_count\_is

    $self = $self->live_element_count_is("a", 12);

Checks that the selector finds the correct number of elements in the browser.

See ["element\_count\_is" in Test::Mojo](https://metacpan.org/pod/Test::Mojo#element_count_is).

## live\_element\_exists

    $self = $self->live_element_exists("div.content");

Checks that the selector finds an element in the browser.

See ["element\_exists" in Test::Mojo](https://metacpan.org/pod/Test::Mojo#element_exists).

## live\_element\_exists\_not

    $self = $self->live_element_exists_not("div.content");

Checks that the selector does not find an element in the browser.

    $self = $self->live_element_exists("div.foo");

See ["element\_exists\_not" in Test::Mojo](https://metacpan.org/pod/Test::Mojo#element_exists_not).

## live\_text\_is

    $self = $self->live_text_is("div.name", "Mojo");

Checks text content of the CSS selectors first matching HTML element in the
browser matches the given string.

## live\_text\_like

    $self = $self->live_text_is("div.name", qr{Mojo});

Checks text content of the CSS selectors first matching HTML element in the
browser matches the given regex.

## live\_value\_is

    $self = $self->live_value_is("div.name", "Mojo");

Checks value of the CSS selectors first matching HTML element in the browser
matches the given string.

## live\_value\_like

    $self = $self->live_value_like("div.name", qr{Mojo});

Checks value of the CSS selectors first matching HTML element in the browser
matches the given regex.

## navigate\_ok

    $self = $self->navigate_ok("/");
    $self = $self->navigate_ok("http://mojolicious.org/");

Open a browser window and go to the given location.

## new

    $self = $class->new;
    $self = $class->new($app);

Same as ["new" in Test::Mojo](https://metacpan.org/pod/Test::Mojo#new), but will not build `$app` if
["MOJO\_SELENIUM\_BASE\_URL"](#mojo_selenium_base_url) is set.

## refresh

    $self = $self->refresh;

Equivalent to hitting the refresh button on the browser.

See ["refresh" in Selenium::Remote::Driver](https://metacpan.org/pod/Selenium::Remote::Driver#refresh).

## send\_keys\_ok

    $self->send_keys_ok("input[name=name]", ["web", \"space", "framework"]);
    $self->send_keys_ok(undef, [\"return"]);

Used to send keys to a given element. Scalar refs will be sent as
[Selenium::Remote::WDKeys](https://metacpan.org/pod/Selenium::Remote::WDKeys) strings. Passing in `undef` as the first argument
will cause the keys to be sent to the currently active element.

List of some of the special keys:

- alt, control, shift
- right\_arrow, down\_arrow, left\_arrow, up\_arrow
- backspace, clear, delete, enter, return, escape, space, tab
- f1, f2, ..., f12
- command\_meta, pause

## set\_window\_size

    $self = $self->set_window_size([$width, $height]);
    $self = $self->set_window_size([375, 667]);

Set the browser window size.

## setup\_or\_skip\_all

    $self = $self->setup_or_skip_all;

Will ["skip\_all" in skip all#Test::More](https://metacpan.org/pod/skip&#x20;all#Test::More#skip_all) tests unless `TEST_SELENIUM` is set and
and ["driver"](#driver) can be built.

Will also set ["MOJO\_SELENIUM\_BASE\_URL"](#mojo_selenium_base_url) if `TEST_SELENIUM` looks like a URL.

## submit\_ok

    $self = $self->submit_ok("form");

Submit a form, either by selector or the current active form.

See ["submit" in Selenium::Remote::WebElement](https://metacpan.org/pod/Selenium::Remote::WebElement#submit).

## toggle\_checked\_ok

    $self = $self->toggle_checked_ok("input[name=human]");

Used to toggle the "checked" attribute either with a click event or fallback to
javascript.

## wait\_for

    $self = $self->wait_for(0.2);
    $self = $self->wait_for('[name="agree"]', "test description");
    $self = $self->wait_for('[name="agree"]:enabled', {interval => 1.5, timeout => 10});
    $self = $self->wait_for('[name="agree"]:selected');
    $self = $self->wait_for('[href="/"]:visible');
    $self = $self->wait_for('[href="/hidden"]:hidden');
    $self = $self->wait_for('[name=checkbox]:checked');

Simpler version of ["wait\_until"](#wait_until) for the most common use cases:

- Number

    Allows the browser and server to run for a given interval in seconds. This is
    useful if you want the browser to receive data from the server or simply let
    `setTimeout()` in JavaScript run.

- String

    Wait for an element matching the CSS selector with some additional modifiers:
    [:enabled](https://metacpan.org/pod/Selenium::Remote::WebElement#is_enabled),
    [:hidden](https://metacpan.org/pod/Selenium::Remote::WebElement#is_hidden),
    [:selected](https://metacpan.org/pod/Selenium::Remote::WebElement#is_selected) and
    [:visible](https://metacpan.org/pod/Selenium::Remote::WebElement#is_displayed).

    Check out [Selenium::Remote::WebElement](https://metacpan.org/pod/Selenium::Remote::WebElement) for details about the modifiers.

## wait\_until

    $self = $self->wait_until(sub { my $self = shift; return 1 }, \%args);
    $self = $self->wait_until(sub { $_->get_current_url =~ /foo/ }, \%args);

    # Use it as a sleep(0.8)
    $self = $self->wait_until(sub { 0 }, {timeout => 0.8, skip => 1});

Start [Mojo::IOLoop](https://metacpan.org/pod/Mojo::IOLoop) and run it until the callback returns true. Note that
`$_[0]` is `$self` and `$_` is ["driver"](#driver). `%args` is optional, but can
contain these values:

    {
      interval => $seconds, # Default: 0.5
      timeout  => $seconds, # Default: 60
      skip     => $bool,    # Default: 0
    }

## window\_size\_is

    $self = $self->window_size_is([$width, $height]);
    $self = $self->window_size_is([375, 667]);

Test if window has the expected width and height.

# AUTHOR

Jan Henning Thorsen

# COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# SEE ALSO

[Test::Mojo](https://metacpan.org/pod/Test::Mojo).

[Selenium::Remote::Driver](https://metacpan.org/pod/Selenium::Remote::Driver)
