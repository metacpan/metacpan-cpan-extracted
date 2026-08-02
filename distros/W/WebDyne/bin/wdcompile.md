# wdcompile #

# NAME #

wdcompile - parse and display internal data representation of WebDyne files

# SYNOPSIS #

`wdcompile [OPTIONS] FILE`

# Description #

The  `wdcompile`  command compiles a \.psp page with the WebDyne perl module and displays the resulting internal Perl data structure using `Data::Dumper`.

WebDyne parses HTML into an intermediate format which can then be stored to disk to speed up subsequent rendering of pages. It is dependent on HTML::TreeBuilder and HTML::Parser modules to build the tree, and the compiler produces a container of metadata plus compiled page data.

The parser may build incorrect representations on a HTML tree if the HTML is badly formed or there are errors in the WebDyne compiler itself. This utility is useful for diagnosing any such errors.

The parser interprets files in 3 main stages \(and some lesser intermediate stages that do not impact data structure but are used in the test suites): a full HTML::TreeBuilder representation of all tags with no optimisation, an intermediate partial optimisation stage that re-renders tags with no dynamic components \(e.g. no &lt;perl&gt; or similar tags) back into static HTML and a final fully optimised file that should only contain a data structure for dynamic components of the page.

The final data structure contains various artifacts used by the render engine such as a manifest section, and notation of line numbers for dynamic sections to aid in error display and source file tracebacks should an error occur in any dynamic code at render time.

By default the command prints the compiled page data section only. `--meta` prints only the metadata section, and `--all` prints the full two-element container.

# Options #

* **--help**

    Show brief help message.

* **--meta**

    Show only the metadata section of the compiled container.

* **--data**

    Show only the compiled page data section. This is the default output mode.

* **--all**

    Show the full compiled container, including both metadata and compiled page data.

* **--test**

    Use WebDyne's built-in default test page as the source file.

* **--manifest**

    Enable or disable population of the source filename in the metadata manifest section. Manifest output is enabled by default.

* **--timestamp**

    Enable or disable compile timestamps in metadata. Timestamps are disabled by default.

* **--perl**

    Enable or disable execution of Perl in \__PERL__ sections at compile time. Perl execution is disabled by default.

* **--filter**

    Enable or disable compile-time filter stages nominated in the file. Filters are disabled by default.

* **--head_insert**

    Enable or disable WebDyne head insertion while compiling from the command line, including configured `WEBDYNE_HEAD_INSERT` content and related `start_html` parameters. This is disabled by default so diagnostic compile output is not changed by runtime head additions normally intended for Apache, PSGI, or PAGI request handling.

* **--outfile**

    Intended to specify a destination file for the compiled Storable cache. In the current `wdcompile` script this option is parsed but not wired through to the compiler's `dest` parameter, so it does not currently write an output file.

* **--repeat=NUM**

    Specify the number of times to repeat the compile. Used for consistency testing.

* **--stage0**

    Stop after parsing into the initial container representation.

* **--stage1**

    Stop after compile-time Perl processing.

* **--stage2**

    Stop after compile-time filter processing.

* **--stage3**

    Stop after the first optimisation pass.

* **--stage4**

    Stop after the second optimisation pass.

* **--stage5**

    Stop at the final compiled container representation. This is the default.

* **--dump_opt**

    Dump the parsed option hash for debugging and exit.

* **--man**

    Display the full manual.

* **--version**

    Display the script version and WebDyne version, then exit.

# Examples #

```sh
# Reference file saved as time.psp
#
<start_html>
The current server time is: <? localtime() ?>

```

```sh
# Show the final compiled data structure of time.psp
#
$ wdcompile time.psp

$VAR1 = [
  '<!DOCTYPE html><html lang="en"><head><title>Untitled Document</title><meta charset="UTF-8"><meta content="width=device-width, initial-scale=1.0" name="viewport"></head>
<body><p>The current server time is: ',
  [
    'perl',
    {
      'inline' => 1,
      'perl' => ' localtime() '
    },
    undef,
    undef,
    2,
    2,
    \'time.psp'
  ],
  '</p></body></html>'
];

```

```sh
# Show the initial compiled data structure (stage 0) of the time.psp file including metadata
#
$ wdcompile --all --stage0 time.psp

$VAR1 = [
  {
    'manifest' => [
      'time.psp'
    ]
  },
  [
    'html',
    {
      'lang' => 'en'
    },
    [
      [
        'head',
        undef,
        [
          [
            'title',
            undef,
            [
              'Untitled Document'
            ],
            undef,
            1,
            1,
            \$VAR1->[0]{'manifest'}[0]
            ...

```

# Notes #

The  `wdcompile`  command will attempt to build the HTML tree as faithfully as possible from the command line environment, but may not be able to interpret all HTML files, especially those with malformed HTML tags. It is reliant on HTML::TreeBuilder and HTML::Parser. If you are sure your HTML is compliant \(all tags closed, all attributes double quoted
 etc.) and wdcompile is still producing a malformed tree you can submit a bug report with the smallest possible HTML file needed to replicate the issue.

# Author #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright \(c) 2026 by Andrew Speer &lt;andrew.speer@isolutions.com.au&gt;.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

Full license text is available at:

&lt;http://dev.perl.org/licenses/>;
