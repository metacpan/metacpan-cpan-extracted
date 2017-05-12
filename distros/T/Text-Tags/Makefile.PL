use inc::Module::Install;

name ('Text-Tags');
author ('David Glasser <glasser@bestpractical.com>');
version_from ('lib/Text/Tags.pm');
abstract_from('lib/Text/Tags.pm');
license('perl');
requires('Test::More');

&WriteAll;
