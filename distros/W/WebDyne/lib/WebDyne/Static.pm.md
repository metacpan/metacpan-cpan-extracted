# WebDyne::Static(3pm) #

# NAME #

WebDyne::Static - WebDyne module to flag pages as static and compile once to
    HTML

# SYNOPSIS #

```
#  Sample time.psp compiled to static HTML. Every time this page is requested it will show
#  the same time
#
<start_html>
This page was first loaded at <? localtime ?>
__PERL__
use WebDyne::Static;
```

# Description #

The WebDyne::Static module will flag that all dynamic components of a page should be run at compile time, and the resulting HTML saved as a
 static file which will be served on subsequent requests.

The WebDyne framework will monitor for changes in the source file and recompile to a new HTML if the source \.psp file is updated.

# Methods #

* **static()**

    Get or set the static attribute for this page. When setting the static attribute for a page it is only set for that instance of
 the page. To set a page as permanently static \(except on source file
 update) use the WebDyne::Static module as per synopsis, or update
 the meta data via $self-&gt;meta-&gt;{&#39;static&#39;}=1;

# Options #

WebDyne::Static does not expose any options to the import function when called via use.

# Author #

Andrew Speer &lt;andrew.speer@isolutions.com.au&gt; and contributors.

# License #

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See  [https://dev.perl.org/licenses/](https://dev.perl.org/licenses/) .