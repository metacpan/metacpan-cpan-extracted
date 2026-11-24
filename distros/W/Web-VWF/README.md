## Name

Web::VWF - Versatile Web Framework - easily build a website to support different languages and client platforms

## Version

Version 0.004.1

## Synopsis

A site's page script, `cgi-bin/page.fcgi`, is all of this:

```perl
    use FindBin;
    use Web::VWF;

    Web::VWF->new({ directory => "$FindBin::Bin/../conf" })->run();
```

## Description

Web::VWF is [VWF](https://github.com/nigelhorne/vwf), the Versatile Web
Framework, packaged as a CPAN distribution.  It is an MVC framework for
building responsive websites that adapt to the client's language, to the kind
of client (web, mobile, robot, search engine or AI crawler) and to whichever
database back end the site uses.

This module is the distribution's front door: it holds the version number, this
overview, and the one thing a site builds by hand - ["new"](#new), the site's
configuration and the directory the server keeps it in.  Working the framework
does these modules:

- [Web::VWF::Display](https://metacpan.org/pod/Web%3A%3AVWF%3A%3ADisplay)

    The page renderer.  Given the configuration, the browser's language and the
    kind of client it is, it finds the right template for a page and renders it.
    A site subclasses it for each of its pages.

- [Web::VWF::Config](https://metacpan.org/pod/Web%3A%3AVWF%3A%3AConfig)

    Reads the site's XML configuration.

- [Web::VWF::Allow](https://metacpan.org/pod/Web%3A%3AVWF%3A%3AAllow)

    Access control and rate limiting.

- [Web::VWF::Blacklist](https://metacpan.org/pod/Web%3A%3AVWF%3A%3ABlacklist)

    The country blacklist, shared by the page script, [Web::VWF::Allow](https://metacpan.org/pod/Web%3A%3AVWF%3A%3AAllow) and
    [Web::VWF::Display](https://metacpan.org/pod/Web%3A%3AVWF%3A%3ADisplay).

- [Web::VWF::Utils](https://metacpan.org/pod/Web%3A%3AVWF%3A%3AUtils)

    Cache initialisation and the Haversine distance calculation.

- [Web::VWF::CAPTCHA](https://metacpan.org/pod/Web%3A%3AVWF%3A%3ACAPTCHA)

    reCAPTCHA integration and the bypass that follows a solved challenge.

- [Web::VWF::Mail](https://metacpan.org/pod/Web%3A%3AVWF%3A%3AMail)

    Sends mail through sendmail(1), signed with DKIM when the site has a key.

- [Web::VWF::Throttle](https://metacpan.org/pod/Web%3A%3AVWF%3A%3AThrottle)

    A YAML backend for Data::Throttler that also works on Windows.

- [Web::VWF::Data::&lt;source>](https://metacpan.org/pod/Web%3A%3AVWF%3A%3AData%3A%3A%3Csource%3E)

    The data access layer: CSV, XML and SQLite, through Database::Abstraction.

`example/` in this distribution is a small working site to copy and adapt:
`example/cgi-bin/page.fcgi` is the page script, `example/conf/default` is the
configuration (placeholders only - put real keys in your own copy), and
`example/templates/` holds the templates.  Run it from the command line with
`CONFIG_DIR=$(pwd)/example/conf root_dir=$(pwd)/example perl -Ilib example/cgi-bin/page.fcgi page=index`.

A site's templates sit under a path built from the page's class name,
so the file to change when the page module is `Web::VWF::Display::index` is
`templates/web/Web/VWF/Display/index.tmpl` - see [Web::VWF::Display](https://metacpan.org/pod/Web%3A%3AVWF%3A%3ADisplay)
for the rest of the search order.

A site that used to carry a renamed copy of VWF of its own deletes that copy,
installs this distribution, renames `VWF::` to `Web::VWF::` in its own code,
and moves its templates from `.../VWF/Display/` to `.../Web/VWF/Display/`.

## Configuration

A site is configured by files, usually XML, in its `conf/` directory (see
[Web::VWF::Config](https://metacpan.org/pod/Web%3A%3AVWF%3A%3AConfig) for where they are looked for, in which order, and how an
environment variable of the same name as a top-level key overrides that key).
The file named `default` is read first, then one named for the site's domain
name, then `$CONFIG_FILE`.  `example/conf/default` is a complete working
example.

Every setting is optional.  What a site does not say gets the default given
below, which is what the framework did before the setting existed.

### Environment Variables

- `CONFIG_DIR`

    The one directory configuration is read from.  When it is set nothing else is
    searched.  It must exist.

- `CONFIG_FILE`

    An extra configuration file, read after `default` and the domain's file.

- `root_dir`

    The site's own directory: where the templates are.  It also overrides the `root_dir` of every cache driver,
    and the one in the configuration.  The server's directory of sites, for a
    server that has one directory for each, is the `directory` argument of
    ["new"](#new) and defaults to this variable and then to `/usr/lib/vwf`.

- `CACHEDIR`, `CACHE_DIR`

    Where the file-based caches (`File` and `BerkeleyDB`) are kept, so that they
    need not be inside the site: `CACHEDIR` is used if it is set and not empty,
    else `CACHE_DIR`.  Either beats `root_dir` above, and the directory is
    created if it does not exist.

### Pages: `Display`

```
    <display>
            <directory>/path/to/modules</directory>
            <page>
                    <name>states</name>
                    <description>Displays information about the U.S. states</description>
                    <directory>/path/to/this/page</directory>
            </page>
    </display>
```

One `page` for each page that `?page=` may name.  The `name` is required and
may only be word characters.  The `description` is shown in the `300 Multiple
Choices` response, which lists the pages when no `page` is given.  A page is
the class `Web::VWF::Display::<name>` and its template.

`directory` says where the page modules are.  In `display` it is the default
for all of them, in a `page` it is that page's alone and wins.  It is where the
`<name>.pm` file is, not a directory of templates.  A relative one is
taken from the directory the page script is in.  A page with no directory at
all is found in `@INC`.

With no `page` at all, `display`'s `directory` is searched and every `.pm`
in it, except `captcha.pm`, is a page.  With no `display` either, that is
`../lib/Web/VWF/Display` beside the script.

The old `pages` is read when there is no `display`, as is its old form of one
string of names, `<pages>index, meta_data</pages>`.

### Data: `Databases` and `Data`

```
    <databases>
            <directory>/path/to/files</directory>
    </databases>
    <data>
            <directory>/path/to/drivers</directory>
            <driver>
                    <name>states</name>
                    <description>List of data about the U.S. states</description>
                    <directory>/path/to/this/driver</directory>
            </driver>
    </data>
```

`databases` says where the data files are (CSV, XML, SQLite), and `data` where the
drivers that read them are: the [Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction) subclasses.  They are
separate so that the files may be kept apart from code.

`databases`'s `directory` is the directory of the data files.  Default:
`../databases` beside the script.  Pages are told it as `database_dir` and
`databasedir`.  The old top-level `database_dir` is read when there is no
`directory` in `databases`.

One `driver` in `data` for each driver a page may use.  A page is given each as
a variable named for the last part of its class, lower-cased: the module
`Web::VWF::Data::states` is `$states` in the page.  A `name` with no `::` in it is
a `Web::VWF::Data::` module; one with `::`, such as `Bands::Data::bands`, is
used as written.  The `description` is only logged.

`directory` is where the driver's `.pm` file is, named for the last part of the
class: in the `driver` for that driver alone, in `data` for all of them.  With
neither, the drivers are looked for in the `databases` directory.  A driver that
is not in the `data` or `databases` directory is taken from `@INC`, which is
how a site uses the distribution's own `Web::VWF::Data::index`.  Only the
`directory` of a `driver` is strict: a driver that is not in it is not loaded.

What is loaded, in order of preference:

- 1. the `driver` elements;
- 2. the old `data_modules`, one string of names, `index, states` (an empty
one means none);
- 3. every `.pm` in the `data` directory, or failing that the `databases`
directory;
- 4. the default, `Web::VWF::Data::index`.

A module that cannot be loaded is logged and skipped; the pages that do not
need it still work.

Take care in naming a driver's own configuration: the drivers are given the
configuration's top-level keys as their constructor arguments, so a key called
`data` would replace the rows of every database.  The framework discards those
rows, but a driver of your own that is constructed elsewhere must do the same.

### Other Settings

- `supported_languages`

    The languages the site has templates for.  Default: `en-gb`.

- `allow_ips`

    Addresses always allowed through the access control.  Default: `108.44.193.70`
    and `127.0.0.1`; a site should set its own.  It is not called `allowed_ips`,
    which would be taken as a constructor argument by [CGI::ACL](https://metacpan.org/pod/CGI%3A%3AACL).

- `rate_limit_trusted_ips`

    Addresses never rate limited.  Default: `127.0.0.1` and `192.168.1.1`.

- `blacklist_countries`

    Two-letter country codes to refuse.  Default: `BY MD RU CN BR UY TR MA VE SA
    CY CO MX IN RS PK UA XH`.  Setting it replaces the list.

- `vwflog`

    The path of the access log, a CSV file that the `meta_data` page reads.
    Default: `vwf.log` in the log directory [CGI::Info](https://metacpan.org/pod/CGI%3A%3AInfo) chooses.

- `root_dir`

    The site's own directory, as the environment variable of the same name, which
    wins.  When it is set, the output of pages other than the home page and mail
    sending is also saved, for a day, in `save_to` inside it, by [FCGI::Buffer](https://metacpan.org/pod/FCGI%3A%3ABuffer).

- `twitter`

    A Twitter handle, which gives the pages a tweet button.

- `SiteTitle`, `contact`, and any other key

    All of the configuration is available to the templates, so a site may put its
    own settings in it.  `SiteTitle` and `contact` in the example are only
    that.

- `syslog`

    Passed to [CGI::Info](https://metacpan.org/pod/CGI%3A%3AInfo) to log to syslog.  `server` is accepted for `host`.

- `DKIMSelector`, `DKIMKey`

    The selector and the private key file with which the mail the contact page
    sends is signed.  Without both it is sent unsigned.  See [Web::VWF::Mail](https://metacpan.org/pod/Web%3A%3AVWF%3A%3AMail).

List-valued settings (`supported_languages`, `allow_ips`,
`rate_limit_trusted_ips`, `blacklist_countries`) may be written as one string
separated by commas or spaces, or as an element with one child for each value.

### `Recaptcha`

```
    <recaptcha>
            <enabled>1</enabled>
            <site_key>...</site_key>
            <secret_key>...</secret_key>
    </recaptcha>
```

Google reCAPTCHA, from [https://www.google.com/recaptcha/admin](https://www.google.com/recaptcha/admin).  When it is
enabled a client past the soft rate limit is shown a challenge instead of
being refused.  When it is not, the hard limit refuses with a plain-text `429`.

### `Security`

- `security.rate_limiting.max_requests`

    Requests from one address in the `time_window` after which the CAPTCHA is
    shown.  Default: 100.

- `security.rate_limiting.max_requests_hard`

    After which the request is refused.  Default: one and a half times
    `max_requests`.

- `security.rate_limiting.time_window`

    A duration such as `60s` or `5 minutes`.  Default: `60s`.

- `security.rate_limiting.captcha_bypass_duration`

    How long a solved CAPTCHA exempts the client from the limit.  Default: `300s`.

- `security.ids_threshold`

    The [CGI::IDS](https://metacpan.org/pod/CGI%3A%3AIDS) impact above which a request is treated as an attack.
    Default: 50.

- `security.csrf.enable`

    Set to `0` to turn off the CSRF cookie that pages with a form are given.
    Default: 1.

- `security.csrf.secret`

    The secret the CSRF tokens are signed with.  Without one a random secret is
    made for each process and the tokens do not outlive it.  See
    [Web::VWF::Display](https://metacpan.org/pod/Web%3A%3AVWF%3A%3ADisplay).

### `Throttle`

The per-address throttle used by [Web::VWF::Allow](https://metacpan.org/pod/Web%3A%3AVWF%3A%3AAllow) and by
[Web::VWF::Display](https://metacpan.org/pod/Web%3A%3AVWF%3A%3ADisplay), which share one file.

- `throttle.max_items`

    Requests allowed in the interval.  Default: 30.

- `throttle.interval`

    The interval, in seconds.  Default: 90.

- `throttle.file`

    The file the counts are kept in.  Default: `throttle` in the temporary
    directory.

### Caches: `disc_cache` and `memory_cache`

```
    <disc_cache>
            <driver>File</driver>
            <root_dir>/var/tmp/cache</root_dir>
    </disc_cache>
```

The [CHI](https://metacpan.org/pod/CHI) caches.  `driver` is one of `Memory`, `BerkeleyDB`, `DBI`,
`Redis`, `Memcached`, `SharedMem`, `File` or `Null`.  Default for
`disc_cache`: `BerkeleyDB`, or `File` where that is not installed; for
`memory_cache`: `Memory`.  The other keys depend on the driver:

- `root_dir`

    For `File` and `BerkeleyDB`.  Overridden by `$CACHEDIR`, `$CACHE_DIR` and
    `$root_dir`, in that order.  It must exist and be writable unless one of the
    environment variables made it.

- `server` (or `host`) and `port`

    For `Memcached`: `host:port` pairs separated by commas, or a host with the
    port in `port`.  Default: `127.0.0.1:11211`.

- `connect`, `create_table`

    For `DBI`: the DSN, which is required, and whether to create the table
    (default: yes).

- `reconnect`, `every`, `encoding`, `redis_options`

    For `Redis`, which also takes `server` (or `host`) and `port` as above.

- `shm_key`, `shm_size`, `max_size`

    For `SharedMem`; `shm_key` is required.

- `global`, `datastore`

    For `Memory`; not both.

## Subroutines/Methods

### New

The configuration of a site, and the directory the server keeps it in.

**Parameters:**

- `directory` - The directory the server keeps the configuration of the
sites it serves in: one directory per site, named after the site, so that a site
reached as `example.com` is configured from `/usr/lib/vwf/example.com`.  Any
other root can be named here - `/etc/vwf`, `/usr/local/etc/vwf` - and the
default is `/usr/lib/vwf`.  Optional.
- `info`, `logger`, `config_directory`, `config_file`, `config` -
handed to [Web::VWF::Config](https://metacpan.org/pod/Web%3A%3AVWF%3A%3AConfig), which describes them.

#### Api Specification

##### Input

```perl
    {
            directory => { type => 'string', optional => 1 },
            info => { type => 'object', optional => 1 },
            logger => { type => 'object', optional => 1 },
            config_directory => { type => 'string', optional => 1 },
            config_file => { type => 'string', optional => 1 },
            config => { type => 'hashref', optional => 1 },
    }
```

`new` croaks with `directory must be a string` when `directory` is a reference.

##### Output

```perl
    { type => 'object', isa => 'Web::VWF' }
```

### Run

Serve requests.  It accepts FastCGI requests one after another and sends each
one to the page named by `?page=`, as described in ["DESCRIPTION"](#description); an error in
one request is logged and does not end the worker.

The loop ends, and `run` returns, when the web server asks the worker to exit,
after a TERM or USR1 signal, or when the page script has been changed since the
worker started, so that the next request starts a worker with the new code.

When `REMOTE_ADDR` is not set, which is how the script is run from a command
line, there is no web server: `run` handles one request, built from the
command-line arguments such as `page=index`, turns caching off, takes the
language from `LANG` and prints debug logging to STDOUT among the response.

`run` refuses to run again from inside itself, and to run while the script is
still being compiled, which happens when something reads the page script as if
it were a configuration file.  It prints a message on STDERR and returns.

#### Api Specification

##### Input

```
    {}
```

##### Output

```perl
    { type => 'undef' }
```

### \_Directory

Internal: not part of the public interface.  The directory the server keeps this site's configuration in: what `new()` was
given, or `/usr/lib/vwf`.  [Web::VWF::Config](https://metacpan.org/pod/Web%3A%3AVWF%3A%3AConfig) adds the site's own name to it.

#### Api Specification

##### Input

```
    {}
```

##### Output

```perl
    { type => 'string' }
```

### \_Config

Internal: not part of the public interface.  The site's configuration, read once and kept: a site that has no `conf/` of its
own beside `cgi-bin/` is configured from the server's directory for it, and
[Web::VWF::Config](https://metacpan.org/pod/Web%3A%3AVWF%3A%3AConfig) describes the rest of the search.

#### Api Specification

##### Input

```
    {}
```

##### Output

```perl
    { type => 'object', isa => 'Web::VWF::Config' }
```

### Sig\_Handler

Internal: not part of the public interface, though it is a plain function, not a
method.  The handler for TERM and USR1.  It sets the flag that makes `run` leave its loop and, if no
request is being handled, flushes the response cache and statistics, detaches
[Log::WarnDie](https://metacpan.org/pod/Log%3A%3AWarnDie) and exits at once.  Mid-request it only sets the flag, so the
response in flight is sent whole.

#### Api Specification

##### Input

```perl
    { signal => { type => 'string' } }
```

##### Output

```perl
    { type => 'undef' }
```

### Choose

Internal: a plain function.  Sends the `300 Multiple Choices` response: plain
text that lists `?page=` and the description of each page the site serves, with
a `Last-Modified` header from the page script.  The list is left out for
`HEAD`.  It does nothing when the status of the request is already not 200,
as for an unknown page, where the status line is sent elsewhere.

#### Api Specification

##### Input

```
    {}
```

##### Output

```perl
    { type => 'undef' }
```

### Send\_Error

Internal: a plain function.  Sends a short plain-text error response, and
records the status in the request's [CGI::Info](https://metacpan.org/pod/CGI%3A%3AInfo).  Takes a hash or a hashref:

- `status`

    The HTTP status code.  Required.

- `body`

    The text to send.  It is not sent for `HEAD`.

- `headers`

    Extra header lines, each ending in a newline, such as `Retry-After`.

- `buffered`

    True once [FCGI::Buffer](https://metacpan.org/pod/FCGI%3A%3ABuffer) is capturing the output: it sends the `Status` line
    itself, so this does not.

#### Api Specification

##### Input

```perl
    {
            status => { type => 'integer', min => 100, max => 599 },
            body => { type => 'string', optional => 1 },
            headers => { type => 'string', optional => 1 },
            buffered => { type => 'boolean', optional => 1 },
    }
```

##### Output

```perl
    { type => 'integer', value => 1 }
```

### Duration\_Seconds

Internal: a plain function.  Converts a duration such as `60s`, `2 minutes` or
`90` to whole seconds, with [Time::Duration::Parse](https://metacpan.org/pod/Time%3A%3ADuration%3A%3AParse).  A string of digits is
already seconds.  One that cannot be parsed is logged as a warning, and
counts as 60 seconds.

#### Api Specification

##### Input

```perl
    { duration => { type => 'string' } }
```

##### Output

```perl
    { type => 'integer', min => 0 }
```

### Blacklisted

Internal: a plain function.  Takes the request's [CGI::Info](https://metacpan.org/pod/CGI%3A%3AInfo) and says whether
the request looks like an SQL injection attempt.  The address that sent one is
remembered by the worker, so its later requests are refused without scanning
them again.  It is only a filter for noise, see [Web::VWF::Blacklist](https://metacpan.org/pod/Web%3A%3AVWF%3A%3ABlacklist).  A
request of more than 8192 characters is not scanned.  There is nothing to check
without `REMOTE_ADDR`.  When it returns true the status of the request has been
set to 403.

#### Api Specification

##### Input

```perl
    { info => { type => 'object', isa => 'CGI::Info' } }
```

##### Output

```perl
    { type => 'boolean' }
```

### Filter

Internal: a plain function, registered with [Log::WarnDie](https://metacpan.org/pod/Log%3A%3AWarnDie).  Called with a
warning, returns false for the few harmless ones that are not worth logging
(two missing optional modules under [Net::OAuth](https://metacpan.org/pod/Net%3A%3AOAuth) and [NetAddr::IP](https://metacpan.org/pod/NetAddr%3A%3AIP), and an
`S_IFFIFO` message from Fcntl) and true for all the rest.

#### Api Specification

##### Input

```perl
    { message => { type => 'string' } }
```

##### Output

```perl
    { type => 'boolean' }
```

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Licence and Copyright

Copyright 2010-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
