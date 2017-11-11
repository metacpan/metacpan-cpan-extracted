README for libintl-perl
=======================

The package libintl-perl is an internationalization library for Perl
that aims to be compatible with the Uniforum message translations
system as implemented for example in GNU gettext.

See the file COPYING and the source code for licensing.

Requirements
------------

The library is entirely written in Perl.  It should run on every
system with a Perl5 interpreter.  The minimum required Perl version
should be 5.004.

The behavior of the package varies a little depending on the Perl
version:

- Perl 5.8 or better

Recommended.  Perl 5.8 offers maximum performance and support for
various multi-byte encodings (even more if Encode::Han is installed).
Additionally the output charset is chosen automatically according to
the information provided by I18N::Langinfo.  In fact, I18N::Langinfo
is already available for Perl 5.7 but this developer version is
probably not much in use any more.

- Perl 5.6 or better

Still offers high-performance UTF-8 handling but no support for other
multi-byte encodings unless the package Encode is installed.

- Earlier Perl versions

Full UTF-8 support but quiet slow since all conversion routines are
written in Perl.  More exactly: Encoding from 8 bit charsets into
UTF-8 is reasonably fast and usable.  Decoding UTF-8 is slow, however.

Note that these are actually the requirements for the *users* of your
software internationalized with libintl-perl.

As a maintainer of a Perl package that uses libintl-perl, you will
also need a recent version of GNU gettext (see the file README in the
subdirectory "sample/" of the source distribution of libintl-perl).
Translators of your software can basically do their job with any text
editor, but it usually makes sense for them, too, to have GNU gettext
installed.  End users of your software, or people that install an
internationalized Perl package do *not* need it, unless they want to
add a new language to your software.

Installation
------------

If libintl-perl is not installed on your system, you have to build it
from the sources, which is a lot easier than you may think.  You need 
the program "make" for that and a command line shell.  No C compiler is 
required.

Unpack the package in a directory of your choice, cd into that
directory and then type

     perl Makefile.PL
     make
	  
This will build the package.  You can then run the tests with

     make test

To install the package, type

     make install

You will probably need root permissions to do that.

Of course, you can also use the CPAN module to install the package.

Feedback
--------

Send negative (and positive!) feedback to me.  Bug reports can be send 
directly to me or you can use the 
[RT bugtracking system](http://rt.cpan.org/ "Link to RT").

If you use libintl-perl for your project, private or public, free or
commercial, please let me know.  I am interested in such information.

If you really like (or dislike?) libintl-perl, tell the world about.  
You can star it on [github](http://github.com/gflohr/libintl-perl).  You
can rate it and even write a review at 
[cpanratings](http://cpanratings.perl.org/)
(search for "libintl-perl").

Design Goals
------------

The primary design goal of libintl-perl is maximum compatibility with
the gettext functions available for other programming languages.  It
is intended that programmers, translators, and end users can fully
benefit from all existing i18n tools like xgettext for message
extraction, msgfmt, msgmerge, etc. for catalog manipulation, Emacs PO
mode (or KBabel, PO-Edit, ...) for catalog editing and so on.

Another design goal is maximum portability.  The library should be
functional without any additional software but with a wide range of
Perl versions.  Wherever possible, hooks have been inserted to benefit
from advanced features in the runtime environment, but the basic
functionality should be present everywhere.

Overview
--------

The core of the library is the module Locale::gettext_pp.  It is a
pure Perl re-implementation of the module Locale::gettext available on
CPAN.  However, the XS version Locale::gettext lacks some functions
(notably plural handling and output conversion) that are already
present in Locale::gettext_pp.  Locale::gettext_pp provides the
internationalization functions that are available in your system
library (libc) or additional C libraries (for example libintl in the
case of GNU gettext).

The class Locale::Messages is an additional abstraction layer that is
prepared for dynamic switching between different gettext implementations (for
example Locale::gettext_pp and Locale::gettext).  It provides
basically the same interface as Locale::gettext_pp but in an
implementation-independent manner.

The module Locale::TextDomain is the only module that you should
actually use in your software.  It represents the message translation
system for a particular text domain (a text domain is a unique
identifier for your software package), makes use of Locale::Messages
for message translation and catalog location, and it provides
additional utility functions, for example common shortcut names for
i18n routines, tied hashes for hash-like lookups into the translation
database, and finally an interpolation mechanism suitable for
internationalized messages.

The package also contains a charset conversion library
Locale::Recode.  This library is used internally by Locale::gettext_pp
to allow on-the-fly charset conversion between the charset in a
message catalog and the preferred (end) user charset.  Its main
advantage about the Encode package available for recent Perl versions
is its portability, since it does not require the Unicode capabilities
of Perl that were introduced with Perl 5.6.  It fully supports UTF-8
with every Perl version and a wealth of common 8 bit encodings.  If
you have to do charset conversion with older Perl versions, then
Locale::Recode may be worth a try although it is really only a helper
library, not intended as a competitor to Encode.

Documentation
-------------

For a basic understanding of message translation in Perl with
libintl-perl you should read the perldoc of Locale::TextDomain.  Don't
bother about the documentation of the other modules in the library,
you will not need it unless you want to hack the library yourself.

In order to make use of the software, you will also need various tools
from GNU gettext [savannah](http://savannah.gnu.org/projects/gettext/). The documentation is located at [www.gnu.org](http://www.gnu.org/manual/gettext/).
You will find there a language-independent overview of 
internationalization with GNU gettext, and in the Perl-specific
sections you will find details about the parser that extracts
translatable messages from your Perl sources. 

Quick-Start
-----------

The subdirectory "sample" of the source distribution of libintl-perl
contains a full-fledged example for an internationalized Perl package,
including a working Makefile.  The README of that subdirectory
explains all necessary steps.

However, if you are on a recent GNU/Linux system or similar (cygwin
should also do), chances are that you can get the following example to
run:

	#! /usr/local/bin/perl -w

	use strict;

	# This assumes that the textdomain 'libc' is available on your
	# system.  Try "locate libc.mo" or "locate libc.gmo" (or
	# "find / -type f -name libc.mo" if locate is not available on
	# your system).
	#
	# By the way, the "use Locale::TextDomain (TEXTDOMAIN) is the 
	# equivalent of
	#
	#      textdomain ("TEXTDOMAIN");
	#
	# in C or similar languages.
	use Locale::TextDomain ('libc');

	# The locale category LC_MESSAGES is not exported by the POSIX
	# module on older Perl versions.  
	use Locale::Messages qw (LC_MESSAGES);

	use POSIX ('setlocale');

	# Set the locale according to our environment.
	setlocale (LC_MESSAGES, '');

	# This makes the assumption that your system libc defines a 
	# message "No such file or directory".  Check the exact
	# spelling on your system with something like 
	# "ls NON-EXISTANT".
	# Note the double underscore in front of the string.  This is
	# really a function call to the function __() that is
	# automagically imported by Locale::TextDomain into your
	# namespace.  This function takes its argument, looks up a
	# translation for it, and returns that, or the unmodified
	# string in case of failure.
	print __"No such file or directory", ".\n";

	__END__

Now run the command "locale -a" or "nlsinfo" to get a list of
available locales on your system.  Try the section "Finding locales"
in "perldoc perllocale" if you have problems.

If, for example, the locale "fr_FR" is available on your system, set
the environment variable LANG to that value, for a POSIX shell

     LANG=fr_FR
     export LANG

for the C shell

     setenv LANG fr_FR

and run your little Perl script.  It should tell you what the error
message for "No such file or directory" is in French, or whatever
language you chose.  Not a real example, because we have "stolen" a
message from a system catalog.  But it should give you the general
idea, especially if you are already familiar with gettext in C.

If you still see the English message, this does not necessarily mean a
failure, since the string is maybe not translated on your system (try
"locate libc.mo" to get a list of available translations).  Even for
the translations listed there, that particular message might be
missing.  Try a common locale like "de_DE" or "fr_FR" that are usually
fully translated then.

Your next steps should be "perldoc Locale::TextDomain", and then study
the example in the subdirectory "sample" of this distribution.

Have fun with libintl-perl!

Guido Flohr
