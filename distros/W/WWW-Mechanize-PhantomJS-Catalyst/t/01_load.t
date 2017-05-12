#! /usr/bin/perl
use strict;
use warnings;

use Test::More tests => 5;

use_ok('Catalyst');
use_ok('WWW::Mechanize');
use_ok('Test::WWW::Mechanize');
use_ok('WWW::Mechanize::PhantomJS');
use_ok('WWW::Mechanize::PhantomJS::Catalyst');

