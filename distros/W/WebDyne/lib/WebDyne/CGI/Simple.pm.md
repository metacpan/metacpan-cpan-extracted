# WebDyne::CGI::Simple #

# NAME #

WebDyne::CGI::Simple - CGI-style parameter wrapper used by WebDyne request handling

# SYNOPSIS #

```perl
use WebDyne::CGI::Simple;

my $cgi = WebDyne::CGI::Simple->new($request);
my $name = $cgi->param('name');
my $uploads = $cgi->uploads();
```

# DESCRIPTION #

`WebDyne::CGI::Simple` is the concrete CGI-style parameter object used by WebDyne. It subclasses `CGI::Simple`, adapts request-body parsing to WebDyne request objects, and adds a few compatibility helpers so the result behaves more like modern PSGI request parameter and upload APIs.

It is normally created indirectly through `$self->CGI()` or `WebDyne::CGI`.

# METHODS #

* **new($request, %param)**

    Construct a CGI-style parameter object from a WebDyne request object.

* **Vars()**

    Return a `Hash::MultiValue` object of all current parameters. When called with an argument, replace the current parameter set from the supplied multivalue object.

* **env()**

    Return the current `%ENV` as a hash reference.

* **upload()**

    Delegate file-upload access to `CGI::Simple` with multipart handling forced on.

* **uploads()**

    Return a `Hash::MultiValue` mapping parameter names to upload wrapper objects.

# UPLOAD OBJECTS #

The module also provides `WebDyne::CGI::Simple::Upload`, a lightweight upload wrapper with methods:

* **filename()**
* **basename()**
* **size()**
* **content_type()**
* **content()**
* **fh()**
* **path()**

# NOTES #

Upload allowance and maximum POST size are controlled by `WEBDYNE_CGI_DISABLE_UPLOADS` and `WEBDYNE_CGI_POST_MAX`.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
