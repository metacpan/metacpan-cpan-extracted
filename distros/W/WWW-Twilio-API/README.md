WWW-Twilio-API version 0.20
===========================

WWW::Twilio::API is a flexible, extensible API for Twilio written in
Perl. It's primary objective is reliability and robustness for
Twilio's RESTful API. The module should survive any future updates to
the API without any changes whatsoever.

Make any Twilio API call in two lines of code:

    ## make a Twilio object
    my $twilio = new WWW::Twilio::API( AccountSid => '(your sid here)',
                                     AuthToken  => '(your auth token here)' );

    ## retrieve calls I've made
    $response = $twilio->GET('Calls');

    ## place a new call to 801-123-5555 from 403-123-1234
    $response = $twilio->POST('Calls',
                              From => '4031231234',
                              To   => '8011235555',
                              Url  => 'http://perlcode.org/cgi-bin/twilio');

    ## see account information
    $response = $twilio->GET('Accounts');

    ## see details for a specific call
    $response = $twilio->GET('Calls/CA42ed11f93dc08b952027ffbc406d0868');

    ## send an SMS message
    $response = $twilio->POST( 'SMS/Messages',
                               From => $from,
                               To   => $to,
                               Body => $body );

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

Copyright (C) 2009-2016 by Scott Wiersdorf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.
