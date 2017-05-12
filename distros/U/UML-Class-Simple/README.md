# NAME

UML::Class::Simple - Render simple UML class diagrams, by loading the code

Table of Contents
=================

* [NAME](#name)
* [VERSION](#version)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [SAMPLE OUTPUTS](#sample-outputs)
* [SUBROUTINES](#subroutines)
* [METHODS](#methods)
* [PROPERTIES](#properties)
* [INSTALLATION](#installation)
* [LIMITATIONS](#limitations)
* [TODO](#todo)
* [BUGS](#bugs)
* [ACKNOWLEDGEMENT](#acknowledgement)
* [SOURCE CONTROL](#source-control)
* [AUTHORS](#authors)
* [COPYRIGHT](#copyright)
* [SEE ALSO](#see-also)

# VERSION

This document describes `UML::Class::Simple` 0.22 released by 18 December 2016.

# SYNOPSIS

    use UML::Class::Simple;

    # produce a class diagram for Alias's PPI
    # which has already installed to your perl:

    @classes = classes_from_runtime("PPI", qr/^PPI::/);
    $painter = UML::Class::Simple->new(\@classes);
    $painter->as_png('ppi.png');

    # produce a class diagram for your CPAN module on the disk

    @classes = classes_from_files(['lib/Foo.pm', 'lib/Foo/Bar.pm']);
    $painter = UML::Class::Simple->new(\@classes);

    # we can explicitly specify the image size
    $painter->size(5, 3.6); # in inches

    # ...and change the default title background color:
    $painter->node_color('#ffffff'); # defaults to '#f1e1f4'

    # only show public methods and properties
    $painter->public_only(1);

    # hide all methods from parent classes
    $painter->inherited_methods(0);

    $painter->as_png('my_module.png');

# DESCRIPTION

`UML::Class::Simple` is a Perl CPAN module that generates UML class
diagrams (PNG format, GIF format, XMI format, or dot source) automatically
from Perl 5 source or Perl 5 runtime.

Perl developers can use this module to obtain pretty class diagrams
for arbitrary existing Perl class libraries (including modern perl OO
modules based on Moose.pm), by only a single command. Companies can
also use the resulting pictures to visualize the project hierarchy and
embed them into their documentation.

The users no longer need to drag a mouse on the screen so as to draw
figures themselves or provide any specs other than the source code of
their own libraries that they want to depict. This module does all the
jobs for them! :)

Methods created on-the-fly (in BEGIN or some such) can be inspected. Accessors created by modules [Class::Accessor](https://metacpan.org/pod/Class::Accessor), [Class::Accessor::Fast](https://metacpan.org/pod/Class::Accessor::Fast), and
[Class::Accessor::Grouped](https://metacpan.org/pod/Class::Accessor::Grouped) are recognized as "properties" rather than "methods". Intelligent distingishing between Perl methods and properties other than that is not provided.

You know, I was really impressed by the outputs of [UML::Sequence](https://metacpan.org/pod/UML::Sequence), so I
decided to find something to (automatically) get pretty class diagrams
too. The images from [Autodia](https://metacpan.org/pod/Autodia)'s Graphviz backend didn't quite fit my needs
when I was making some slides for my presentations.

I think most of the time you just want to use the command-line utility
[umlclass.pl](https://metacpan.org/pod/umlclass.pl) offered by this module (just like me). See the
documentation of [umlclass.pl](https://metacpan.org/pod/umlclass.pl) for details.

[Back to TOC](#table-of-contents)

# SAMPLE OUTPUTS

- PPI

    [https://raw.githubusercontent.com/agentzh/uml-class-simple-pm/master/samples/ppi\_small.png](https://raw.githubusercontent.com/agentzh/uml-class-simple-pm/master/samples/ppi_small.png)

    <div>
            <img src="https://raw.githubusercontent.com/agentzh/uml-class-simple-pm/master/samples/ppi_small.png">
    </div>

    (See also `samples/ppi_small.png` in the distribution.)

- Moose

    [https://raw.githubusercontent.com/agentzh/uml-class-simple-pm/master/samples/moose\_small.png](https://raw.githubusercontent.com/agentzh/uml-class-simple-pm/master/samples/moose_small.png)

    <div>
            <img src="https://raw.githubusercontent.com/agentzh/uml-class-simple-pm/master/samples/moose_small.png">
    </div>

    (See also `samples/moose_small.png` in the distribution.)

- FAST

    [https://raw.githubusercontent.com/agentzh/uml-class-simple-pm/master/samples/fast.png](https://raw.githubusercontent.com/agentzh/uml-class-simple-pm/master/samples/fast.png)

    <div>
            <img src="https://raw.githubusercontent.com/agentzh/uml-class-simple-pm/master/samples/fast.png">
    </div>

    (See also `samples/fast.png` in the distribution.)

[Back to TOC](#table-of-contents)

# SUBROUTINES

- classes\_from\_runtime($module\_to\_load, $regex?)
- classes\_from\_runtime(\\@modules\_to\_load, $regex?)

    Returns a list of class (or package) names by inspecting the perl runtime environment.
    `$module_to_load` is the _main_ module name to load while `$regex` is
    a perl regex used to filter out interesting package names.

    The second argument can be omitted.

- classes\_from\_files($pmfile, $regex?)
- classes\_from\_files(\\@pmfiles, $regex?)

    Returns a list of class (or package) names by scanning through the perl source files
    given in the first argument. `$regex` is used to filter out interesting package names.

    The second argument can be omitted.

- exclude\_by\_paths

    Excludes package names via specifying one or more paths where the corresponding
    modules were installed into. For example:

        @classes = exclude_by_paths(\@classes, 'C:/perl/lib');

        @classes = exclude_by_paths(\@classes, '/home/foo', '/System/Library');

- grep\_by\_paths

    Filters out package names via specifying one or more paths where the corresponding
    modules were installed into. For instance:

        @classes = grep_by_paths(\@classes, '/home/malon', './blib/lib');

All these subroutines are exported by default.

[Back to TOC](#table-of-contents)

# METHODS

- `$obj->new( [@class_names] )`

    Create a new `UML::Class::Simple` instance with the specified class name list.
    This list can either be constructed manually or by the utility functions
    `classes_from_runtime` and `classes_from_files`.

- `$obj->as_png($filename?)`

    Generate PNG image file when `$filename` is given. It returns
    binary data when `$filename` is not given.

- `$obj->as_svg($filename?)`

    Generate SVG image file when `$filename` is given. It returns
    binary data when `$filename` is not given.

- `$obj->as_gif($filename?)`

    Similar to `as_png`, bug generate a GIF-format image. Note that, for many graphviz installations, `gif` support is disabled by default. So you'll probably see the following error message:

        Format: "gif" not recognized. Use one of: bmp canon cmap cmapx cmapx_np
            dia dot fig gtk hpgl ico imap imap_np ismap jpe jpeg jpg mif mp
            pcl pdf pic plain plain-ext png ps ps2 svg svgz tif tiff vml
            vmlz vtx xdot xlib

- `$obj->as_dom()`

    Return the internal DOM tree used to generate dot and png. The tree's structure
    looks like this:

        {
          'classes' => [
                         {
                           'subclasses' => [],
                           'methods' => [],
                           'name' => 'PPI::Structure::List',
                           'properties' => []
                         },
                         {
                           'subclasses' => [
                                             'PPI::Structure::Block',
                                             'PPI::Structure::Condition',
                                             'PPI::Structure::Constructor',
                                             'PPI::Structure::ForLoop',
                                             'PPI::Structure::Unknown'
                                           ],
                           'methods' => [
                                          '_INSTANCE',
                                          '_set_finish',
                                          'braces',
                                          'content',
                                          'new',
                                          'refaddr',
                                          'start',
                                          'tokens'
                                        ],
                           'name' => 'PPI::Structure',
                           'properties' => []
                         },
                         ...
                      ]
        }

    You can adjust the data structure and feed it back to `$obj` via
    the `set_dom` method.

- `$obj->set_dom($dom)`

    Set the internal DOM structure to `$obj`. This will be used to
    generate the dot source and thus the PNG/GIF images.

- `$obj->as_dot()`

    Return the Graphviz dot source code generated by `$obj`.

- `$obj->set_dot($dot)`

    Set the dot source code used by `$obj`.

- `$obj->as_xmi($filename)`

    Generate XMI model file when `$filename` is given. It returns
    XML::LibXML::Document object when `$filename` is not given.

- `can_run($path)`

    Copied from [IPC::Cmd](https://metacpan.org/pod/IPC::Cmd) to test if $path is a runnable program. This code
    is copyright by IPC::Cmd's author.

- `$prog = $obj->dot_prog()`
- `$obj->dot_prog($prog)`

    Get or set the dot program path.

[Back to TOC](#table-of-contents)

# PROPERTIES

- `$obj->size($width, $height)`
- `($width, $height) = $obj->size`

    Set/get the size of the output images, in inches.

- `$obj->public_only($bool)`
- `$bool = $obj->public_only`

    When the `public_only` property is set to true, only public methods or properties
    are shown. It defaults to false.

- `$obj->inherited_methods($bool)`
- `$bool = $obj->inherited_methods`

    When the `inherited_methods` property is set to false, then all methods,
    inherited from parent classes, are not shown.
    It defaults to true.

- `$obj->node_color($color)`
- `$color = $obj->node_color`

    Set/get the background color for the class nodes. It defaults to `'#f1e1f4'`.

- `$obj->moose_roles($bool)`

    When this property is set to true values, then relationships between Moose::Role packages and their consumers
    will be drawn in the output. Default to false.

- `$obj->display_methods($bool)`

    When this property is set to false, then class methods will not be shown in the output. Default to true.

- `$obj->display_inheritance($bool)`

    When this property is set to false, then the class inheritance relationship
    will not be drawn in the output. Default to false.

[Back to TOC](#table-of-contents)

# INSTALLATION

Please download and intall a recent Graphviz release from its home:

[http://www.graphviz.org/](http://www.graphviz.org/)

`UML::Class::Simple` requires the HTML label feature which is only
available on versions of Graphviz that are newer than mid-November 2003.
In particular, it is not part of release 1.10.

Add Graphviz's `bin/` path to your PATH environment. This module needs its
`dot` utility.

Grab this module from the CPAN mirror near you and run the following commands:

    perl Makefile.PL
    make
    make test
    make install

For windows users, use `nmake` instead of `make`.

Note that it's recommended to use the `cpan` utility to install CPAN modules.

[Back to TOC](#table-of-contents)

# LIMITATIONS

- It's pretty hard to distinguish perl methods from properties (actually they're both
implemented by subs in perl). Currently only accessors created by [Class::Accessor](https://metacpan.org/pod/Class::Accessor), [Class::Accessor::Fast](https://metacpan.org/pod/Class::Accessor::Fast), and [Class::Accessor::Grouped](https://metacpan.org/pod/Class::Accessor::Grouped) are provided. (Thanks to the patches from Adam Lounds and Dave Howorth!) If you have any other good idea on this issue, please drop me a line ;)
- Only the inheritance relationships are shown in the images. I believe
other subtle
relations may mess up the Graphviz layouter. Hence the "::Simple" suffix in
this module name.
- Unlike [Autodia](https://metacpan.org/pod/Autodia), at this moment only Graphviz and XMI backends are provided.
- There's no way to recognize _real_ perl classes automatically. After all, Perl 5's
classes are implemented by packages. I think Perl 6 will make my life much easier.
- To prevent potential naming confusion. I'm using Perl's `::` namespace
separator
in the class diagrams instead of dot (`.`) chosen by the UML standard.
One can argue that following UML standards is more important since people
in the same team may
use different programming languages, but I think it's not the case for
the majority (including myself) ;-)

[Back to TOC](#table-of-contents)

# TODO

- Add more unit tests.
- Add support for more image formats, such as `as_ps`, `as_jpg`, and etc.
- Plot class relationships other than inheritance on the user's request.
- Provide backends other than Graphviz.

Please send me your wish list by emails or preferably via the CPAN RT site.
I'll add them here or even implement them promptly if I'm also interested
in your (crazy) ideas. ;-)

[Back to TOC](#table-of-contents)

# BUGS

There must be some serious bugs lurking somewhere;
if you found one, please report
it to [http://rt.cpan.org](http://rt.cpan.org) or contact the author directly.

[Back to TOC](#table-of-contents)

# ACKNOWLEDGEMENT

I must thank Adam Kennedy (Alias) for writing the excellent [PPI](https://metacpan.org/pod/PPI) and
[Class::Inspector](https://metacpan.org/pod/Class::Inspector) modules. [umlclass.pl](https://metacpan.org/pod/umlclass.pl) uses the former to extract
package names from user's `.pm` files or the latter to retrieve the function list of a
specific package.

I'm also grateful to Christopher Malon since he has (unintentionally)
motivated me to turn the original hack into this CPAN module. ;-)

[Back to TOC](#table-of-contents)

# SOURCE CONTROL

You can always grab the latest version from the following GitHub
repository:

[https://github.com/agentzh/uml-class-simple-pm](https://github.com/agentzh/uml-class-simple-pm)

It has anonymous access to all.

If you have the tuits to help out with this module, please let me know.
I have a dream to keep sending out commit bits like Audrey Tang. ;-)

[Back to TOC](#table-of-contents)

# AUTHORS

Yichun "agentzh" Zhang (章亦春) `<agentzh@gmail.com>`, OpenResty Inc.

Maxim Zenin `<max@foggy.ru>`.

[Back to TOC](#table-of-contents)

# COPYRIGHT

Copyright (c) 2006-2016 by Yichun Zhang (章亦春), OpenResty Inc.
Copyright (c) 2007-2014 by Maxim Zenin.

This library is free software; you can redistribute it and/or modify it under
the same terms as perl itself, either Artistic and GPL.

[Back to TOC](#table-of-contents)

# SEE ALSO

[umlclass.pl](https://metacpan.org/pod/umlclass.pl), [Autodia](https://metacpan.org/pod/Autodia), [UML::Sequence](https://metacpan.org/pod/UML::Sequence), [PPI](https://metacpan.org/pod/PPI), [Class::Inspector](https://metacpan.org/pod/Class::Inspector), [XML::LibXML](https://metacpan.org/pod/XML::LibXML).

[Back to TOC](#table-of-contents)

