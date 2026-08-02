# WebDyne::CGI #

# NAME #

WebDyne::CGI - Provides abstracted access to GET and POST parameters and file upload objects.

# SYNOPSIS #

```
#  Get form responses
#
<start_html>
<start_form>
...
<perl handler>
...
__PERL__
sub handler {

    #  WebDyne object ref passed as first option
    #
    my $self=shift();

    #  Get abstracted CGI object
    #
    my $cgi_or=$self->CGI();

    #  All parameter names
    #
    my @param=$cgi_or->param();

    #  Single param value, same as $_{'name'}
    #
    my $name=$cgi_or->param('name');

    #  Multiple param values, if supplied
    #
    my @name=$cgi_or->param('name');

    #  Hash::MultiValue reference of files uploaded
    # 
    my $uploads_hr=$cgi_or->uploads();

    #  Hash::MultiValue reference of all parameter name/value(s) pairs
    #
    my $param_hr=$cgi_or->Vars();
```

# DESCRIPTION #

The  `WebDyne::CGI`  module provides an abstracted object reference to CGI style form parameters supplied as GET or POST responses to a form or other methodology. It is normally accessed through the main WebDyne object with:

```perl
my $cgi_or = $self->CGI();
```

Internally it constructs and caches a `WebDyne::CGI::Simple` object for the current request.

It attempts to abstract the different ways of getting parameter values from different request handlers \(Apache mod_perl, Plack PSGI, PAGI, and the fake request handler used for script rendering) into a uniform object.

It makes use of the `WebDyne::CGI::Simple` wrapper, which in turn builds on `CGI::Simple`, and many of the method calls are identical.

# METHODS #

The following notable methods are made available from the WebDyne::CGI module:

* **Vars()**

    Return a Hash::MultiValue reference of all name/value pairs.

* **env()**

    Returns a hash reference of the current Environment.

* **uploads()**

    Return an object reference to uploaded file data that mimics as Plack::Request::Upload object

* **param(<name>)**

    When called in a scalar context return a single value of a names parameter. When called in an array context return all values if a multi-value parameter item.

* **param(name, value, <value> ..)**

    Set the parameter value \(or values) for a named parameter.

* **delete(name)**

    Delete the entire parameter \(and all values) from the CGI object

* **delete_all()**

    Delete all parameters from the CGI object

* **uploads()**

    Return a Hash::MultiValue reference consisting of name/value pairs of file upload objects that mimic Plack::Request::Upload references.

Most other methods from CGI::Simple are also supported, including utility methods such as url_encode(), url_decode() etc.

# OPTIONS #

`WebDyne::CGI` does not expose import-time options of its own. Request parsing behaviour is influenced by the following `WebDyne::Constant` values:

* `$WEBDYNE_CGI_DISABLE_UPLOADS`

* `$WEBDYNE_CGI_POST_MAX`

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au> and contributors.

# LICENSE #

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See  [https://dev.perl.org/licenses/](https://dev.perl.org/licenses/) .
