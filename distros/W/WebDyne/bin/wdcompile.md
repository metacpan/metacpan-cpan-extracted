# wdcompile(1) #

# NAME #

`wdcompile` - parse and compile WebDyne pages

# SYNOPSIS #

`wdcompile [OPTIONS] FILE`

`wdcompile --stage0 time.psp`

# Description #

The  `wdcompile`  command displays the internal data structure used by WebDyne when compiling psp pages.

WebDyne uses the same parsing and compilation routines as `wdcompile` . After compilation WebDyne optionally stores the resulting data structure to a cache directory using the Perl `Storable`  module to speed up subsequent rendering operations.

If the tree structure does not appear correct when debugging with `wdcompile`  then it will probably not display as expected when rendered with WebDyne. Missing end quotes, closing tags and general
 HTML syntax problems can all make the parse tree misplace \(or omit
 completely) blocks of HTML/WebDyne code.

By default  `wdcompile`  will show the data structure after all parsing and optimisation stages have been completed. You can
 display various intermediate stages using the options below.

# Options #

* **-h, --help**

    Show brief help message.

* **--stage0 | -0**

    Compile to stage 0. This the first parse of the source file and has no optimisations.

* **--stage1 | -1**

    Compile to stage 1. Metadata is added to the data structure.

* **--stage2 | -2**

    Compile to stage 2. Any WebDyne Filters are applied.

* **--stage3 | -3**

    Compile to stage 3. First optimisation is performed.

* **--stage4 | -4**

    Compile to stage 4. Second optimisation is run

* **--stage5 | --final | -5**

    Compile to stage 5. Final data structure

* **--meta | -m**

    Only show the metadata of the compiled page. This is the manifest or attributes held in  `<meta>`  sections with the name &quot;WebDyne&quot; \(used to alter WebDyne behaviour). If found such meta data is removed from the resulting
 HTML parse tree and stored in a separate data structure. This
 option will show that data structure if it exists.

* **--data**

    Only show the data structure of the compiled page.

* **--nomanifest**

    Do not generate or store a manifest in the compiled page. The manifest contains the path to the source file(s), and is
 stored in the metadata area.

* **--dest | --dest_fn**

    Specify a destination file for the compiled page, with data stored in Perl Storable format. Once saved it can be reviewed
 later with the  `wddump`  command

* **--all**

    Show all data in the compiled page

* **--timestamp**

    Include a timestamp

* **--version**

    Display the script version and exit

* **--man**

    Display this man page

# Examples #

```sh
# Show the compiled version of the time.psp page with all optimisations.
wdcompile time.psp
```

Compile and display the completed internal WebDyne data structure of the file called time.psp. The resulting output shows the data structure
 after the file is parsed, then rebuilt around any dynamic WebDyne
 tags.

```sh
#  Show the compiled version of time.psp as the early HTML tree
wdcompile --stage0 widget.psp
```

Parse and display the very data structure of the time.psp file at the lowest level \- as interpreted by the HTML::Treebuilder module, with no
 optimisation at all.

# Notes #

The wdcompile will not run any code in the  `__PERL__`  section of a psp file. It will also not execute any WebDyne filters that may be called by the source file.

# Author #

Written by Andrew Speer,  <andrew@webdyne.org>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright \(c) 2025 by Andrew Speer &lt;andrew.speer@isolutions.com.au&gt;.

This is free software; you can redistribute it and/or modify it underthe same terms as the Perl 5 programming language system itself.

Full license text is available at:

&lt;http://dev.perl.org/licenses/&gt;