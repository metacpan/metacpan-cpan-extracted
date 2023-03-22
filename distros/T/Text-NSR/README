[Text::NSR](https://metacpan.org/pod/Text::NSR)
==========

Read "newline separated records" (NSR) structured text files

## SYNOPSIS

	use Text::NSR;
	my $nsr = Text::NSR->new(
		filepath  => 't/test.nsr',
		fieldspec => ['f1','f2','f3','f4']
	);
	my $records = $nsr->read();

## DESCRIPTION

There are a number of data exchange formats out there that strive to be structured in a way that is both,
easily and intuitively editable by humans and reliably parseable by machines. This module here adds yet another
structured file format, a file composed of "newline separated records".

The guiding principal here is that each line in a file represents a value. And that multiple lines form a
single record. Multiple records then are separated by one empty line. Exactly one empty line. A second empty
line will be interpreted as the first line of the next record. The only exception to this rule are leading or
trailing newlines. They are considered "padding" and are dropped.

NSR files can be used to hold very simple human editable databases.

This module here helps with reading and parsing of such files.

Please note:

This here is only a short github placeholder README. More information about this module can be found in the POD
embedded in source code. So, please hop over to _cpan_ for the canonical
[documentation](https://metacpan.org/pod/Text::NSR).

## INSTALLATION

via CPAN (official releases):

    sudo cpan -i Text::NSR

from command-line (latest changes, if any):

    wget https://github.com/clipland/text-nsr/archive/master.tar.gz
    tar xvf master.tar.gz
    cd text-nsr-main
    perl Makefile.PL
    make
    make test
    sudo make install

## AUTHOR

Clipland GmbH, [clipland.com](https://www.clipland.com/)

This module was developed for [live streaming](https://instream.de/) infotainment website [InStream.de](https://instream.de/).

## COPYRIGHT & LICENSE

Copyright 2022 Clipland GmbH. All rights reserved.

This library is free software, dual-licensed under [GPLv3](http://www.gnu.org/licenses/gpl)/[AL2](http://opensource.org/licenses/Artistic-2.0).
You can redistribute it and/or modify it under the same terms as Perl itself.
