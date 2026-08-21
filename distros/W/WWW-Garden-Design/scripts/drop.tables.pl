#!/usr/bin/env perl

use strict;
use warnings;

use WWW::Garden::Design::Util::Create;

# ----------------------------

WWW::Garden::Design::Util::Create -> new -> drop_all_tables;
