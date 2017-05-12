Wrangler
========

A file manager with sophisticated metadata handling capabilities

## DESCRIPTION

Extended file attributes are a very versatile and powerful extension of traditional
file system semantics. Yet, most end-user applications ignore xattribs, or in cases
where an app choses to make xattribs accessible for the average user, the actual
user-interface is hidden in "file properties" sub menus, or cumbersome to use.

Wrangler is a "file manager"-like application that puts file metadata first, offering
xattribs and other metadata alongside traditional metadata (size,type,mtime,...)
in all of it's views. The application was designed to browse and manage large collections
of multimedia content files, digital assets, and their associated metadata.

A modular application-layout in combination with a Plugin facility makes Wrangler
adaptable to most workflows or work environments. The central file-browser can be
complemented with a Navbar and Sidebar widget, for comfortable browsing, or with
more specialised multimedia widgets: Wrangler's image/video Previewer or the Metadata-Editor.
If you try only one feature, and you haven't used xattribs until now, then test
the Previewer. It reads preview-thumbnails embedded into JPEGs and takes the lag
out of browsing large image file collections - without maintaining an additional
database.

Wrangler is not meant as a replacement for your primary file manager.
Wrangler is primarily a metadata handling
application, while it also offers the interface and most functionalities commonly
found in file-managers for navigating filesystems and selecting files. But if you
end up using Wrangler for everyday file browsing, that's okay with us.

_Please note:_

This here is only a short github placeholder README. More information about
how to install and use Wrangler can be found in the POD embedded in the source code.
So, please hop over to:

- [Wrangler's Documentation](http://search.cpan.org/perldoc?Wrangler).
- [Wrangler's Official Homepage](http://www.clipland.com/wrangler)

## SCREENSHOTS

<div>
<a href="https://raw.github.com/clipland/wrangler/master/screenshot1.png"><span><img src="https://raw.github.com/clipland/wrangler/master/screenshot1_small.png" width="400" height="300" alt="Screenshot 1" style="border: 1px solid #888;" /></span></a>
<a href="https://raw.github.com/clipland/wrangler/master/screenshot2.png"><span><img src="https://raw.github.com/clipland/wrangler/master/screenshot2_small.png" width="400" height="300" alt="Screenshot 1" style="border: 1px solid #888;" /></span></a>
</div>

## INSTALLATION

via CPAN (official releases):

    sudo cpan -i Wrangler

from command-line (latest changes, if any):

    wget https://github.com/clipland/wrangler/archive/master.tar.gz
    tar xvf master.tar.gz
    cd wrangler-master
    perl Makefile.PL
    make
    make test
    sudo make install

via .deb file:

    go to http://www.clipland.com/wrangler
    download .deb file
    use gdebi or similar to install
    install File::ExtAttr via CPAN (as long as there's no libfile-extattr-perl package)


## AUTHOR

Clipland GmbH, [clipland.com](http://www.clipland.com/)

## COPYRIGHT

Copyright 2009-2015 Clipland GmbH. All rights reserved.

## LICENSE

Wrangler is dual-licensed under the _Wrangler Non-Commercial License_ for private,
non-commercial use, free-of-charge; and under a purchasable license for commercial,
institutional and educational use. Please contact Clipland at http://www.clipland.com/wrangler
to buy commercial licenses.

Please note that Wrangler's license keeps it from being [officially "open source" software](http://opensource.org/faq#avoid-unapproved-licenses).
Nor is it GNU "free software", as it permits only one (freedom 2) of the [four freedoms](http://www.gnu.org/philosophy/free-sw.html).

Wrangler belongs to Debian's non-free software category, as the Wrangler Licenses
do not allow derived works, which would be rule 3 of the [Debian Free Software Guidelines (DFSG)](https://www.debian.org/doc/debian-policy/ch-archive.html).

Wrangler relies on a number of Perl modules and the WxWidgets toolkit. If you are
interested in the licensing and copyright status of these modules, please have a
look at Makefile.PL which contains some notes.
