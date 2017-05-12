#!/usr/bin/perl
use warnings;
use strict;
use lib 't/lib';
use Test;

use T::WebDAO::Container;
use T::Engine;
Test::Class->runtests();
