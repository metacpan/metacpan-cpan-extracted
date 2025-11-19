# Introduction

WebDyne is a Perl based dynamic HTML engine. It works with web servers
(or from the command line) to render HTML documents with embedded Perl
code.

Once WebDyne is installed and initialised any file with a `.psp`
extension is treated as a WebDyne source file. It is parsed for WebDyne
pseudo-tags (such as `<perl>` and `<block>`) which are interpreted and
executed on the server. The resulting output is then sent to the
browser.

WebDyne works with common web server persistent Perl interpreters - such
as Apache `mod_perl` and `PSGI` - to provide fast dynamic content. It
works with PSGI servers such as Plack and Starman, and can be
implemented as a Docker container to run HTML with embedded Perl code.

Pages are parsed once, then stored in a partially compiled format -
speeding up subsequent processing by avoiding the need to re-parse a
page each time it is loaded.

Alternate syntaxes are available to enable WebDyne code to be used with
editors that do not recognise custom HTML tags, and the syntax supports
the use of PHP type processing instruction tags (`<?..?>`) or `<div>`
tags (via data attributes such as `<div data-webdyne-perl>`) to define
WebDyne blocks.

Perl code can be co-mingled in the HTML code for "quick and dirty" pages
or completed isolated into separate files or modules for separation of
presentation and logic layers. You can see examples in a dedicated
section - but here are a few very simple examples as an overview.

Simple HTML file with Perl code embedded using WebDyne :

``` html
<html>
<head><title>Server Time</title></head>
<body>
The local server time is:
<perl> localtime() </perl>
</body>
</html>
```

[Run](https://demo.webdyne.org/introduction1.psp)

This can be abbreviated with some WebDyne shortcut tags such as
`<start_html>`. This does exactly the same thing and still renders
compliant HTML to the browser:

``` html
<start_html title="Server Time">
The local server time is: <? localtime() ?>
```

[Run](https://demo.webdyne.org/introduction2.psp)

Don't like the co-mingling code and HTML but still want things in one
file ?

``` html
<start_html title="Server Time">
The local server time is <? print_time() ?>
</html>
__PERL__
sub print_time {
    print(scalar localtime);
}
    
```

[Run](https://demo.webdyne.org/introduction3.psp)

Want further code and HTML separation ? You can import methods from any
external Perl module. Example from a core module below, but could be any
installed CPAN module or your own code:

``` html
<start_html title="Server Time">
Server Time::HiRes time:
<perl require="Time::HiRes" import="time">time()</perl>
```

[Run](https://demo.webdyne.org/introduction4.psp)

Same concepts implemented in slightly different ways:

``` html
<start_html title="Server Time">
The local server epoch time (hires) is: <? time() ?>
<end_html>
__PERL__
use Time::HiRes qw(time);
1;
```

[Run](https://demo.webdyne.org/introduction5.psp)

``` html
<start_html title="Server Time">
<perl require="Time::HiRes" import="time"/>
The local server time (hires) is: <? time() ?>
```

[Run](https://demo.webdyne.org/introduction6.psp)

Using an editor that doesn't like custom tags ? Use of the <div\> tag
with a `data-*` attribute is legal HTML syntax and can be used to embed
Perl:

``` html
<start_html title="Server Time">
The local server time is: <div data-webdyne-perl> localtime() </div>
```

[Run](https://demo.webdyne.org/introduction7.psp)

Don't like <div\> style syntax ? Put the code in a <script\> block -
it will be interpreted on the server, not the client:

``` html
<start_html title="Server Time">
Server local time is: 
<script type="application/perl">
    print scalar localtime()
</script>
```

[Run](https://demo.webdyne.org/introduction7.psp)

Template blocks and variable replacement is supported also:

``` html
<start_html>

<!-- Call perl code to render server time -->
<perl handler="server_time">

<!-- Template Block it will be rendered into -->
<block name="server_time">
<p>
Loop ${i}: The local server time is: ${time}
</block>

</perl>

__PERL__

sub server_time {

    #  Get self ref
    #
    my $self=shift();
    
    #  Get local time
    #
    my $time=scalar localtime();

    #  Loop 4 times
    #
    foreach my $i (1..4) {
    
        #  Render template block
        #
        $self->render_block('server_time', i=>$i, time=>$time)
        
    }

    #  Return section
    #
    return $self->render()

}
```

[Run](https://demo.webdyne.org/introduction9.psp)

# Installation and Quickstart

## Prerequisites

WebDyne will install and run on any modern Linux system that has a
recent version of Perl installed and is capable of installing Perl
module via CPAN. Installation via Docker is also supported.

When installing WebDyne there are two components which are required
before you can begin serving .psp files:

-   The core WebDyne Perl modules

-   A web server configured to use WebDyne

WebDyne will work with Apache mod_perl or PSGI compatible web servers
(such as Plack, Starman etc.).

Docker containers with pre-built versions of WebDyne are also available.

## Installing via CPAN or CPANMinus

Install from the Perl CPAN library using `cpan` or `cpanm` utilities.
Installs dependencies if required (also from CPAN).

Destination of the installed files is dependent on the local CPAN
configuration, however in most cases it will be to the Perl site library
location. WebDyne supports installation to an alternate location using
the PREFIX option in CPAN. Binaries are usually installed to `/usr/bin`
or `/usr/local/bin` by CPAN, but may vary by distribution/local
configuration.

Assuming your CPAN environment is setup correctly you can run the
command:

`perl -MCPAN -e "install WebDyne"`

Or (with `cpanminus` if installed)

`cpanm WebDyne`

This will install the base WebDyne modules, which includes the Apache
config utility and PSGI version. Note that Apache or PSGI servers and
dependencies such as Plack or Starman are **not** installed by default
and need to be installed separately - see the relevant section.

Once installed you will need to configure your web server to use WebDyne
to serve files with the `.psp` extension if using Apache - see section
below.

## Quickstart

If using PSGI you can start a quick web server with:

``` bash
#  Render a file to STDOUT to see the HTML
#
$ wdrender app.psp

#  Install Plack
#
$ cpanm Plack

#  Check all working
#
$ webdyne.psgi --test

#  Start serving only a single PSP file
#
$ webdyne.psgi app.psp

# Start serving any file in the current directory, using app.psp as the default
#
$ webdyne.psgi .

# Start but listen on non-default port, only on localhost
#
$ webdyne.psgi --port=5001 --host=127.0.0.1
```

Connect your browser to the host and you should see the WebDyne output

## Apache mod_perl

If using Apache with mod_perl you can initialise WebDyne using the
`wdapacheinit` command. This will attempt to auto-discover where the
Apache binary and configuration files are, then add a suitable
`webdyne.conf` file to the apache configuration. Apache will need to be
restarted for the new configuration file to take effect. This will need
to be done as a the root user.

``` bash
[root@localhost ~]# wdapacheinit 

[install] - Installation source directory '/usr'.
[install] - Creating cache directory '/var/cache/webdyne'.

[install] - Writing Apache config file '/etc/httpd/conf.d/webdyne.conf'.
[install] - Writing Webdyne config file '/etc/httpd/conf.d/webdyne_conf.pl'.
[install] - Apache uses conf.d directory - not changing httpd.conf file.
[install] - Granting Apache (apache.apache) ownership of cache directory '/var/cache/webdyne'.
[install] - Install completed.

[root@localhost ~]# systemctl restart httpd
```

By default WebDyne will create a cache directory in `/var/cache/webdyne`
on Linux systems when a default CPAN install is done (no PREFIX
specified). If a PREFIX is specified the cache directory will be created
as `$PREFIX/cache`. Use the `wdapacheinit` `--cache` command-line option
to specify an alternate location.

Once `wdapacheinit` has been run the Apache server should be reloaded or
restarted. Use a method appropriate for your Linux distribution.

    [root@localhost ~]# systemctl httpd restart
    Stopping httpd:                                            [  OK  ]
    Starting httpd:                                            [  OK  ]

### Manual configuration of Apache

If the `wdapacheinit` command does not work as expected on your system
then the Apache config files can be modified manually.

Include the following section in the Apache httpd.conf file (or create a
webdyne.conf file if you distribution supports conf.d style
configuration files). These following config files are written with
Apache 2.4 syntax - adjust path and syntax as required:

    #  Need mod_perl, load up if not already done
    #
    <IfModule !mod_perl.c>
    LoadModule perl_module "/etc/httpd/modules/mod_perl.so"
    </IfModule>

    #  Uncomment and update if using a local::lib location for Perl modules
    #
    #PerlSwitches -I/opt/perl -I/opt/otherperl

    #  Preload the WebDyne and WebDyne::Compile module
    #
    PerlModule    WebDyne WebDyne::Compile

    #  Associate psp files with WebDyne
    #
    AddHandler    modperl    .psp
    PerlHandler   WebDyne

    #  Set a directory for storage of cache files. Make sure this exists already is writable by the 
    #  Apache daemon process.
    #
    PerlSetVar    WEBDYNE_CACHE_DN    '/opt/webdyne/cache'

    #  Allow Apache to access the cache directory if it needs to serve pre-compiled pages from there.
    #
    <Directory "/opt/webdyne/cache">
    Require all granted
    </Directory>

    # Put variables in a separate file - best
    #
    PerlRequire conf.d/webdyne_constant.pl

    #  Or use <Perl> sections - but warning, certbot doesn't like this syntax in http conf files
    #
    <Perl>

    #  Error display/extended display on/off. Set to 1 to enable, 0 to disable
    #
    $WebDyne::WEBDYNE_ERROR_SHOW=1;
    $WebDyne::WEBDYNE_ERROR_SHOW_EXTENDED=1;
    </Perl>

!!! important

    Substitute directory paths in the above example for the
    relevant/correct/appropriate ones on your system.

Create the cache directory and assign ownership and permission
appropriate for your distribution (group name will vary by
distribution - locate the correct one for your distribution)

    [root@localhost ~]# mkdir /opt/webdyne/cache
    [root@localhost ~]# chgrp apache /opt/webdyne/cache
    [root@localhost ~]# chmod 770 /opt/webdyne/cache

Restart Apache and check for any errors.

## PSGI

Ensure that Plack is installed on your system via CPAN:

    # Via CPAN
    perl -MCPAN -e 'install Plack'

    # Modern systems
    #
    cpan Plack

    # Or better via CPANM
    cpanm Plack

You can start a basic WebDyne server by running the webdyne.psgi command
with the --test parameter

    webdyne.psgi --test

This will start a PSGI web server on your machine listening to port 5000
(or port 5001 on a Mac). Open a connection to http://127.0.0.1:5000/ or
the IP address of your server in your web browser to view the test page
and validate the WebDyne is working correctly:

Once verified as working correctly you can serve WebDyne content from a
particular directory - or from a single file - using the syntax:

    #  To serve up all files in a directory:
    #
    $ webdyne.psgi <directory>

    #  E.g serve files in /var/www/html. By default WebDyne will serve app.psp if no filename
    #  is specified
    #
    $ webdyne.psgi /var/www/html

    #  Allow static files such as css, jpg files etc. to be served also
    #
    $ webdyne.psgi --static /var/www/html/app.psp

    #  Or just a single app.psp file. Only this file will be served regardless of URL
    #
    $ webdyne.psgi /var/www/html/time.psp

The above starts a single-threaded web server using Plack. To start the
more performant Starman server (assuming installed):

    #  Start Starman instance. Substitute port + document root and location of webdyne.psgi
    #  as appropriate for your system.
    #
    $ DOCUMENT_ROOT=/var/www/html starman --port 5001 /usr/local/bin/webdyne.psgi

!!! note

    Starman does not support options such as --test and --static. If you
    want to server static files from starman you should do so using best
    practice via a traditional web server front end.

Numerous options can be set from the command line via environment
variables, including Webdyne configuration. See relevant section for all
WebDyne configuration options but assuming in a local file
webdyne.conf.pl:

    #  Start instance webdyne.psgi using local config file
    #
    $ WEBDYNE_CONF=./webdyne.conf.pl webdyne.psgi --port=5012 .

## Docker

Docker containers are available from the Github Container Registry.
Install the default Docker container (based on Debian) via:

    #  Default debian version
    #
    $ docker pull ghcr.io/aspeer/webdyne:latest

    #  Or Alpine/Fedora/Perl versions
    #
    # docker pull ghcr.io/aspeer/webdyne-alpine:latest
    # docker pull ghcr.io/aspeer/webdyne-fedora:latest
    # docker pull ghcr.io/aspeer/webdyne-perl:latest

Start the docker container with the command:

    $ docker run -e PORT=5002 -p 5002:5002 --name=webdyne webdyne

This will start WebDyne running on port 5002 on the host. Connecting to
that location should show the server *localtime* test page

To mount a local page and serve it through the docker container use the
command:

    docker run --mount <local_dir>:/app:ro -e PORT=5011 -e DOCUMENT_ROOT=/app -p 5011:5011 --name=webdyne webdyne

This will tell docker to mount the local directory into the docker
container. If there is a default file named app.psp in the location it
will be displayed. if there is a `cpanfile` in the mount directory any
modules will be installed into the docker container automatically.

### Deploying WebDyne apps with Docker

The WebDyne container can be used as the basis for new docker images
containing your application files. Consider the following directory
structure (available from Github as
[aspeer/psp-WebDyne-Fortune](https://github.com/aspeer/psp-WebDyne-Fortune):

    psp-WebDyne-Fortune/
    ├── app.pm
    ├── app.psp
    ├── cpanfile
    ├── Dockerfile
    └── webdyne.conf.pl

Where:

app.psp

:   The main and default psp file

app.pm

:   Perl code used in the psp file

cpanfile

:   A list of Perl modules to be installed in the docker container by
    cpanm

Dockerfile

:   The docker build file

webdyne.conf.pl

:   Any variables to be set for the WebDyne environment

Constitute all the files needed to stand up a WebDyne based application
in a Docker container. The contents of the Dockerfile are minimal:

    FROM webdyne:latest
    WORKDIR /app
    # Debian packages needed for this app
    RUN apt-get update && apt-get -y install fortunes
    COPY app.* .
    COPY cpanfile .
    COPY webdyne.conf.pl /etc

Build the Docker container:

    docker build  -t webdyne-app-fortune -f ./Dockerfile .

And run it:

    docker run -e PORT=5010 -p 5010:5010 --name=webdyne-app-fortune webdyne-app-fortune

Your application should now be available:

![](images/webdyne-app-fortune1.png)

# Basic Usage {#examples}

Assuming the installation has completed with no errors you are now ready
to start creating WebDyne pages and applications.

## Integrating Perl into HTML

Some code fragments to give a very high-level overview of how WebDyne
can be implemented. First the most basic usage example:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- Note the perl tags -->

Hello World <perl> localtime() </perl>

</body>
</html>
```

[Run](https://demo.webdyne.org/hello1.psp)

So far not too exciting - after all we are mixing code and content. Lets
try again:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- Empty perl tag this time, but with method name as attribute -->

Hello World <perl method="hello"/>

</body>
</html>

__PERL__

sub hello { return localtime }
```

[Run](https://demo.webdyne.org/hello2.psp)

Better - at least code and content are distinctly separated. Note that
whatever the Perl code returns at the end of the routine is what is
displayed. Although WebDyne will happily display returned strings or
scalars, it is more efficient to return a scalar reference, e.g.:

``` perl
#  Works
#
sub greeting { print "Hello World" }


#  Is the same as
#
sub greeting { return "Hello World" }
sub greeting { my $var="Hello World"; return $var }


# But best is
#
sub greeting { my $var="Hello World"; return \$var }


# This will cause an error
#
sub greeting { return undef }


# If you don't want to display anything return \undef,
#
sub greeting { return \undef }


# This will fail also
#
sub greeting { return 0 }


#  If you want "0" to be displayed ..
#
sub greeting { return \0 }
```

Perl code in WebDyne pages must always return a
non-undef/non-0/non-empty string value (i.e. it must return something
that evals as "true"). If the code returns a non-true value (e.g. 0,
undef, '') then WebDyne assumes an error has occurred in the routine. If
you actually want to run some Perl code, but not display anything, you
should return a reference to undef, (`\undef)`, e.g.:

    sub log { &dosomething; return \undef }

Up until now all the Perl code has been contained within the WebDyne
file. The following example shows an instance where the code is
contained in a separate Perl module, which should be available somewhere
in the `@INC` path.

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- Perl tag with call to external module method -->

Hello World <perl handler="Digest::MD5::md5_hex"/>

</body>
</html>
```

[Run](https://demo.webdyne.org/hello3.psp)

If not already resident the module (in this case "Digest::MD5") will be
loaded by WebDyne, so it must be available somewhere in the `@INC` path.

### Use of the <perl\> tag for in-line code.

The above examples show several variations of the <perl\> tag in use.
Perl code that is enclosed by <perl\>..</perl\> tags is called
*in-line* code:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>
<pre>

<!-- Perl tag containing perl code which generates output -->

<perl>

for (0..3) {
    print "Hello World\n"
}

#  Must return a positive value, but don't want anything
#  else displayed, so use \undef
#
return \undef;

</perl>


</pre>
</body>
</html>
```

[Run](https://demo.webdyne.org/inline1.psp)

This is the most straight-forward use of Perl within a HTML document,
but does not really make for easy reading - the Perl code and HTML are
intermingled. It may be OK for quick scripts etc, but a page will
quickly become hard to read if there is a lot of in-line Perl code
interspersed between the HTML.

in-line Perl can be useful if you want a "quick" computation, e.g.
insertion of the current year:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- Very quick and dirty block of perl code -->

Copyright (C) <perl>(localtime())[5]+1900</perl> Foobar Gherkin corp.

</body>
</html>
```

[Run](https://demo.webdyne.org/inline2.psp)

Which can be pretty handy, but looks a bit cumbersome - the tags
interfere with the flow of the text, making it harder to read. For this
reason in-line perl can also be flagged in a WebDyne page using the
shortcuts !{! .. !}, or by the use of processing instructions (**<? ..
?\>**) e.g.:

``` html
<html>
<head><title>Hello World</title></head>
<body>

<!-- Same code with alternative denotation -->

The time is: !{! localtime() !}

<p>

The time is:  <? localtime() ?>


</body>
</html>
```

[Run](https://demo.webdyne.org/inline3.psp)

The !{! .. !} denotation can also be used in tag attributes (processing
instructions, and <perl\> tags cannot):

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- Perl code can be used in tag attributes also -->

<font color="!{! (qw(red blue green))[rand 3] !}">

Hello World

</font>
</body>
</html>
```

[Run](https://demo.webdyne.org/inline4.psp)

### Use of the <perl\> tag for non-inline code.

Any code that is not co-mingled with the HTML of a document is
*non-inline* code. It can be segmented from the content HTML using the
\_\_PERL\_\_ delimiter, or by being kept in a completely different
package and referenced as an external Perl subroutine call. An example
of non-inline code:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- Empty perl tag this time, but with method name as attribute -->

Hello World <perl method="hello"/>

</body>
</html>

__PERL__

sub hello { return localtime }
```

[Run](https://demo.webdyne.org/hello2.psp)

Note that the <perl\> tag in the above example is explicitly closed and
does not contain any content. However non-inline code can enclose HTML
or text within the tags:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- The perl method will be called, but "Hello World" will not be displayed ! -->

<perl method="hello">
Hello World 
</perl>

</body>
</html>

__PERL__

sub hello { return localtime() }
```

[Run](https://demo.webdyne.org/noninline1.psp)

But this is not very interesting so far - the "Hello World" text is not
displayed when the example is run !

In order for text or HTML within a non-inline perl block to be
displayed, it must be "rendered" into the output stream by the WebDyne
engine. This is done by calling the render() method. Let's try that
again:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- The perl method will be called, and this time the "Hello World" will be displayed-->

<perl method="hello">
Hello World 
</perl>

</body>
</html>

__PERL__

sub hello {
    
    my $self=shift();
    $self->render();

}
```

[Run](https://demo.webdyne.org/noninline2.psp)

And again, this time showing how to render the text block multiple
times. Note that an array reference is returned by the Perl routine -
this is fine, and is interpreted as an array of HTML text, which is
concatenated and send to the browser.

``` html
<html>
<head><title>Hello World</title></head>
<body>

<!-- The "Hello World" text will be rendered multiple times -->

<perl method="hello">
<p>
Hello World 
</perl>

</body>
</html>

__PERL__

sub hello {
    
    my $self=shift();
    my @html;
    for (0..3) { push @html, $self->render() };
    return \@html;
}
```

[Run](https://demo.webdyne.org/noninline3.psp)

Same output using the \$self-\>print() method:

``` html
<html>
<head><title>Hello World</title></head>
<body>

<!-- The "Hello World" text will be rendered multiple times -->

<perl method="hello">
<p>
Hello World 
</perl>

</body>
</html>

__PERL__

sub hello {
    
    #  Note use of $self->print()
    #
    my $self=shift();
    for (0..3) { $self->print($self->render()) };
    return \undef;
}
```

[Run](https://demo.webdyne.org/noninline3.psp)

### Alternate output methods from Perl handlers

When calling a perl handler from a .psp file at some stage you will want
your code to deliver output to the browser. Various examples have been
given throughout this document, here is a summary of various output
options:

``` html
<start_html>
<pre>
<perl handler="handler1" />
<perl handler="handler2" />
<perl handler="handler3" />
<perl handler="handler4" />
<perl handler="handler5" />
<perl handler="handler6" chomp />
<perl handler="handler7" />
<perl handler="handler8" />
__PERL__

#  Different ways of sending output to the browser
#
sub handler1 {

    #  Simplest - just return a scalar variable
    #
    my $text='Hello World 1';
    return $text;
    
}

sub handler2 {

    #  Scalar ref better because if var is empty (undef) won't trigger and error
    #
    my $text='Hello World 2';
    return \$text;
    
}

sub handler3 {

    #  Returning an array ref is OK
    #
    my @text=('Hello', 'World', 3);
    
    
    #  This won't work
    #
    #return @text

    
    #  Returning an array ref is OK - note it won't auto insert spaces though !
    #
    return \@text
    
}

sub handler4 {

    #  Print something also using the print statement
    #
    my $text='Hello World 4';
    print $text;
    print "\n";
    
    #  Printing a scalar ref is OK
    #
    print \$text;
    
}


sub handler5 {

    #  Print arrays
    #
    my @text=('Hello ', 'World ', 5);
    print @text;
    
    
    #  Print new line manually, or turn on autonewline -
    #  see next example;
    #
    print "\n";
    
    #  Array refs are OK
    #
    print \@text;
    
    
    #  Printing hash ref's won't work ! This will fail
    #
    # print { a=>1, b=>2 }
    return \undef;
    
}

sub handler6 {

    #  You can print using a webdyne method handler
    #
    my $self=shift();
    
    
    #  Text we want to print
    #
    my $text="Hello World 6\n";
    my @text=('Hello ', 'World ', 6, "\n");
    
    
    #  These all work
    #
    $self->print($text);
    $self->print(\$text);
    $self->print(@text);
    $self->print(\@text);
    return \undef;
    
}

sub handler7 {

    #  You can print using a webdyne method handler
    #
    my $self=shift();
    
    
    #  Text we want to print
    #
    my $text="Hello World 7";
    my @text=('Hello ', 'World ', 7);
    
    
    #  Turn on autonew line to print "\n" at end of every call
    #
    $self->autonewline(1);
    
    
    #  These work
    #
    $self->print($text);
    $self->print(\$text);
    
    
    #  These put a CR between every element in the array
    $self->print(@text);
    $self->print(\@text);
    
    
    #  Turn off autonewline and return
    #
    $self->autonewline(0);
    return \undef;
    
}

sub handler8 {

    #  The say() method is supported also
    #
    use feature 'say';
    my $self=shift();
    my $text='Hello World 8';
    
    
    #  These will print, but won't send newline - say() won't send \n to TIEHANDLE
    #
    say($text);
    say($text);
    $self->print("\n");
    
    
    #  Use this instead
    #
    $self->say($text, $text);
}
```

[Run](https://demo.webdyne.org/output1.psp)

### Passing parameters to subroutines

The behaviour of a called \_\_PERL\_\_ subroutine can be modified by
passing parameters which it can act on:

``` html
<html>
<head><title>Hello World</title></head>
<body>

<!-- The "Hello World" text will be rendered with the param name -->

<perl method="hello" param="Alice"/>
<p>
<perl method="hello" param="Bob"/>
<p>

<!-- We can pass an array or hashref also - see variables section for more info on this syntax -->

<perl method="hello_again" param="%{ firstname=>'Alice', lastname=>'Smith' }"/>

</body>
</html>

__PERL__

sub hello {
    
    my ($self, $param)=@_;
    return \"Hello world $param"
}

sub hello_again {

    my ($self, $param_hr)=@_;
    my $firstname=$param_hr->{'firstname'};
    my $lastname =$param_hr->{'lastname'};
    return \"Hello world $firstname $lastname";

}
```

[Run](https://demo.webdyne.org/noninline7.psp)

### Parameter inheritance

In-line code can inherit parameters passed from a perl handler/method.
In-line code gets two parameters supplied - the first (`$_[0)`) is the
self reference (e.g. `$self`), the second (`$_[1]`) is any inherited
parameters as a hash reference. This can be useful for quick "in-line"
formatting, e.g:

``` html
<start_html>
<perl method="inherit">
<pre>
Time - Unix epoch format: ${time}
Time - local time format: <? strftime('%X', localtime($_[1]->{'time'})) ?>
Date - ISO format: <? strftime('%Y-%m-%d', localtime($_[1]->{'time'})) ?>
Date - US format: <? strftime('%m/%d/%Y', localtime($_[1]->{'time'})) ?>
Date - UK format: <? strftime('%d/%m/%Y', localtime($_[1]->{'time'})) ?>
</pre>
</perl>
__PERL__
use POSIX qw(strftime);
sub inherit {
    shift()->render( time=>time() )
}
```

[Run](https://demo.webdyne.org/inherit1.psp)

### Notes about \_\_PERL\_\_ sections

Code in \_\_PERL\_\_ sections has some particular properties.
\_\_PERL\_\_ code is only executed once. Subroutines defined in a
\_\_PERL\_\_ section can be called as many times as you want, but the
code outside of subroutines is only executed the first time a page is
loaded. No matter how many times it is run, in the following code `$i`
will always be 1:

``` html
<html>
<head><title>Hello World</title></head>
<body>

<perl method="hello"/>
<p>
<perl method="hello"/>

</body>
</html>

__PERL__

my $i=0;
$i++;

my $x=0;

sub hello {
    
    #  Note x may not increment as you expect because you will probably
    #  get a different Apache process each time you load this page
    #
    return sprintf("value of i: $i, value of x in PID $$: %s", $x++)
}
```

[Run](https://demo.webdyne.org/noninline4.psp)

Lexical variables are not accessible outside of the \_\_PERL\_\_ section
due to the way perl's eval() function works. The following example will
fail:

``` html
<html>
<head><title>Hello World</title></head>
<body>

The value of $i is !{! \$i !}

</body>
</html>

__PERL__

my $i=5;
```

[Run](https://demo.webdyne.org/noninline5.psp)

Package defined vars declared in a \_\_PERL\_\_ section do work, with
caveats:

``` html
<html>
<head><title>Hello World</title></head>
<body>

<!-- Does not work -->
The value of $i is !{! $::i !}
<p>

<!-- Ugly hack, does work though -->
The value of $i is !{! ${__PACKAGE__.::i} !}
<p>

<!-- Probably best to just do this though -->
The value of $i is !{! &get_i() !}
<p>

<!-- Or this - see variable substitution section  -->
<perl method="render_i">
The value of $i is ${i}
</perl>

</body>
</html>

__PERL__

our $i=5;

sub get_i { \$i }

sub render_i { shift()->render(i=>$i) }
```

[Run](https://demo.webdyne.org/noninline6.psp)

See the Variables/Substitution section for clean ways to insert variable
contents into the page.

## Variables

WebDyne starts to get more useful when variables are used to modify the
content of a rendered text block. A simple example:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- The var ${time} will be substituted for the correspondingly named render parameter -->

<perl method="hello">
Hello World ${time}
</perl>

</body>
</html>

__PERL__

sub hello { 
    my $self=shift();
    my $time=localtime();
    $self->render( time=>$time );
}
```

[Run](https://demo.webdyne.org/var1.psp)

Note the passing of the `time` value as a parameter to be substituted
when the text is rendered.

Combine this with multiple call to the render() routine to display
dynamic data:

``` html
<html>
<head><title>Hello World</title></head>
<body>

<!-- Multiple variables can be supplied at once as render parameters -->

<perl method="hello0">
<p>
Hello World ${time}, loop iteration ${i}.
</perl>

<br>
<br>

<perl method="hello1">
<p>
Hello World ${time}, loop iteration ${i}.
</perl>

</body>
</html>

__PERL__

sub hello0 {
    
    my $self=shift();
    my @html;
    my $time=localtime();
    for (my $i=0; $i<3; $i++) { 
        push @html, $self->render( time=>$time, i=>$i) 
    };
    return \@html;
}

sub hello1 {
    
    #  Alternate syntax using print
    #
    my $self=shift();
    my $time=localtime();
    for (my $i=0; $i<3; $i++) { 
        print $self->render( time=>$time, i=>$i)
    };
    return \undef
}
```

[Run](https://demo.webdyne.org/var2.psp)

Variables can also be used to modify tag attributes:

``` html
<html>
<head><title>Hello World</title></head>
<body>

<!-- Render paramaters also work in tag attributes -->

<perl method="hello">
<p>
<font color="${color}">
Hello World
</font>
</perl>

</body>
</html>

__PERL__

sub hello {

    my $self=shift();
    my @html;
    for (0..3) {
        my $color=(qw(red green yellow blue orange))[rand 5];
        push @html, $self->render( color=>$color );
    }
    \@html;

}
```

[Run](https://demo.webdyne.org/var3.psp)

Other variable types are available also, including:

-   `@{var,var,..}` for arrays, e.g. `@{'foo', 'bar'}`

-   `%{key=>value, key=>value, ..}` for hashes e.g.`%{ a=>1, b=>2 }`

-   `+{varname}` for CGI form parameters, e.g. `+{firstname}`

-   `*{varname}`for environment variables, e.g. `*{HTTP_USER_AGENT}`

-   `^{requestmethod}` for Apache request (`$r=Apache->request`) object
    methods, e.g. `^{protocol}`. Only available for in Apache/mod_perl,
    and only useful for request methods that return a scalar value.

The following template uses techniques and tags discussed later, but
should provide an example of potential variable usage:

``` html
<html>
<head>
<title>Variables</title>
</head>
<body>

<!-- Environment variables -->

<p>
<!-- Short Way -->
Mod Perl Version: *{MOD_PERL}
<br>
<!-- Same as Perl code -->
Mod Perl Version: 
<perl> \$ENV{'MOD_PERL'} </perl>


<!-- Apache request record methods. Only methods that return a scalar result are usable -->

<p>
<!-- Short Way -->
Request Protocol: ^{protocol}
<br>
<!-- Same as Perl code -->
Request Protocol: 
<perl> my $self=shift(); my $r=$self->r(); \$r->protocol() </perl>


<!-- CGI params -->

<form>
Your Name:
<p><textfield name="name" default="Test" size="12">
<p><submit name="Submit">
</form>
<p>
<!-- Short Way -->
You Entered: +{name}
<br>
<!-- Same as Perl code -->
You Entered: 
<perl> my $self=shift(); my $cgi_or=$self->CGI(); \$cgi_or->param('name') </perl>
<br>
<!-- CGI vars are also loaded into the %_ global var, so the above is the same as -->
You Entered: 
<perl> $_{'name'} </perl>


<!-- Arrays -->

<form>
<p>
Favourite colour 1:
<p><popup_menu name="popup_menu" values="@{qw(red green blue)}">


<!-- Hashes -->

<p>
Favourite colour 2:
<p><popup_menu name="popup_menu" 
    values="%{red=>Red, green=>Green, blue=>Blue}">

</form>

</body>
</html>
```

[Run](https://demo.webdyne.org/var4.psp)

## Shortcut Tags

Previous versions of WebDyne used Lincoln Stein's CGI.pm module to
render tags, and supported CGI.pm shortcut tags such as <start_html\>,
<popup_menu\> etc. Modern versions of WebDyne do not use CGI.pm in any
modules, having ported tag generation to HTML::Tiny. Support for
shortcut tags is preserved though - they provide a quick and easy way to
generate simple web pages.

### Quick pages using shortcut <start_html\>, <end_html\> tags

For rapid development you can take advantage of the <start_html\> and
<end_html\> tags. The following page generates compliant HTML (view the
page source after loading it to see for yourself):

``` html
<start_html title="Quick Page">
The time is: !{! localtime() !}
<end_html>
```

[Run](https://demo.webdyne.org/cgi6.psp)

The <start_html\> tag generates all the <html\>, <head\>, <title\>
tags etc needed for a valid HTML page plus an opening body tag. Just
enter the body content, then optionally finish with <end_html\> to
generate the closing <body\> and <html\> tags (optional because the
page is automatically closed if these are omitted). See the tag
reference section but here is an example using several of the properties
available in the <start_html\> tag including loading multiple scripts
and stylesheets:

``` html
<start_html title="Hello World" 
    style="@{qw(https://cdn.jsdelivr.net/npm/aos@2.3.4/dist/aos.css https://fonts.googleapis.com/css2?family=Inter:wght@400;600&family=Playfair+Display:wght@700&display=swap)}"
    script="@{qw(https://cdn.jsdelivr.net/npm/aos@2.3.4/dist/aos.js https://cdn.jsdelivr.net/npm/typed.js@2.1.0/dist/typed.umd.js)}"
>
<p>
<h2 id="typed"></h2>
<div data-aos="fade-up">I animate on load and scroll !</div>

<script>
  AOS.init({
    duration: 1000,  // 1s animations
    once: true       // animate only once
  });
</script>

<script>
  new Typed('#typed', {
    strings: ["Lorem", "Ipsum", "!{! localtime !}"],
    typeSpeed: 50,
    backSpeed: 25,
    loop: true
  });
</script>
```

[Run](https://demo.webdyne.org/start_html1.psp)

!!! caution

    If make sure any attributes using the `@{..}` or `%{..}` convention are
    on one line - the parser will not interpret them correctly if spanning
    multiple lines.

If using the <start_html\> shortcut tag you can optionally insert
default stylesheets and/or <head\> sections from the Webdyne
configuration file. E.g if in your `webdyne.conf.pl` file you have the
following:

    $_={
        'WebDyne::Constant' => {

            #  Inserted as <meta> into <head> section
            #
            WEBDYNE_META => {
                #  These all rendered as <meta name="$key" content="$value">
                viewport => 'width=device-width, initial-scale=1.0',
                author => 'Bob Foobar',
                #  This one rendered as <meta http-equiv="X-UA-Compatible" content="IE=edge">
                'http-equiv=X-UA-Compatible' => 'IE=edge',
                'http-equiv=refresh' => '5; url=https://www.example.com'
            }

            #  This is inserted inside the <html> starting tag, works for <start_html> or straight <html>
            #
            WEBDYNE_HTML_PARAM => {
                lang => 'de'
            }

            #  This is inserted before the </head> closing tag, works for <start_html> or straight <html>
            #
            WEBDYNE_HEAD_INSERT => << 'END'
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.classless.min.css">
    <style>
    :root { --pico-font-size: 85% } 
    body { padding-top: 10px; padding-left: 10px;
    </style>
    END
        
        }
    }

Then any `.psp` file with a <start_html\> tag will have the following
content:

    <!DOCTYPE html><html lang="de">
    <head>
    <title>Untitled Document</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="author" content="Bob Foobar">
    <meta http-equiv="refresh" content="5; url=https://www.example.com">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.classless.min.css">
    <style>
        :root { --pico-font-size: 85% } 
    </style>
    </head>

### HTML Forms using <popup_menu\>,<checkbox_group\> and other tags

The CGI.pm module presented several shortcut tags for generating HTML
forms. These tags have been recreated in WebDyne and act in a similar
way.

The manual page for CGI.pm contains the following synopsis example:

    use CGI qw/:standard/;
       print header,
             start_html('A Simple Example'),
             h1('A Simple Example'),
             start_form,
             "What's your name? ",textfield('name'),p,
             "What's the combination?", p,
             checkbox_group(-name=>'words',
                            -values=>['eenie','meenie','minie','moe'],
                            -defaults=>['eenie','minie']), p,
             "What's your favorite color? ",
             popup_menu(-name=>'color',
                        -values=>['red','green','blue','chartreuse']),p,
             submit,
             end_form,
             hr;

        if (param()) {
            print "Your name is",em(param('name')),p,
                  "The keywords are: ",em(join(", ",param('words'))),p,

If the example was ported to a WebDyne compatible page it might look
something like this:

``` html
<!-- The same form from the CGI example -->

<start_html title="A simple example">
<h1>A Simple Example</h1>
<start_form>
<p>
What's your name ?
<p><textfield name="name">
<p>
What's the combination ? 
<p><checkbox_group 
    name="words" values="@{qw(eenie meenie minie moe)}" defaults="@{qw(eenie minie)}">
<p>
What's your favourite color ? 
<p><popup_menu name="color" values="@{qw(red green blue chartreuse)}">
<p><submit>
<end_form>
<hr>


<!-- This section only rendered when form submitted -->

<perl method="answers">
<p>
Your name is: <em>+{name}</em>
<p>
The keywords are: <em>${words}</em>
<p>
Your favorite color is: <em>+{color}</em>
</perl>

__PERL__

sub answers {

    my $self=shift();
    my $cgi_or=$self->CGI();
    if ($cgi_or->param()) {
        my $words=join(",", $cgi_or->param('words'));
        return $self->render( words=>$words )
    }
    else {
        return \undef;
    }

}
```

[Run](https://demo.webdyne.org/cgi1.psp)

!!! note

    When using the WebDyne form tags, state (previous form values) are
    preserved after the Submit button is presented. This makes building
    single page application simple as there is no need to implement logic to
    adjust options in a traditional HTML form to reflect the user's choice.

### More on HTML shortcut tags in forms

Tags such as <popup_menu\> output traditional HTML form tags such as
<select\><option\>...</select\>, but they have the advantage of
allowing Perl data types as attributes. Take the following example:

    <popup_menu value="%{red=>Red, green=>Green, blue=>Blue}"/>

it is arguably easier to read than:

    <select name="values" tabindex="1">
    <option value="green">Green</option>
    <option value="blue">Blue</option>
    <option value="red">Red</option>
    </select>

So there is some readability benefit, however the real advantage shows
when we consider the next example:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- Generate all country names for picklist -->

<form>

Your Country ?
<perl method="countries">
<popup_menu values="${countries_ar}" default="Australia">
</perl>

</form>
</body>
</html>

__PERL__

use Locale::Country;

sub countries {
    
    my $self=shift();
    my @countries = sort { $a cmp $b } all_country_names();
    $self->render( countries_ar=>\@countries );

}
```

[Run](https://demo.webdyne.org/cgi5.psp)

All values for the menu item were pre-populated from one WebDyne
variable - which saves a significant amount of time populating a
"countries" style drop-down box.

### Access to HTML form responses and query strings

Once a form is submitted you will want to act on responses. There are
several ways to do this - you can access a CGI::Simple object instance
in any WebDyne template by calling the CGI() method to obtain form
responses:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- Note use of CGI.pm derived textfield tag -->

<form>
Enter your name: 
<p><textfield name="name">
<p><submit>
</form>


<!-- And print out name if we have it -->

<perl method="hello">
Hello ${name}, pleased to meet you.
</perl>

</body>
</html>

__PERL__

sub hello { 
    my $self=shift();

    #  Get CGI instance
    #
    my $cgi_or=$self->CGI();

    #  Use CGI.pm param() method. Could also use other
    #  methods like keywords(), Vars() etc.
    #
    my $name=$cgi_or->param('name');

    $self->render( name=>$name);
}
```

[Run](https://demo.webdyne.org/cgi3.psp)

From there you can all any method supported by the CGI::Simple module -
see the CGI::Simple manual page (`man CGI::Simple`) or review on CPAN:
[CGI::Simple](https://metacpan.org/pod/CGI::Simple)

Since one of the most common code tasks is to access query parameters,
WebDyne stores them in the special `%_` global variable before any user
defined Perl methods are called. For example:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>
<form>
Enter your name:
<p><textfield name="name">
<p><submit>
</form>

<!-- Use the %_ global var, other options below -->
<p>
Hello <? uc($_{'name'} || 'Anonymous') ?>, pleased to meet you.


<!-- Quick and dirty, no perl code at all -->

<p>
Hello +{name}, pleased to meet you.


<!-- Traditional, using the CGI::Simple param() call in the hello1 sub -->

<p>
<perl method="hello1">
Hello ${name}, pleased to meet you.
</perl>


<!-- Quicker method using %_ global var in the hello2 sub -->

<p>
<perl method="hello2">
Hello ${name}, pleased to meet you.
</perl>


<!-- Quick and dirty using inline Perl. Note use of \ to prevent error if param empty -->

<p>
Hello !{! \$_{name} !}, pleased to meet you.

</body>
</html>


__PERL__

sub hello1 { 
    my $self=shift();
    my $cgi_or=$self->CGI();
    my $name=$cgi_or->param('name');
    $self->render( name=>$name);
}

sub hello2 { 

    my $self=shift();
    
    #  Quicker method of getting name param
    #
    my $name=$_{'name'};
    $self->render( name=>$name);
}
```

[Run](https://demo.webdyne.org/cgi4.psp)

# Advanced Usage

A lot of tasks can be achieved just using the basic features detailed
above. However there are more advanced features that can make life even
easier

## Blocks

Blocks are a powerful dynamic content generation tool. WebDyne can
render arbitrary blocks of text or HTML within a page, which makes
generation of dynamic content generally more readable than similar
output generated within Perl code. An example:

``` html
<html>
<head>
<title>Blocks</title>
</head>
<body>
<p>

<form>
2 + 2 = <textfield name="sum">
<p><submit>
</form>

<p>
<perl method="check">


<!-- Each block below is only rendered if specifically requested by the Perl code -->

<block name="pass">
Yes, +{sum} is the correct answer ! Brilliant ..
</block>

<block name="fail">
I am sorry .. +{sum} is not correct .. Please try again !
</block>

<block name="silly">
Danger, does not compute ! .. "+{sum}" is not a number !
</block>

<p>
Thanks for playing !

</perl>

</body>
</html>

__PERL__

sub check {

    my $self=shift();

    if ((my $ans=$_{'sum'}) == 4) {
        $self->render_block('pass')
    }
    elsif ($ans=~/^[0-9.]+$/) {
        $self->render_block('fail')
    }
    elsif ($ans) {
        $self->render_block('silly')
    }

    #  Blocks aren't displayed until whole section rendered
    #
    return $self->render();

}
        
```

[Run](https://demo.webdyne.org/block1.psp)

There can be more than one block with the same name - any block with the
target name will be rendered:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>
<form>
Enter your name:
<p><textfield name="name">
<p><submit>
</form>

<perl method="hello">


<!-- The following block is only rendered if we get a name - see the perl 
    code -->

<block name="greeting">
Hello +{name}, pleased to meet you !
<p>
</block>


<!-- This text is always rendered - it is not part of a block -->

The time here is !{! localtime() !}


<!-- This block has the same name as the first one, so will be rendered
    whenever that one is -->

<block name="greeting">
<p>
It has been a pleasure to serve you, +{name} !
</block>


</perl>

</body>
</html>

__PERL__

sub hello { 

    my $self=shift();

    #  Only render greeting blocks if name given. Both blocks
    #  will be rendered, as the both have the name "greeting"
    #
    if ($_{'name'}) {
        $self->render_block('greeting');
    }

    $self->render();
}
```

[Run](https://demo.webdyne.org/block2.psp)

Like any other text or HTML between <perl\> tags, blocks can take
parameters to substitute into the text:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>
<form>
Enter your name: <textfield name="name">
&nbsp;
<submit>
</form>

<perl method="hello">


<!-- This block will be rendered multiple times, the output changing depending
    on the variables values supplied as parameters -->

<block name="greeting">
${i} .. Hello +{name}, pleased to meet you !
<p>
</block>

The time here is <? localtime() ?>

</perl>

</body>
</html>

__PERL__

sub hello { 

    my $self=shift();

    #  Only render greeting blocks if name given. Both blocks
    #  will be rendered, as the both have the name "greeting"
    #
    if ($_{'name'}) {
        for(my $i=0; $i<3; $i++) {
            $self->render_block('greeting', i=>$i );
        }
    }

    $self->render();
}
```

[Run](https://demo.webdyne.org/block3.psp)

Blocks have a non-intuitive feature - they still display even if they
are outside of the <perl\> tags that made the call to render them. e.g.
the following is OK:

``` html
<html>
<head><title>Hello World</title></head>

<body>

<!-- Perl block with no content -->
<perl method="hello">
</perl>

<p>

<!-- This block is not enclosed within the <perl> tags, but will still render -->
<block name="hello">
Hello World
</block>

<p>

<!-- So will this one -->
<block name="hello">
Again
</block>

</body>
</html>

__PERL__

sub hello {

    my $self=shift();
    $self->render_block('hello');

}
```

[Run](https://demo.webdyne.org/block4.psp)

You can mix the two styles:

``` html
<html>
<head><title>Hello World</title></head>

<body>
<perl method="hello">

<!-- This block is rendered -->
<block name="hello">
Hello World
</block>

</perl>

<p>
<!-- So is this one, even though it is outside the <perl>..</perl> block -->
<block name="hello">
Again
</block>

</body>
</html>

__PERL__

sub hello {

    my $self=shift();
    $self->render_block('hello');
    $self->render();

}
```

[Run](https://demo.webdyne.org/block5.psp)

You can use the <block\> tag display attribute to hide or show a block,
or use a CGI parameter to determine visibility (e.g for a status update
or warning):

``` html
<start_html>

<!-- Form to get block toggle status. Update hidden param based on toggle button -->
<form>
<submit name="button" value="Toggle">
<hidden name="toggle" value="!{! $_{'toggle'} ? 0 : 1 !}">
</form>

<!-- This block will only be displayed if the toggle value is true -->
<block name="toggle1" display="!{! $_{'toggle'} !}">
Toggle On (+{toggle})
</block>
<p>

<!-- This block will always display -->
<block name="hello" display=1>
Hello World
</block>

<!-- This block will never display unless called from a perl handler -->
<block name="hello" display=0>
Goodbye world
</block>
```

[Run](https://demo.webdyne.org/block_toggle1.psp)

## File inclusion

You can include other file fragments at compile time using the include
tag:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>
The protocols file on this machine:
<pre>
<include file="/etc/protocols">
</pre>
</body>
</html>
```

[Run](https://demo.webdyne.org/include1.psp)

If the file name is not an absolute path name is will be loaded relative
to the directory of the parent file. For example if file "bar.psp"
incorporates the tag <include file="foo.psp"\> it will be expected that
"`foo.psp`" is in the same directory as "`bar.psp`".

!!! important

    The include tag pulls in the target file at compile time. Changes to the
    included file after the WebDyne page is run the first time (resulting in
    compilation) are not reflected in subsequent output unless the `nocache`
    attribute is set. Thus the include tag should not be seen as a shortcut
    to a pseudo Content Management System. For example <include
    file="latest_news.txt"\> will probably not behave in the way you expect.
    The first time you run it the latest news is displayed. However updating
    the "latest_news.txt" file will not result in changes to the output (it
    will be stale).

    If you do use the `nocache` attribute the included page will be loaded
    and parsed every time, significantly slowing down page display. There
    are betters ways to build a CMS with WebDyne - use the include tag
    sparingly !

You can include just the head or body section of a HTML or PSP file by
using the head or body attributes. Here is the reference file (file to
be included). It does not have to be a .psp file - a standard HTML file
can be supplied :

``` html
<start_html title="Include Head Title">
Include Body
```

[Run](https://demo.webdyne.org/include2.psp)

And here is the generating file (the file that includes sections from
the reference file).

``` html
<html>
<head>
<include head file="./include2.psp">
</head>
<body>
<include body file="./include2.psp">
```

[Run](https://demo.webdyne.org/include3.psp)

You can also include block sections from `.psp` files. If this is the
reference file (the file to be included) containing two blocks. This is
a renderable `.psp` file in it's own right. The blocks use the `display`
attribute to demonstrate that they will produce output, but it's not
required:

``` html
<start_html>
<p>
<block name="block1" display>
This is block 1
</block>

<p>
<block name="block2" display>
This is block 2
</block>
```

[Run](https://demo.webdyne.org/include4.psp)

And here is the file that brings in the blocks from the reference file
and incorporates them into the output:

``` html
<start_html>
This is my master file
<p>
Here is some text pulled from the "include4.psp" file:
<p>
<include file="include4.psp" block="block1">
<p>
And another different block from the same file with caching disabled:
<p>
<include file="include4.psp" block="block2" nocache>
```

[Run](https://demo.webdyne.org/include5.psp)

## Static Sections {#static_sections}

Sometimes you want to generate dynamic output in a page once only (e.g.
a last modified date, a sidebar menu etc.) Using WebDyne this can be
done with Perl or CGI code flagged with the "static" attribute. Any
dynamic tag so flagged will be rendered at compile time, and the
resulting output will become part of the compiled page - it will not
change on subsequent page views, or have to be re-run each time the page
is loaded. An example:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>
Hello World
<hr>


<!-- Note the static attribute -->

<perl method="mtime" static="1">
<em>Last Modified: </em>${mtime}
</perl>

</body>
</html>

__PERL__

sub mtime {

    my $self=shift();
    my $r=$self->request();
    
    my $srce_pn=$r->filename();
        my $srce_mtime=(stat($srce_pn))[9];
    my $srce_localmtime=localtime $srce_mtime;

        return $self->render( mtime=>$srce_localmtime )

}
```

[Run](https://demo.webdyne.org/static1.psp)

In fact the above page will render very quickly because it has no
dynamic content at all once the <perl\> content is flagged as static.
The WebDyne engine will recognise this and store the page as a static
HTML file in its cache. Whenever it is called WebDyne will use the
Apache lookup_file() function to return the page as if it was just
serving up static content.

You can check this by looking at the content of the WebDyne cache
directory (usually /var/webdyne/cache). Any file with a ".html"
extension represents the static version of a page.

Of course you can still mix static and dynamic Perl sections:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>
Hello World
<p>

<!-- A normal dynamic section - code is run each time page is loaded -->

<perl method="localtime">
Current time: ${time} 
</perl>
<hr>

<!-- Note the static attribute - code is run only once at compile time -->

<perl method="mtime" static="1">
<em>Last Modified: </em>${mtime}
</perl>


</body>
</html>

__PERL__


sub localtime {

    shift()->render(time=>scalar localtime);

}


sub mtime {

    my $self=shift();
    my $r=$self->request();
    
    my $srce_pn=$r->filename();
        my $srce_mtime=(stat($srce_pn))[9];
    my $srce_localmtime=localtime $srce_mtime;

        return $self->render( mtime=>$srce_localmtime )

}
```

[Run](https://demo.webdyne.org/static2.psp)

If you want the whole pages to be static, then flagging everything with
the "static" attribute can be cumbersome. There is a special meta tag
which flags the entire page as static:

``` html
<html>
<head>

<!-- Special meta tag -->
<meta name="WebDyne" content="static=1">

<title>Hello World</title>
</head>
<body>
<p>
Hello World
<hr>


<!-- A normal dynamic section, but because of the meta tag it will be frozen 
    at compile time -->

<perl method="localtime">
Current time: ${time} 
</perl>

<!-- Note the static attribute. It is redundant now the whole page is flagged
    as static - it could be removed safely. -->

<p>
<perl method="mtime" static="1">
<em>Last Modified: </em>${mtime}
</perl>


</body>
</html>

__PERL__


sub localtime {

    shift()->render(time=>scalar localtime);

}


sub mtime {

    my $self=shift();
    my $r=$self->request();
    
    my $srce_pn=$r->filename();
        my $srce_mtime=(stat($srce_pn))[9];
    my $srce_localmtime=localtime $srce_mtime;

        return $self->render( mtime=>$srce_localmtime )

}
```

[Run](https://demo.webdyne.org/static3.psp)

If you don't like the idea of setting the static flag in meta data, then
"using" the special package "WebDyne::Static" will have exactly the same
effect:

``` html
<html>
<head>
<title>Hello World</title>
</head>
<body>
<p>
Hello World
<hr>

<perl method="localtime">
Current time: ${time} 
</perl>

<p>

<perl method="mtime">
<em>Last Modified: </em>${mtime}
</perl>

</body>
</html>

__PERL__


#  Makes the whole page static
#
use WebDyne::Static;


sub localtime {

    shift()->render(time=>scalar localtime);

}


sub mtime {

    my $self=shift();
    my $r=$self->request();
    
    my $srce_pn=$r->filename();
        my $srce_mtime=(stat($srce_pn))[9];
    my $srce_localmtime=localtime $srce_mtime;

        return $self->render( mtime=>$srce_localmtime )

}
```

[Run](https://demo.webdyne.org/static3a.psp)

If the static tag seems trivial consider the example that displayed
country codes:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- Generate all country names for picklist -->

<form>

Your Country ?
<perl method="countries">
<popup_menu values="${countries_ar}" default="Australia">
</perl>

</form>
</body>
</html>

__PERL__

use Locale::Country;

sub countries {
    
    my $self=shift();
    my @countries = sort { $a cmp $b } all_country_names();
    $self->render( countries_ar=>\@countries );

}
```

[Run](https://demo.webdyne.org/cgi5.psp)

Every time the above example is viewed the Country Name list is
generated dynamically via the Locale::Country module. This is a waste of
resources because the list changes very infrequently. We can keep the
code neat but gain a lot of speed by adding the `static` tag attribute:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- Generate all country names for picklist -->

<form>

Your Country ?
<perl method="countries" static="1">

<!-- Note the addition of the static attribute -->

<popup_menu values="${countries_ar}">
</perl>

</form>
</body>
</html>

__PERL__

use Locale::Country;

sub countries {
    
    my $self=shift();
    my @countries = sort {$a cmp $b} all_country_names();
    $self->render( countries_ar=>\@countries );

}
```

[Run](https://demo.webdyne.org/static4.psp)

By simply adding the "static" attribute output on a sample machine
resulted in a 4x speedup in page loads. Judicious use of the static tag
in places with slow changing data can markedly increase efficiency of
the WebDyne engine.

## Caching {#caching_section}

WebDyne has the ability to cache the compiled version of a dynamic page
according to specs you set via the API. When coupled with pages/blocks
that are flagged as static this presents some powerful possibilities.

!!! important

    Caching will only work if `$WEBDYNE_CACHE_DN` is defined and set to a
    directory that the web server has write access to. If caching does not
    work check that \$`WEBDYNE_CACHE_DN` is defined and permissions set
    correctly for your web server.

There are many potential examples, but consider this one: you have a
page that generates output by making a complex query to a database,
which takes a lot of CPU and disk IO resources to generate. You need to
update the page reasonably frequently (e.g. a weather forecast, near
real time sales stats), but can't afford to have the query run every
time someone view the page.

WebDyne allows you to configure the page to cache the output for a
period of time (say 5 minutes) before re-running the query. In this way
users sees near real-time data without imposing a high load on the
database/Web server.

WebDyne knows to enable the caching code by looking for a meta tag, or
by loading the `WebDyne::Cache` module in a \_\_PERL\_\_ block.

The cache code can command WebDyne to recompile a page based on any
arbitrary criteria it desires. As an example the following code will
recompile the page every 10 seconds. If viewed in between refresh
intervals WebDyne will serve up the cached HTML result using Apache
r\$-\>lookup_file() or the FCGI equivalent, which is very fast.

Try it by running the following example and clicking refresh a few times
over a 20 second interval

``` html
<html>
<head>
<title>Caching</title>
<!-- Set static and cache meta parameters -->
<meta name="WebDyne" content="cache=&cache;static=1">
</head>

<body>
<p>

This page will update once every 10 seconds.

<p>

Hello World !{! localtime() !}

</body>
</html>

__PERL__


#  The following would work in place of the meta tags
#
#use WebDyne::Static;
#use WebDyne::Cache (\&cache);


sub cache {

    my $self=shift();

    #  Get cache file mtime (modified time)
        #
        my $mtime=${ $self->cache_mtime() };


        #  If older than 10 seconds force recompile
        #
        if ((time()-$mtime) > 10) { 
                $self->cache_compile(1) 
        };

    #  Done
    #
    return \undef;

}
```

[Run](https://demo.webdyne.org/cache1.psp)

WebDyne uses the return value of the nominated cache routine to
determine what UID (unique ID) to assign to the page. In the above
example we returned \\undef, which signifies that the UID will remain
unchanged.

You can start to get more advanced in your handling of cached pages by
returning a different UID based on some arbitrary criteria. To extend
our example above: say we have a page that generated sales figures for a
given month. The SQL code to do this takes a long time, and we do not
want to hit the database every time someone loads up the page. However
we cannot just cache the output, as it will vary depending on the month
the user chooses. We can tell the cache code to generate a different UID
based on the month selected, then cache the resulting output.

The following example simulates such a scenario:

``` html
<!-- Start to cheat by using start/end_html tags to save space -->

<start_html>
<form method="GET">
Get sales results for:&nbsp;<popup_menu name="month" values="@{qw(January February March)}">
<submit>
</form>

<perl method="results">
Sales results for +{month}: $${results}
</perl>

<hr>
This page generated: !{! localtime() !}
<end_html>

__PERL__

use WebDyne::Static;
use WebDyne::Cache (\&cache);

my %results=(

    January     => 20,
    February    => 30,
    March       => 40
);

sub cache {

    #  Return UID based on month
    #
    my $uid=undef;
    if (my $month=$_{'month'}) {

        #  Make sure month is valid
        #
        $uid=$month if defined $results{$month}

    }
    return \$uid;

}


sub results {

    my $self=shift();
    if (my $month=$_{'month'}) {
        
        #  Could be a really long complex SQL query ...
        #
        my $results=$results{$month};


        #  And display
        #
        return $self->render(results => $results);
    }
    else {
        return \undef;
    }

}
```

[Run](https://demo.webdyne.org/cache2.psp)

!!! important

    Take care when using user-supplied input to generate the page UID. There
    is no inbuilt code in WebDyne to limit the number of UID's associated
    with a page. Unless we check it, a malicious user could potentially DOS
    the server by supplying endless random "months" to the above page with a
    script, causing WebDyne to create a new file for each UID - perhaps
    eventually filling the disk partition that holds the cache directory.
    That is why we check the month is valid in the code above.

## JSON

WebDyne has a <json\> tag that can be used to present JSON data objects
to Javascript libraries in an output page. Here is a very simple
example:

``` html
<start_html title="Sample JSON Chart" script="https://cdn.jsdelivr.net/npm/chart.js">

<h2>Monthly Sales Chart</h2>

<canvas id="myChart"></canvas>

<json handler="chart_data" id="chartData">

<script>
  // Parse JSON from the script tag
  const data = JSON.parse(document.getElementById("chartData").textContent);

  const ctx = document.getElementById('myChart').getContext('2d');
  new Chart(ctx, {
    type: 'bar', // You can also use 'line', 'pie', etc.
    data: {
      labels: data.labels,
      datasets: [{
        label: 'Sales',
        data: data.values,
      }]
    }
  });
</script>

__PERL__

sub chart_data {

    my %data=(
        labels  => [qw(Jan Feb Mar Apr)],
        values  => [(120, 150, 180, 100)]
    );
    return \%data
    
}
        
```

[Run](https://demo.webdyne.org/chart1.psp)

If you run it and review the source HTML you will see the JSON data
rendered into the page as <script\></script\> block of type
application/json with an id of "chartData". Any data returned by the
perl routine nominated by the json tag is presented as JSON within that
tag block, and available to Javascript libraries within the page. JSON
data is kept in canononical order by default, which can be adjusted with
the WEBDYNE_JSON_CANONICAL variable if not desired/needed for a very
small speed-up.

## API Tags

WebDyne has the ability to make available a basic REST API facility
using the <api\> tag in conjunction with the Router::Simple CPAN
module. Documents that utilise the <api\> tag are somewhat unique in
that:

-   There is no need for any other tags in the document besides the
    <api\> tag. All other tags are ignored - in fact they are
    discarded.

-   Any .psp file file an <api\> tag will only emit JSON data with a
    content type of "`application/json`"

-   The REST api path must correspond .psp file at some path level, e.g.
    if your path is `/api/user/42` you must have a file called either
    "`api.psp`" or "`api/user.psp`" in your path.

-   A .psp file can contain multiple <api\> tags corresponding to
    different `Router::Simple` routes

Here is a very simple example. Note the format of the URL in the Run
hyperlink:

``` html
<api handler=uppercase pattern="/api/uppercase/{user}/:id">
<api handler=doublecase pattern="/api/doublecase/{user}/:id">
__PERL__
sub uppercase {

    my ($self, $match_hr)=@_;
    my ($user, $id)=@{$match_hr}{qw(user id)};
    my %data=(
        user => uc($user),
        id   => $id
    );
    return \%data
    
}

sub doublecase {

    my ($self, $match_hr)=@_;
    my ($user, $id)=@{$match_hr}{qw(user id)};
    my %data=(
        user => join('_', uc($user), lc($user)),
        id   => $id
    );
    return \%data
    
}
```

[Run uppercase API
example](https://demo.webdyne.org/api/uppercase/bob/42)

[Run doublecase API
example](https://demo.webdyne.org/api/doublecase/bob/42)

!!! caution

    The <api\> tag is still somewhat experimental. Use with caution

## HTMX

WebDyne has support for <htmx\> tags to supply fragmented HTML to pages
using the [HTMX Javascript Library](https://htmx.org). WebDyne can
support just supplying HTML snippet to pages in response to htmx calls.
HTMX and WebDyne are complementary libraries which can be combined
together to support dynamic pages with in-place updates from WebDybe
Perl backends. Here is a simple HTML file (`htmx_demo1.psp`)
incorporating HTMX calls to a backend file called `htmx_time1.psp`. Here
is the display file, `htmx_demo1.psp`

``` html
<start_html script="https://unpkg.com/htmx.org@1.9.10">
<h2>Current time</h2>
<p>Click the button below to load time data from the server</p>

<!-- HTMX Trigger Button -->
<button 
  hx-get="htmx_time1.psp"
  hx-target="#time-container"
  hx-swap="innerHTML"
>
Get Time
</button>

<!-- Where the fetched HTML fragment will go -->
<p>
<div id="time-container">
  <em>Time data not loaded yet.</em>
</div>
```

[Run](https://demo.webdyne.org/htmx_demo1.psp)

And the backend file which generates the HTMX data for the above page
(`htmx_time1.psp`):

``` html
<start_html>
<htmx>Server local time: <? localtime() ?> </htmx>
```

[Run](https://demo.webdyne.org/htmx_time1.psp)

Note the <htmx\> tags. You can run the above htmx resource file and it
will render correctly as a full HTML page - however if WebDyne detects a
'hx-request' HTTP header it will only send the fragment back.

!!! important

    Only one <htmx\> section from a file will ever be rendered. You can
    have multiple <htmx\> sections in a .psp file however only one can be
    rendered at any time. You can use the display attribute with dynamic
    matching (see later) do render different <htmx\> sections in a .psp
    file, or you can keep them all in different files (e.g. one <htmx\>
    section per .psp file

### Using Perl within <htmx\> tags

<htmx\> tags can be called with the same attributes as <perl\> tags,
including nominating a handler to generate data. See the following
example:

``` html
<start_html script="https://unpkg.com/htmx.org@1.9.10">
<h2>Current time</h2>
<p>Click the button below to load time data from the server</p>

<!-- HTMX Trigger Button -->
<button 
  hx-get="htmx_time2.psp"
  hx-target="#time-container"
  hx-swap="innerHTML"
>
Get Time
</button>

<!-- Where the fetched HTML fragment will go -->
<p>
<div id="time-container">
  <em>Time data not loaded yet.</em>
</div>
```

[Run](https://demo.webdyne.org/htmx_demo2.psp)

And the backend file which generates the HTMX data for the above page:

``` html
<start_html>
<htmx handler="server_time">
<p>
Server local time: ${server_time}
</htmx>

__PERL__

sub server_time {
    my $self=shift();
    my $time=scalar localtime;
    for (1..3) {
        $self->print( $self->render( server_time=> $time ));
    }
    return \undef;
}
```

[Run](https://demo.webdyne.org/htmx_time2.psp)

### Using multiple <htmx\> tags in one .psp file

As is mentioned above only one <htmx\> fragment can be returned by a
.psp page at a time - but you can use techniques to select which tag
should be rendered. The <htmx\> tag supports the display attribute. If
this attribute exists and is a "true" value then the <htmx\> fragment
will be returned. At first this doesn't seem very useful - but when
combined with dynamic evaluation via either page query parameters or
`!{! .. !}` evaluation it becomes more compelling. Take the following
two button example:

``` html
<start_html script="https://unpkg.com/htmx.org@1.9.10">
<h2>HTMX Demo</h2>
<p>
Click the button below to load time data from the server.</p>

<!-- HTMX Trigger Button for Local Time -->
<button 
  style="width:180px"
  hx-get="/htmx_time3.psp"
  hx-target="#time-container"
  hx-swap="innerHTML"
  hx-vals="js:{ time_local: 1 }"
>
Get Local Time
</button>

<p>

<!-- HTMX Trigger Button for UTC Time -->
<button 
  style="width:180px"
  hx-get="/htmx_time3.psp"
  hx-target="#time-container"
  hx-swap="innerHTML"
  hx-vals="js:{ time_utc: 1 }"
>
Get UTC Time
</button>

<!-- Where the fetched HTML fragment will go -->
<p>
<div id="time-container">
  <em>Time data not loaded yet.</em>
</div>
```

[Run](https://demo.webdyne.org/htmx_demo3.psp)

``` html
<htmx display="+{time_local}"> Time Local: <? localtime() ?></htmx>
<htmx display="+{time_utc}"> Time UTC: <? gmtime() ?></htmx>
```

[Run](https://demo.webdyne.org/htmx_time3.psp)

Normally you would expect to have the hx-get attribute for each button
go to a different .psp page. But in this instance they refer to the same
page. So how do we discriminate ? The key is in the supply of the
hx-vals attribute, which allows us to send query strings to the htmx
resource page. We can then use them to select which <htmx\> block is
returned.

!!! note

    Note the use of `js:{ <json> }` notation in the <htmx\> `hx-vals`
    attribute. It allows for easier supply of JSON data without needed to
    manipulate/escape double-quotes in raw JSON data. You'll also note there
    is no <start_html\> tag. It's not necessary for <htmx\> pages.

## Dump

The <dump\> tag is a informational element which can be included in a
page for diagnostic or debugging purposes. It will show various variable
and state values for the page. By default if a <dump\> flag is embedded
in a page diagnostic information is not shown unless the `force`
attribute is specified or the `$WEBDYNE_DUMP_FLAG` is set, the latter
allowing the <dump\> tag to be embedded into all pages on a site but
not activated unless debugging enabled.

Various diagnostic elements can be displayed - see the <dump\> tag
section for information on what they are. In this example all components
are enabled and display is forced:

``` html
<start_html>
<p>
<form>
Your Name: <textfield name="name">
<p>
<submit>
</form>
<dump all force>
```

[Run](https://demo.webdyne.org/dump1.psp)

Dump display/hide can be controlled by form parameters or run URI query
strings. In the example below ticking the checkbox or simply appending
"?dump_enable=1" to the URL will display the dump information:

``` html
<start_html>
<p>
<form>
Your Name: <textfield name="name">
<p>
Show Dump: <checkbox name="dump_enable">
<p>
<submit>
</form>
<dump all force="!{! $_{'dump_enable'} !}">
```

[Run](https://demo.webdyne.org/dump2.psp)

# Error Handling

## Error Messages

Sooner or later something is going to go wrong in your code. If this
happens WebDyne will generate an error showing what the error was and
attempting to give information on where it came from: Take the following
example:

``` html
<start_html title="Error">
Let's divide by zero: !{! my $z=0; return 5/$z !}
<end_html>
```

[Run](https://demo.webdyne.org/err1.psp)

If you run the above example an error message will be displayed

![](images/err1.png)

In this example the backtrace is within in-line code, so all references
in the backtrace are to internal WebDyne modules. The code fragment will
show the line with the error.

If we have a look at another example:

``` html
<start_html title="Error">
<perl method="hello"/>
<end_html>

__PERL__

sub hello {

    die('bang !');

}
```

[Run](https://demo.webdyne.org/err2.psp)

And the corresponding screen shot:

![](images/err2.png)

We can see that the error occurred in the "hello" subroutine (invoked at
line 2 of the page) within the perl block on line 9. The 32 digit
hexadecimal number is the page unique ID - it is different for each
page. WebDyne runs the code for each page in a package name space that
includes the page's UID - in this way pages with identical subroutine
names (e.g. two pages with a "hello" subroutine) can be accommodated
with no collision.

## Exceptions

Errors (exceptions) can be generated within a WebDyne page in two ways:

-   By calling die() as shown in example above.

-   By returning an error message via the err() method, exported by
    default.

Examples

    __PERL__


    #  Good
    #
    sub hello {

        return err('no foobar') if !$foobar;

    }

    # Also OK
    #
    sub hello {

        return die('no foobar') if !$foobar;

    }

## Error Checking

So far all the code examples have just assumed that any call to a
WebDyne API method has been successful - no error checking is done.
WebDyne always returns "undef" if an API method call fails - which
should be checked for after every call in a best practice scenario.

``` html
<start_html title="Error">
<perl method="hello">

Hello World ${foo}

</perl>
<end_html>

__PERL__

sub hello {

    #  Check for error after calling render function
    #
    shift()->render( bar=> 'Again') || return err();

}
```

[Run](https://demo.webdyne.org/err3.psp)

You can use the err() function to check for errors in WebDyne Perl code
associated with a page, e.g.:

``` html
<start_html title="Error">
<form>
<submit name="Error" value="Click here for error !">
</form>
<perl method="foo"/><end_html>

__PERL__

sub foo {

    &bar() || return err();
    \undef;

}

sub bar {

    return err('bang !') if $_{'Error'};
    \undef;
}
```

[Run](https://demo.webdyne.org/err4.psp)

Note that the backtrace in this example shows clearly where the error
was triggered from.

# WebDyne API

## WebDyne tags

Reference of WebDyne tags and supported attributes

<perl\>

:   Run Perl code either in-line (between the <perl\>..</perl\>) tags,
    or non-inline via the method attribute

    method\|handler=method

    :   Call an external Perl subroutine in from a module, or a
        subroutine in a \_\_PERL\_\_ block at the of the .psp file. If
        the handler is specified a module call (e.g.
        Digest::MD5::md5_hex()) then a require call will be load the
        module (Digest::MD5 in this example.

    package\|require=\[Module::Name\] \| \[Path/Filename.pm\]

    :   Load a Perl module or file needed to support a method call. E.g.
        <perl require=Digest::MD5/\> to load the Digest::MD5 module.
        Anything with a \[./\\\] character is treated as file patch to a
        Perl file (e.g. "/home/user/module.pm"), otherwise it is treated
        as module name ("Digest::MD5")

    import=\[function\], <function\>, <function\> ..

    :   Import a single or multiple functions into the file namespace.
        Use "import=name" for a single function, or pass an array ref
        (import="@{name1, name2}" for multiple functions. E.g. <perl
        require="Digest::SHA" import="@{qw(sha1 sha1_hex)}"/\>.
        Functions are then available anywhere in the file namespace.

    param=scalar\|array\|hash

    :   Parameters to be supplied to perl routine. Supply array and hash
        using "@{1,2}" and "%{a=\>1, b=\>2}" conventions respectively,
        e.g. <perl method="sum2num" param="@{2,2}"/\>

    static=1

    :   This Perl code to be run once only and the output cached for all
        subsequent requests.

    file=1

    :   Force package\|require attribute to be treated as a file, even
        if it appears to "look like" a module name to the loader. Rarely
        needed, use case would be a Perl module in the current directory
        without an extension.

    hidden=1

    :   The output from the Perl module will be hidden.

<json\>

:   Run Perl code similar to <perl\> tag but expect code to return a
    HASH or ARRAY ref and encode into JSON, outputting in a <script\>
    tag with type="application/json". When supplied with an id attribute
    this data can be used by any Javascript function in the page. All
    attributes are the same as the <perl\> tag with the following extra
    attribute

    id=\[name\]

    :   ID this <script\> tag will be given, e.g. <script id="mydata"
        type="application/json"\>\[{"foo":1}\]</script\>

<block\>

:   Block of HTML code to be optionally rendered if desired by call to
    render_block Webdyne method:

    name=identifier

    :   *Mandatory.* The name for this block of HTML. Referenced when
        rendering a particular block in perl code, e.g. return
        \$self-\>render_block("foo");

    display=1

    :   Force display of this block even if not invoked by render_block
        WebDyne method. Useful for prototyping.

    static=1

    :   This block rendered once only and the output cached for all
        subsequent requests

<include\>

:   Include HTML or text from an external file. This includes pulling in
    the <head\> or <body\> section from another HTML or .psp file. If
    pulled in from a .psp file it will compiled and interpreted in the
    context of the current page.

    file=filename

    :   *Mandatory*. Name of file we want to include. Can be relative to
        current directory or absolute path.

    head=1

    :   File is an HTML or `.psp` file and we want to include just the
        <head\> section

    body=1

    :   File is an HTML or `.psp` file and we want to include just the
        <body\> section.

    block=blockname

    :   File is a `.psp` file and we want to include a <block\> section
        from that file.

    nocache

    :   Don't cache the results of the include, bring them in off disk
        each time. Will incur performance penalty

<api\>

:   Respond to a JSON request made from a client.

    pattern=string

    :   *Mandatory*. Name of `Route::Simple` pattern we want to serve,
        e.g. /api/{user}/:id

    destination \| dest \| data=hash ref

    :   Hash we want to supply to perl routine if match made. See
        `Route::Simple`

    option=hash ref

    :   Match options, GET, PUT etc. `Route::Simple`

<htmx\>

:   Serve HTML snippets. Takes exactly the same parameters as the
    <perl\> tag with one addition

    display=boolean

    :   *Optional*. If evaluates to true then this <htmx\> snippet
        fires. Only tag can respond per page. Use this attribute in
        conjunction with dynamic evaluation (e.g. display="!{!
        \$\_{name} eq 'Bob' !}")

<dump\>

:   Display CGI parameters in dump format via CGI::Simple-\>Dump call.
    Useful for debugging. Only rendered if `$WEBDYNE_DUMP_FLAG` global
    set to 1 in WebDyne constants of the display\|force attribute
    specified (see below). Useful while troubleshooting or debugging
    pages.

    display\|force=1

    :   *Optional.* Force display even if `$WEBDYNE_DUMP_FLAG` global
        not set

    all

    :   Display all diagnostic blocks

    cgi

    :   Display CGI parameters and query strings

    env

    :   Display environment variables

    constant

    :   Display Webdyne constants

    version

    :   Display version strings

## WebDyne methods

When running Perl code within a WebDyne page the very first parameter
passed to any routine (in-line or in a \_\_PERL\_\_ block) is an
instance of the WebDyne page object (referred to as `$self` in most of
the examples). All methods return undef on failure, and raise an error
using the `err()` function. The following methods are available to any
instance of the WebDyne object:

CGI()

:   Returns an instance of the CGI::Simple object for the current
    request.

r(), request()

:   Returns an instance of the Apache request object, or a mock object
    with similar functionality when running under PSGI or FCGI

html_tiny()

:   Returns an instance of the HTML::Tiny object, can be used for
    creating programmatic HTML output

include()

:   Returns HTML derived from a file, using the same parameters as the
    <include\> tag

render( <key=\>value, key=\>value\>, .. )

:   Called to render the text or HTML between <perl\>..</perl\> tags.
    Optional key and value pairs will be substituted into the output as
    per the variable section. Returns a scalar ref of the resulting
    HTML.

render_block( blockname, <key=\>value, key=\>value, ..\>).

:   Called to render a block of text or HTML between
    <block\>..</block\> tags. Optional key and value pairs will be
    substituted into the output as per the variable section. Returns
    scalar ref of resulting HTML if called with from <perl\>..</perl\>
    section containing the block to be rendered, or true (\\undef) if
    the block is not within the <perl\>..</perl\> section (e.g.
    further into the document, see the block section for an example).

render_reset()

:   Erase anything previously set to render - it will not be sent to the
    browser.

redirect( uri=\>uri \| file=\>filename \| html=\>\\html_text \| json=\>\\json_text \| text=\>\\plain_text)

:   Will redirect to URI or file nominated, or display only nominated
    text. Any rendering done to prior to this method is abandoned. If
    supplying HTML text to be rendered supply as a SCALAR reference.

cache_inode( <seed\> )

:   Returns the page unique ID (UID). Called inode for legacy reasons,
    as that is what the UID used to be based on. If a seed value is
    supplied a new UID will be generated based on an MD5 of the seed.
    Seed only needs to be supplied if using advanced cache handlers.

cache_mtime( <uid\> )

:   Returns the mtime (modification time) of the cache file associated
    with the optionally supplied UID. If no UID supplied the current one
    will be used. Can be used to make cache compile decisions by
    WebDyne::Cache code (e.g if page \> x minutes old, recompile).

source_mtime()

:   Returns the mtime (modification time) of the source .psp file
    currently being rendered.

cache_compile()

:   Force recompilation of cache file. Can be used in cache code to
    force recompilation of a page, even if it is flagged static. Returns
    current value if no parameters supplied, or sets if parameter
    supplied.

filename()

:   Return the full filename (including path) of the file being
    rendered. Will only return the core (main) filename - any included
    files, templates etc. are not reported.

cwd()

:   Return the current working directory WebDyne is operating in.

no_cache()

:   Send headers indicating that the page is not be cached by the
    browser or intermediate proxies. By default WebDyne pages
    automatically set the no-cache headers, although this behaviour can
    be modified by clearing the `$WEBDYNE_NO_CACHE` variable and using
    this function

meta()

:   Return a hash ref containing the meta data for this page.
    Alterations to meta data are persistent for this process, and carry
    across Apache requests (although not across different Apache
    processes)

print(), printf(), say()

:   Render the output of the print(), printf() or say() routines into
    the current HTML stream. The print() and printf() methods emulate
    their Perl functions in not appending a new line into the output,
    where as say() does.

render_time()

:   Return the elapsed time since the WebDyne hander started rendering
    this page. Obviously only meaningful if called at the end of a page,
    just before final output to browser.

## WebDyne Constants {#webdyne_constants}

Constants defined in the WebDyne::Constant package control various
aspects of how WebDyne behaves. Constants can be modified globally by
altering a global configuration file (`/etc/webdyne.conf.pl` under Linux
distros), setting environment variable or by altering configuration
parameters within the Apache web server config.

### Global constants file

WebDyne will look for a system constants file under
`/etc/webdyne.conf.pl` and set package variables according to values
found in that file. The file is in Perl Data::Dumper format, and takes
the format:

    # sample /etc/webdyne.conf.pl file
    #
    $VAR1={
            WebDyne::Constant => {

                    WEBDYNE_CACHE_DN       => '/data1/webdyne/cache',
                    WEBDYNE_STORE_COMMENTS => 1,
                    #  ... more variables for WebDyne package

           },

           WebDyne::Session::Constant => {

                    WEBDYNE_SESSION_ID_COOKIE_NAME => 'session_cookie',
                    #  ... more variables for WebDyne::Session package

           },

    };

The file is not present by default and should be created if you wish to
change any of the WebDyne constants from their default values.

!!! important

    Always check the syntax of the `/etc/webdyne.conf.pl` file after editing
    by running `perl -c -w /etc/webdyne.conf.pl` to check that the file is
    readable by Perl. Files with syntax errors will fail silently and the
    variables will revert to module defaults.

### Setting WebDyne constants in Apache

WebDyne constants can be set in an Apache httpd.conf file using the
PerlSetVar directive:

    PerlHandler     WebDyne
    PerlSetVar      WEBDYNE_CACHE_DN                '/data1/webdyne/cache'
    PerlSetVar      WEBDYNE_STORE_COMMENTS          1

    #  From WebDyne::Session package
    #
    PerlSetVar      WEBDYNE_SESSION_ID_COOKIE_NAME  'session_cookie'

!!! important

    WebDyne constants cannot be set on a per-location or per-directory
    basis - they are read from the top level of the config file and set
    globally.

    Some 1.x versions of mod_perl do not read PerlSetVar variables
    correctly. If you encounter this problem use a <Perl\>..</Perl\>
    section in the `httpd.conf` file, e.g.:

        # Mod_perl 1.x

        PerlHandler     WebDyne
        <Perl>
        $WebDyne::Constant::WEBDYNE_CACHE_DN='/data1/webdyne/cache';
        $WebDyne::Constant::WEBDYNE_STORE_COMMENTS=1;
        $WebDyne::Session::Constant::WEBDYNE_SESSION_ID_COOKIE_NAME='session_cookie';
        </Perl>

Where you need to set variables without simple string content you can
use a <Perl\>..</Perl\> section in the `httpd.conf` file, e.g.:

    # Setting more complex variables

    PerlHandler     WebDyne
    <Perl>
    $WebDyne::Constant::WEBDYNE_CACHE_DN='/data1/webdyne/cache';
    $WebDyne::Constant::WEBDYNE_STORE_COMMENTS=1;
    $WebDyne::Session::Constant::WEBDYNE_SESSION_ID_COOKIE_NAME='session_cookie';
    </Perl>

!!! warning

    The letsencrypt `certbot` utility will error out when trying to update
    any Apache config file with `<Perl>` sections. To avoid this you put the
    variables in a separate file and include them, e.g. in the `apache.conf`
    file:

        # Some config setting defaults. See documentation for full range. 
        # Commented out # options represent defaults 
        #
        PerlRequire conf.d/webdyne_constant.pl

    And then in the webdyne_constant.pl file:

        use WebDyne;
        use WebDyne::Constant;

        #  Error display/extended display on/off. More granular options below. 
        #  Set to 1 to enable, 0 to disable
        #
        $WebDyne::WEBDYNE_ERROR_SHOW=1;
        $WebDyne::WEBDYNE_ERROR_SHOW_EXTENDED=1;

        #  Extended error control.
        #
        #  $WebDyne::WEBDYNE_ERROR_SOURCE_CONTEXT_SHOW=1;
        #  $WebDyne::WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_PRE=4;
        #  $WebDyne::WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_POST=4;

### Constants Reference

The following constants can be altered to change the behaviour of the
WebDyne package. All these constants reside in the `WebDyne::Constant`
package namespace.

`$WEBDYNE_CACHE_DN`

:   The name of the directory that will hold partially compiled WebDyne
    cache files. Must exist and be writable by the Apache process

`$WEBDYNE_STARTUP_CACHE_FLUSH`

:   Remove all existing disk cache files at Apache startup. 1=yes
    (default), 0=no. By default all disk cache files are removed at
    startup, and thus pages must be recompiled again the first time they
    are viewed. If you set this to 0 (no) then disk cache files will be
    saved between startups and pages will not need to be re-compiled if
    Apache is restarted.

`$WEBDYNE_CACHE_CHECK_FREQ`

:   Check the memory cache after this many request (per-process
    counter). default=256. After this many requests a housekeeping
    function will check compiled pages that are stored in memory and
    remove old ones according to the criteria below.

`$WEBDYNE_CACHE_HIGH_WATER`

:   Remove compiled from pages from memory when we have more than this
    many. default=64

`$WEBDYNE_CACHE_LOW_WATER`

:   After reaching HIGH_WATER delete until we get down to this amount.
    default=32

`$WEBDYNE_CACHE_CLEAN_METHOD`

:   Clean algorithm. default=1, means least used cleaned first, 0 means
    oldest last view cleaned first

`$WEBDYNE_EVAL_SAFE`

:   default=0 (no), If set to 1 means eval in a Safe.pm container.
    Evaluating code in a Safe container is experimental and not
    supported or recommended for general WebDyne use.

`$WEBDYNE_EVAL_SAFE_OPCODE_AR`

:   The opcode set to use in Safe.pm evals (see the Safe man page).
    Defaults to "\[':default'\]". Use \[&Opcode::full_opset()\] for the
    full opset. CAUTION Use of WebDyne with Safe.pm not comprehensively
    tested and considered experimental.

`$WEBDYNE_EVAL_USE_STRICT`

:   The string to use before each eval. Defaults to "use strict
    qw(vars);". Set to undef if you do not want strict.pm. In Safe mode
    this becomes a flag only - set undef for "no strict", and non-undef
    for "use strict" equivalence in a Safe mode (checked under Perl
    5.8.6 only, results in earlier versions of Perl may vary).

`$WEBDYNE_STRICT_VARS`

:   Check if a var is declared in a render block (e.g \$ {foo}) but not
    supplied as a render parameter. If so will throw an error. Set to 0
    to ignore. default=1

`$WEBDYNE_DUMP_FLAG`

:   If 1, any instance of the special <dump\> tag will print out
    results from CGI-\>dump(). Use when debugging forms. default=0

`$WEBDYNE_DTD`

:   The DTD to place at the top of a rendered page. Defaults to:
    <!DOCTYPE html\>

`$WEBDYNE_HTML_PARAM`

:   attributes for the <html\> tag, default is { lang =\>'en' }

`$WEBDYNE_HEAD_INSERT`

:   Any HTML you want inserted before the closing </head\> tag, e.g.
    stylesheet or script includes to be added to every `.psp` page. Must
    be valid HTML <head\> directives, not interpreted or compiled by
    WebDyne, incorporated as-is

`$WEBDYNE_COMPILE_IGNORE_WHITESPACE`

:   Ignore source file whitespace as per HTML::TreeBuilder
    ignore_ignorable_whitespace function. Defaults to 1

`$WEBDYNE_COMPILE_NO_SPACE_COMPACTING`

:   Do not compact source file whitespace as per HTML::TreeBuilder
    no_space_compacting function. Defaults to 0

`$WEBDYNE_STORE_COMMENTS`

:   By default comments are not rendered. Set to 1 to store and display
    comments from source files. Defaults to 0

`$WEBDYNE_NO_CACHE`

:   WebDyne should send no-cache HTTP headers. Set to 0 to not send such
    headers. Defaults to 1

`$WEBDYNE_DELAYED_BLOCK_RENDER`

:   By default WebDyne will render blocks targeted by a render_block()
    call, even those that are outside the originating
    <perl\>..</perl\> section that made the call. Set to 0 to not
    render such blocks. Defaults to 1

`$WEBDYNE_WARNINGS_FATAL`

:   If a programs issues a warning via warn() this constant determines
    if it will be treated as a fatal error. Default is 0 (warnings not
    fatal). Set to 1 if you want any warn() to behave as if die() had
    been called..

`$WEBDYNE_CGI_DISABLE_UPLOADS`

:   Disable CGI::Simple file uploads. Defaults to 1 (true - do not allow
    uploads).

`$WEBDYNE_CGI_POST_MAX`

:   Maximum size of a POST request. Defaults to 512Kb

`$WEBDYNE_JSON_CANONICAL`

:   Set is JSON encoding should be canonical, i.e. respect the order of
    supplied data (slightly slows down encoding). Defaults to 1 (true -
    preserve variable order)

`$WEBDYNE_ERROR_TEXT`

:   Display simplified errors in plain text rather than using HTML.
    Useful in internal WebDyne development only. By default this is 0
    =\> the HTML error handler will be used.

`$WEBDYNE_ERROR_SHOW`

:   Display the error message. Only applicable in the HTML error handler

`$WEBDYNE_ERROR_SOURCE_CONTEXT_SHOW`

:   Display a fragment of the `.psp` source file around where the error
    occurred to give some context of where the error happened. Set to 0
    to not display context.

`$WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_PRE`

:   Number of lines of the source file before the error occurred to
    display. Defaults to 4

`$WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_POST`

:   Number of lines of the source file after the error occurred to
    display. Defaults to 4

`$WEBDYNE_ERROR_SOURCE_CONTEXT_LINE_FRAGMENT_MAX`

:   Max line length to show. Defaults to 80 characters.

`$WEBDYNE_ERROR_BACKTRACE_SHOW`

:   Show a backtrace of modules through which the error propagated. On
    by default, set to 0 to disable,

`$WEBDYNE_ERROR_BACKTRACE_SHORT`

:   Remove WebDyne internal modules from backtrace. Off by default, set
    to 1 to enable.

`$WEBDYNE_AUTOLOAD_POLLUTE`

:   When a method is called from a <perl\> routine the WebDyne AUTOLOAD
    method must search multiple modules for the method owner. Setting
    this flag to 1 will pollute the WebDyne name space with the method
    name so that AUTOLOAD is not called if that method is used again
    (for the duration of the Perl process, not just that call to the
    page). This is dangerous and can cause confusion if different
    modules use the same name. In very strictly controlled
    environments - and even then only in some cases - it can result is
    faster throughput. Off by default, set to 1 to enable.

Extension modules (e.g., WebDyne::Session) have their own constants -
see each package for details.

## WebDyne Directives

A limited number of directives are are available which change the way
WebDyne processes pages. Directives are set in either the Apache .conf
files and can be set differently per location. At this stage only one
directive applies to the core WebDyne module:

`WebDyneHandler`

:   The name of the handler that WebDyne should invoke instead of
    handling the page internally. The only other handler available today
    is WebDyne::Chain.

This directive exists primarily to allow PSGI to invoke WebDyne::Chain
as the primary handler. It can be used in Apache httpd.conf files, but
is not very efficient:

    #  This will work, but is not very efficient
    #
    <location /shop/>
    PerlHandler     WebDyne
    PerlSetVar      WebDyneHandler               'WebDyne::Chain'
    PerlSetVar      WebDyneChain                 'WebDyne::Session'
    </location>


    #  This is the same, and is more efficient
    #
    <location /shop/>
    PerlHandler     WebDyne::Chain
    PerlSetVar      WebDyneChain                 'WebDyne::Session'
    </location>

# Miscellaneous

## Command Line Utilities

Command line utilities are fairly basic at this stage. Installation
location will vary depening on your distribution - most will default to
`/usr/local/bin`, but may be installed elsewhere in some cases,
especially if you have nominated a `PREFIX` option when using CPAN.

`wdapacheinit`

:   Runs the WebDyne initialization routines, which create needed
    directories, modify and create Apache .conf files etc.

`wdcompile`

:   Usage: `wdcompile filename.psp`. Will compile a .psp file and use
    Data::Dumper to display the WebDyne internal representation of the
    page tree structure. Useful as a troubleshooting tool to see how
    HTML::TreeBuilder has parsed your source file, and to show up any
    misplaced tags etc.

`wdrender`

:   Usage: `wdrender filename.psp`. Will attempt to render the source
    file to screen using WebDyne. Can only do basic tasks - any advanced
    use (such as calls to the Apache request object) will fail.

`wddump`

:   Usage: `wddump filename`. Where filename is a compiled WebDyne
    source file (usually in /var/webdyne/cache). Will dump out the saved
    data structure of the compiled file.

`wddebug`

:   Usage: `wddebug --status|--enable|--disable`. Enable/disable
    debugging in the WebDyne code.

`webdyne.psgi`

:   Used to run WebDyne as a PSGI process- usually invoked by Plack via
    plackup or starman, but can be run directly for development
    purposes.

wdlint

:   Run perl -c -w over code in \_\_PERL\_\_ sections on any .psp file
    to check for syntax errors.

## Other files referenced by WebDyne

`/etc/webdyne.conf.pl`

:   Used for storage of local constants that override WebDyne defaults.
    See the [WebDyne::Constant](#webdyne_constants) section for details

# Extending WebDyne

WebDyne can be extended by the installation and use of supplementary
Perl packages. There are several standard packages that come with the
Webdyne distribution, or you can build your own using one of the
standard packages as a template.

The following gives an overview of the standard packages included in the
distribution, or downloadable as extensions from CPAN.

## WebDyne::Chain {#webdyne_chain}

WebDyne::Chain is a module that will cascade a WebDyne request through
one or more modules before delivery to the WebDyne engine. Most modules
that extend WebDyne rely on WebDyne::Chain to get themselves inserted
into the request lifecycle.

Whilst WebDyne::Chain does not modify content itself, it allows any of
the modules below to intercept the request as if they had been loaded by
the target page directly (i.e., loaded in the \_\_PERL\_\_ section of a
page via the "use" or "require" functions).

Using WebDyne::Chain you can modify the behaviour of WebDyne pages based
on their location. The WebDyne::Template module can be used in such
scenario to wrap all pages in a location with a particular template.
Another would be to make all pages in a particular location static
without loading the WebDyne::Static module in each page:

    <Location /static>

    #  All pages in this location will be generated once only.
    PerlHandler     WebDyne::Chain
    PerlSetVar      WebDyneChain    'WebDyne::Static'

    </Location>

Multiple modules can be chained at once:

    <Location />

    #  We want templating and session cookies for all pages on our site.
    PerlHandler     WebDyne::Chain
    PerlSetVar      WebDyneChain    'WebDyne::Session WebDyne::Template'
    PerlSetVar      WebDyneTemplate '/path/to/template.psp'

    </Location>

The above example would place all pages within the named template, and
make session information to all pages via \$self-\>session_id(). A good
start to a rudimentary CMS.

WebDyneChain

:   Directive. Supply a space separated string of WebDyne modules that
    the request should be passed through.

## WebDyne::Static

Loading WebDyne::Static into a \_\_PERL\_\_ block flags to WebDyne that
the entire page should be rendered once at compile time, then the static
HTML resulting from that compile will be handed out on subsequent
requests. Any active element or code in the page will only be run once.
There are no API methods associated with this module

See the [Static Sections](#static_sections) reference for more
information on how to use this module within an individual page.

WebDyne::Static can also be used in conjunction with the
[WebDyne::Chain](#webdyne_chain) module to flag all files in a directory
or location as static. An example httpd.conf snippet:

    <Location /static/>

    PerlHandler     WebDyne::Chain
    PerlSetVar      WebDyneChain    'WebDyne::Static'

    </Location>

## WebDyne::Cache

Loading WebDyne::Cache into a \_\_PERL\_\_ block flags to WebDyne that
the page wants the engine to call a designated routine every time it is
run. The called routine can generate a new UID (Unique ID) for the page,
or force it to be recompiled. There are no API methods associated with
this module.

See the [Caching](#caching_section) section above for more information
on how to use this module with an individual page.

WebDyne::Cache can also be used in conjunction with the
[WebDyne::Chain](#webdyne_chain) module to flag all files in a
particular location are subject to a cache handling routine. An example
httpd.conf snippet:

    <Location /cache/>

    #  Run all requests through the MyModule::cache function to see if a page should
    #  be recompiled before sending it out
    #
    PerlHandler     WebDyne::Chain
    PerlSetVar      WebDyneChain    'WebDyne::Cache'
    PerlSetVar      WebDyneCacheHandler '&MyModule::cache'

    </Location>

Note that any package used as the WebDyneCacheHandler target should be
already loaded via "PerlRequire" or similar mechanism.

As an example of why this could be useful consider the [caching
examples](#caching_section) above. Instead of flagging that an
individual file should only be re-compiled every x seconds, that policy
could be applied to a whole directory with no alteration to the
individual pages.

## WebDyne::Session

WebDyne::Session generates a unique session ID for each browser
connection and stores it in a cookie. It has the following API:

session_id()

:   Function. Returns the unique session id assigned to the browser.
    Call via \$self-\>session_id() from perl code.

`$WEBDYNE_SESSION_ID_COOKIE_NAME`

:   Constant. Holds the name of the cookie that will be used to assign
    the session id in the users browser. Defaults to "session". Set as
    per [WebDyne::Constants](#webdyne_constants) section. Resides in the
    `WebDyne::Session::Constant` package namespace.

Example:

    <start_html>

    Session ID: !{! shift()->session_id() !}

    <end_html>

    __PERL__

    use WebDyne::Session;
    1;

[Run](https://demo.webdyne.org/session1.psp)

WebDyne::Session can also be used in conjunction with the
[WebDyne::Chain](#webdyne_chain) module to make session information
available to all pages within a location. An example httpd.conf snippet:

    <Location />

    # We want session cookies for our whole site
    #
    PerlHandler     WebDyne::Chain
    PerlSetVar      WebDyneChain    'WebDyne::Session'

    #  Change cookie name from "session" to "gingernut" for something different
    #
    PerlSetVar      WEBDYNE_SESSION_ID_COOKIE_NAME    'gingernut'

    </Location>

## WebDyne::Template

One of the more powerful WebDyne extensions. WebDyne::Template can be
used to build CMS (Content Management Systems). It will extract the
<head\> and <body\> sections from an existing HTML or WebDyne page and
insert them into the corresponding head and body blocks of a template
file.

The merging is done once at compile time - there are no repeated search
and replace operations each time the file is loaded, or server side
includes, so the resulting pages are quite fast.

Both the template and content files should be complete - there is no
need to write the content without a <head\> section, or leave out
<html\> tags. As a result both the content and template files can be
viewed as standalone documents.

The API:

template ( filename )

:   Function. Set the file name of the template to be used. If no path
    is specified file name will be relative to the current request
    directory

WebDyneTemplate

:   Directive. Can be used to supply the template file name in a Apache
    or lighttpd/FastCGI configuration file.

Example:

The template:

``` html
<html>

<head>
<block name="head" display="1">
<title>Template</title>
</block>
</head>

<body>

<table width="100%">

<tr>
<td colspan=2 bgcolor="green">
<span style="color:white;font-size:20px">Site Name</span>
</td>
</tr>

<tr>
<td bgcolor="green" width="100px">
<p>
Left
<p>
Menu
<p>
Here
</td>

<td bgcolor="white">

<!-- Content goes here -->
<block name="body" display="1">
This is where the content will go
</block>

</td>
</tr>

<tr>
<td colspan=2 bgcolor="green">
<span style="color:white">
<perl method="copyright">
Copyright (C) ${year} Foobar corp.
</perl>
</span>
</td>
</tr>


</table>

</body>
</html>

__PERL__
    
sub copyright {

    shift()->render(year=>((localtime)[5]+1900));

}
```

[Run](https://demo.webdyne.org/template1.psp)

The content, run to view resulting merge:

    <html>
    <head><title>Content 1</title></head>

    <body>
    This is my super content !
    </body>

    </html>

    __PERL__

    use WebDyne::Template qw(template1.psp);

[Run](https://demo.webdyne.org/content1.psp)

In real life it is not desirable to put the template name into every
content file (as was done in the above example), nor would we want to
have to "use WebDyne::Template" in every content file.

To overcome this WebDyne::Template can read the template file name using
the Apache dir_config function, and assign a template on a per location
basis using the WebDyneTemplate directive. Here is a sample `httpd.conf`
file:

    <Location />

    PerlHandler     WebDyne::Chain
    PerlSetVar      WebDyneChain    'WebDyne::Template'
    PerlSetVar      WebDyneTemplate '/path/to/template.psp'

    </Location>

# Credits

WebDyne relies heavily on modules and code developed and open-sourced by
other authors. Without Perl, and Perl modules such as mod_perl/PSGI,
HTML::Tiny, HTML::TreeBuilder, Storable and many other, WebDyne would
not be possible. To the authors of those modules - and all the other
modules used to a lesser extent by WebDyne - I convey my thanks.

# Miscellaneous

Things to note or information not otherwise contained elsewhere

How to check syntax on a PSP file

:   To check the syntax of a PSP file, specifically any Perl code in the
    \_\_PERL\_\_ section make sure you have a #!perl shebang after the
    \_\_PERL\_\_ delimiter as here:

    ``` html
    <start_html>
    Hello World <? server_time() ?>
    __PERL__
    #!perl

    sub server_time {
        my 2==1; #Error here
    }
    ```

    Then run the command `perl -x -c -w <filename.psp>`. This will check
    the file for syntax error and report back:

        $ perl -c -w -x check.psp 
        syntax error at check.psp line 4, near "my 2"
        check.psp had compilation errors.

How to pass \$self ref if using processing instructions

:   If you use the processing instruction form of calling a perl method
    it will not pass the WebDyne object ref through to your perl code.
    You can pass it by supplying \@\_ as a param, or just shift() and
    your parameters:

    ``` html
    <start_html>
    Hello World <? server_time(@_) ?>
    Hello World <? server_time(shift(), 'UTC' ?>
    Hello World <perl handler="server_time" param="UTC"/>
    __PERL__

    sub server_time {
        #  Now we can get self ref
        my ($self, $timezone)=@_;
        #  Do something and return
    }
    ```

Use of hash characters for comments in .psp files

:   Any \# characters at the very start of a PSP file before a <html\>
    or <start_html\> tag are treated as comments and discarded - they
    will not be stored or displayed (they are **not** translated into
    HTML comments). This allows easy to read comments at the start of
    .psp files. Any \# characters after the first valid tag are not
    treated specially - they will be rendered as normal HTML:

    ``` html
    #  This is my server time display file
    #  
    #  VERSION=1.23
    #
    <start_html>
    Server local time is: <? localtime ?>
    ```

The <checkbox\> tag will always set a hidden form field

:   The <checkbox\> tag is unusual in that it adds a hidden field (with
    the same name as the checkbox) to the HTML page to retain state.
    Thus if you are examining the checkbox parameter from CGI via
    `$_{'checkbox_name'}` or `$self->CGI->param('checkbox_name')` you
    may get an array rather than a single value. The value of the
    checkbox (boolean, checked or unchecked, i.e. 1 or 0) will always be
    the first value returned. So the code
    `if ($_{'checkbox_name'}) { .. do_something }` will work as
    expected - but just be careful if using in an array context.

# Legal Information - Licensing and Copyright

WebDyne is Copyright © Andrew Speer 2006-2025. WebDyne is free software;
you can redistribute it and/or modify it under the same terms as Perl
itself.

WebDyne is written in Perl and uses modules from
[CPAN](http://www.cpan.org) (the Comprehensive Perl Archive Network).
CPAN modules are Copyright © the owner/author, and are available in
source form by downloading from CPAN directly. All CPAN modules used are
covered by the [Perl Artistic
License](http://www.perl.com/pub/a/language/misc/Artistic.html)
