perl-wkhtmltox / WKHTMLTOX::XS
=========================

Generate PDF and Images from HTML using WKHTMLTOX. e.g, for PDF

    use WKHTMLTOX::XS qw( generate_pdf );
    generate_pdf( {out => 'google.pdf'}, { page => 'http://www.google.com'} );
    
or for an image,

    use WKHTMLTOX::XS qw( generate_image );
    generate_image( {out => 'google.jpg', in => "http://www.google.com", fmt => "jpeg"} );
    
#### EXPORT
 
    generate_pdf( global_pdf_settings, pdf_settings );
    generate_image( image_settings )

#### DEPENDENCIES

    qt
    libwkhtmltox
    libXext
    libXredner
    gcc-c++ (for building)

#### INSTALLATION

1. Install http://wkhtmltopdf.org/.

2. Install required dependencies

    ```
    # yum install qt urw-fonts gcc-c++ libXext libXrender
    ```

3. Install this module, e.g:

    ```
    $ perl Makefile.PL
    $ make
    $ make test
    # make install
    ```

#### GLOBAL & OBJECT SETTINGS
 
For complete information regarding the global and object settings, please see: http://wkhtmltopdf.org/libwkhtmltox/pagesettings.html

##### PDF GLOBAL SETTINGS

- `size.paperSize` The paper size of the output document, e.g. "A4".
- `size.width` The with of the output document, e.g. "4cm".
- `size.height` The height of the output document, e.g. "12in".
- `orientation` The orientation of the output document, must be either "Landscape" or "Portrait".
- `colorMode` Should the output be printed in color or gray scale, must be either "Color" or "Grayscale"
- `resolution` Most likely has no effect.
- `dpi` What dpi should we use when printing, e.g. "80".
- `pageOffset` A number that is added to all page numbers when printing headers, footers and table of content.
- `copies` How many copies should we print?. e.g. "2".
- `collate` Should the copies be collated? Must be either "true" or "false".
- `outline` Should a outline (table of content in the sidebar) be generated and put into the PDF? Must be either "true" or false".
- `outlineDepth` The maximal depth of the outline, e.g. "4".
- `dumpOutline` If not set to the empty string a XML representation of the outline is dumped to this file.
- `out` The path of the output file, if "-" output is sent to stdout, if empty the output is stored in a buffer.
- `documentTitle` The title of the PDF document.
- `useCompression` Should we use loss less compression when creating the pdf file? Must be either "true" or "false".
- `margin.top` Size of the top margin, e.g. "2cm"
- `margin.bottom` Size of the bottom margin, e.g. "2cm"
- `margin.left` Size of the left margin, e.g. "2cm"
- `margin.right` Size of the right margin, e.g. "2cm"
- `imageDPI` The maximal DPI to use for images in the pdf document.
- `imageQuality` The jpeg compression factor to use when producing the pdf document, e.g. "92".
- `load.cookieJar` Path of file used to load and store cookies.

##### PDF OBJECT SETTINGS

- `toc.useDottedLines` Should we use a dotted line when creating a table of content? Must be either "true" or "false".
- `toc.captionText` The caption to use when creating a table of content.
- `toc.forwardLinks` Should we create links from the table of content into the actual content? Must be either "true or "false.
- `toc.backLinks` Should we link back from the content to this table of content.
- `toc.indentation` The indentation used for every table of content level, e.g. "2em".
- `toc.fontScale` How much should we scale down the font for every toc level? E.g. "0.8"
- `page` The URL or path of the web page to convert, if "-" input is read from stdin.
- `header.*` Header specific settings see Header and footer settings.
- `footer.*` Footer specific settings see Header and footer settings.
- `useExternalLinks` Should external links in the HTML document be converted into external pdf links? Must be either "true" or "false.
- `useLocalLinks` Should internal links in the HTML document be converted into pdf references? Must be either "true" or "false"
- `replacements` TODO
- `produceForms` Should we turn HTML forms into PDF forms? Must be either "true" or file".
- `load.*` Page specific settings related to loading content, see Object Specific loading settings.
- `web.*` See Web page specific settings.
- `includeInOutline` Should the sections from this document be included in the outline and table of content?
- `pagesCount` Should we count the pages of this document, in the counter used for TOC, headers and footers?
- `tocXsl` If not empty this object is a table of content object, "page" is ignored and this xsl style sheet is used to convert the outline XML into a table of content.

#### IMAGE OBJECT SETTINGS

- `crop.left` left/x coordinate of the window to capture in pixels. E.g. "200"
- `crop.top` top/y coordinate of the window to capture in pixels. E.g. "200"
- `crop.width` Width of the window to capture in pixels. E.g. "200"
- `crop.height` Height of the window to capture in pixels. E.g. "200"
- `load.cookieJar` Path of file used to load and store cookies.
- `load.*` Page specific settings related to loading content, see Object Specific loading settings.
- `web.*` See Web page specific settings.
- `transparent` When outputting a PNG or SVG, make the white background transparent. Must be either "true" or "false"
- `in` The URL or path of the input file, if "-" stdin is used. E.g. "http://google.com"
- `out` The path of the output file, if "-" stdout is used, if empty the content is stored to a internalBuffer.
- `fmt` The output format to use, must be either "", "jpg", "png", "bmp" or "svg".
- `screenWidth` The with of the screen used to render is pixels, e.g "800".
- `smartWidth` Should we expand the screenWidth if the content does not fit? must be either "true" or "false".
- `quality` The compression factor to use when outputting a JPEG image. E.g. "94".

#### TODO

- Improved testing & support
    
#### COPYRIGHT & LICENCE

Copyright (C) 2014 by Kurt Wagner

The library is licensed under the terms of the GNU Lesser General Public License 3.0. See http://www.gnu.org/licenses/lgpl-3.0.html.


