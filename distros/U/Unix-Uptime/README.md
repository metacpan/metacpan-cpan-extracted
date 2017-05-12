Unix-Uptime is Copyright (C) 2008-2014, Mike Kelly.

This is a simple module that allows you to get the current system
uptime, in seconds, and the current load average.

On *BSD systems, this involves using an optional XS module, with a
fallback on parsing the output of the 'syslog' command. If you wish to
avoid building the XS module, set the 'NO_XS' environment variable to
some true value before running `perl Build.PL`.

See the Unix::Uptime perldoc for more information.

LICENSE INFORMATION

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses at <http://www.perlfoundation.org/artistic_license_1_0>,
and <http://www.gnu.org/licenses/gpl-2.0.html>.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

[![Build Status](https://travis-ci.org/pioto/Unix-Uptime.svg?branch=develop)](https://travis-ci.org/pioto/Unix-Uptime)
