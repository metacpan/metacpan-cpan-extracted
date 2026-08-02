# WebDyne::Template #

# NAME #

WebDyne::Template - wrapper-template module for embedding WebDyne page output

# SYNOPSIS #

```perl
__PERL__
use WebDyne::Template 'layout.psp';
```

# DESCRIPTION #

`WebDyne::Template` is a chaining and filter module that compiles a wrapper template page and inserts the current page output into named blocks inside that template.

When imported from a page `__PERL__` block, it switches the page to `WebDyne::Chain`, registers itself as both a chain component and filter, and stores the nominated template name in page metadata.

# METHODS #

* **template()**

    Resolve the active template filename from page metadata or `dir_config('WebDyneTemplate')`.

* **source_mtime($srce_mtime)**

    Return the later of the content-page and template modification times so cache staleness checks account for both files.

* **filter($self, $data_content_ar, $meta_content_hr)**

    Main template-composition routine. Compiles the template, merges metadata, and inserts the content page into the template’s named blocks.

* **handler($self, $r, @param)**

    Internal chaining entry point that enables this module as the active filter.

# NOTES #

Template paths may be supplied as absolute paths or as filenames relative to the current page working directory.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
