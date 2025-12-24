# wdcompile(1) #

# NAME #

wdcompile - parse and display internal data representation of WebDyne files

# SYNOPSIS #

`wdcompile [OPTIONS] FILE`

# Description #

The  `wdcompile`  command displays internal compiled \(Storable) representation of a \.psp page using the WebDyne perl module.

WebDyne parses HTML into an intermediate format which is then stored to disk to speed up subsequent rendering of pages. It is dependent on HTML::Treebuilder and HTML::Parser modules to build the tree, and results are stored to disk in a data array format via the Storable module.

The parser may build incorrect representations on a HTML tree if the HTML is badly formed or there are errors in the WebDyne compiler itself. This utility is useful for diagnosing any such errors.

The parser interprets files in 3 main stages \(and some lesser intermediate stages that do not impact data structure but are used in the test suites): a full HTML::TreeBuilder representation of all tags with no optimisation, an intermediate partial optimisation stage that re-renders tags with no dynamic components \(e.g. no &lt;perl&gt; or similar tags) back into
 static HTML and a final fully optimised file that should only contain a data structure for dynamic components of the page.

The final data structure contains various artifacts used by the render engine such as a manifest section, and notation of line numbers for dynamic sections to aid in error display and source file tracebacks should an error occur in any dynamic code at render time.

# Options #

* **-h, --help**

    Show brief help message.

* **--meta**

    Show just the file metadata in compile output

* **--data**

    Show just the file data structure in compile output, no meta data. This is the default

* **--all**

    Show both the file meta and core data in output

* **--[no]manifest**

    Do/do not populate the filename into the metadata manifest section. Only used in test suite.

* **--[no]timestamp**

    Do/do not populate the timestamp into the metadata manifest section. Only used in test suite.

* **--[no]perl**

    Do/do not run Perl in \__PERL__ section at compile time. The default is to not run any Perl sections.

* **--[no]filter**

    Do/do not run any filter stages that may be nominated in the file.

* **--outfile**

    Specify the output file to save the Storable representation of the data.

* **--repeat | --r | --num | --n**

    Specify the number of times to repeat the compile. Used for consistency testing

* **--stage[n]|stage0|stage1|stage2|stage3|stage4|stage5|final**

    Stop at a certain stage of the compile process. The default is to compile to final representation. The most significant intermediate stages are stage 0 for the raw tree, stage 4 for the first intermediate compile optimisation and stage 5 \(final) for final optimisation.

* **--man**

    Display the full manual.

* **--version**

    Display the script version and exit.

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
 etc.) and wdcompile is still producing a malformed tree you can submit a big report with the smallest possible HTML file needed to replicate the issue.

# Author #

Written by Andrew Speer,  <andrew@webdyne.org>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright \(c) 2025 by Andrew Speer &lt;andrew.speer@isolutions.com.au&gt;.

This is free software; you can redistribute it and/or modify it underthe same terms as the Perl 5 programming language system itself.

Full license text is available at:

&lt;http://dev.perl.org/licenses/&gt;