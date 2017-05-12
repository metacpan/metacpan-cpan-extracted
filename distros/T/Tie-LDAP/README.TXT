
WHAT IS IT
==========

This library allows you to tie LDAP database to Perl hash.
Any read/write operation to hash will cause corresponding
access to LDAP database automatically.

LDAP entry returned by hash access is also tied with LDAP
database (Tie::LDAP::Entry object). Any hash operation to
that also will cause corresponding field of LDAP entry to
be manipulated.

HOW TO INSTALL
==============

Just type:

    perl Makefile.PL
    make
    make install

and you should be all set. By the way, you might want to test
this before installation by

    make test

But you'll need working LDAP database which can be used for
the test.

REQUIREMENT
===========

This module requires Net::LDAPapi.

Version 0.01 required Net::LDAP, but I had switched (for speed).

HOW TO USE
==========

For the usage, please consult POD document embedded in the source.

    perldoc Tie::LDAP

should show you the document if installed correctly.
