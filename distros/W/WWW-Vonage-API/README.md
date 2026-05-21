WWW-Vonage-API version 0.20
===========================

WWW::Vonage::API is a flexible, extensible API for Vonage written in
Perl. It's primary objective is reliability and robustness for
Vonage's RESTful API. The module should survive any future updates to
the API without any changes whatsoever.

Make any Vonage API call in two lines of code:

    ## make a Vonage object
   

INSTALLATION

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

DEPENDENCIES

This module requires these other modules and libraries:

    LWP::UserAgent
    Crypt::SSLeay
    URI::Escape

COPYRIGHT AND LICENCE

Copyright (C) 2026 by John Scole based on WWW-Twilio-API by Scott Wiersdorf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.
