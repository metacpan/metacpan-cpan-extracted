# XML::Printer::ESCPOS

[![Build Status](https://travis-ci.org/sonntagd/XML-Printer-ESCPOS.svg?branch=master)](https://travis-ci.org/sonntagd/XML-Printer-ESCPOS) [![Coverage Status](https://coveralls.io/repos/github/sonntagd/XML-Printer-ESCPOS/badge.svg?branch=master)](https://coveralls.io/github/sonntagd/XML-Printer-ESCPOS?branch=master)


## DESCRIPTION

This module provides a markup language that describes what your ESCPOS printer should do. It works on top of the great and easy to use [Printer::ESCPOS](https://metacpan.org/pod/Printer::ESCPOS). Now you can save your printer output in an XML file and you can write templates to be processed by Template Toolkit or the template engine of your choice.

## SYNOPSIS

```perl
use Printer::ESCPOS;
use XML::Printer::ESCPOS;

# connect to your printer, see Printer::ESCPOS for more examples
my $device = Printer::ESCPOS->new(
    driverType => 'Network',
    deviceIp   => '192.168.0.10',
    devicePort => 9100,
);

my $parser = XML::Printer::ESCPOS->new(printer => $device->printer);
$parser->parse(q#
<escpos>
    <bold>bold text</bold>
    <underline>underlined text</underline>
</escpos>
#) or die "Error parsing ESCPOS XML file: ".$parser->errormessage;

$device->printer->cutPaper();
$device->printer->print();
```

## HOW TO WRITE ESCPOS XML FILES

The XML file should be enclosed in `<escpos>` ... `</escpos>` tags.


## TODO

See the separate ToDo list [here](TODO.md).

## INSTALLATION

To install this module, use `cpanm`:

```bash
cpanm XML::Printer::ESCPOS
```

## SUPPORT AND BUGS

Please report any bugs or feature requests by opening an [issue on Github](https://github.com/sonntagd/XML-Printer-ESCPOS/issues).

## LICENSE AND COPYRIGHT

Copyright (C) 2017 Dominic Sonntag.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

http://www.perlfoundation.org/artistic_license_2_0