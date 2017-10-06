Introduction
============
This module aims to provide an alternative to the Net::DNS module, based the ldns library from NLnet Labs (https://www.nlnetlabs.nl/projects/ldns/). The module includes the necessary C code, so the library does not need to be globally installed. It does, however, rely on a sufficiently recent version of OpenSSL being present.

This module is written as part of the Zonemaster project (http://github.com/dotse/zonemaster), and therefore primarily exposes the functionality needed for that. Since Zonemaster is a diagnostic tool, that means the functions most used are those for looking things up and inspecting them.

If you want a module that specifically aims to be a complete and transparent interface to ldns, DNS::LDNS is a better fit than this module.

Initially this module was named Net::LDNS.

API
===
This module started as an alternative to Net::DNS. Thus, the interface is similar but not identical. The main difference at the moment is that the expected entrypoint to the system is through Zonemaster::LDNS directly rather than a submodule (like Net::DNS::Resolver). It's also not possible to set the flags in the resolver object at creation, although that may change.

The API should at the moment be considered slightly volatile. We have other code written to the current interface, so it's unlikely that we'll want to make any drastic changes, but at least until we start calling it version 1.0 it's a good idea to check for changes before upgrading.

IDN
===
If GNU libidn is installed when this module is compiled, it will be used to add a simple function that converts strings from Perl's internal encoding to IDNA domain name format. In order to convert strings from whatever encoding you have to Perl's internal format, use L<Encode>. If you need any kind of control or options, use L<Net::LibIDN>. The included function here is only meant to assist in the most basic case, although that should cover a lot of real-world use cases.

Installation
============
Installation uses the normal `perl Makefile.PL && make && make test && make install` sequence. This assumes that OpenSSL can be found in one of the places where the C compiler looks by default (if it's somewhere else, try using the `--prefix` flag when running `Makefile.PL`). `make test` assumes that it can send queries to the outside world.

There is a small part in the code that may not be compatible with non-Unix operating systems, in that it assumes that the file /dev/null exists. If you try using this on Windows, VMS, z/OS or something else non-Unix, I'd love to hear from you so we can sort that bit out.
