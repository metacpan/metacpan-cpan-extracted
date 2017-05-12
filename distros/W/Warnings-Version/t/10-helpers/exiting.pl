#!/usr/bin/env perl

use strict;
use Warnings::Version 'all';

FOO: { eval { last FOO } }
