#!/usr/bin/env perl

use Test::More tests => 2;

use_ok('Test::Locale::PO');
can_ok('Test::Locale::PO', 'po_file_ok');

