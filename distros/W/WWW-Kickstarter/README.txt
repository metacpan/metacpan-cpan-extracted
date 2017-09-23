WWW-Kickstarter

This distribution provides access to Kickstarter's private API
to obtain information about your account, other users and and projects.


INSTALLATION

To install this module, run the following commands:

   perl Makefile.PL
   make
   make test
   make install


DEPENDENCIES

This module requires these other modules and libraries:

    ExtUtils::MakeMaker 6.52    (For installation only)
    Software::License::CC0_1_0  (For installation only)
    Test::More                  (For testing only)
    autovivification
    Carp
    overload
    strict
    Time::HiRes
    URI
    URI::Escape
    URI::QueryParam
    version
    warnings

    The default HTTP client requires the following:
        HTTP::Headers
        HTTP::Request::Common
        LWP::Protocol::https
        LWP::UserAgent

    The default JSON parser requires the following:
        JSON::XS


DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc WWW::Kickstarter

You can also find it online at these locations:

    http://search.cpan.org/dist/WWW-Kickstarter

    https://metacpan.org/release/WWW-Kickstarter


COPYRIGHT AND LICENSE

No rights reserved.

The author has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.
