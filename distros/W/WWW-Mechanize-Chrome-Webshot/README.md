# NAME

WWW::Mechanize::Chrome::Webshot - cheap and cheerful html2pdf converter, take a screenshot of rendered HTML, complete with CSS and Javascript

# VERSION

Version 0.05

# SYNOPSIS

This module provides ["shoot($params)"](#shoot-params) which loads
a specified URL or local file into a spawned, possibly headless, browser
(thank you Corion for [WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome)),
waits for some settle time, optionally removes
specified DOM elements (e.g. advertisements and consents),
takes a screenshot of the rendered content and saves into
the output file, as PDF or PNG, optionally adding any specified EXIF tags.

At the same time, this functionality can be seen as a
round-about way for converting HTML,
complete with CSS and JS, to PDF or PNG. And that is no mean feat.

Actually it's a mean hack.

Did I say that it supports as much HTML, CSS and JS
as the modern browser does?

Here are some examples:

    use WWW::Mechanize::Chrome::Webshot;

    my $shooter = WWW::Mechanize::Chrome::Webshot->new({
      'settle-time' => 10,
      # optionally specify a Mojo::Log logger,
      # useful if you have a global logger you want to use:
      'logger-object' => Mojo::Log->new(path=>'webshot.log'),
      # or just specify a file to log output to:
      #'logfile' => 'webshot.log',
    });
    $shooter->shoot({
      'output-filename' => 'abc.png',
      # optional unless it can not be deduced from filename
      'output-format' => 'png', # or pdf

      # URL or local file, e.g. 'file:///A/B/C.html'
      # !!! BUT USE ABSOLUTE FILEPATH in uri
      'url' => 'https://www.902.gr',

      # remove irritating DOM elements cluttering our view...
      'remove-DOM-elements' => [
        {'element-xpathselector' => '//div[id="advertisments"]'},
        {...}
      ],

      # optionally add exif metadata to the output image
      'exif' => {'created' => 'by the shooter', 'tag2' => 'hehe', ...},
    }) or die;
    ...

# CONSTRUCTOR

## `new($params)`

Creates a new `WWW::Mechanize::Chrome::Webshot` object. `$params`
is a hash reference used to pass initialization options which may
or should include the following:

- **`confighash`** or **`configfile`** or **`configstring`**

    Optional, default will be used. The configuration file/hash/string holds
    configuration parameters and its format is "enhanced" JSON
    (see ["use Config::JSON::Enhanced"](#use-config-json-enhanced)) which is basically JSON
    which allows comments between ` </* ` and ` */> `.

    Here is an example configuration file to get you started,
    this configuration is used as default when none is provided:

        </* $VERSION = '0.01'; */>
        </* comments are allowed */>
        </* and <% vars %> and <% verbatim sections %> */>
        {
            "debug" : {
                    "verbosity" : 1,
                    </* cleanup temp files on exit */>
                    "cleanup" : 1
            },
            "logger" : {
                    </* log to file if you uncomment this */>
                    </* "filename" : "..." */>
            },
            "constructor" : {
                    </* for slow connections */>
                    "settle-time" : "3",
                    "resolution" : "1600x1200",
                    "stop-on-error" : "0",
                    "remove-dom-elements" : []
            },
            "WWW::Mechanize::Chrome" : {
                    "headless" : "1",
                    "launch_arg" : [
                            </* this will change as per the 'resolution' setting above */>
                            "--window-size=600x800",
                            "--password-store=basic", </* do not ask me for stupid chrome account password */>
                    </*     "--remote-debugging-port=9223", */>
                    </*     "--enable-logging", */>
                            "--disable-gpu",
                    </*     "--no-sandbox", NO LONGER VALID */>
                            "--ignore-certificate-errors",
                            "--disable-background-networking",
                            "--disable-client-side-phishing-detection",
                            "--disable-component-update",
                            "--disable-hang-monitor",
                            "--disable-save-password-bubble",
                            "--disable-default-apps",
                            "--disable-infobars",
                            "--disable-popup-blocking"
                    ]
            }
        }

    All sections in the configuration are mandatory.

    `confighash` is a hash of configuration options with
    structure as above and can be supplied to the constructor
    instead of the configuration file.

    If no configuration is specified, then a default
    configuration will be used. This is hardcoded in the source code.

- **`logger`** or **`logfile`**

    Optional. Specify a logger object which adheres
    to [Mojo::Log](https://metacpan.org/pod/Mojo%3A%3ALog)'s API or a logfile to write
    log info into. It must implement methods `info()`, `error()`, `warn()`.

- **`verbosity`**

    Optional. Verbosity level as an integer, default is 0, silent.

- **`cleanup`**

    Optional. Cleanup all temporary files after exit. Default is 1 (yes). It is useful when debugging.

- **`settle-time`**

    Optional. Seconds to wait between loading the specified URL and taking the screenshot.
    This is very important if target URL has lots to do or on a slow connection. Default is 2 seconds.

- **`resolution`**

    Optional. Specify the size of the
    mechanized browser in the form `WxH`. Ideally,
    this should set the size of the output image. Default
    value is `1600x1200`.

- **`headless`**

    Optional. When debugging you may find it useful to display the browser while
    it loads the URL. Set this to `0` if you want this.
    Default is 1 (yes, headless, the browser window does not show).
    I am not sure if the browser dies soon after the mechanized browser object
    goes out of scope. You may want to place a `sleep($long_time);`
    before that in order to inspect its contents at your leisure.

- **`remove-dom-elements`**

    Optional. After the URL is loaded and settle time has passed, DOM elements can
    be removed. Annoyances like advertisements, consents, warnings can be
    zapped by specifying their XPath selectors. This is an ARRAY\_REF of HASH\_REF.
    Each HASH\_REF is a selector for DOM elements to be zapped. See [https://metacpan.org/pod/WWW::Mechanize::Chrome::DOMops#ELEMENT-SELECTORS](https://metacpan.org/pod/WWW::Mechanize::Chrome::DOMops#ELEMENT-SELECTORS)
    on the exact spec of the DOM selectors.

- **`exif`**

    Optional. Specify one or more EXIF tags to be
    inserted into the output image as a HASH\_REF of tag/value pairs
    each time ["shoot($params)"](#shoot-params) is called. This value will be overwritten
    if `$params` (of ["shoot($params)"](#shoot-params)) contains its own `exif` parameter.

- **`WWW::Mechanize::Chrome`**

    Optional. Specify any parameters to be passed on to the
    constructor of [WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome) as a HASH\_REF of parameters.

# METHODS

## **`shoot($params)`**

It takes a screenshot of the specified URL as
rendered by [WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome) (usually headless)
and saves it as an image to the specified file.

It returns `0` on failure, `1` on success.

Input parameters `$params`:

- **`url`**: specifies the target URL or even a URI pointing
to a local file (e.g. `file:///A/B/C.html`, use absolute filepath).
- **`remove-dom-elements`**: specifies DOM elements to
be removed after the URL has been loaded and settle time has passed.
Annoyances like advertisements, consents, warnings can be
zapped by specifying their XPath selectors. This is an ARRAY\_REF of HASH\_REF.
Each HASH\_REF is a selector for DOM elements to be zapped. See [https://metacpan.org/pod/WWW::Mechanize::Chrome::DOMops#ELEMENT-SELECTORS](https://metacpan.org/pod/WWW::Mechanize::Chrome::DOMops#ELEMENT-SELECTORS)
on the exact spec of the DOM selectors. Note that a parameter with the same
name can be specified in the constructor. If one is specified here,
then the one specified in the constructor will be ignored, else, it will
be used.
- **`exif`**: optionally specify one or more EXIF tags to be
inserted into the output image as a HASH\_REF of tag/value pairs.
If **`exif`** data is specified here, then
any exif data specified in the constructor will be ignored. This works
well for both PNG and PDF output images.

## **`shutdown()`**

It shutdowns the current [WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome) object, if any.

## **`scroll_to_bottom()`**

It scrolls the browser's contents to the very bottom without
changing its horizontal position.

## **`scroll($w, $h)`**

It scrolls the browser's screen by `$w` pixels in the horizontal
direction and by `$h` pixels in the vertical direction.

## **`mech_obj()`**

It returns the currently used [WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome) object.

# SCRIPTS

For convenience, the following scripts are provided:

- **`script/www-mechanize-webshot.pl`**

    It will take a URL, load it, render it, optionally zap any
    specified DOM elements and save the rendered content into
    an output image:

    This will save the screenshot and also adds the specified exif data:

    `script/www-mechanize-webshot.pl --url 'https://www.902.gr' --resolution 2000x2000 --exif 'created' 'bliako' --output-filename '902.png' --settle-time 10`

    Debug why the output is not what you expect, show the browser and let it live for huge settle time, also log output to a file:

    `script/www-mechanize-webshot.pl --no-headless --url 'https://www.902.gr' --resolution 2000x2000 --output-filename '902.png' --settle-time 100000 --verbosity 10 --logfile debug.log`

    This will also remove specified DOM elements by tag name and XPath selector. Note that
    the output format will be deduced as PDF because of the filename:

    `script/www-mechanize-webshot.pl --remove-dom-elements '[{\"element-tag\":\"div\",\"element-id\":\"sickle-and-hammer\",\"&&\":\"1\"},{\"element-xpathselector\":\"//div[id=ads]\"}]' --url 'https://www.902.gr' --resolution 2000x2000 --exif 'created' 'bliako' --output-filename '902.pdf' --settle-time 10`

    Explicitly save the output as PDF:

    `script/www-mechanize-webshot.pl --url 'https://www.902.gr' --resolution 2000x2000 --exif 'created' 'bliako' --output-filename 'tmpimg' --output-format 'PDF' --settle-time 10`

# CREATING THE MECH OBJECT

The mech ([WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome)) object must be supplied
to the functions in this module. It must be created by the caller.
This is how I do it:

    use WWW::Mechanize::Chrome;
    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($ERROR);

    my %default_mech_params = (
        headless => 1,
    #   log => $mylogger,
        launch_arg => [
                '--window-size=600x800',
                '--password-store=basic', # do not ask me for stupid chrome account password
    #           '--remote-debugging-port=9223',
    #           '--enable-logging', # see also log above
                '--disable-gpu',
                '--no-sandbox',
                '--ignore-certificate-errors',
                '--disable-background-networking',
                '--disable-client-side-phishing-detection',
                '--disable-component-update',
                '--disable-hang-monitor',
                '--disable-save-password-bubble',
                '--disable-default-apps',
                '--disable-infobars',
                '--disable-popup-blocking',
        ],
    );

    my $mech_obj = eval {
        WWW::Mechanize::Chrome->new(%default_mech_params)
    };
    die $@ if $@;

    # This transfers all javascript code's console.log(...)
    # messages to perl's warn()
    # we need to keep $console var in scope!
    my $console = $mech_obj->add_listener('Runtime.consoleAPICalled', sub {
          warn
              "js console: "
            . join ", ",
              map { $_->{value} // $_->{description} }
              @{ $_[0]->{params}->{args} };
        })
    ;

    # and now fetch a page
    my $URL = '...';
    my $retmech = $mech_obj->get($URL);
    die "failed to fetch $URL" unless defined $retmech;
    $mech_obj->sleep(1); # let it settle
    # now the mech object has loaded the URL and has a DOM hopefully.
    # You can pass it on to domops_find() or domops_zap() to operate on the DOM.

# SECURITY WARNING

[WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome) invokes the `google-chrome`
executable
on behalf of the current user. Headless or not, `google-chrome`
is invoked. Depending on the launch parameters, either
a fresh, new browser session will be created or the
session of the current user with their profile, data, cookies,
passwords, history, etc. will be used. The latter case is very
dangerous.

This behaviour is controlled by [WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome)'s
[constructor](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome%23WWW%3A%3AMechanize%3A%3AChrome-%253Enew%28-%25options-%29)
parameters which, in turn, are used for launching
the `google-chrome` executable. Specifically,
see [WWW::Mechanize::Chrome#separate\_session](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome%23separate_session),
[<WWW::Mechanize::Chrome#data\_directory](https://metacpan.org/pod/%3CWWW%3A%3AMechanize%3A%3AChrome%23data_directory)
and [WWW::Mechanize::Chrome#incognito](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome%23incognito).

**Unless you really need to mechsurf with your current session, aim
to launching the browser with a fresh new session.
This is the safest option.**

**Do not rely on default behaviour as this may change over
time. Be explicit.**

Also, be warned that [WWW::Mechanize::Chrome::DOMops](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome%3A%3ADOMops) executes
javascript code on that `google-chrome` instance.
This is done nternally with javascript code hardcoded
into the [WWW::Mechanize::Chrome::DOMops](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome%3A%3ADOMops)'s package files.

On top of that [WWW::Mechanize::Chrome::DOMops](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome%3A%3ADOMops) allows
for **user-specified javascript code** to be executed on
that `google-chrome` instance. For example the callbacks
on each element found, etc.

This is an example of what can go wrong if
you are not using a fresh `google-chrome`
session:

You have just used `google-chrome` to access your
yahoo webmail and you did not logout.
So, there will be an
access cookie in the `google-chrome` when you later
invoke it via [WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome) (remember
you have not told it to use a fresh session).

If you allow
unchecked user-specified (or copy-pasted from ChatGPT)
javascript code in
[WWW::Mechanize::Chrome::DOMops](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome%3A%3ADOMops)'s
`domops_find()`, `domops_zap()`, etc. then it is, theoretically,
possible that this javascript code
initiates an XHR to yahoo and fetch your emails and
pass them on to your perl code.

But there is another problem,
[WWW::Mechanize::Chrome::DOMops](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome%3A%3ADOMops)'s
integrity of the embedded javascript code may have
been compromised to exploit your current session.

This is very likely with a Windows installation which,
being the security swiss cheese it is, it
is possible for anyone to compromise your module's code.
It is less likely in Linux, if your modules are
installed by root and are read-only for normal users.
But, still, it is possible to be compromised (by root).

Another issue is with the saved passwords and
the browser's auto-fill when landing on a login form.

Therefore, for all these reasons, **it is advised not to invoke (via [WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome))
`google-chrome` with your
current/usual/everyday/email-access/bank-access
identity so that it does not have access to
your cookies, passwords, history etc.**

It is better to create a fresh
`google-chrome`
identity/profile and use that for your
`WWW::Mechanize::Chrome::DOMops` needs.

No matter what identity you use, you may want
to erase the cookies and history of `google-chrome`
upon its exit. That's a good practice.

It is also advised to review the
javascript code you provide
via [WWW::Mechanize::Chrome::DOMops](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome%3A%3ADOMops) callbacks if
it is taken from 3rd-party, human or not, e.g. ChatGPT.

Additionally, make sure that the current
installation of [WWW::Mechanize::Chrome::DOMops](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome%3A%3ADOMops)
in your system is not compromised with malicious javascript
code injected into it. For this you can check its MD5 hash

## REQUIREMENTS

# DEPENDENCIES

This module depends on [WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome) which, in turn,
depends on the `google-chrome` executable be installed on the
host computer. See [WWW::Mechanize::Chrome::Install](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome%3A%3AInstall) on
how to install the executable.

Test scripts (which create there own mech object) will detect the absence
of `google-chrome` binary and exit gracefully, meaning the test passes.
But with a STDERR message to the user. Who will hopefully notice it and
proceed to `google-chrome` installation. In any event, this module
will be installed with or without `google-chrome`.

The browser will be run, usually headless -- so a headless host system is fine,
the first time you take a screenshot. It will only be re-spawned if
you have shutdown the browser in the meantime. Exiting your script
will shutdown the browser. And so, running a script again will
re-spawn the browser (AFAICU/sic/).

## CAVEATS

In exporting to PDF, the size of the output image does not
seem to be the same as the browser size. This does not happen
with exporting to PNG.

# AUTHOR

Andreas Hadjiprocopis, `<bliako at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-www-mechanize-chrome-webshot at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Mechanize-Chrome-Webshot](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Mechanize-Chrome-Webshot).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Mechanize::Chrome::Webshot

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mechanize-Chrome-Webshot](https://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mechanize-Chrome-Webshot)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/WWW-Mechanize-Chrome-Webshot](http://annocpan.org/dist/WWW-Mechanize-Chrome-Webshot)

- CPAN Ratings

    [https://cpanratings.perl.org/d/WWW-Mechanize-Chrome-Webshot](https://cpanratings.perl.org/d/WWW-Mechanize-Chrome-Webshot)

- Search CPAN

    [https://metacpan.org/release/WWW-Mechanize-Chrome-Webshot](https://metacpan.org/release/WWW-Mechanize-Chrome-Webshot)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2019 Andreas Hadjiprocopis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
