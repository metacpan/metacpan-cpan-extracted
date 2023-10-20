# Building from source

To build and install this module, use these commands:

    perl Makefile.PL
    make
    make test
    make install

Several dependencies should be installed prior building from source.

## Required Perl modules

### For configure phase

- ExtUtils::Depends
- ExtUtils::PkgConfig
- Module::Install
- Module::Install::AuthorRequires
- Module::Install::XSUtil
- XS::Object::Magic

### For compile phase

- Data::Dump
- Mouse
- MouseX::NativeTraits
- Test::Deep
- Test::Exception
- Try::Tiny
- XML::Descent
- XML::Simple

## Required C libraries

### For Debian GNU/Linux

- libxcb-ewmh-dev
- libxcb-icccm4-dev
- libxcb-randr0-dev
- libxcb-render0-dev
- libxcb-util-dev
- libxcb-xinerama0-dev
- libxcb-xinput-dev
- libxcb-xkb-dev
- libxcb-xtest0-dev
- libxcb1-dev
- xcb-proto

### For FreeBSD

- expat
- pkgconf
- xcb-proto
- xcb-util-wm
