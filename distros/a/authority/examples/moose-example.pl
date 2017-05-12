#!/usr/bin/perl

use 5.010;
use authority 'cpan:STEVAN', 'Moose';

say Moose->can('has') ? 'Moose can has' : 'Moose cannot has';
