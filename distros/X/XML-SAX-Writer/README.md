XML::SAX::Writer - SAX2 XML Writer
==================================

About this module
-----------------

This module has been developed by Robin Berjon <robin@knowscape.com>.

Since version 0.50, it is maintained by means of the Perl XML 
project [perl-xml.sourceforge.net]:

 - The sources are stored in the Github repository at
   https://github.com/perigrin/xml-sax-writer

 - Requests and comments should be sent to the 
   Perl-XML@listserv.ActiveState.com mailing list

 - Bugs should be reported to RT.cpan.org or the Github issue tracker.

Robin considered this module alpha but after years of testing on
humans we believe it can be considered beta now.

The version 0.50 has been created by Petr Cimprich <petr@gingerall.cz>, 
using patches and sugestions from RT.cpan.org. Thanks go to all those
who reported bugs and suggested fixes.

Usage
-----

>   use XML::SAX::Writer;
>   use XML::SAX::SomeDriver;
> 
>   my $w = XML::SAX::Writer->new;
>   my $d = XML::SAX::SomeDriver->new(Handler => $w);
> 
>   $d->parse('some options...');

See [http://perl-xml.sourceforge.net/perl-sax/]() for more details about
Perl SAX 2.

License
-------

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
