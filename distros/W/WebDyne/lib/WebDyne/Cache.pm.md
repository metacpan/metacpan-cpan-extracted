# WebDyne::Cache #

# NAME #

WebDyne::Cache - WebDyne module to cache dynamic output for improved performance.

# SYNOPSIS #

```
#  Sample time.psp compiled to cached HTML. Every time this page is requested it will show
#  the same time unless an interval of more than 10 seconds has elapsed.
#
<start_html>
The most recent time this page was run was <? localtime ?>
__PERL__
use WebDyne::Cache (\&cache);

sub cache {
    
    #  Self ref
    #
    my $self=shift();

    #  Get file last modified time (mtime)
    #
    my $mtime=${ $self->cache_mtime() };

    #  If older than 10 seconds force recompile
    #
    if ((time()-$mtime) > 10) { 
        $self->cache_compile(1) 
    };

    #  Done
    #
    return 1;

}
```

# DESCRIPTION #

The WebDyne::Cache module works in conjunction with the WebDyne::Static module to allow less frequent running of dynamic code, speeding up responsiveness for CPU or I/O heavy pages.

The WebDyne framework will continue to monitor for changes in the source file and recompile if the source \.psp file is updated, regardless of the response of any caching directive.

`use WebDyne::Cache ...` is intended to be called from within a WebDyne page `__PERL__` block. When imported successfully it marks the page as static and stores the nominated cache callback in page metadata.

# USAGE #

The WebDyne::Cache code must be invoked in the requested page via one of the following methods:

1. Via use of the WebDyne::Cache module, supplying a code ref as an import parameter as in the synopsis:

```
<start_html>
...
__PERL__
use WebDyne::Cache qw(\&cache);
sub cache {
...
```

The import parser also accepts a named form such as:

```perl
use WebDyne::Cache cache => \&cache;
```

2. Via use of the meta-data field, with supply of the code ref in the &lt;head&gt; section of the document, e.g.

```
<start_html meta="%{ 'WebDyne' => 'cache=&cache' }">
...
__PERL__
sub cache {
...
```

    Or:

```
<html>
<head>
<title>Cache Demo</title>
<meta name="WebDyne" content="cache=&cache">
</head>
<body>
...
__PERL__
sub cache {
...
```

3. Via use of the cache attribute in the start_html tag:

```
<start_html cache="&cache">
...
__PERL__
sub cache {
...
```

In all cases the routine must flag to the WebDyne engine that the page should be recompiled. After whatever logic is required to make that determination \(time elapsed, user input etc.) it should call the cache_compile() method with a true value to flag recompilation is required.

# METHODS #

Methods below are not actually specific to the WebDyne::Cache module \(they are presented by the main WebDyne module), but are listed here for convenience:

* **cache_mtime()**

    Return a scalar ref of the cache file modification time in Unix epoch seconds.

* **cache_compile()**

    Flag that page recompilation is required by supplying a true value.

* **inode()**

    Get or set the UUID for a page. See Notes for usage in context of caching

* **handler()**

    Internal chaining handler used when the module is inserted into the WebDyne handler pipeline. It reads the cache handler name from `WebDyneCacheHandler`, marks the page static, and passes control back to the main WebDyne handler flow.

# OPTIONS #

WebDyne::Cache takes a single subroutine reference as an import parameter. No other options are available

# NOTES #

Pages are cached to static HTML via their inode \(UUID) value. You can change the inode value in the cache code \(usually according to an input parameter) to generate multiple cached versions of a single page, e.g.

```
<start_html cache="&cache">
<start_form>
<popup_menu name="month" values="@{qw(Jan Feb Mar)}">
<submit>
__PERL__
sub cache {
    my $self=shift();
    ... some tests ..
    $self->inode($_{'month'});
    $self->cache_compile(1) if <...something..>
    return 1;
}

    return 
```

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au> and contributors.

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright \(c) 2026 by Andrew Speer &lt;andrew.speer@isolutions.com.au&gt;.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

Full license text is available at:

&lt;http://dev.perl.org/licenses/&gt;
