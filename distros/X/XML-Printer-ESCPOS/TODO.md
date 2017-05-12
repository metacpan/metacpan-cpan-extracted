# Improvement ideas for XML::Printer::ESCPOS

This document tries to summarize what needs to be done to make `XML::Printer::ESCPOS` a module that is easy to use.

## Implement Printer::ESCPOS methods

* font
* justify
* fontHeight
* fontWidth
* charSpacing
* lineSpacing
* selectDefaultLineSpacing
* printPosition
* leftMargin
* printNVImage
* printImage

The following methods could be implemented, but are not really content methods:

* cutPaper
* print

## Ideas for convenience functions

* Add special tag(s) for creating table-like prints. This could be useful for receipt printing, for example. It should contain automatic word wrapping or automatic cropping of long texts.
* Add horizontal line tag `<hr />`
* Set global values for `<utf8ImagedText>` attributes. This way we could omit setting the font for every line.

## Fix improvable implementations

### image

* The `<image>` tag currently only works with PNG files. This should be replaced by a function that checks for file extension to select import method. JPEG and GIF should be possible in addition to PNG.
* The `<image>` tag function contains a hacky workaround for problems with my printer: We send `->print()` before and after `->image()` to the printer object. In plain Printer::ESCPOS code this is not necessary. If it is not fixable, it maybe should be configurable by an `<image>` tag attribute.
* Write good tests for image tag.

## Documentation

Add documentation describing the XML structure to use. By now you can find examples in the test suite.

## SUPPORT AND BUGS

Please report any bugs or feature requests by opening an [issue on Github](https://github.com/sonntagd/XML-Printer-ESCPOS/issues).

## LICENSE AND COPYRIGHT

Copyright (C) 2017 Dominic Sonntag.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

http://www.perlfoundation.org/artistic_license_2_0
