# Tk-AppWindow

An extendable application framework written in perl/Tk. The aim is maximum user configurability
and ease of application building.

It inherits Tk::MainWindow and adds a lot of features to it like:

    * Add custom config variables
    * Extensions so you load only functionality you need
    * Simplified menu definitions
    * A plugin system
    * All you need for a config folder

And a lot more.

# Requirements

Following Perl modules must be installed:

    * Data::Compare
    * File::Basename
    * File::Path
    * File::Spec
    * Imager
    * Imager::File::PNG
    * MIME::Base64
    * Module::Load::Conditional
    * Pod::Usage
    * Scalar::Util
    * Scalar::Util::Numeric
    * Test::Tk
    * Test::More
    * Tk
    * Tk::DocumentTree
    * Tk::FontDialog
    * Tk::Pod
    * Tk::QuickForm
    * Tk::YADialog
    * Tk::YANoteBook

Unless you are running Windows, we strongly recommend you also install the Perl modules:

## Tk::GtkSettings 

Run the following commands each time you login;

    tkgtk
    xrdb .Xdefaults

This will make the look and feel of all your Tk applications conform to your desktop settings and helps 
the Art extension locate the correct icon library.

## Image::LibRSVG

This will allow you to load vector graphics based themes like Breeze. We did not include it as a 
prerequisite since it does not respond well to unattended install. It requires the gnome library 
librsvg-2 and its development files to be installed.

## On Windows

If you use the windows operating system please make sure you have an icon library installed.
Preferably the Oxygen theme. Download it from here. Extract the file and rename the folder 
oxygen-icons-master to Oxygen. Create a folder Icons in C:\ProgramData and move the Oxygen folder into it.
SVG based icon themes do not work on Windows.

# Installation

    perl Makefile.PL
    make
    make test
    make install


