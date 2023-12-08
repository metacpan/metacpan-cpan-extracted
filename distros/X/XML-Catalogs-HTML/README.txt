XML-Catalogs-HTML

XML::Catalogs::HTML provides a catalog of HTML DTDs.
XML parsers can use catalogs to avoid downloading
remote DTDs to parse and validate documents.


INSTALLATION

To install this module, run the following commands:

   perl Makefile.PL
   make
   make test
   make install


DEPENDENCIES

This module requires these other modules and libraries:

    ExtUtils::MakeMaker      (For installation only)
    File::ShareDir::Install  (For installation only)
    Test::More               (For testing only)
    parent
    strict
    XML::Catalogs
    version
    warnings


SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc XML::Catalogs

You can also find it online at this location:

    https://metacpan.org/dist/XML-Catalogs


COPYRIGHT AND LICENCE

The .dtd and .ent files included in this distrubution are
covered by Copyright. See the individual files for the notice.
The may be distributed unmodified. See
L<http://www.w3.org/Consortium/Legal/2002/copyright-documents-20021231>
for the exact terms.

For everything else, the following applies:

No rights reserved.

The author has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.
