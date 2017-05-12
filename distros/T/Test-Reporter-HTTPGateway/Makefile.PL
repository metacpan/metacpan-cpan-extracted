
use strict;
use warnings;

use inc::Module::Install;

name          ('Test-Reporter-HTTPGateway');
author        ('Ricardo Signes <rjbs@cpan.org>');
license       ('perl');
all_from      ('lib/Test/Reporter/HTTPGateway.pm');

requires('CGI'                    => '0.000'); # min unknown
requires('Email::Send'            => '0.000'); # min unknown
requires('Email::Simple'          => '0.000'); # min unknown
requires('Email::Simple::Creator' => '0.000'); # min unknown

author_tests('xt');

WriteAll();
