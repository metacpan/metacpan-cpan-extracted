#!/usr/bin/env perl

use strict;
use Warnings::Version 'all';
no warnings 'bareword';

our $FOO = $0;
open FOO || die;
