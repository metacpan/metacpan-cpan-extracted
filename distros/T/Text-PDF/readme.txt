                        Text::PDF

There seem to be a growing plethora of Perl modules for creating and
manipulating PDF files. This module is no exception. Beyond the standard
features you would expect from a PDF manipulation module there are:

FEATURES

 .  Works with more than one PDF file open at once
 .  Supports TrueType fonts as well as the base 14 (requires Font::TTF module)
        including Type0 glyph based fonts (for Unicode), and subsetting

UN-FEATURES (which may one day be fixed)

 .  No nice higher level interface for rendering and Page description insertion
 .  No support for Type1 or Type3 fonts
 .  No higher level support of annotations, bookmarks, hot-links, etc.
 .  This is beta code although new features should be considered alpha

In summary, this module provides a strong (IMO) base for working with PDF files
but lacks some finesse. Users should know their way around the PDF specification.

Included in the examples directory are some example programs starting from very
simple PDF creation programs and working up. More extensive samples are included
as scripts.

SCRIPTS

Installed with this package are the following scripts:

    pdfbklt     Turns documents into booklets
    pdfrevert   Removes one layer of edits from a PDF file
    pdfstamp    Adds the given text in a given font, size to all pages at given
                location

EXAMPLES

Included in the examples directory are some smaller utilities which are also
useful, so don't throw them away!

    graph       Makes graph paper - not very complex
    hello       The "Hello World" program
    pdfaddobj   Debug aid to insert data as an object in a file
    pdfaddpg    Adds a blank page to a PDF file at any location
    pdfcrop     Adds crop marks to a page (see cd.cfg)
    pdfgetobj   Extracts a particular object from a PDF file (debugging aid)

REQUIREMENTS

This module set requires Compress::Zlib. It is used for compressed streams and
within the Standard Fonts.

INSTALLATION

If you want to have TrueType support in your application, then you will
need to install the Font::TTF module (available from CPAN) as well.

Installation is as per the standard module installation approach:

    perl Makefile.PL
    make
    make test
    make install

If working on Win32 platform, then try:

    perl Makefile.PL
    dmake
    dmake test
    dmake install

Your mileage may vary

CONTACT

Bugs, comments and offers of collaboration to: Martin_Hosken@sil.org

