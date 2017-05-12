Unix-Statgrab
=============

## Description

Unix::Statgrab is a wrapper for libstatgrab, as available from
http://www.i-scream.org/libstatgrab/. It is a reasonably portable 
attempt to query interesting stats about your computer. It covers 
information on the operating system, CPU, memory usage, network 
interfaces, hard-disks etc.

## Copying

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

## Build/Installation

  cpan Unix::Statgrab

## External Dependencies

This module requires these other modules and libraries:

    libstatgrab from http://www.i-scream.org/libstatgrab/

Version 0.90 of libstatgrab is required.

If you have installed libstatgrab in a non-standard location,
you have to tell Makefile.PL about it:

    env PKG_CONFIG_PATH=${non_std_prefix}/lib/pkgconfig \
    cpan Unix::Statgrab

## Copyright

Copyright (C) 2004-2005 Tassilo von Parseval
Copyright (C) 2012-2014 Jens Rehsack


