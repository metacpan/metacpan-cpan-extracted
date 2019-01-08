#!/usr/bin/env perl

# $Id: app.psgi 68 2019-01-04 00:15:58Z stro $

use strict;
use warnings;

use lib 'lib', '../lib';

use WWW::CPAN::SQLite;

WWW::CPAN::SQLite->new()->run();

