# Test-Health

Test-Health is a Perl distribution created to implement a "poor's man" health check API.

By using standard test modules like Test-Simple, you can implement your tests and use Test-Health
to run those tests, collect results and send an e-mail in the case any test fails.

This is usefull if you want to implement a simple health check on your system, but don't have a monitoring system
like Nagios (or doesn't want to use one). Once you have the test files, it is pretty straighforward to send an e-mail
in case of problems.

Test-Health relies on good modules from [CPAN](http://search.cpan.org) like:

* Moo
* Email::Stuffer
* TAP::Formatter::HTML
* Email::Sender::Transport::SMTP

Be sure to check the Pod documentation include for more details. Also take a look at the [project's Wiki](https://github.com/glasswalk3r/Test-Health/wiki).

This software is Copyright (c) 2016 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

