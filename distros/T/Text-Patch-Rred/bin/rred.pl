#!/usr/bin/perl

# Copyright (C) 2006-2009 Jakob Bohm.  All Rights Reserved.
# See README in the distribution for the current license status of the
#    entire package, including this file.

# For Pod documentation, see Text::Patch::Rred.pm

use 5.006;    # Even older might work, but are not supported
use strict;
use warnings;
use Text::Patch::Rred;

our $VERSION = $Text::Patch::Rred::VERSION;

exit Text::Patch::Rred::main(@ARGV);
