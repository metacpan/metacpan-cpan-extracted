#!/usr/bin/env perl

use strict;
use Warnings::Version '5.20';

$_ = 'foo'; /(?[ \p{Thai} & \p{Digit} ])/ or exit 0;
