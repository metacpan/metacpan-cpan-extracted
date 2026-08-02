INSTALL

# Installation via CPAN #

Install the base WebDyne module, and its core prerequisites, with:

```bash
perl -MCPAN -e 'install WebDyne'
```

or, on systems using `cpanm`:

```bash
cpanm WebDyne
```

Test successful installation:

```bash
wdrender --test

<!DOCTYPE html>
<html lang="en">
<head>
<title>Untitled Document</title>
<meta charset="UTF-8">
<meta content="width=device-width, initial-scale=1.0" name="viewport">
</head>
<body>
<h1>WebDyne Test File</h1>
<hr>
<p>The local server time is: Fri Jul 31 10:38:07 2026</p>
</body>
</html>
```

This installs the core modules and command-line tools. Depending on the runtime you want to use, you may also need PSGI/Plack, PAGI, or Apache/mod_perl components.

Full documentation is available in the `doc` directory and at [https://webdyne.org](https://webdyne.org).

# PSGI / Plack #

To use WebDyne through PSGI, install Plack and any PSGI server you want to run:

```bash
# Core Plack/PSGI modules
cpanm Task::WebDyne::Plack
# Optional Starman server
cpanm Starman
```

You can then validate the wrapper with:

```bash
webdyne.psgi --test
```

or serve a document root:

```bash
webdyne.psgi /path/to/site-root
```

# PAGI #

To use WebDyne through PAGI, install the PAGI runtime stack required by your chosen PAGI server.

```bash
# Core PAGI modules
cpanm Task::WebDyne::PAGI
```
You can then validate the wrapper with:

```bash
webdyne.pagi --test
```

or serve a document root:

```bash
webdyne.pagi /path/to/site-root
```

The PAGI runtime supports normal HTTP requests as well as server-sent event, WebSocket, and lifespan flows.

# Apache / mod_perl #

For permanent Apache/mod_perl configuration, use the Apache installer:

```bash
wdapacheinit
```

It uses reasonable defaults to locate and update Apache configuration and WebDyne cache directories. Run `wdapacheinit --help` to review available options before changing a system Apache installation.

For temporary local development and troubleshooting under Apache/mod_perl, use:

```bash
webdyne.apache --test
```

or serve a local document root:

```bash
webdyne.apache /path/to/site-root
```

# Optional modules #

WebDyne supports colourization and tidying of command line output for development/debugging purposes. Install the HTML5::Tidy and Syntax::Highlight::Engine::Kate modules if desired

```bash
# Install system libraries for libtidy via appropriate package manager
# dnf install libtidy

# Then CPAN modules. Force of HTML::Tidy may be required due to failing non-critical test
cpanm --force HTML::Tidy5
# Syntax highlighter 
cpanm Syntax::Highlight::Engine::Kate 
```

## Notes on Mac installation of Apache ##

If installing on a Mac, Apache can be installed by Homebrew, but mod_perl is not available. Use the following guide to install all pre-requisites:

```bash
brew install apache-httpd pkg-config
export MP_APXS="$(brew --prefix httpd)/bin/apxs"
export PATH="$(brew --prefix perl)/bin:$PATH"
cpanm --notest --configure-args="MP_APXS=$MP_APXS MP_CCOPTS=-fgnu89-inline" mod_perl2
--> Working on mod_perl2
Fetching http://www.cpan.org/authors/id/S/SH/SHAY/mod_perl-2.0.13.tar.gz ... OK
Configuring mod_perl-2.0.13 ... OK
Building mod_perl-2.0.13 ... OK
Successfully installed mod_perl-2.0.13
1 distribution installed
```

Installation of optional supporting modules for colorization of command line output etc. can be undertaken with:

```bash
brew install tidy-html5
# Force necessary during to non-critical test failing
cpanm --force HTML::Tidy5
# Syntax highlighter 
cpanm Syntax::Highlight::Engine::Kate 
```

# Installation via Manual Build #

After unpacking the source tree, build and install with:

```bash
cpanm --installdeps --reinstall .
```

If CPANM is not available you can install manually:

```bash
perl Makefile.PL
make
make test
make install
```

Modules required by the selected build and runtime path should be reported when you run `perl Makefile.PL`. and will have to be installed manually. As with a CPAN install, you still need to configure or start the appropriate runtime wrapper before WebDyne pages will be served.
