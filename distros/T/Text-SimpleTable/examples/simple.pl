#!/usr/bin/env perl

# Copyright (C) 2005-2010, Sebastian Riedel.

use strict;
use warnings;

use Text::SimpleTable;

my $t = Text::SimpleTable->new(5, 10);
$t->row('Catalyst',          'rockz!');
$t->row('DBIx::Class',       'suckz!');
$t->row('Template::Toolkit', 'rockz!');
print $t->draw;
