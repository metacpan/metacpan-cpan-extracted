#!/usr/bin/perl

use strict;
use lib '.';
use inc::Module::Install;

name     'i18n';
author   'Audrey Tang <cpan@audreyt.org>';
all_from 'lib/i18n.pm';

requires 'Locale::Maketext';
requires 'Locale::Maketext::Lexicon';
requires 'Locale::Maketext::Simple';

auto_provides;

WriteAll;
