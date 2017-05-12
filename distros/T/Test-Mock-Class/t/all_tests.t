#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

use Test::Unit::Lite;

local $SIG{__WARN__} = sub { require Carp; Carp::confess(@_) };

Test::Unit::HarnessUnit->new->start('Test::Unit::Lite::AllTests');
