use inc::Module::Install;

name         ('Test::FIT');
version_from ('lib/Test/FIT.pm');
author       ('Brian Ingerson');
abstract     ('A FIT Test Framework for Perl');

install_script('fit-run.cgi');

&Meta->write;
&Makefile->write;
